# frozen_string_literal: true

# RSpec infrastructure, split the way the application is (see app/): the models
# live in spec/models/ and the routes in spec/routes/, one file per resource,
# named after it:
#
#   spec/models/<resource>.rb         one model, on its own
#   spec/routes/<resource>_routes.rb  the routes of the resource, through Rack
#
# spec/errors_spec.rb is the exception: the protocol (404, 405, 400, 500)
# belongs to no single resource, so it sits at the top of spec/.
#
# What the specs reuse lives in two other places, because the two are not the
# same thing: spec/support/helpers/ holds the tools the specs use (sending a
# JSON body, reading the answer), and spec/shared/ holds the behaviour more than
# one spec asserts (a hardened endpoint answering the same four ways for every
# resource).
#
# The specs run in the `test` environment, against `storage/test.sqlite3`
# (see config/environment.rb and data/database.yml). Prepare that database with
# `APP_ENV=test bundle exec rake db:migrate`: the specs assume it exists with
# the tables migrated, and without it they fail fast with a boot error that says
# what to run.
#
# Both kinds use the same database connection, cleaned between examples so each
# example sees an empty database. The integration specs go through Rack with
# Rack::Test, without starting a server.

require "rspec"

# The environment must be selected before the application loads: dotenv never
# overrides a variable that is already set, so forcing `test` here keeps the
# specs from touching the development database even when `.env` says otherwise.
ENV["APP_ENV"] = "test"

require_relative "../config/environment"
require "rack/test"
require_relative "support/helpers/request_helpers"
require_relative "shared/hardened_json_endpoint"

RSpec.configure do |config|
  config.include Rack::Test::Methods

  # The request specs go through Rack: Rack::Test sends every request to the
  # Sinatra application. The model specs do not, so they do not need the type.
  # The request specs are the files in spec/routes/, plus the protocol-level
  # errors_spec.
  config.define_derived_metadata(file_path: %r{spec/(?:routes/.+|errors)_spec\.rb}) do |metadata|
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
