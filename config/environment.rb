# frozen_string_literal: true

# Application environment.
# Prepares the runtime (see config/boot.rb), then loads environment variables,
# the application and the environment-specific settings.

require_relative "boot"

require "dotenv/load"

# Runtime environment: development (default) or test.
ENV["APP_ENV"] ||= "development"
APP_ENV = ENV["APP_ENV"].to_sym

require_relative "../app"
require_relative "../models/user"
require_relative "../models/product"
require_relative "../models/payment"

# Settings specific to the current environment (development/test).
require_relative "environment/#{APP_ENV}"
