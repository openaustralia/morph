worker: bundle exec sidekiq -C config/sidekiq.yml
web: bundle exec rails s -b 0.0.0.0
faye: bundle exec dotenv rackup sync.ru -E production

# mitmproxy is commented out for development
# This is because it is rarely needed in practice in development (unless you're doing work specifically on the scraped urls)
# Also, on OS X at least the version that is installed by Homebrew is older than the version
# that is installed in production. Helpfully (not), the different versions have incompatible
# command line options so this doesn't work anyway
#
#mitmproxy: dotenv mitmdump --quiet --transparent --script mitmproxy/log_to_morph.py --cadir mitmproxy
