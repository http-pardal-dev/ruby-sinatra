# frozen_string_literal: true

# Tests run in the `test` environment (database storage/test.sqlite3).
ENV["APP_ENV"] = "test"

require_relative "../config/environment"
require "rack/test"

# Provides the `app` method required by Rack::Test in request specs.
module AppHelper
  def app
    App
  end
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include AppHelper

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
