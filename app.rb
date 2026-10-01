# frozen_string_literal: true

require "sinatra/base"
require "sinatra/activerecord"
require "json"

require_relative "errors/errors"
require_relative "helpers/json"

# Modular-style Sinatra application.
#
# Default configuration: the server works only with JSON.
#   - every response uses the application/json content-type;
#   - the request body is parsed as JSON;
#   - errors (404 and 500) also return JSON.
#
# Database access uses the sinatra-activerecord gem (ActiveRecord).
# Routes live in routes/ (one file per resource) and the models (ActiveRecord) in models/.
class App < Sinatra::Base
  configure do
    set :environment, APP_ENV
    set :show_exceptions, false
    set :raise_errors, false

    # Default content-type for every response.
    set :default_content_type, :json
  end

  # ActiveRecord integration via the sinatra-activerecord gem.
  # The connection is defined in data/database.yml, according to the environment.
  register Sinatra::ActiveRecordExtension
  set :database_file, File.expand_path("data/database.yml", __dir__)

  # JSON helpers (json and json_body) defined in helpers/json.rb.
  helpers Helpers::Json

  # Error handling (not_found and error) defined in errors/errors.rb.
  register Errors

  # Health check route: confirms the server is up.
  get "/" do
    # TODO: return a JSON with service information.
  end
end

# Routes for each resource, one file per resource in routes/:
#   - routes/users.rb    -> Users    (CRUD and fundamentals)
#   - routes/products.rb -> Products (queries)
#   - routes/payments.rb -> Payments (lifecycle)
require_relative "routes/users"
require_relative "routes/products"
require_relative "routes/payments"
