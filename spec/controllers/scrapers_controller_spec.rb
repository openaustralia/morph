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

  describe '#data' do
    render_views

    before :each do
      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        Scraper.create(owner: user, name: 'a_scraper',
                       full_name: 'mlandauer/a_scraper')
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
        body = Nokogiri::XML(response.body)

        expect(body.css('title').first.text)
          .to eq 'morph.io: mlandauer/a_scraper'
        expect(body.css('author name').first.text).to eq 'mlandauer'
        expect(body.css('link').first[:href])
          .to eq 'http://test.host/mlandauer/a_scraper'

        expect(body.css('entry').count).to eq 1
        expect(body.css('entry > title').first.text).to eq 'Foo'
        expect(body.css('entry > content').first.text).to eq 'Bar'
        expect(body.css('entry > link').first[:href]).to eq 'http://example.com'
        expect(body.css('entry > updated').first.text)
          .to eq Date.new(2013, 1, 1).rfc3339
      end

      it 'should return sqlite' do
        expect(controller).to receive(:send_file)
          .with('/path/to/db.sqlite', filename: 'a_scraper.sqlite') do
            controller.render nothing: true
          end
        get :data, id: 'mlandauer/a_scraper', key: '1234', format: :sqlite
        expect(response).to be_success
      end
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
