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

      response.should be_success
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
        'internalout', "Injecting configuration and compiling...\n"
      ).and_yield(
        'internalout', "Injecting scraper and running...\n"
      ).and_yield(
        'stdout', "Hello!\n"
      )

      post :run_remote, api_key: user.api_key, code: code

      response.should be_success
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
end
