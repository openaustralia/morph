FROM ubuntu:12.04
MAINTAINER Matthew Landauer <matthew@oaf.org.au>

RUN apt-get update

RUN mkdir /repo
# Give the scraper user the same uid as deploy on the docker server
# TODO Currently hardcoded values
RUN addgroup --gid 4243 scraper
RUN adduser --home /data --disabled-login --gecos "Scraper User" --uid 4243 --gid 4243 scraper

VOLUME /repo
VOLUME /data
WORKDIR /data

RUN apt-get -y install php5-tidy

RUN apt-get -y install time php5-cli git
RUN git clone https://github.com/openaustralia/scraperwiki-php.git /usr/local/lib/scraperwiki
RUN cd /usr/local/lib/scraperwiki; git checkout morph_defaults
ADD php.ini /etc/php5/cli/php.ini
RUN apt-get -y install php5-curl
RUN apt-get -y install php5-sqlite
RUN apt-get -y install php5-gd
# TODO Install php5-geoip (which doesn not appear to be present on this version of Ubuntu)
RUN apt-get -y install php-pear
RUN apt-get -y install re2c
# TODO This doesn't yet work because it needs the database
#RUN pecl install geoip
