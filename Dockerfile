FROM ruby:2.7.6

RUN echo "Install a javascript runtime and other gem dependencies ..." \
    && apt-get update  \
    && apt-get install -y \
       nodejs \
       cmake \
       pkg-config \
       libgit2-dev \
       sudo \
       tini

ARG UID=1000
ARG GID=1000
ARG DOCKER_GID=999

RUN echo "Run everything as a non-root 'deploy' user with sudo support ..." \
    && groupadd --gid $GID deploy \
    && groupadd -g $DOCKER_GID docker \
    && useradd --uid $UID --gid deploy --groups docker -m deploy \
    && echo deploy ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/deploy \
    && chmod 0440 /etc/sudoers.d/deploy

WORKDIR /app

USER deploy

COPY --chown=deploy:deploy Gemfile /app/Gemfile
COPY --chown=deploy:deploy Gemfile.lock /app/Gemfile.lock

# TODO: Update bundler by running "gem install bundler"

COPY --chown=deploy:deploy Gemfile /app/Gemfile
COPY --chown=deploy:deploy Gemfile.lock /app/Gemfile.lock

RUN echo "Install gems..." \
    && bundle install

ENTRYPOINT ["/app/bin/docker-entrypoint"]

CMD ["bin/rails", "server", "-p", "3000", "-b", "0.0.0.0"]
