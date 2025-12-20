# typed: false
# frozen_string_literal: true

require "spec_helper"
require "rake"

RSpec.describe "rake docker", type: :integration do # rubocop:disable RSpec/DescribeClass
  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  #       desc "Remove least recently used docker images"
  describe "app:docker:remove_old_unused_images" do
    let(:task) { "app:docker:remove_old_unused_images" }

    it "removes old unused images when over target size" do
      image_base = instance_double(Docker::Image)
      allow(Morph::DockerRunner).to receive(:buildstep_image).and_return(image_base)

      image1 = instance_double(Docker::Image, id: "sha256:image1id123456789")
      image2 = instance_double(Docker::Image, id: "sha256:image2id123456789")

      allow(Docker::Image).to receive(:all).and_return([image1, image2])
      allow(Morph::DockerUtils).to receive(:image_built_on_other_image?).with(image1, image_base).and_return(true)
      allow(Morph::DockerUtils).to receive(:image_built_on_other_image?).with(image2, image_base).and_return(true)

      # image1 used 1 day ago, size 6GB
      # image2 used 2 days ago, size 6GB
      # Total 12GB, target 10GB.
      # The task sorts images by last_used ASC, then REVERSES.
      # Sort (asc): image2 (2 days ago), image1 (1 day ago)
      # Reverse: [image1 (newest), image2 (oldest)]
      # It removes images from the start of the list until min_size_to_remove (2GB) is reached.
      # So it removes image1 (NEWEST). This seems to be the current behavior of the rake task.

      create(:run, docker_image: "image1id1234", created_at: 1.day.ago)
      create(:run, docker_image: "image2id1234", created_at: 2.days.ago)

      allow(Morph::DockerUtils).to receive(:disk_space_image_relative_to_other_image).with(image1, image_base).and_return(6 * 1024 * 1024 * 1024)
      allow(Morph::DockerUtils).to receive(:disk_space_image_relative_to_other_image).with(image2, image_base).and_return(6 * 1024 * 1024 * 1024)

      allow(Morph::DockerMaintenance).to receive(:remove_image)

      Rake::Task[task].reenable
      expect { Rake::Task[task].invoke }.to output(/Removing 1 of the least recently used images/).to_stdout

      expect(Morph::DockerMaintenance).to have_received(:remove_image).with(image1.id)
    end

    it "removes images that have never been used" do
      image_base = instance_double(Docker::Image)
      allow(Morph::DockerRunner).to receive(:buildstep_image).and_return(image_base)

      image1 = instance_double(Docker::Image, id: "sha256:image1id123456789")
      image2 = instance_double(Docker::Image, id: "sha256:image2id123456789")

      allow(Docker::Image).to receive(:all).and_return([image1, image2])
      allow(Morph::DockerUtils).to receive(:image_built_on_other_image?).with(image1, image_base).and_return(true)
      allow(Morph::DockerUtils).to receive(:image_built_on_other_image?).with(image2, image_base).and_return(true)

      # No runs for these images
      allow(Morph::DockerUtils).to receive(:disk_space_image_relative_to_other_image).with(image1, image_base).and_return(6 * 1024 * 1024 * 1024)
      allow(Morph::DockerUtils).to receive(:disk_space_image_relative_to_other_image).with(image2, image_base).and_return(7 * 1024 * 1024 * 1024)

      # Sort logic for unused: -(image1[:size] <=> image2[:size])
      # 6 <=> 7 is -1. -(-1) is 1.
      # So image1 comes AFTER image2. [image2, image1].
      # Reverse: [image1, image2].
      # It removes image1 first? image1 is smaller.

      allow(Morph::DockerMaintenance).to receive(:remove_image)

      Rake::Task[task].reenable
      expect { Rake::Task[task].invoke }.to output(/Removing 1 of the least recently used images/).to_stdout
      expect(Morph::DockerMaintenance).to have_received(:remove_image).with(image1.id)
    end
  end

  #       desc "Show size of images built on top of buildstep"
  describe "app:docker:list_image_sizes" do
    let(:task) { "app:docker:list_image_sizes" }

    it "lists image sizes" do
      image_base = instance_double(Docker::Image)
      allow(Morph::DockerRunner).to receive(:buildstep_image).and_return(image_base)

      image = instance_double(Docker::Image, id: "sha256:imageid123456789")
      allow(Docker::Image).to receive(:all).and_return([image])
      allow(Morph::DockerUtils).to receive(:image_built_on_other_image?).with(image, image_base).and_return(true)
      allow(Morph::DockerUtils).to receive(:disk_space_image_relative_to_other_image).with(image, image_base).and_return(1024 * 1024)

      Rake::Task[task].reenable
      expect { Rake::Task[task].invoke }.to output(/imageid12345 1 MB/).to_stdout
    end
  end

  #       desc "Delete dead Docker containers"
  describe "app:docker:delete_dead_containers" do
    let(:task) { "app:docker:delete_dead_containers" }

    it "deletes dead containers" do
      container = instance_double(Docker::Container)
      allow(Docker::Container).to receive(:all).with(all: true, filters: { status: ["dead"] }.to_json).and_return([container])
      allow(Morph::DockerMaintenance).to receive(:delete_container)

      Rake::Task[task].reenable
      expect { Rake::Task[task].invoke }.to output(/Found 1 dead containers to delete/).to_stdout
      expect(Morph::DockerMaintenance).to have_received(:delete_container).with(container)
    end
  end

  #       desc "Delete Docker containers with 'created' status"
  describe "app:docker:delete_created_status_containers" do
    let(:task) { "app:docker:delete_created_status_containers" }

    it "deletes created status containers" do
      container = instance_double(Docker::Container)
      allow(Docker::Container).to receive(:all).with(all: true, filters: { status: ["created"] }.to_json).and_return([container])
      allow(Morph::DockerMaintenance).to receive(:delete_container)

      Rake::Task[task].reenable
      expect { Rake::Task[task].invoke }.to output(/Found 1 created status containers to delete/).to_stdout
      expect(Morph::DockerMaintenance).to have_received(:delete_container).with(container)
    end
  end

  #       desc "Delete ALL stopped Docker containers without associated morph run"
  describe "app:docker:delete_stopped_containers" do
    let(:task) { "app:docker:delete_stopped_containers" }

    it "deletes stopped containers without associated run" do
      container1 = instance_double(Docker::Container)
      container2 = instance_double(Docker::Container)
      allow(Docker::Container).to receive(:all).with(all: true, filters: { status: ["exited"] }.to_json).and_return([container1, container2])

      allow(Morph::Runner).to receive(:run_for_container).with(container1).and_return(instance_double(Run))
      allow(Morph::Runner).to receive(:run_for_container).with(container2).and_return(nil)

      allow(Morph::DockerMaintenance).to receive(:delete_container)

      Rake::Task[task].reenable
      expect { Rake::Task[task].invoke }.to output(/Found 1 stopped containers to delete/).to_stdout
      expect(Morph::DockerMaintenance).to have_received(:delete_container).with(container2)
      expect(Morph::DockerMaintenance).not_to have_received(:delete_container).with(container1)
    end
  end
end
