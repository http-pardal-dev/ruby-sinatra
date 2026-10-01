# frozen_string_literal: true

# Server boot entry point.
# Loads dependencies and environment variables, then the application.

require "bundler/setup"
require "bundler"
Bundler.require(:default)

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
