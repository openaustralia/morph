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
