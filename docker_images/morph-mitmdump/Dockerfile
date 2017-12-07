FROM debian:jessie
MAINTAINER Matthew Landauer <matthew@oaf.org.au>

# We're install python on its own first so that when we install python-pip
# and later uninstall python-pip and run autoremove it leaves a working python
# behind
RUN apt-get update && apt-get install -y python

# Need to install ca-certificates otherwise won't verify ssl certificate
# of morph.io which is necessary for the connection log callback
RUN apt-get install -y \
  libffi-dev   \
  libssl-dev   \
  libxslt1-dev \
  libjpeg62-turbo-dev \
  python-dev   \
  python-pip \
  ca-certificates

RUN pip install --upgrade setuptools
RUN pip install --upgrade cffi
RUN pip install --upgrade cryptography
RUN pip install mitmproxy==0.12
RUN pip install --upgrade pyOpenSSL
RUN pip install --upgrade pyasn1
RUN pip install ipaddress
RUN pip install enum34

# Cleaning up things we don't actually need to run mitmdump.
# This won't actually reduce the size of the final image unless we combine
# all these steps into one RUN or use something like
# https://github.com/jwilder/docker-squash
RUN apt-get remove -y \
  libffi-dev   \
  libssl-dev   \
  libxslt1-dev \
  python-dev   \
  python-pip   && \
  apt-get -y autoremove

RUN apt-get clean autoclean
RUN rm -rf /var/lib/{apt,dpkg,cache,log}

# TODO: Don't run as root

COPY mitmproxy /mitmproxy
CMD ["mitmdump", "--quiet", "--transparent", "--script", "/mitmproxy/log_to_morph.py", "--cadir", "/mitmproxy"]
EXPOSE 8080
