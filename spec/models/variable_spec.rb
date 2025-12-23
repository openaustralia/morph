# typed: false
# frozen_string_literal: true

# == Schema Information
#
# Table name: variables
#
#  id         :integer          not null, primary key
#  name       :string(255)      not null
#  value      :text(65535)      not null
#  created_at :datetime
#  updated_at :datetime
#  scraper_id :integer
#
# Indexes
#
#  fk_rails_f537200e37  (scraper_id)
#
# Foreign Keys
#
#  fk_rails_...  (scraper_id => scrapers.id)
#

require "spec_helper"

describe Variable do
  let(:scraper) { create(:scraper) }

  it "allows really long values" do
    value = "https://github.com/openaustralia/australian_local_councillors_popolo/raw/master/nsw_local_councillor_popolo.json https://github.com/openaustralia/australian_local_councillors_popolo/raw/master/vic_local_councillor_popolo.json https://github.com/openaustralia/australian_local_councillors_popolo/raw/master/qld_local_councillor_popolo.json https://github.com/openaustralia/australian_local_councillors_popolo/raw/master/wa_local_councillor_popolo.json https://github.com/openaustralia/australian_local_councillors_popolo/raw/master/tas_local_councillor_popolo.json https://github.com/openaustralia/australian_local_councillors_popolo/raw/master/act_local_councillor_popolo.json https://github.com/openaustralia/australian_local_councillors_popolo/raw/master/nt_local_councillor_popolo.json"

    variable = described_class.create!(scraper: scraper, name: "MORPH_TEST", value: value)

    expect(variable.value).to eql value
  end
end
