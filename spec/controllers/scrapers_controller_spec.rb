require 'spec_helper'

describe ScrapersController do
  describe "#destroy" do
    let(:user) { User.create(nickname: "mlandauer") }
    let(:organization) do
      o = Organization.create(nickname: "org")
      o.users << user
      o
    end

    context "not signed in" do
      it "should not allow you to delete a scraper" do
        scraper = Scraper.create(owner: user, name: "a_scraper", full_name: "mlandauer/a_scraper")
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
          Scraper.create(owner: user, name: "a_scraper", full_name: "mlandauer/a_scraper")
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
          Scraper.create(owner: organization, name: "a_scraper", full_name: "org/a_scraper")
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
        scraper = Scraper.create(owner: other_user, name: "a_scraper", full_name: "otheruser/a_scraper")
        delete :destroy, id: "otheruser/a_scraper"
        Scraper.count.should == 1
      end

      it "should not allow you to delete a scraper if it's owner is an organisation your're not part of" do
        other_organisation = Organization.create(nickname: "otherorg")
        scraper = Scraper.create(owner: other_organisation, name: "a_scraper", full_name: "otherorg/a_scraper")
        delete :destroy, id: "otherorg/a_scraper"
        Scraper.count.should == 1
      end
    end
  end
end
