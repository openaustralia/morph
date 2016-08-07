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

    desc "Delete dead Docker containers"
    task delete_dead_containers: [:environment, :set_logger_to_stdout] do
      dead_containers = Docker::Container.all(all: true, filters: { status: ["dead"] }.to_json)
      puts "Found #{dead_containers.count} dead containers to delete..."

      dead_containers.each do |c|
        Morph::DockerMaintenance::delete_container(c)
      end
    end

    desc "Delete old stopped Docker containers"
    task delete_old_stopped_containers: [:environment, :set_logger_to_stdout] do
      old_stopped_containers = Docker::Container.all(all: true, filters: { status: ["exited"] }.to_json)
      # Containers older than a day or so are almost certainly orphaned and we don't want them
      old_stopped_containers.select! { |c| Time.parse(c.json["State"]["FinishedAt"]) < 2.days.ago }
      puts "Found #{old_stopped_containers.count} stopped containers to delete..."

      old_stopped_containers.each do |c|
        Morph::DockerMaintenance::delete_container(c)
      end
    end

    task :set_logger_to_stdout do
      Rails.logger = ActiveSupport::Logger.new(STDOUT)
      Rails.logger.level = 1
    end
  end
end
