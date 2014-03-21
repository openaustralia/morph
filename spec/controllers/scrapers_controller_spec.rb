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
        delete :destroy, id: "otheruser/a_scraper"
        Scraper.count.should == 1
      end

      it "should not allow you to delete a scraper if it's owner is an organisation your're not part of" do
        other_organisation = Organization.create(nickname: "otherorg")
        VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
          scraper = Scraper.create(owner: other_organisation, name: "a_scraper", full_name: "otherorg/a_scraper")
        end
        delete :destroy, id: "otherorg/a_scraper"
        Scraper.count.should == 1
      end
    end
  end

  describe '#create_scraperwiki' do
    before :each do
      sign_in user
    end

    it 'should error if the scraper already exists on Morph' do
      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        create :scraper, full_name: "#{user.nickname}/my_scraper"
        post :create_scraperwiki, scraper: { name: 'my_scraper', owner_id: user.id }
      end
      assigns(:scraper).errors[:name].should == ['is already taken on Morph']
    end

    it 'should error if the scraper already exists on GitHub' do
      Morph::Github.stub(:in_public_use?).and_return(true)
      post :create_scraperwiki, scraper: { name: 'my_scraper', owner_id: user.id }
      assigns(:scraper).errors[:name].should == ['is already taken on GitHub']
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
  end
end
