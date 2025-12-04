# typed: false
# frozen_string_literal: true

# == Schema Information
#
# Table name: owners
#
#  id                     :integer          not null, primary key
#  access_token           :string(255)
#  admin                  :boolean          default(FALSE), not null
#  alerted_at             :datetime
#  api_key                :string(255)
#  blog                   :string(255)
#  company                :string(255)
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string(255)
#  email                  :string(255)
#  feature_switches       :string(255)
#  gravatar_url           :string(255)
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string(255)
#  location               :string(255)
#  name                   :string(255)
#  nickname               :string(255)
#  provider               :string(255)
#  remember_created_at    :datetime
#  remember_token         :string(255)
#  sign_in_count          :integer          default(0), not null
#  suspended              :boolean          default(FALSE), not null
#  type                   :string(255)
#  uid                    :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  stripe_customer_id     :string(255)
#  stripe_plan_id         :string(255)
#  stripe_subscription_id :string(255)
#
# Indexes
#
#  index_owners_on_api_key   (api_key)
#  index_owners_on_nickname  (nickname)
#
require "spec_helper"

describe User do
  let(:user) { described_class.new }

  context "when user has no scrapers" do
    describe "#watched_successful_scrapers" do
      it { expect(user.watched_successful_scrapers).to eq [] }
    end

    describe "#watched_broken_scrapers" do
      it { expect(user.watched_broken_scrapers).to eq [] }
    end
  end

  context "when user is watching one scraper and it ran successfully" do
    let(:scraper) { mock_model(Scraper, finished_successfully?: true, finished_with_errors?: false, finished_recently?: true) }

    before do
      allow(user).to receive(:all_scrapers_watched).and_return([scraper])
    end

    describe "#watched_successful_scrapers" do
      it { expect(user.watched_successful_scrapers).to eq [scraper] }
    end

    describe "#watched_broken_scrapers" do
      it { expect(user.watched_broken_scrapers).to eq [] }
    end
  end

  context "when user is watching one scraper and it ran successfully but not recently" do
    let(:scraper) { mock_model(Scraper, finished_successfully?: true, finished_with_errors?: false, finished_recently?: false) }

    before do
      allow(user).to receive(:all_scrapers_watched).and_return([scraper])
    end

    describe "#watched_successful_scrapers" do
      it { expect(user.watched_successful_scrapers).to eq [] }
    end

    describe "#watched_broken_scrapers" do
      it { expect(user.watched_broken_scrapers).to eq [] }
    end
  end

  context "when user is watching one scraper and it failed" do
    let(:scraper) { mock_model(Scraper, finished_successfully?: false, finished_with_errors?: true, finished_recently?: true) }

    before do
      allow(user).to receive(:all_scrapers_watched).and_return([scraper])
    end

    describe "#watched_successful_scrapers" do
      it { expect(user.watched_successful_scrapers).to eq [] }
    end

    describe "#watched_broken_scrapers" do
      it { expect(user.watched_broken_scrapers).to eq [scraper] }
    end
  end

  context "when user is watching two scrapers, one failed and one ran successfully" do
    let(:scraper1) { mock_model(Scraper, finished_successfully?: false, finished_with_errors?: true, finished_recently?: true) }
    let(:scraper2) { mock_model(Scraper, finished_successfully?: true, finished_with_errors?: false, finished_recently?: true) }

    before do
      allow(user).to receive(:all_scrapers_watched).and_return([scraper1, scraper2])
    end

    describe "#watched_successful_scrapers" do
      it { expect(user.watched_successful_scrapers).to eq [scraper2] }
    end

    describe "#watched_broken_scrapers" do
      it { expect(user.watched_broken_scrapers).to eq [scraper1] }
    end
  end
end
