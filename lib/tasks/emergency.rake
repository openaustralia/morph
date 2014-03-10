namespace :app do
  namespace :emergency do
    # This is a temporary workaround for an occasional bug that hits where containers are dissapearing
    # without an exception being thrown or anything like that. So, what we end up with is a running scraper,
    # an associated background job that finished without errors, and no container for that run.
    desc "If there are scrapers that think they're running but there is no container remove the running run"
    task :delete_broken_runs => :environment do
      Run.where("finished_at IS NULL").each do |run|
        if Morph::DockerRunner.container_exists?(run.docker_container_name)
          # TODO could potentially check if container is running or stopped and
          # then if it's stopped delete the container (this is assuming that
          # there still is a running background job that will kick in again)
          puts "Container #{run.docker_container_name} exists"
        else
          puts "Container #{run.docker_container_name} doesn't exist. Therefore deleting run"
          # Using destroy to ensure that callbacks are called (mainly for caching)
          run.destroy
        end
      end
    end
  end
end
