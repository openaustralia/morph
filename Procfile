worker: bundle exec sidekiq -C config/sidekiq.yml
web: bundle exec rails s -b 0.0.0.0
faye: bundle exec dotenv rackup sync.ru -E production

# mitmproxy is commented out for development
# This is because it is rarely needed in practice in development (unless you're doing work specifically on the scraped urls)
#
#mitmproxy: dotenv mitmdump --quiet --transparent --script docker_images/morph-mitmdump/mitmproxy/log_to_morph.py --cadir docker_images/morph-mitmdump/mitmproxy
