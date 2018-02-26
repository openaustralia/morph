require 'spec_helper'

describe ApiController do
  describe '#run_remote' do
    let(:user) { User.create! }
    let(:code) do
      # Is there a chance the temp file will get garbage collected?
      temp = Dir.mktmpdir do |dir|
        File.open(File.join(dir, 'scraper.rb'), 'w') do |f|
          f << %q(
puts 'Hello!'
          )
        end
        Morph::DockerUtils.create_tar_file(dir)
      end

      Rack::Test::UploadedFile.new(temp.path, nil, true)
    end
    before(:each) { user }

    it "shouldn't work without an api key" do
      post :run_remote
      expect(response.response_code).to eq 401
      expect(response.body).to eq 'API key is not valid'
    end

    it "shouldn't work without a valid api key" do
      post :run_remote, api_key: "1234"
      expect(response.response_code).to eq 401
      expect(response.body).to eq 'API key is not valid'
    end

    it 'should fail when site is in read-only mode' do
      ability = double(Ability)
      expect(Ability).to receive(:new).with(user).and_return(ability)
      expect(ability).to receive(:can?).with(:create, Run).and_return(false)

      post :run_remote, api_key: user.api_key, code: code

      expect(response).to be_success
      parsed = response.body.split("\n").map { |l| JSON.parse(l) }
      expect(parsed).to eq [{
        'stream' => 'internalerr',
        'text'   => "You currently can't start a scraper run." \
                    ' See https://morph.io for more details'
      }]
    end

    it 'should work with a valid api key' do
      runner = double(Morph::Runner)
      expect(Morph::Runner).to receive(:new).and_return(runner)
      expect(runner).to receive(:go).and_yield(
        nil, 'internalout', "Injecting configuration and compiling...\n"
      ).and_yield(
        nil, 'internalout', "Injecting scraper and running...\n"
      ).and_yield(
        nil, 'stdout', "Hello!\n"
      )
      expect(runner).to receive(:container_for_run).and_return(nil)

      post :run_remote, api_key: user.api_key, code: code

      expect(response).to be_success
      parsed = response.body.split("\n").map{|l| JSON.parse(l)}
      expect(parsed).to eq [
        {
          'stream' => 'internalout',
          'text'   => "Injecting configuration and compiling...\n"
        },
        {
          'stream' => 'internalout',
          'text'   => "Injecting scraper and running...\n" },
        {
          'stream' => 'stdout',
          'text'   => "Hello!\n" }
      ]
    end

    skip 'should test streaming'
  end

  describe '#data' do
    let(:user) { create(:user, nickname: 'mlandauer') }
    render_views

    before :each do
      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        # Freezing time so that the updated time of the scraper is set to a
        # consistent time. Makes a later test easier to handle
        Timecop.freeze(Time.utc(2000)) do
          Scraper.create(owner: user, name: 'a_scraper',
                         full_name: 'mlandauer/a_scraper')
        end
      end

      allow_any_instance_of(Scraper)
        .to receive_message_chain(:database, :sql_query) do
        [
          {
            'title' => 'Foo',
            'content' => 'Bar',
            'link' => 'http://example.com',
            'date' => '2013-01-01'
          }
        ]
      end
      allow_any_instance_of(Scraper)
        .to receive_message_chain(:database, :sql_query_streaming).and_yield(
          {
            'title' => 'Foo',
            'content' => 'Bar',
            'link' => 'http://example.com',
            'date' => '2013-01-01'
          }
        )
      allow_any_instance_of(Scraper)
        .to receive_message_chain(:database, :sqlite_db_path)
        .and_return('/path/to/db.sqlite')
      allow_any_instance_of(Scraper)
        .to receive_message_chain(:database, :sqlite_db_size)
        .and_return(12)
    end

    context 'user not signed in and no key provided' do
      it 'should return an error in json' do
        get :data, id: 'mlandauer/a_scraper', format: :json
        expect(response.code).to eq '401'
        expect(JSON.parse(response.body))
          .to eq 'error' => 'API key is missing'
        expect(response.content_type).to eq 'application/json'
      end

      it 'should return csv error as text' do
        get :data, id: 'mlandauer/a_scraper', format: :csv
        expect(response.code).to eq '401'
        expect(response.body).to eq 'API key is missing'
        expect(response.content_type).to eq 'text'
      end

      it 'should return atom feed error as text' do
        get :data, id: 'mlandauer/a_scraper', format: :atom
        expect(response.code).to eq '401'
        expect(response.body).to eq 'API key is missing'
        expect(response.content_type).to eq 'text'
      end

      it 'should return sqlite error as text' do
        get :data, id: 'mlandauer/a_scraper', format: :sqlite
        expect(response.code).to eq '401'
        expect(response.body).to eq 'API key is missing'
        expect(response.content_type).to eq 'text'
      end
    end

    context 'user not signed in and incorrect key provided' do
      it 'should return an error in json' do
        get :data, id: 'mlandauer/a_scraper', key: 'foo', format: :json
        expect(response.code).to eq '401'
        expect(JSON.parse(response.body))
          .to eq 'error' => 'API key is not valid'
        expect(response.content_type).to eq 'application/json'
      end

      it 'should return csv error as text' do
        get :data, id: 'mlandauer/a_scraper', key: 'foo', format: :csv
        expect(response.code).to eq '401'
        expect(response.body).to eq 'API key is not valid'
        expect(response.content_type).to eq 'text'
      end

      it 'should return atom feed error as text' do
        get :data, id: 'mlandauer/a_scraper', key: 'foo', format: :atom
        expect(response.code).to eq '401'
        expect(response.body).to eq 'API key is not valid'
        expect(response.content_type).to eq 'text'
      end

      it 'should return sqlite error as text' do
        get :data, id: 'mlandauer/a_scraper', key: 'foo', format: :sqlite
        expect(response.code).to eq '401'
        expect(response.body).to eq 'API key is not valid'
        expect(response.content_type).to eq 'text'
      end
    end

    context 'user not signed in and correct key provided' do
      before :each do
        user.update_attributes(api_key: '1234')
      end

      it 'should return json' do
        get :data, id: 'mlandauer/a_scraper', key: '1234', format: :json
        expect(response).to be_success
        expect(JSON.parse(response.body)).to eq [
          {
            'title' => 'Foo',
            'content' => 'Bar',
            'link' => 'http://example.com',
            'date' => '2013-01-01'
          }
        ]
      end

      it 'should return jsonp' do
        get :data, id: 'mlandauer/a_scraper', key: '1234', format: :json, callback: 'foo'
        expect(response).to be_success
        expect(response.body).to eq <<-EOF
