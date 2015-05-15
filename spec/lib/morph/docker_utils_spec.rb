require 'spec_helper'

describe Morph::DockerUtils do
  describe ".create_tar" do
    it "should preserve the symbolic link" do
      tar = Dir.mktmpdir do |dest|
        FileUtils.ln_s "scraper.rb", File.join(dest, "link.rb")
        Morph::DockerUtils.create_tar(dest)
      end

      Dir.mktmpdir do |dir|
        Morph::DockerUtils.in_directory(dir) do
          File.open("test.tar", "w") {|f| f << tar}
          # Quick and dirty
          `tar xf test.tar`
          File.symlink?("link.rb").should be_truthy
          File.readlink("link.rb").should == "scraper.rb"
        end
      end
    end
  end
end
