FROM debian:jessie
MAINTAINER Matthew Landauer <matthew@oaf.org.au>

RUN apt-get update && apt-get install -y \
  libffi-dev   \
  libssl-dev   \
  libxslt1-dev \
  python-dev   \
  python-pip

RUN pip install --upgrade cryptography
RUN pip install mitmproxy==0.12

ENTRYPOINT ["mitmdump"]
EXPOSE 8080
