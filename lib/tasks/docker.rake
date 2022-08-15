# typed: true
# frozen_string_literal: true

# Putting rake tasks inside a class to keep sorbet happy
class DockerRake
  extend Rake::DSL
  extend ActiveSupport::NumberHelper

  namespace :app do
    namespace :docker do
      desc "Remove least recently used docker images"
      task remove_old_unused_images: %i[environment set_logger_to_stdout] do
        include ActionView::Helpers::NumberHelper

        # We don't want to take up more than 10 GB
        target_size = 10 * 1024 * 1024 * 1024

        # First compile list of images, when they were last used and how much space they're using
        # Images built on top of buildstep

        # We're currently just checking images that are based on the default platform. Images
        # based on the other platforms are ignored which IS NOT GOOD.
        # TODO: Check images for ALL platforms
        image_base = Morph::DockerRunner.buildstep_image(Morph::DockerRunner::DEFAULT_PLATFORM)
        images = Docker::Image.all.select do |image|
          Morph::DockerUtils.image_built_on_other_image?(image, image_base)
        end
        # Now find out when they were last used
        images = images.map do |image|
          short_image_id = image.id.split(":")[1][0..11]
          {
            image: image,
            last_used: Run.where(docker_image: short_image_id).maximum(:created_at),
            size: Morph::DockerUtils.disk_space_image_relative_to_other_image(image, image_base)
          }
        end
        # Sort by the time
        images = images.sort do |image1, image2|
          l1 = image1[:last_used]
          l2 = image2[:last_used]
          if l1 && l2
            l1 <=> l2
          elsif l1
            -1
          elsif l2
            1
          else
            # We want the smallest images last when they've never been used
            -(image1[:size] <=> image2[:size])
          end
        end
        images = images.reverse
        total_size = images.pluck(:size).sum
        min_size_to_remove = total_size - target_size

        images_to_remove = []
        size = 0
        images.each do |image|
          if size < min_size_to_remove
            images_to_remove << image[:image]
            size += image[:size]
          end
        end
        puts "Currently using #{number_to_human_size(total_size)} with a target maximum of #{number_to_human_size(target_size)}"
        puts "Removing #{images_to_remove.count} of the least recently used images taking up #{number_to_human_size(size)}..."
        images_to_remove.each { |i| Morph::DockerMaintenance.remove_image(i.id) }
      end

      desc "Show size of images built on top of buildstep"
      task list_image_sizes: :environment do
        include ActionView::Helpers::NumberHelper

        # We're currently only working out the size of images that are based on the default platform
        # TODO: We should do all the platforms
        image_base = Morph::DockerRunner.buildstep_image(Morph::DockerRunner::DEFAULT_PLATFORM)
        total = 0
        Docker::Image.all.each do |image|
          next unless Morph::DockerUtils.image_built_on_other_image?(image, image_base)

          size = Morph::DockerUtils.disk_space_image_relative_to_other_image(image, image_base)
          puts "#{image.id.split(':')[1][0..11]} #{number_to_human_size(size)}"
          total += size
        end
        puts "Total: #{number_to_human_size(total)}"
      end

      desc "Delete dead Docker containers"
      task delete_dead_containers: %i[environment set_logger_to_stdout] do
        dead_containers = Docker::Container.all(all: true, filters: { status: ["dead"] }.to_json)
        puts "Found #{dead_containers.count} dead containers to delete..."

        dead_containers.each do |c|
          Morph::DockerMaintenance.delete_container(c)
        end
      end

      # This is exactly the same as the task above but for a different container status
      # TODO: Refactor this with the above task
      desc "Delete Docker containers with 'created' status"
      task delete_created_status_containers: %i[environment set_logger_to_stdout] do
        created_status_containers = Docker::Container.all(all: true, filters: { status: ["created"] }.to_json)
        puts "Found #{created_status_containers.count} created status containers to delete..."

        created_status_containers.each do |c|
          Morph::DockerMaintenance.delete_container(c)
        end
      end

      desc "Delete ALL stopped Docker containers without associated morph run"
      task delete_stopped_containers: %i[environment set_logger_to_stdout] do
        filters = { status: ["exited"] }.to_json
        stopped_containers = Docker::Container.all(all: true, filters: filters)
        # Don't deleted containers with associated runs - these should be tidied
        # up by the usual process as part of their run
        stopped_containers.reject! { |c| Morph::Runner.run_for_container(c) }
        puts "Found #{stopped_containers.count} stopped containers to delete..."

        stopped_containers.each do |c|
          Morph::DockerMaintenance.delete_container(c)
        end
      end

      task set_logger_to_stdout: :environment do
        Rails.logger = ActiveSupport::Logger.new($stdout)
        Rails.logger.level = 1
      end
    end
  end
end
