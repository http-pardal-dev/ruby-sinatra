# frozen_string_literal: true

require_relative "../spec_helper"

# Protocol-level behavior: unknown routes, unsupported methods, malformed
# requests and unexpected failures. These specs pin down the HTTP contract
# that every resource inherits: 404 for what does not exist, 405 for what
# exists under another verb, 400 for what the server cannot parse, and 500
# without internals for what the server did not expect.
RSpec.describe "HTTP protocol", type: :request do
  it "GET /nope returns 404 for a route that does not exist" do
    get "/nope"

    expect(last_response.status).to eq(404)
    expect(json_response["error"]).to eq("Resource not found")
  end

  it "DELETE /products/:id returns 405 with an Allow header" do
    post_json "/products", { "name" => "Webcam", "category" => "video", "price" => "180.00" }
    product_id = json_response["product"]["id"]

    delete "/products/#{product_id}"

    expect(last_response.status).to eq(405)
    expect(json_response["error"]).to eq("Method not allowed")
    expect(last_response.headers["Allow"]).to include("GET", "PATCH")
    expect(json_response["allow"]).to eq(last_response.headers["Allow"])
  end

  it "PUT /payments/:id/confirm returns 405 with an Allow header" do
    post_json "/payments", { "amount" => "10.00" }
    payment_id = json_response["payment"]["id"]

    put "/payments/#{payment_id}/confirm", {}.to_json, "CONTENT_TYPE" => "application/json"

    expect(last_response.status).to eq(405)
    expect(last_response.headers["Allow"]).to include("POST")
  end

  it "POST /users returns 400 for invalid JSON" do
    post "/users", "{invalid", "CONTENT_TYPE" => "application/json"

    expect(last_response.status).to eq(400)
    expect(json_response["error"]).to eq("Invalid JSON")
  end

  it "answers 500 without internals on an unexpected failure" do
    allow(User).to receive(:all).and_raise(RuntimeError, "boom")

    get "/users"

    expect(last_response.status).to eq(500)
    expect(json_response["error"]).to eq("Internal server error")
    expect(last_response.body).not_to include("boom")
  end

  it "answers 409 on a uniqueness race that reaches the database" do
    allow(User).to receive(:find_by).and_return(nil)
    allow_any_instance_of(User).to receive(:save!).and_raise(ActiveRecord::RecordNotUnique.new("unique"))

    post_json "/users", {
      "name" => "Ada Lovelace",
      "email" => "ada@example.com",
      "password" => "secret123"
    }

    expect(last_response.status).to eq(409)
  end

  it "answers 400 on an attribute the allowlist missed" do
    user = User.create!(name: "Ada Lovelace", email: "ada@example.com", password: "secret123")

    # The allowlist and the table agree in normal operation, so this failure is
    # simulated: the record is found as usual, but assigning the (allowed)
    # attributes raises, as it would if the allowlist named a column that does
    # not exist.
    allow(User).to receive(:find_by).and_return(user)
    allow(user).to receive(:assign_attributes).and_raise(
      ActiveRecord::UnknownAttributeError.new(user, "unknown column")
    )

    put_json "/users/#{user.id}", {
      "name" => "Ada Lovelace",
      "email" => "ada@example.com",
      "role" => "user"
    }

    expect(last_response.status).to eq(400), dump_response
    expect(json_response["error"]).to eq("Unknown fields")
  end

  it "answers every response as JSON" do
    get "/nope"

    expect(last_response.headers["Content-Type"]).to include("application/json")
  end
end
