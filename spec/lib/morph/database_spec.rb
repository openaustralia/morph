require 'spec_helper'

describe Morph::Database do
  describe '#clear' do
    it "should not raise an error if there's no file" do
      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        expect { Morph::Database.new(create(:scraper)).clear }.not_to raise_error
      end
    end

    it "should attempt to remove the file if it's not there" do
      FileUtils.should_not_receive(:rm)
      VCR.use_cassette('scraper_validations', allow_playback_repeats: true) do
        Morph::Database.new(create(:scraper)).clear.should_not raise_error
      end
    end
  end
end
