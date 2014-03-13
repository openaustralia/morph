worker: bundle exec sidekiq --concurrency 5 -q default -q low
web: bundle exec rails s
faye: rackup sync.ru -E production
