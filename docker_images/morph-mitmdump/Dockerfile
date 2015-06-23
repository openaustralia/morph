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
RUN pip install --upgrade pyOpenSSL

# TODO: Don't run as root

COPY mitmproxy /mitmproxy
CMD ["mitmdump", "--quiet", "--transparent", "--script", "/mitmproxy/log_to_morph.py", "--cadir", "/mitmproxy"]
EXPOSE 8080
