namespace :app do
  desc "Build docker image (Needs to be done once before any scrapers are run)"
  task :build_docker_image => :environment do
    Scraper.build_docker_image!
  end
end
