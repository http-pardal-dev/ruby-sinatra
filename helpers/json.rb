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
      raw = read_body
      return {} if raw.nil? || raw.strip.empty?

      parse_object(raw)
    end

    private

    # Reads the body, refusing it when it is larger than MAX_BODY_BYTES.
    #
    # The declared length answers first, so an oversized body is refused without
    # being read. It cannot be trusted on its own (a chunked request has none),
    # so the read stops one byte past the limit: a body that fits is read whole
    # and a longer one is cut short, and the server never holds more than the
    # limit plus one byte.
    def read_body
      refuse_large_body if request.content_length && request.content_length.to_i > MAX_BODY_BYTES

      raw = request.body&.read(MAX_BODY_BYTES + 1)
      refuse_large_body if raw && raw.bytesize > MAX_BODY_BYTES

      raw
    end

    def refuse_large_body
      halt 413, { error: "Request body too large" }.to_json
    end

    # Parses the body, which is expected to be a JSON object.
    def parse_object(raw)
      data = JSON.parse(raw)
      halt 400, { error: "JSON body must be an object" }.to_json unless data.is_a?(Hash)

      data
    rescue JSON::ParserError
      halt 400, { error: "Invalid JSON" }.to_json
    end
  end
end
