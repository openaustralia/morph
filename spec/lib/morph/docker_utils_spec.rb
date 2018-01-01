require 'spec_helper'

describe Morph::DockerUtils do
  describe '.create_tar' do
    it 'should preserve the symbolic link' do
      tar = Dir.mktmpdir do |dest|
        FileUtils.ln_s 'scraper.rb', File.join(dest, 'link.rb')
        Morph::DockerUtils.create_tar(dest)
      end

      Dir.mktmpdir do |dir|
        path = File.join(dir, 'test.tar')
        File.open(path, 'w') { |f| f << tar }
        # Quick and dirty
        `tar xf #{path} -C #{dir}`
        expect(File.symlink?(File.join(dir, 'link.rb'))).to be_truthy
        expect(File.readlink(File.join(dir, 'link.rb'))).to eq 'scraper.rb'
      end
    end

    it 'should have an encoding of ASCII-8BIT' do
      Dir.mktmpdir do |dest|
        tar = Morph::DockerUtils.create_tar(dest)
        expect(tar.encoding).to eq Encoding::ASCII_8BIT
      end
    end
  end

  describe '.extract_tar' do
    it 'should do the opposite of create_tar' do
      # Binary data that can't be interpreted as valid text
      target = "\xE6"
      target.force_encoding('ASCII-8BIT')

      content = Dir.mktmpdir do |dir|
        File.open(File.join(dir, 'foo'), 'wb') { |f| f << target }
        Morph::DockerUtils.create_tar(dir)
      end

      Dir.mktmpdir do |dir|
        Morph::DockerUtils.extract_tar(content, dir)
        v = File.open(File.join(dir, 'foo'), 'rb') { |f| f.read }
        expect(v).to eq target
      end
    end
  end

  describe '.fix_modification_times' do
    it do
      Dir.mktmpdir do |dir|
        FileUtils.touch(File.join(dir, 'foo'))
        FileUtils.mkdir_p(File.join(dir, 'bar'))
        FileUtils.touch(File.join(dir, 'bar', 'twist'))
        Morph::DockerUtils.fix_modification_times(dir)
        expect(File.mtime(dir)).to eq Time.new(2000, 1, 1)
        expect(File.mtime(File.join(dir, 'foo'))).to eq Time.new(2000, 1, 1)
        expect(File.mtime(File.join(dir, 'bar'))).to eq Time.new(2000, 1, 1)
        expect(File.mtime(File.join(dir, 'bar', 'twist')))
          .to eq Time.new(2000, 1, 1)
      end
    end
  end

  describe '.copy_directory_contents' do
    it 'should copy a file in the root of a directory' do
      Dir.mktmpdir do |source|
        Dir.mktmpdir do |dest|
          File.open(File.join(source, 'foo.txt'), 'w') { |f| f << 'Hello' }
          Morph::DockerUtils.copy_directory_contents(source, dest)
          expect(File.read(File.join(dest, 'foo.txt'))).to eq 'Hello'
        end
      end
    end

    it 'should copy a directory and its contents' do
      Dir.mktmpdir do |source|
        Dir.mktmpdir do |dest|
          FileUtils.mkdir(File.join(source, 'foo'))
          File.open(File.join(source, 'foo', 'foo.txt'), 'w') do |f|
            f << 'Hello'
          end
          Morph::DockerUtils.copy_directory_contents(source, dest)
          expect(File.read(File.join(dest, 'foo', 'foo.txt'))).to eq 'Hello'
        end
      end
    end

    it 'should copy a file starting with .' do
      Dir.mktmpdir do |source|
        Dir.mktmpdir do |dest|
          File.open(File.join(source, '.foo.txt'), 'w') { |f| f << 'Hello' }
          Morph::DockerUtils.copy_directory_contents(source, dest)
          expect(File.read(File.join(dest, '.foo.txt'))).to eq 'Hello'
        end
      end
    end
  end

  describe '.find_all_containers_with_label', docker: true do
    before :each do
      Morph::DockerUtils.find_all_containers_with_label('foobar').each do |c|
        c.delete
      end
    end
    after :each do
      Morph::DockerUtils.find_all_containers_with_label('foobar').each do |c|
        c.delete
      end
    end
    it 'should find no containers with a particular label initially' do
      expect(Morph::DockerUtils.find_all_containers_with_label('foobar').count).to eq 0
    end

    it 'should find two containers with the particular label when I create then' do
      Docker::Container.create('Cmd' => ['ls'], 'Image' => 'openaustralia/buildstep', 'Labels' => {'foobar' => '1'})
      Docker::Container.create('Cmd' => ['ls'], 'Image' => 'openaustralia/buildstep', 'Labels' => {'foobar' => '2'})
      Docker::Container.create('Cmd' => ['ls'], 'Image' => 'openaustralia/buildstep', 'Labels' => {'bar' => '1'})
      expect(Morph::DockerUtils.find_all_containers_with_label('foobar').count).to eq 2
    end
  end

  describe '.copy_file' do
    it 'should create a temporary file locally from a file on a container' do
      c = Docker::Container.create('Cmd' => ['ls'], 'Image' => 'openaustralia/buildstep', 'Labels' => {'foobar' => '1'})
      # Grab file provided by buildstep
      file = Morph::DockerUtils.copy_file(c, '/etc/fstab')
      expect(file.read).to eq "# UNCONFIGURED FSTAB FOR BASE SYSTEM\n"
      file.close!
      c.delete
    end

    it 'should return nil for a file that does not exist' do
      c = Docker::Container.create('Cmd' => ['ls'], 'Image' => 'openaustralia/buildstep', 'Labels' => {'foobar' => '1'})
      file = Morph::DockerUtils.copy_file(c, '/not/a/path')
      expect(file).to be_nil
      c.delete
    end
  end
end
