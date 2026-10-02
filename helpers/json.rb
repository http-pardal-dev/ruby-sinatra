# frozen_string_literal: true

require "json"

# Helpers responsible for JSON handling in requests and responses.
module Helpers
  module Json
    # Serializes `data` as JSON, optionally with an HTTP status.
    def json(data, status_code = 200)
      status(status_code)
      data.to_json
    end

    # Reads and parses the request JSON body.
    # The server expects a JSON object, so this returns a Hash; an empty body
    # results in an empty Hash. Invalid JSON or a valid JSON value that is not
    # an object (for example an array or a string) aborts the request with 400.
    def json_body
      body = request.body&.read
      return {} if body.nil? || body.strip.empty?

      data = JSON.parse(body)
      halt 400, { error: "JSON body must be an object" }.to_json unless data.is_a?(Hash)

      data
    rescue JSON::ParserError
      halt 400, { error: "Invalid JSON" }.to_json
    end
  end
end
