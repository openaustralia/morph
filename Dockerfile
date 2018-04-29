FROM ruby:2.3.7
WORKDIR /morph
# We need a javascript runtime
RUN apt-get update && apt-get install -y nodejs
COPY Gemfile* ./
# TODO: Don't run as root
# TODO: Update bundler by running "gem install bundler"
RUN bundle install
COPY . .
