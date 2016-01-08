namespace :app do
  namespace :docker do
    desc "Remove Docker images that haven't been used in over 1 month"
    task remove_old_unused_images: [:environment, :set_logger_to_stdout] do
      Docker::Image.all.each do |image|
        last_run = Run.where(docker_image: image.id[0..11]).maximum(:created_at)
        if last_run && last_run < 1.months.ago
          Morph::DockerMaintenance.remove_image(image)
        end
      end
    end

    desc "Delete dead Docker containers and remove their images"
    task delete_dead_containers: [:environment, :set_logger_to_stdout] do
      dead_containers = Docker::Container.all(all: true, filters: { status: ["dead"] }.to_json)
      puts "Found #{dead_containers.count} containers to delete..."

      dead_containers.each do |c|
        Morph::DockerMaintenance::delete_container_and_remove_image(c)
      end

      puts "All done."
    end

    desc "Delete old stopped Docker containers and remove their images"
    task delete_old_stopped_containers: [:environment, :set_logger_to_stdout] do
      old_stopped_containers = Docker::Container.all(all: true, filters: { status: ["exited"] }.to_json)
      # Containers older than a day or so are almost certainly orphaned and we don't want them
      old_stopped_containers.select! { |c| Time.parse(c.json["State"]["FinishedAt"]) < 2.days.ago }
      puts "Found #{old_stopped_containers.count} containers to delete..."

      old_stopped_containers.each do |c|
        Morph::DockerMaintenance::delete_container_and_remove_image(c)
      end

      puts "All done."
    end

    task :set_logger_to_stdout do
      Rails.logger = ActiveSupport::Logger.new(STDOUT)
      Rails.logger.level = 1
    end
  end
end
