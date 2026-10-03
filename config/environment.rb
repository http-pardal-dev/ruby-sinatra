# frozen_string_literal: true

# Application environment.
# Prepares the runtime (see config/boot.rb), then loads environment variables,
# the application and the environment-specific settings.

require_relative "boot"

require "dotenv/load"
require_relative "checks"

# Runtime environment. The server knows exactly three of them, and each one has
# its own settings in config/environment/<name>.rb and its own database in
# data/database.yml.
ENVIRONMENTS = %w[development test production].freeze

ENV["APP_ENV"] ||= "development"

# An unknown environment is refused here, before anything else is loaded. A typo
# such as `dev` or `testing` would otherwise pick a database that does not exist
# (or worse, the wrong one) and fail much later with a message that does not
# point at the name that is actually wrong.
unless ENVIRONMENTS.include?(ENV["APP_ENV"])
  raise Checks::Error, <<~MESSAGE
    APP_ENV is #{ENV["APP_ENV"].inspect}, but this server only knows: #{ENVIRONMENTS.join(", ")}.
    Fix it in the .env file (see .env.example) or export APP_ENV=<name> before starting the server.
  MESSAGE
end

APP_ENV = ENV["APP_ENV"].to_sym

require_relative "../app"
require_relative "../models/user"
require_relative "../models/product"
require_relative "../models/payment"

# Settings specific to the current environment.
require_relative "environment/#{APP_ENV}"

# The database has to be ready before the first request. Rake is excluded on
# purpose: it loads this file to run `db:migrate`, which is one of the commands
# the checks point to (see config/checks.rb).
Checks.verify! unless defined?(Rake)
