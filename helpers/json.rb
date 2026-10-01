# frozen_string_literal: true

require "json"

# Helpers responsible for JSON handling in requests and responses.
module Helpers
  module Json
    # Serializes `data` as JSON, optionally with an HTTP status.
    def json(data, status_code = 200)
      self.status(status_code)
      data.to_json
    end

    # Reads and parses the request JSON body.
    # Returns a Hash; an empty body results in an empty Hash and
    # invalid JSON aborts the request with 400.
    def json_body
      body = request.body&.read
      return {} if body.nil? || body.strip.empty?

      JSON.parse(body)
    rescue JSON::ParserError
      halt 400, { error: "Invalid JSON" }.to_json
    end
  end
end
