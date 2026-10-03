# frozen_string_literal: true

require_relative "../spec_helper"

# Baseline behavior of the Users routes, before the input hardening of the
# roadmap (§3). These request specs document the HTTP contract that the
# hardening must preserve: status codes, response shapes and headers.
RSpec.describe "Users requests", type: :request do
  # The smallest valid user body: name, email and password decide validity.
  def user_body(overrides = {})
    {
      "name" => "Ada Lovelace",
      "email" => "ada@example.com",
      "password" => "secret123",
      "role" => "user"
    }.merge(overrides)
  end

  # Creates a user through the API and returns the parsed resource: the
  # response wraps it in a "user" key.
  def create_user(overrides = {})
    post_json "/users", user_body(overrides)
    expect(last_response.status).to eq(201)
    json_response["user"]
  end

  it "POST /users creates a user with 201 and a Location header" do
    post_json "/users", user_body

    expect(last_response.status).to eq(201)
    expect(last_response.headers["Location"]).to match(%r{\A/users/\d+\z})
    expect(json_response["user"]["name"]).to eq("Ada Lovelace")
    expect(json_response["user"]).not_to have_key("password_digest")
  end

  it "GET /users/:id finds a user by id" do
    user = create_user

    get "/users/#{user["id"]}"

    expect(last_response.status).to eq(200)
    expect(json_response["user"]["name"]).to eq("Ada Lovelace")
  end

  it "GET /users lists users" do
    create_user

    get "/users"

    expect(last_response.status).to eq(200)
    expect(json_response["users"]).not_to be_empty
  end

  it "PUT /users/:id updates a user" do
    user = create_user

    put_json "/users/#{user["id"]}", { "name" => "Ada King", "role" => "admin" }

    expect(last_response.status).to eq(200)
    expect(json_response["user"]["name"]).to eq("Ada King")
    expect(json_response["user"]["role"]).to eq("admin")
  end

  it "PATCH /users/:id partially updates a user" do
    user = create_user

    patch_json "/users/#{user["id"]}", { "name" => "Ada L. King" }

    expect(last_response.status).to eq(200)
    expect(json_response["user"]["name"]).to eq("Ada L. King")
  end

  it "DELETE /users/:id removes a user with 204" do
    user = create_user

    delete "/users/#{user["id"]}"

    expect(last_response.status).to eq(204)
  end

  it "GET /users/:id returns 404 for a user that does not exist" do
    get "/users/999999"

    expect(last_response.status).to eq(404)
    expect(json_response["error"]).to eq("User not found")
  end

  it "POST /users returns 400 for a user without a name" do
    post_json "/users", user_body("name" => nil)

    expect(last_response.status).to eq(400)
    expect(json_response["error"]).to eq("Validation failed")
  end

  it "POST /users returns 400 for a duplicated email" do
    create_user
    post_json "/users", user_body("name" => "Grace Hopper")

    expect(last_response.status).to eq(400)
    expect(json_response["error"]).to eq("Validation failed")
  end
end
