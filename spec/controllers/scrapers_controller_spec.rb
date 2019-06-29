require 'spec_helper'

describe ScrapersController do
  let(:user) { create(:user, nickname: 'mlandauer') }
  let(:organization) do
    o = create(:organization, nickname: 'org')
    o.users << user
    o
  end

  describe '#destroy' do
    context 'not signed in' do
      it 'should not allow you to delete a scraper' do
        VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
          create(:scraper, owner: user, name: 'a_scraper',
                           full_name: 'mlandauer/a_scraper')
        end
        delete :destroy, id: 'mlandauer/a_scraper'
        expect(Scraper.count).to eq 1
      end
    end

    context 'signed in' do
      before :each do
        sign_in user
      end

      context 'you own the scraper' do
        before :each do
          VCR.use_cassette('scraper_validations',
                           allow_playback_repeats: true) do
            Scraper.create(owner: user, name: 'a_scraper',
                           full_name: 'mlandauer/a_scraper')
          end
        end

        it 'should allow you to delete the scraper' do
          delete :destroy, id: 'mlandauer/a_scraper'
          expect(Scraper.count).to eq 0
        end

        it 'should redirect to the owning user' do
          delete :destroy, id: 'mlandauer/a_scraper'
          expect(response).to redirect_to user_url(user)
        end
      end

      context "an organisation you're part of owns the scraper" do
        before :each do
          VCR.use_cassette('scraper_validations',
                           allow_playback_repeats: true) do
            Scraper.create(owner: organization, name: 'a_scraper',
                           full_name: 'org/a_scraper')
          end
        end

        it "should allow you to delete a scraper if it's owner by an "\
           "organisation you're part of" do
          delete :destroy, id: 'org/a_scraper'
          expect(Scraper.count).to eq 0
        end

        it 'should redirect to the owning organisation' do
          delete :destroy, id: 'org/a_scraper'
          expect(response).to redirect_to organization_url(organization)
        end
      end

      it "should not allow you to delete a scraper if you don't own the "\
         'scraper' do
        other_user = User.create(nickname: 'otheruser')
        VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
          Scraper.create(owner: other_user, name: 'a_scraper',
                         full_name: 'otheruser/a_scraper')
        end
        expect { delete :destroy, id: 'otheruser/a_scraper' }
          .to raise_error(CanCan::AccessDenied)
        expect(Scraper.count).to eq 1
      end

      it "should not allow you to delete a scraper if it's owner is an "\
         "organisation your're not part of" do
        other_organisation = Organization.create(nickname: 'otherorg')
        VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
          Scraper.create(owner: other_organisation, name: 'a_scraper',
                         full_name: 'otherorg/a_scraper')
        end
        expect { delete :destroy, id: 'otherorg/a_scraper' }
          .to raise_error(CanCan::AccessDenied)
        expect(Scraper.count).to eq 1
      end
    end
  end

  describe '#create_scraperwiki' do
    before :each do
      sign_in user
    end

    it 'should error if the scraper already exists on morph.io' do
      scraperwiki_double = double('Morph::Scraperwiki',
                                  exists?: true,
                                  private_scraper?: false,
                                  view?: false)
      expect(Morph::Scraperwiki).to receive(:new).at_least(:once)
                                                 .and_return(scraperwiki_double)

      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        create :scraper, owner: user
        post :create_scraperwiki, scraper: {
          name: 'my_scraper',
          owner_id: user.id,
          scraperwiki_shortname: 'my_scraper'
        }
      end

      expect(assigns(:scraper).errors[:name])
        .to eq ['is already taken on morph.io']
    end

    it 'should error if the scraper already exists on GitHub' do
      scraperwiki_double = double('Morph::Scraperwiki',
                                  exists?: true,
                                  private_scraper?: false,
                                  view?: false)
      expect(Morph::Scraperwiki).to receive(:new).at_least(:once)
                                                 .and_return(scraperwiki_double)
      expect(Octokit).to receive(:repository?).and_return(true)

      post :create_scraperwiki, scraper: {
        name: 'my_scraper',
        owner_id: user.id,
        scraperwiki_shortname: 'my_scraper'
      }

      expect(assigns(:scraper).errors[:name])
        .to eq ['is already taken on GitHub']
    end

    it 'should error if the ScraperWiki shortname is not set' do
      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        post :create_scraperwiki, scraper: {
          name: 'my_scraper',
          owner_id: user.id
        }
      end

      expect(assigns(:scraper).errors[:scraperwiki_shortname])
        .to eq ['cannot be blank']
    end

    it "should error if the scraper doesn't exist on ScraperWiki" do
      scraperwiki_double = double('Morph::Scraperwiki',
                                  exists?: false,
                                  private_scraper?: false,
                                  view?: false)
      expect(Morph::Scraperwiki).to receive(:new).at_least(:once)
                                                 .and_return(scraperwiki_double)

      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        post :create_scraperwiki, scraper: {
          name: 'my_scraper',
          owner_id: user.id,
          scraperwiki_shortname: 'missing_scraper'
        }
      end

      expect(assigns(:scraper).errors[:scraperwiki_shortname])
        .to eq ["doesn't exist on ScraperWiki"]
    end

    it 'should error if the ScraperWiki scraper is private' do
      scraperwiki_double = double('Morph::Scraperwiki',
                                  exists?: true,
                                  private_scraper?: true,
                                  view?: false)
      expect(Morph::Scraperwiki).to receive(:new).at_least(:once)
                                                 .and_return(scraperwiki_double)

      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        post :create_scraperwiki, scraper: {
          name: 'my_scraper',
          owner_id: user.id,
          scraperwiki_shortname: 'private_scraper'
        }
      end

      expect(assigns(:scraper).errors[:scraperwiki_shortname])
        .to eq ['needs to be a public scraper on ScraperWiki']
    end

    it 'should error if the ScraperWiki scraper is private' do
      scraperwiki_double = double('Morph::Scraperwiki',
                                  exists?: true,
                                  private_scraper?: false,
                                  view?: true)
      expect(Morph::Scraperwiki).to receive(:new).at_least(:once)
                                                 .and_return(scraperwiki_double)

      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        post :create_scraperwiki, scraper: {
          name: 'my_scraper',
          owner_id: user.id,
          scraperwiki_shortname: 'some_view'
        }
      end

      expect(assigns(:scraper).errors[:scraperwiki_shortname])
        .to eq ["can't be a ScraperWiki view"]
    end

    it 'should call ForkScraperwikiWorker if all looks good' do
      scraperwiki_double = double('Morph::Scraperwiki',
                                  exists?: true,
                                  private_scraper?: false,
                                  view?: false)
      expect(Morph::Scraperwiki).to receive(:new).at_least(:once)
                                                 .and_return(scraperwiki_double)

      expect(ForkScraperwikiWorker).to receive(:perform_async)

      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        post :create_scraperwiki, scraper: {
          name: 'my_scraper',
          owner_id: user.id,
          scraperwiki_shortname: 'missing_scraper'
        }
      end
    end

    it 'should not attempt to fork if ScraperWiki shortname is not set' do
      expect(ForkScraperwikiWorker).to_not receive(:perform_async)

      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        post :create_scraperwiki, scraper: {
          name: 'my_scraper',
          owner_id: user.id
        }
      end
    end
  end
end
