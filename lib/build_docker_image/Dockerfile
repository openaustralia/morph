FROM ubuntu:12.04
MAINTAINER Matthew Landauer <matthew@oaf.org.au>

RUN apt-get update
RUN apt-get -y install curl git libxslt-dev libxml2-dev

RUN curl -sSL https://get.rvm.io | bash -s stable
RUN echo 'source /usr/local/rvm/scripts/rvm' >> /etc/bash.bashrc

RUN /bin/bash -l -c 'rvm install ruby-1.9.2-p320'
RUN mkdir /repo
# Give the scraper user the same uid and gid as deploy on the docker server
# TODO Currently hardcoded values
RUN adduser --home /data --disabled-login --gecos "Scraper User" --uid 1001 --gid 1003 scraper

ADD Gemfile /etc/Gemfile
RUN /bin/bash -l -c 'bundle install --gemfile /etc/Gemfile'

VOLUME /repo
VOLUME /data
WORKDIR /data
