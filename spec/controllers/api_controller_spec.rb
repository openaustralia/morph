# typed: false
# frozen_string_literal: true

require "spec_helper"

describe ApiController do
  describe "#run_remote" do
    let(:user) { User.create! }
    let(:code) do
      # Is there a chance the temp file will get garbage collected?
      temp = Dir.mktmpdir do |dir|
        File.open(File.join(dir, "scraper.rb"), "w") do |f|
          f << "puts 'Hello!'\n"
        end
        Morph::DockerUtils.create_tar_file(dir)
      end

      Rack::Test::UploadedFile.new(temp.path, nil, true)
    end

    before { user }

    it "does not work without an api key" do
      post :run_remote
      expect(response.response_code).to eq 401
      expect(response.body).to eq "API key is not valid"
    end

    it "does not work without a valid api key" do
      post :run_remote, params: { api_key: "1234" }
      expect(response.response_code).to eq 401
      expect(response.body).to eq "API key is not valid"
    end

    it "fails when site is in read-only mode" do
      ability = instance_double(Ability)
      allow(Ability).to receive(:new).with(user).and_return(ability)
      allow(ability).to receive(:can?).with(:create, Run).and_return(false)

      post :run_remote, params: { api_key: user.api_key, code: code }

      expect(response).to be_success
      parsed = response.body.split("\n").map { |l| JSON.parse(l) }
      expect(parsed).to eq [{
        "stream" => "internalerr",
        "text" => "You currently can't start a scraper run. " \
                  "See https://morph.io for more details"
      }]
    end

    it "works with a valid api key" do
      runner = instance_double(Morph::Runner)
      allow(Morph::Runner).to receive(:new).and_return(runner)
      allow(runner).to receive(:go).and_yield(
        nil, "internalout", "Injecting configuration and compiling...\n"
      ).and_yield(
        nil, "internalout", "Injecting scraper and running...\n"
      ).and_yield(
        nil, "stdout", "Hello!\n"
      )
      allow(runner).to receive(:container_for_run).and_return(nil)

      post :run_remote, params: { api_key: user.api_key, code: code }

      expect(response).to be_success
      parsed = response.body.split("\n").map { |l| JSON.parse(l) }
      expect(parsed).to eq [
        {
          "stream" => "internalout",
          "text" => "Injecting configuration and compiling...\n"
        },
        {
          "stream" => "internalout",
          "text" => "Injecting scraper and running...\n"
        },
        {
          "stream" => "stdout",
          "text" => "Hello!\n"
        }
      ]
    end

    skip "should test streaming"
  end

  describe "#data" do
    let(:user) { create(:user, nickname: "mlandauer") }

    render_views

    before do
      VCR.use_cassette("scraper_validations", allow_playback_repeats: true) do
        # Freezing time so that the updated time of the scraper is set to a
        # consistent time. Makes a later test easier to handle
        Timecop.freeze(Time.utc(2000)) do
          Scraper.create(owner: user, name: "a_scraper",
                         full_name: "mlandauer/a_scraper")
        end
      end

      allow_any_instance_of(Scraper)
        .to receive_message_chain(:database, :sql_query) do
        [
          {
            "title" => "Foo",
            "content" => "Bar",
            "link" => "http://example.com",
            "date" => "2013-01-01"
          }
        ]
      end
      allow_any_instance_of(Scraper)
        .to receive_message_chain(:database, :sql_query_streaming).and_yield(
          "title" => "Foo",
          "content" => "Bar",
          "link" => "http://example.com",
          "date" => "2013-01-01"
        )
      allow_any_instance_of(Scraper)
        .to receive_message_chain(:database, :sqlite_db_path)
        .and_return("/path/to/db.sqlite")
      allow_any_instance_of(Scraper)
        .to receive_message_chain(:database, :sqlite_db_size)
        .and_return(12)
    end

    context "when user not signed in and no key provided" do
      it "returns an error in json" do
        get :data, params: { id: "mlandauer/a_scraper", format: :json }
        expect(response.code).to eq "401"
        expect(JSON.parse(response.body))
          .to eq "error" => "API key is missing"
        expect(response.content_type).to eq "application/json"
      end

      it "returns csv error as text" do
        get :data, params: { id: "mlandauer/a_scraper", format: :csv }
        expect(response.code).to eq "401"
        expect(response.body).to eq "API key is missing"
        expect(response.content_type).to eq "text"
      end

      it "returns atom feed error as text" do
        get :data, params: { id: "mlandauer/a_scraper", format: :atom }
        expect(response.code).to eq "401"
        expect(response.body).to eq "API key is missing"
        expect(response.content_type).to eq "text"
      end

      it "returns sqlite error as text" do
        get :data, params: { id: "mlandauer/a_scraper", format: :sqlite }
        expect(response.code).to eq "401"
        expect(response.body).to eq "API key is missing"
        expect(response.content_type).to eq "text"
      end
    end

    context "when user not signed in and incorrect key provided" do
      it "returns an error in json" do
        get :data, params: { id: "mlandauer/a_scraper", key: "foo", format: :json }
        expect(response.code).to eq "401"
        expect(JSON.parse(response.body))
          .to eq "error" => "API key is not valid"
        expect(response.content_type).to eq "application/json"
      end

      it "returns csv error as text" do
        get :data, params: { id: "mlandauer/a_scraper", key: "foo", format: :csv }
        expect(response.code).to eq "401"
        expect(response.body).to eq "API key is not valid"
        expect(response.content_type).to eq "text"
      end

      it "returns atom feed error as text" do
        get :data, params: { id: "mlandauer/a_scraper", key: "foo", format: :atom }
        expect(response.code).to eq "401"
        expect(response.body).to eq "API key is not valid"
        expect(response.content_type).to eq "text"
      end

      it "returns sqlite error as text" do
        get :data, params: { id: "mlandauer/a_scraper", key: "foo", format: :sqlite }
        expect(response.code).to eq "401"
        expect(response.body).to eq "API key is not valid"
        expect(response.content_type).to eq "text"
      end
    end

    context "when user not signed in and correct key provided" do
      before do
        user.update(api_key: "1234")
      end

      it "returns json" do
        get :data, params: { id: "mlandauer/a_scraper", key: "1234", format: :json, query: "something" }
        expect(response).to be_success
        expect(JSON.parse(response.body)).to eq [
          {
            "title" => "Foo",
            "content" => "Bar",
            "link" => "http://example.com",
            "date" => "2013-01-01"
          }
        ]
        expect(response.headers["Content-Type"]).to eq "application/json; charset=utf-8"
      end

      it "returns jsonp" do
        get :data, params: { id: "mlandauer/a_scraper", key: "1234", format: :json, callback: "foo", query: "something" }
        expect(response).to be_success
        expect(response.body).to eq <<~RESPONSE
          /**/foo([
          {"title":"Foo","content":"Bar","link":"http://example.com","date":"2013-01-01"}
          ])
        RESPONSE
        expect(response.headers["Content-Type"]).to eq "application/javascript; charset=utf-8"
      end

      it "returns csv" do
        get :data, params: { id: "mlandauer/a_scraper", key: "1234", format: :csv, query: "something" }
        expect(response).to be_success

        expect(response.body)
          .to eq <<~RESPONSE
            title,content,link,date
            Foo,Bar,http://example.com,2013-01-01
          RESPONSE
      end

      it "returns an atom feed" do
        # There's a deadlock during tests when writing more than 10 times with ActionController.Live
        # This is fixed in recent versions of rails but this is a workaround for this particular test
        # case which writes many lines
        # https://github.com/rails/rails/issues/31813
        # TODO: Remove this workaround when we've upgraded rails
        allow(SizedQueue).to receive(:new).and_return(SizedQueue.new(1000))

        get :data, params: { id: "mlandauer/a_scraper", key: "1234", format: :atom, query: "something" }

        expect(response).to be_success
        expect(response.body).to eq <<~RESPONSE
          <?xml version="1.0" encoding="UTF-8"?>
          <feed xmlns="http://www.w3.org/2005/Atom" xmlns:dc="http://purl.org/dc/elements/1.1/">
            <title>morph.io: mlandauer/a_scraper</title>
            <subtitle></subtitle>
            <updated>2000-01-01T00:00:00+00:00</updated>
            <author>
              <name>mlandauer</name>
            </author>
            <id>http://test.host/mlandauer/a_scraper/data.atom?key=1234&query=something</id>
            <link href="http://test.host/mlandauer/a_scraper"/>
            <link href="http://test.host/mlandauer/a_scraper/data.atom?key=1234&query=something" rel="self"/>
            <entry>
              <title>Foo</title>
              <content>Bar</content>
              <link href="http://example.com"/>
              <id>http://example.com</id>
              <updated>2013-01-01T00:00:00+00:00</updated>
            </entry>
          </feed>
        RESPONSE
      end

      # TODO: Figure out how to test the sqlite download sensibly
    end

    context "when user signed in and no key provided" do
      before do
        sign_in user
      end

      it "returns error with json" do
        get :data, params: { id: "mlandauer/a_scraper", format: :json }
        expect(response).not_to be_success
      end

      it "returns error with csv" do
        get :data, params: { id: "mlandauer/a_scraper", format: :csv }
        expect(response).not_to be_success
      end

      it "returns error with atom feed" do
        get :data, params: { id: "mlandauer/a_scraper", format: :atom }
        expect(response).not_to be_success
      end

      it "returns error with sqlite" do
        get :data, params: { id: "mlandauer/a_scraper", format: :sqlite }
        expect(response).not_to be_success
      end
    end
  end
end
