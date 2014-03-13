worker: bundle exec sidekiq --concurrency 5 -q default -q low
web: bundle exec rails s
faye: bundle exec dotenv rackup sync.ru -E production