/**/foo([
{"title":"Foo","content":"Bar","link":"http://example.com","date":"2013-01-01"}
])
        EOF
      end

      it 'should return csv' do
        get :data, id: 'mlandauer/a_scraper', key: '1234', format: :csv
        expect(response).to be_success

        expect(response.body)
          .to eq <<-EOF
title,content,link,date
Foo,Bar,http://example.com,2013-01-01
          EOF
      end

      it 'should return an atom feed' do
        get :data, id: 'mlandauer/a_scraper', key: '1234', format: :atom

        expect(response).to be_success
        expect(response.body).to eq <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <title>morph.io: mlandauer/a_scraper</title>
  <subtitle></subtitle>
  <updated>2000-01-01T00:00:00+00:00</updated>
  <author>
    <name>mlandauer</name>
  </author>
  <id>http://test.host/mlandauer/a_scraper/data.atom?key=1234</id>
  <link href="http://test.host/mlandauer/a_scraper"/>
  <link href="http://test.host/mlandauer/a_scraper/data.atom?key=1234" rel="self"/>
  <entry>
    <title>Foo</title>
    <content>Bar</content>
    <link href="http://example.com"/>
    <id>http://example.com</id>
    <updated>2013-01-01T00:00:00+00:00</updated>
  </entry>
</feed>
        EOF
      end

      # TODO: Figure out how to test the sqlite download sensibly
    end

    context 'user signed in and no key provided' do
      before :each do
        sign_in user
      end

      it 'should return error with json' do
        get :data, id: 'mlandauer/a_scraper', format: :json
        expect(response).to_not be_success
      end

      it 'should return error with csv' do
        get :data, id: 'mlandauer/a_scraper', format: :csv
        expect(response).to_not be_success
      end

      it 'should return error with atom feed' do
        get :data, id: 'mlandauer/a_scraper', format: :atom
        expect(response).to_not be_success
      end

      it 'should return error with sqlite' do
        get :data, id: 'mlandauer/a_scraper', format: :sqlite
        expect(response).to_not be_success
      end
    end
  end
end
