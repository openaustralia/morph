FROM ruby:2.0.0
RUN mkdir /morph
WORKDIR /morph
ADD Gemfile /morph/Gemfile
ADD Gemfile.lock /morph/Gemfile.lock
# TODO: Don't run as root
# TODO: Update bundler by running "gem install bundler"
RUN bundle install
ADD . /morph
# We need a javascript runtime
RUN apt-get update
RUN apt-get install -y nodejs
