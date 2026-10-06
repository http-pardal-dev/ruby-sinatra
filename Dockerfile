# Development and test image for the ruby-sinatra server.
#
# The image carries the toolchain and the gems of Gemfile.lock; the repository
# itself is bind-mounted over /app by docker-compose.yml, so the code that runs
# is always the working tree. The result is the same environment everywhere:
# the Ruby of .ruby-version, the exact Bundler of "BUNDLED WITH", and the same
# commands the CI runs (rake db:migrate, rspec, rake lint, bundle-audit).
#
#   docker compose build            # once, and again after Gemfile.lock changes
#   docker compose up dev           # migrate + server on http://127.0.0.1:9292
#   docker compose run --rm test    # migrate + the RSpec suite
#
# RUBY_VERSION mirrors .ruby-version. The CI matrix (3.3, 3.4, 4.0) can be
# reproduced with: docker compose build --build-arg RUBY_VERSION=3.4

ARG RUBY_VERSION=3.3

FROM ruby:${RUBY_VERSION}-bookworm AS base

# The toolchain for the native extensions of the bundle: sqlite3, bcrypt,
# puma, fiddle, bigdecimal and rbs all compile one. git and ca-certificates
# are here for gems fetched from their repositories and for HTTPS.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        git \
        libffi-dev \
        libsqlite3-dev \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# The same knobs ruby/setup-ruby gives Bundler in CI. Gems live in the image
# (BUNDLE_PATH), never in the bind-mounted repository: the working tree stays
# clean and the gems survive a container being recreated.
ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    APP_ENV=development

FROM base AS deps

COPY Gemfile Gemfile.lock ./

# The exact Bundler of "BUNDLED WITH", chosen the way ruby/setup-ruby chooses
# it: a different Bundler could resolve the lock differently. BUNDLE_FROZEN
# makes the install fail when Gemfile and Gemfile.lock disagree, which is what
# the CI does (and what caught bundler-audit missing from the lock).
RUN gem install bundler -v "$(awk '/BUNDLED WITH/ { getline; gsub(/[[:space:]]/, ""); print }' Gemfile.lock)" \
    && BUNDLE_FROZEN=true bundle install \
    && rm -rf "${BUNDLE_PATH}"/cache

FROM deps AS dev

# Migrations first: the server refuses to boot against a database without
# tables (config/environment.rb), so a fresh container has to migrate before
# it can listen. puma is started with -b because config/puma.rb binds the
# loopback interface *inside* the container, which no published port can
# reach; the compose file publishes it on 127.0.0.1 of the host only, so the
# API keeps the loopback-only guarantee described in config/puma.rb.
CMD ["sh", "-c", "bundle exec rake db:migrate && exec bundle exec puma -C config/puma.rb -b tcp://0.0.0.0:9292"]
