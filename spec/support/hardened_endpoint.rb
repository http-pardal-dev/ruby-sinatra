# frozen_string_literal: true

# Shared examples for the hardening specs: given an endpoint that accepts a
# JSON body, these examples pin down how the application treats bodies and
# attributes that must never succeed silently.
#
# The host spec provides `path` (the endpoint) and `valid_body` (a Hash the
# endpoint accepts). `subject` is the response of sending `body` to the
# endpoint with the `request` helper the host spec provides.
RSpec.shared_examples "a hardened JSON endpoint" do
  it "returns 400 for an invalid JSON body" do
    post path, "{invalid", "CONTENT_TYPE" => "application/json"

    expect(last_response.status).to eq(400)
    expect(json_response["error"]).to eq("Invalid JSON")
  end

  it "returns 400 for a JSON body that is not an object" do
    post path, "[1, 2]", "CONTENT_TYPE" => "application/json"

    expect(last_response.status).to eq(400)
    expect(json_response["error"]).to eq("JSON body must be an object")
  end

  it "returns 400 for an unknown field, without a 500" do
    request valid_body.merge("unknown_field" => "nope")

    expect(last_response.status).to eq(400)
    expect(json_response["error"]).to eq("Unknown fields")
    expect(json_response["messages"].first).to include("unknown_field")
  end

  it "returns 413 for a body larger than the limit" do
    request valid_body.merge("padding" => "x" * (64 * 1024))

    expect(last_response.status).to eq(413)
    expect(json_response["error"]).to eq("Request body too large")
  end
end
