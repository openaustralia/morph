FROM ruby:2.7.6

WORKDIR /app

RUN echo "Run everything as a non-root "deploy" user..." \
    && groupadd --gid 1000 deploy \
    && useradd --uid 1000 --gid 1000 -m deploy

RUN echo "Add sudo support so that we can install software by hand later on..." \
    && apt-get update \
    && apt-get install -y sudo \
    && echo deploy ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/deploy \
    && chmod 0440 /etc/sudoers.d/deploy

RUN echo "Install a javascript runtime ..." \
    && apt-get update  \
    && apt-get install -y nodejs

RUN echo "Install gem dependencies ..." \
    && apt-get install -y \
       cmake \
       pkg-config \
       libgit2-dev

USER deploy

COPY --chown=deploy:deploy Gemfile /app/Gemfile
COPY --chown=deploy:deploy Gemfile.lock /app/Gemfile.lock

# TODO: Update bundler by running "gem install bundler"

COPY --chown=deploy:deploy Gemfile /app/Gemfile
COPY --chown=deploy:deploy Gemfile.lock /app/Gemfile.lock

RUN echo "Install gems..." \
    && bundle install

ENTRYPOINT ["bin/docker-entrypoint"]

CMD ["bin/rails", "server", "-p", "3000", "-b", "0.0.0.0"]
