FROM ruby:3.0.7

# The ruby images this Dockerfile builds on are Debian bullseye based, and
# bullseye has moved to archive.debian.org now its LTS has ended: the main
# mirrors 404, and the archive's Release files are frozen, so apt has to be
# pointed at the archive and told not to reject its Release files as expired.
# bullseye-security is dropped: it is not on archive.debian.org yet and the
# live mirror's pool has been pruned. This is a development-only image.
RUN echo "deb http://archive.debian.org/debian bullseye main" > /etc/apt/sources.list \
    && echo "deb http://archive.debian.org/debian bullseye-updates main" >> /etc/apt/sources.list

RUN echo "Install a javascript runtime and other gem dependencies ..." \
    && apt-get -o Acquire::Check-Valid-Until=false update  \
    && apt-get install -y \
       nodejs \
       cmake \
       pkg-config \
       libgit2-dev \
       sudo \
       tini \
       # mysqldump and zstd are needed by the db backup tasks and their specs
       default-mysql-client \
       zstd

# The docker CLI (client only, no daemon) is needed so spec_helper.rb can
# detect the daemon ("docker info") and enable the :docker specs; the app
# itself talks to the daemon through the mounted socket via the docker-api
# gem. amd64 is correct here because this image is always built amd64 (see
# docker-compose.yml).
RUN echo "Install the docker CLI ..." \
    && curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-26.1.4.tgz \
       | tar -xz --strip-components=1 -C /usr/local/bin docker/docker

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

RUN echo "Install gems..." \
    && bundle install

ENTRYPOINT ["/app/bin/docker-entrypoint"]

CMD ["bin/rails", "server", "-p", "3000", "-b", "0.0.0.0"]
