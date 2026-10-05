# frozen_string_literal: true

# Tools the request specs use: JSON bodies in, parsed responses out.
#
# This is tooling, not behaviour: nothing here asserts anything, it only makes
# an example shorter. The behaviour several specs assert together lives in
# spec/shared/.
module RequestHelpers
  # Sends a JSON body: the helper serializes the Hash and sets the
  # content-type, so each example shows only the data that matters.
  def post_json(path, body)
    post path, body.to_json, "CONTENT_TYPE" => "application/json"
  end

  def put_json(path, body)
    put path, body.to_json, "CONTENT_TYPE" => "application/json"
  end

  def patch_json(path, body)
    patch path, body.to_json, "CONTENT_TYPE" => "application/json"
  end

  # The parsed response body. Every error response of the application is a
  # Hash with at least an "error" key, and every success response wraps the
  # resource ("user", "product", "payment") or a list of them.
  def json_response
    JSON.parse(last_response.body)
  end

  # Full response dump for debugging a failing example: status, headers and
  # body on a single inspectable line.
  def dump_response
    "status=#{last_response.status} headers=#{last_response.headers.inspect} body=#{last_response.body}"
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
