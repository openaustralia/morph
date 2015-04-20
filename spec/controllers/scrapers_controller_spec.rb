require 'spec_helper'

describe ScrapersController do
  let(:user) { create(:user, nickname: "mlandauer") }
  let(:organization) do
    o = create(:organization, nickname: "org")
    o.users << user
    o
  end

  describe "#destroy" do
    context "not signed in" do
      it "should not allow you to delete a scraper" do
        VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
          create(:scraper, owner: user, name: "a_scraper", full_name: "mlandauer/a_scraper")
        end
        delete :destroy, id: "mlandauer/a_scraper"
        Scraper.count.should == 1
      end
    end

    context "signed in" do
      before :each do
        sign_in user
      end

      context "you own the scraper" do
        before :each do
          VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
            Scraper.create(owner: user, name: "a_scraper", full_name: "mlandauer/a_scraper")
          end
        end

        it "should allow you to delete the scraper" do
          delete :destroy, id: "mlandauer/a_scraper"
          Scraper.count.should == 0
        end

        it "should redirect to the owning user" do
          delete :destroy, id: "mlandauer/a_scraper"
          response.should redirect_to user_url(user)
        end
      end

      context "an organisation you're part of owns the scraper" do
        before :each do
          VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
            Scraper.create(owner: organization, name: "a_scraper", full_name: "org/a_scraper")
          end
        end

        it "should allow you to delete a scraper if it's owner by an organisation you're part of" do
          delete :destroy, id: "org/a_scraper"
          Scraper.count.should == 0
        end

        it "should redirect to the owning organisation" do
          delete :destroy, id: "org/a_scraper"
          response.should redirect_to organization_url(organization)
        end
      end

      it "should not allow you to delete a scraper if you don't own the scraper" do
        other_user = User.create(nickname: "otheruser")
        VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
          scraper = Scraper.create(owner: other_user, name: "a_scraper", full_name: "otheruser/a_scraper")
        end
        expect{delete :destroy, id: "otheruser/a_scraper"}.to raise_error(CanCan::AccessDenied)
        Scraper.count.should == 1
      end

      it "should not allow you to delete a scraper if it's owner is an organisation your're not part of" do
        other_organisation = Organization.create(nickname: "otherorg")
        VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
          scraper = Scraper.create(owner: other_organisation, name: "a_scraper", full_name: "otherorg/a_scraper")
        end
        expect{delete :destroy, id: "otherorg/a_scraper"}.to raise_error(CanCan::AccessDenied)
        Scraper.count.should == 1
      end
    end
  end

  describe '#create_scraperwiki' do
    before :each do
      sign_in user
    end

    it 'should error if the scraper already exists on morph.io' do
      scraperwiki_double = double("Morph::Scraperwiki", exists?: true, private_scraper?: false, view?: false)
      Morph::Scraperwiki.should_receive(:new).at_least(:once).and_return(scraperwiki_double)

      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        create :scraper, owner: user
        post :create_scraperwiki, scraper: { name: 'my_scraper', owner_id: user.id, scraperwiki_shortname: 'my_scraper' }
      end

      assigns(:scraper).errors[:name].should == ['is already taken on morph.io']
    end

    it 'should error if the scraper already exists on GitHub' do
      scraperwiki_double = double("Morph::Scraperwiki", exists?: true, private_scraper?: false, view?: false)
      Morph::Scraperwiki.should_receive(:new).at_least(:once).and_return(scraperwiki_double)
      Morph::Github.stub(:in_public_use?).and_return(true)

      post :create_scraperwiki, scraper: { name: 'my_scraper', owner_id: user.id, scraperwiki_shortname: 'my_scraper' }

      assigns(:scraper).errors[:name].should == ['is already taken on GitHub']
    end

    it "should error if the ScraperWiki shortname is not set" do
      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        post :create_scraperwiki, scraper: { name: 'my_scraper', owner_id: user.id }
      end

      assigns(:scraper).errors[:scraperwiki_shortname].should == ["cannot be blank"]
    end

    it "should error if the scraper doesn't exist on ScraperWiki" do
      scraperwiki_double = double("Morph::Scraperwiki", exists?: false, private_scraper?: false, view?: false)
      Morph::Scraperwiki.should_receive(:new).at_least(:once).and_return(scraperwiki_double)

      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        post :create_scraperwiki, scraper: { name: 'my_scraper', owner_id: user.id, scraperwiki_shortname: 'missing_scraper' }
      end

      assigns(:scraper).errors[:scraperwiki_shortname].should == ["doesn't exist on ScraperWiki"]
    end

    it "should error if the ScraperWiki scraper is private" do
      scraperwiki_double = double("Morph::Scraperwiki", exists?: true, private_scraper?: true, view?: false)
      Morph::Scraperwiki.should_receive(:new).at_least(:once).and_return(scraperwiki_double)

      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        post :create_scraperwiki, scraper: { name: 'my_scraper', owner_id: user.id, scraperwiki_shortname: 'private_scraper' }
      end

      assigns(:scraper).errors[:scraperwiki_shortname].should == ["needs to be a public scraper on ScraperWiki"]
    end

    it "should error if the ScraperWiki scraper is private" do
      scraperwiki_double = double("Morph::Scraperwiki", exists?: true, private_scraper?: false, view?: true)
      Morph::Scraperwiki.should_receive(:new).at_least(:once).and_return(scraperwiki_double)

      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        post :create_scraperwiki, scraper: { name: 'my_scraper', owner_id: user.id, scraperwiki_shortname: 'some_view' }
      end

      assigns(:scraper).errors[:scraperwiki_shortname].should == ["can't be a ScraperWiki view"]
    end

    it "should call ForkScraperwikiWorker if all looks good" do
      scraperwiki_double = double("Morph::Scraperwiki", exists?: true, private_scraper?: false, view?: false)
      Morph::Scraperwiki.should_receive(:new).at_least(:once).and_return(scraperwiki_double)

      ForkScraperwikiWorker.should_receive(:perform_async)

      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        post :create_scraperwiki, scraper: { name: 'my_scraper', owner_id: user.id, scraperwiki_shortname: 'missing_scraper' }
      end
    end

    it "should not attempt to fork if ScraperWiki shortname is not set" do
      ForkScraperwikiWorker.should_not_receive(:perform_async)

      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        post :create_scraperwiki, scraper: { name: 'my_scraper', owner_id: user.id }
      end
    end
  end

  describe '#data' do
    render_views

    before :each do
      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        Scraper.create(owner: user, name: "a_scraper", full_name: "mlandauer/a_scraper")
      end

      Scraper.any_instance.stub_chain(:database, :sql_query) do
        [
          {
            "title" => "Foo",
            "content" => "Bar",
            "link" => "http://example.com",
            "date" => "2013-01-01"
          }
        ]
      end
      Scraper.any_instance.stub_chain(:database, :sqlite_db_path).and_return("/path/to/db.sqlite")
      Scraper.any_instance.stub_chain(:database, :sqlite_db_size).and_return(12)
    end

    context "user not signed in and no key provided" do
      it "should return an error in json" do
        get :data, id: "mlandauer/a_scraper", format: :json
        response.code.should == "401"
        JSON.parse(response.body).should == {
          "error"=>"API key is missing"
        }
        response.content_type.should == "application/json"
      end

      it "should return csv error as text" do
        get :data, id: "mlandauer/a_scraper", format: :csv
        response.code.should == "401"
        response.body.should == "API key is missing"
        response.content_type.should == "text"
      end

      it "should return atom feed error as text" do
        get :data, id: "mlandauer/a_scraper", format: :atom
        response.code.should == "401"
        response.body.should == "API key is missing"
        response.content_type.should == "text"
      end

      it "should return sqlite error as text" do
        get :data, id: "mlandauer/a_scraper", format: :sqlite
        response.code.should == "401"
        response.body.should == "API key is missing"
        response.content_type.should == "text"
      end
    end

    context "user not signed in and incorrect key provided" do
      it "should return an error in json" do
        get :data, id: "mlandauer/a_scraper", key: "foo", format: :json
        response.code.should == "401"
        JSON.parse(response.body).should == {
          "error"=>"API key is not valid"
        }
        response.content_type.should == "application/json"
      end

      it "should return csv error as text" do
        get :data, id: "mlandauer/a_scraper", key: "foo", format: :csv
        response.code.should == "401"
        response.body.should == "API key is not valid"
        response.content_type.should == "text"
      end

      it "should return atom feed error as text" do
        get :data, id: "mlandauer/a_scraper", key: "foo", format: :atom
        response.code.should == "401"
        response.body.should == "API key is not valid"
        response.content_type.should == "text"
      end

      it "should return sqlite error as text" do
        get :data, id: "mlandauer/a_scraper", key: "foo", format: :sqlite
        response.code.should == "401"
        response.body.should == "API key is not valid"
        response.content_type.should == "text"
      end
    end

    context "user not signed in and correct key provided" do
      before :each do
        user.update_attributes(api_key: "1234")
      end

      it "should return json" do
        get :data, id: "mlandauer/a_scraper", key: "1234", format: :json
        response.should be_success
        JSON.parse(response.body).should == [
          {
            "title" => "Foo",
            "content" => "Bar",
            "link" => "http://example.com",
            "date" => "2013-01-01"
          }
        ]
      end

      it "should return csv" do
        get :data, id: "mlandauer/a_scraper", key: "1234", format: :csv
        response.should be_success

        response.body.should == "title,content,link,date\nFoo,Bar,http://example.com,2013-01-01\n"
      end

      it "should return an atom feed" do
        get :data, id: "mlandauer/a_scraper", key: "1234", format: :atom

        response.should be_success
        body = Nokogiri::XML(response.body)

        body.css("title").first.text.should == "morph.io: mlandauer/a_scraper"
        body.css("author name").first.text.should == "mlandauer"
        body.css("link").first[:href].should == "http://test.host/mlandauer/a_scraper"

        body.css("entry").count.should == 1
        body.css("entry > title").first.text.should == "Foo"
        body.css("entry > content").first.text.should == "Bar"
        body.css("entry > link").first[:href].should == "http://example.com"
        body.css("entry > updated").first.text.should == DateTime.parse("2013-01-01").rfc3339
      end

      it "should return sqlite" do
        controller.should_receive(:send_file).with("/path/to/db.sqlite", filename: "a_scraper.sqlite") {controller.render nothing: true}
        get :data, id: "mlandauer/a_scraper", key: "1234", format: :sqlite
        response.should be_success
      end
    end

    context "user signed in and no key provided" do
      before :each do
        sign_in user
      end

      it "should return error with json" do
        get :data, id: "mlandauer/a_scraper", format: :json
        response.should_not be_success
      end

      it "should return error with csv" do
        get :data, id: "mlandauer/a_scraper", format: :csv
        response.should_not be_success
      end

      it "should return error with atom feed" do
        get :data, id: "mlandauer/a_scraper", format: :atom
        response.should_not be_success
      end

      it "should return error with sqlite" do
        get :data, id: "mlandauer/a_scraper", format: :sqlite
        response.should_not be_success
      end
    end
  end
end
