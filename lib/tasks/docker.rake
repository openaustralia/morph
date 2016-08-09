namespace :app do
  namespace :docker do
    desc "Remove Docker images that haven't been used in over 1 month"
    task remove_old_unused_images: [:environment, :set_logger_to_stdout] do
      old_unused_images = Docker::Image.all.select do |image|
        last_run = Run.where(docker_image: image.id[0..11]).maximum(:created_at)
        last_run && last_run < 1.months.ago
      end
      puts "Found #{old_unused_images.count} old unused images to remove..."

      old_unused_images.each { |i| Morph::DockerMaintenance.remove_image(i.id) }
    end

    desc "Remove oldest docker images so that they don't use more than 500 MB"
    task remove_old_unused_images_by_space: [:environment, :set_logger_to_stdout] do
      include ActionView::Helpers::NumberHelper

      # We don't want to take up more than 512 MB
      target_size = 512 * 1024 * 1024

      # First compile list of images, when they were last used and how much space they're using
      # Images built on top of buildstep
      image_base = Morph::DockerRunner.buildstep_image
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
      total_size = images.map{|i| i[:size]}.sum
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

      image_base = Morph::DockerRunner.buildstep_image
      total = 0
      Docker::Image.all.each do |image|
        if Morph::DockerUtils.image_built_on_other_image?(image, image_base)
          size = Morph::DockerUtils.disk_space_image_relative_to_other_image(image, image_base)
          puts "#{image.id.split(':')[1][0..11]} #{number_to_human_size(size)}"
          total += size
        end
      end
      puts "Total: #{number_to_human_size(total)}"
    end

    desc "Delete dead Docker containers"
    task delete_dead_containers: [:environment, :set_logger_to_stdout] do
      dead_containers = Docker::Container.all(all: true, filters: { status: ["dead"] }.to_json)
      puts "Found #{dead_containers.count} dead containers to delete..."

      dead_containers.each do |c|
        Morph::DockerMaintenance::delete_container(c)
      end
    end

    task :set_logger_to_stdout do
      Rails.logger = ActiveSupport::Logger.new(STDOUT)
      Rails.logger.level = 1
    end
  end
end
