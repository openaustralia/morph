# typed: false
# frozen_string_literal: true

require "spec_helper"

describe Morph::DockerUtils do
  describe ".create_tar" do
    it "preserves the symbolic link" do
      tar = Dir.mktmpdir do |dest|
        FileUtils.ln_s "scraper.rb", File.join(dest, "link.rb")
        described_class.create_tar(dest)
      end

      Dir.mktmpdir do |dir|
        path = File.join(dir, "test.tar")
        File.open(path, "w") { |f| f << tar }
        # Quick and dirty
        `tar xf #{path} -C #{dir}`
        expect(File).to be_symlink(File.join(dir, "link.rb"))
        expect(File.readlink(File.join(dir, "link.rb"))).to eq "scraper.rb"
      end
    end

    it "has an encoding of ASCII-8BIT" do
      Dir.mktmpdir do |dest|
        tar = described_class.create_tar(dest)
        expect(tar.encoding).to eq Encoding::ASCII_8BIT
      end
    end
  end

  describe ".extract_tar" do
    it "does the opposite of create_tar" do
      # Binary data that can't be interpreted as valid text
      target = +"\xE6"
      target.force_encoding("ASCII-8BIT")

      content = Dir.mktmpdir do |dir|
        File.open(File.join(dir, "foo"), "wb") { |f| f << target }
        described_class.create_tar(dir)
      end

      Dir.mktmpdir do |dir|
        described_class.extract_tar(content, dir)
        v = File.binread(File.join(dir, "foo"))
        expect(v).to eq target
      end
    end
  end

  describe ".fix_modification_times" do
    it do
      Dir.mktmpdir do |dir|
        FileUtils.touch(File.join(dir, "foo"))
        FileUtils.mkdir_p(File.join(dir, "bar"))
        FileUtils.touch(File.join(dir, "bar", "twist"))
        described_class.fix_modification_times(dir)
        expect(File.mtime(dir)).to eq Time.zone.local(2000, 1, 1)
        expect(File.mtime(File.join(dir, "foo"))).to eq Time.zone.local(2000, 1, 1)
        expect(File.mtime(File.join(dir, "bar"))).to eq Time.zone.local(2000, 1, 1)
        expect(File.mtime(File.join(dir, "bar", "twist")))
          .to eq Time.zone.local(2000, 1, 1)
      end
    end
  end

  describe ".copy_directory_contents" do
    it "copies a file in the root of a directory" do
      Dir.mktmpdir do |source|
        Dir.mktmpdir do |dest|
          File.open(File.join(source, "foo.txt"), "w") { |f| f << "Hello" }
          described_class.copy_directory_contents(source, dest)
          expect(File.read(File.join(dest, "foo.txt"))).to eq "Hello"
        end
      end
    end

    it "copies a directory and its contents" do
      Dir.mktmpdir do |source|
        Dir.mktmpdir do |dest|
          FileUtils.mkdir(File.join(source, "foo"))
          File.open(File.join(source, "foo", "foo.txt"), "w") do |f|
            f << "Hello"
          end
          described_class.copy_directory_contents(source, dest)
          expect(File.read(File.join(dest, "foo", "foo.txt"))).to eq "Hello"
        end
      end
    end

    it "copies a file starting with ." do
      Dir.mktmpdir do |source|
        Dir.mktmpdir do |dest|
          File.open(File.join(source, ".foo.txt"), "w") { |f| f << "Hello" }
          described_class.copy_directory_contents(source, dest)
          expect(File.read(File.join(dest, ".foo.txt"))).to eq "Hello"
        end
      end
    end
  end

  describe ".find_all_containers_with_label", docker: true do
    before do
      described_class.find_all_containers_with_label("foobar").each(&:delete)
    end

    after do
      described_class.find_all_containers_with_label("foobar").each(&:delete)
    end

    it "finds no containers with a particular label initially" do
      expect(described_class.find_all_containers_with_label("foobar").count).to eq 0
    end

    it "finds two containers with the particular label when I create then" do
      Docker::Container.create("Cmd" => ["ls"], "Image" => "openaustralia/buildstep", "Labels" => { "foobar" => "1" })
      Docker::Container.create("Cmd" => ["ls"], "Image" => "openaustralia/buildstep", "Labels" => { "foobar" => "2" })
      Docker::Container.create("Cmd" => ["ls"], "Image" => "openaustralia/buildstep", "Labels" => { "bar" => "1" })
      expect(described_class.find_all_containers_with_label("foobar").count).to eq 2
    end
  end

  describe ".copy_file" do
    it "creates a temporary file locally from a file on a container" do
      c = Docker::Container.create("Cmd" => ["ls"], "Image" => "openaustralia/buildstep", "Labels" => { "foobar" => "1" })
      # Grab file provided by buildstep
      file = described_class.copy_file(c, "/etc/fstab")
      expect(file.read).to eq "# UNCONFIGURED FSTAB FOR BASE SYSTEM\n"
      file.close!
      c.delete
    end

    it "returns nil for a file that does not exist" do
      c = Docker::Container.create("Cmd" => ["ls"], "Image" => "openaustralia/buildstep", "Labels" => { "foobar" => "1" })
      file = described_class.copy_file(c, "/not/a/path")
      expect(file).to be_nil
      c.delete
    end
  end

  describe ".process_json_stream_chunk" do
    it "parses a single line of json" do
      expect(described_class.process_json_stream_chunk(%({"stream": "foo\\n"}\n))).to eq [%W[foo\n], ""]
    end

    it "ignores a json line if it's not a stream" do
      expect(described_class.process_json_stream_chunk(%({"foo": "bar\\n"}\n))).to eq [[], ""]
    end

    it "handles one chunk containing multiple json lines" do
      expect(described_class.process_json_stream_chunk(%({"stream": "foo\\n"}\n{"stream": "bar\\n"}\n))).to eq [%W[foo\n bar\n], ""]
    end

    it "buffers the output until there is a carriage returns at the end" do
      expect(described_class.process_json_stream_chunk(%({"stream": "foo"}\n{"stream": "bar\\n"}\n{"stream": "twist\\n"}\n))).to eq [%W[foobar\n twist\n], ""]
    end

    it "returns the output even if there isn't a carriage return at the end" do
      expect(described_class.process_json_stream_chunk(%({"stream": "foo"}\n{"stream": "bar"}\n{"stream": "twist"}\n))).to eq [%w[foobartwist], ""]
    end
  end
end
