require 'spec_helper'

describe Morph::Database do
  describe '#clear' do
    it "should attempt to remove the file if it's not there" do
      FileUtils.should_not_receive(:rm)
      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        Morph::Database.new(create(:scraper)).clear
      end
    end
  end
end
