# frozen_string_literal: true

require "json"

# Helpers responsible for JSON handling in requests and responses.
module Helpers
  module Json
    # Largest request body the server reads: 64 KB. Every JSON body of this
    # API is a single resource with short fields, so anything larger is a
    # mistake or an abuse, and the request is refused with 413 before the
    # body is parsed.
    MAX_BODY_BYTES = 64 * 1024

    # Serializes `data` as JSON, optionally with an HTTP status.
    def json(data, status_code = 200)
      status(status_code)
      data.to_json
    end

    # Reads and parses the request JSON body.
    # The server expects a JSON object, so this returns a Hash; an empty body
    # results in an empty Hash. Invalid JSON or a valid JSON value that is not
    # an object (for example an array or a string) aborts the request with 400,
    # and a body larger than MAX_BODY_BYTES aborts it with 413.
    def json_body
      if request.content_length && request.content_length.to_i > MAX_BODY_BYTES
        halt 413, { error: "Request body too large" }.to_json
      end

      # Reads one byte past the limit: a body that fits is read whole, and a
      # longer one is cut short, so the server never holds more than the limit
      # plus one byte. Chunked requests have no content-length, which is why
      # the limit is enforced here too, not only above.
      body = request.body&.read(MAX_BODY_BYTES + 1)
      if body && body.bytesize > MAX_BODY_BYTES
        halt 413, { error: "Request body too large" }.to_json
      end

      return {} if body.nil? || body.strip.empty?

      data = JSON.parse(body)
      halt 400, { error: "JSON body must be an object" }.to_json unless data.is_a?(Hash)

      data
    rescue JSON::ParserError
      halt 400, { error: "Invalid JSON" }.to_json
    end
  end
end
