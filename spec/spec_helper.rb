# frozen_string_literal: true

# RSpec infrastructure for unit (models) and request (routes) specs.
#
# The specs run in the `test` environment, against `storage/test.sqlite3`
# (see config/environment.rb and data/database.yml). `bin/setup` prepares that
# database, so the specs assume it exists with the tables migrated: running
# `bundle exec rspec` without it fails fast with a boot error that points to
# `bin/setup`.
#
# Request specs use Rack::Test, which exercises the routes through Rack without
# starting a server. Model specs use the same database connection, cleaned
# between examples so each example sees an empty database.

require "rspec"

# The environment must be selected before the application loads: dotenv never
# overrides a variable that is already set, so forcing `test` here keeps the
# specs from touching the development database even when `.env` says otherwise.
ENV["APP_ENV"] = "test"

require_relative "../config/environment"
require "rack/test"
require_relative "support/request_helpers"
require_relative "support/hardened_endpoint"

RSpec.configure do |config|
  config.include Rack::Test::Methods

  # Rack::Test sends every request to the Sinatra application.
  config.define_derived_metadata(file_path: %r{spec/requests/}) do |metadata|
    metadata[:type] = :request
  end

  def app
    App
  end

  # Each example starts with empty tables, so records created by one example
  # never leak into another. There are no foreign keys between the tables, so
  # the order does not matter.
  config.before do
    User.delete_all
    Product.delete_all
    Payment.delete_all
  end

  # Documentation format by default: the output reads as the behavior of each
  # resource, which is the point of the suite.
  config.formatter = :documentation
end
