namespace :app do
  namespace :emergency do
    desc "Reset all user github access tokens (Needed after heartbleed)"
    task :reset_github_access_tokens => :environment do
      User.all.each do |user|
        puts user.nickname
        user.reset_authorization!
      end
    end

    desc 'Update counter caches in case they get out of sync'
    task :update_counter_caches => :environment do
      Run.find_each do |run|
        Run.reset_counters(run.id, :connection_logs)
      end
    end

    desc "Get meta info for all domains in the connection logs"
    task :get_all_meta_info_for_connection_logs => :environment do
      domains = ConnectionLog.group(:host).pluck(:host)
      total = domains.count
      domains.each_with_index do |domain, index|
        if Domain.where(name: domain).exists?
          puts "Skipping #{index + 1}/#{total} #{domain}"
        else
          puts "Queueing #{index + 1}/#{total} #{domain}"
          d = Domain.create!(name: domain)
          UpdateDomainWorker.perform_async(d.id)
        end
      end
    end

    desc "Remove docker images that haven't been used in over 1 month"
    task remove_old_unused_docker_images: :environment do
      Docker::Image.all.each do |image|
        last_run = Run.where(docker_image: image.id[0..11]).maximum(:created_at)
        if last_run && last_run < 1.months.ago
          puts "Removing #{image.id}"
          begin
            image.remove
          # TODO: This is probably because of a stopped container. Should we remove them too?
          rescue Docker::Error::ConfictError
            puts "Conflict removing image, skipping"
          end
        end
      end
    end

    desc "Delete dead docker containers and remove their images"
    task delete_dead_docker_containers: :environment do
      dead_containers = Docker::Container.all(all: true, filters: { status: ["dead"] }.to_json)
      puts "Found #{dead_containers.count} containers to delete..."

      dead_containers.each do |c|
        puts "Deleting container #{c.id}..."
        c.delete

        begin
          # Get container image ID and strip tag
          image_id = c.info["Image"].split(":").first
          i = Docker::Image.get(image_id)

          puts "Removing image #{i.id}..."
          i.remove
        rescue Docker::Error::ConfictError
          puts "Conflict removing image, skipping..."
        rescue Docker::Error::NotFoundError
          puts "Couldn't find container image, skipping..."
        end
      end

      puts "All done."
    end
  end
end
