# frozen_string_literal: true

# Application environment.
# Prepares the runtime (see config/boot.rb), then loads environment variables,
# the application and the environment-specific settings.

require_relative "boot"

require "dotenv/load"
require_relative "initializers"

# Runtime environment. The server knows exactly three of them, and each one has
# its own settings in config/environments/<name>.rb and its own database in
# data/database.yml.
ENVIRONMENTS = %w[development test production].freeze

ENV["APP_ENV"] ||= "development"

# An unknown environment is refused here, before anything else is loaded. A typo
# such as `dev` or `testing` would otherwise pick a database that does not exist
# (or worse, the wrong one) and fail much later with a message that does not
# point at the name that is actually wrong.
unless ENVIRONMENTS.include?(ENV["APP_ENV"])
  raise Database::Error, <<~MESSAGE
    APP_ENV is #{ENV["APP_ENV"].inspect}, but this server only knows: #{ENVIRONMENTS.join(", ")}.
    Fix it in the .env file (see .env.example) or export APP_ENV=<name> before starting the server.
  MESSAGE
end

APP_ENV = ENV["APP_ENV"].to_sym

require_relative "../app"
require_relative "../app/users/model"
require_relative "../app/products/model"
require_relative "../app/payments/model"

# Settings specific to the current environment.
require_relative "environments/#{APP_ENV}"

# The database has to be ready before the first request, so each initializer
# runs here and stops the boot at the first problem it finds. Rake is excluded on
# purpose: it loads this file to run `db:migrate`, which is exactly what two of
# them point to, so failing during the task would make the fix impossible.
unless defined?(Rake)
  Database.verify!
  Migrations.verify!
end
