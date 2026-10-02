# frozen_string_literal: true

# E2E: Users (CRUD and HTTP fundamentals).
#
# Every example sends its own requests with `curl` to a real server started by
# spec/support/e2e_server.rb. The whole command is written out in each example
# on purpose: the method, the URL, the headers and the body stay visible, with
# no helper hiding how the request is built.
#
# `\\\"` is the Ruby escaping for the `\"` curl needs around a JSON value.
# `rand` only makes the email unique between runs, because the email of a user
# cannot repeat (see the "already taken" example further down).
RSpec.describe "Users (CRUD)", type: :e2e do
  # Creates a user. The password is stored as a digest and is never returned.
  it "creates a user" do
    response = `curl -s -i \
      -X POST \
      http://localhost:9292/users \
      -H "Content-Type: application/json" \
      -d "{\\\"name\\\":\\\"Ada Lovelace\\\",\\\"email\\\":\\\"ada-#{rand(1_000_000)}@example.com\\\",\\\"password\\\":\\\"secret123\\\",\\\"role\\\":\\\"user\\\",\\\"birthdate\\\":\\\"2000-01-01\\\"}"`

    expect(response).to include("HTTP/1.1 201 Created")
    expect(response.downcase).to include("location: /users/")
    expect(response).to include('"name":"Ada Lovelace"')
    expect(response).not_to include("password_digest")
  end

  # Finds the user created by the request above.
  it "finds a user by id" do
    created = `curl -s -i \
      -X POST \
      http://localhost:9292/users \
      -H "Content-Type: application/json" \
      -d "{\\\"name\\\":\\\"Grace Hopper\\\",\\\"email\\\":\\\"grace-#{rand(1_000_000)}@example.com\\\",\\\"password\\\":\\\"secret123\\\",\\\"role\\\":\\\"user\\\",\\\"birthdate\\\":\\\"1906-12-09\\\"}"`
    user_id = JSON.parse(created.split(/\r?\n\r?\n/, 2).last)["user"]["id"]

    response = `curl -s -i \
      http://localhost:9292/users/#{user_id}`

    expect(response).to include("HTTP/1.1 200 OK")
    expect(response).to include('"name":"Grace Hopper"')
  end

  # Lists every user.
  it "lists users" do
    `curl -s -i \
      -X POST \
      http://localhost:9292/users \
      -H "Content-Type: application/json" \
      -d "{\\\"name\\\":\\\"Alan Turing\\\",\\\"email\\\":\\\"alan-#{rand(1_000_000)}@example.com\\\",\\\"password\\\":\\\"secret123\\\",\\\"role\\\":\\\"user\\\",\\\"birthdate\\\":\\\"1912-06-23\\\"}"`

    response = `curl -s -i \
      http://localhost:9292/users`

    expect(response).to include("HTTP/1.1 200 OK")
    expect(response).to include('"name":"Alan Turing"')
  end

  # Replaces a user with PUT.
  it "replaces a user" do
    created = `curl -s -i \
      -X POST \
      http://localhost:9292/users \
      -H "Content-Type: application/json" \
      -d "{\\\"name\\\":\\\"Ada Lovelace\\\",\\\"email\\\":\\\"ada-#{rand(1_000_000)}@example.com\\\",\\\"password\\\":\\\"secret123\\\",\\\"role\\\":\\\"user\\\",\\\"birthdate\\\":\\\"2000-01-01\\\"}"`
    user_id = JSON.parse(created.split(/\r?\n\r?\n/, 2).last)["user"]["id"]

    response = `curl -s -i \
      -X PUT \
      http://localhost:9292/users/#{user_id} \
      -H "Content-Type: application/json" \
      -d "{\\\"name\\\":\\\"Ada King\\\",\\\"email\\\":\\\"ada.king-#{rand(1_000_000)}@example.com\\\",\\\"role\\\":\\\"admin\\\"}"`

    expect(response).to include("HTTP/1.1 200 OK")
    expect(response).to include('"name":"Ada King"')
    expect(response).to include('"role":"admin"')
  end

  # Partially updates a user with PATCH: only the sent field changes.
  it "partially updates a user" do
    created = `curl -s -i \
      -X POST \
      http://localhost:9292/users \
      -H "Content-Type: application/json" \
      -d "{\\\"name\\\":\\\"Ada Lovelace\\\",\\\"email\\\":\\\"ada-#{rand(1_000_000)}@example.com\\\",\\\"password\\\":\\\"secret123\\\",\\\"role\\\":\\\"user\\\",\\\"birthdate\\\":\\\"2000-01-01\\\"}"`
    user_id = JSON.parse(created.split(/\r?\n\r?\n/, 2).last)["user"]["id"]

    response = `curl -s -i \
      -X PATCH \
      http://localhost:9292/users/#{user_id} \
      -H "Content-Type: application/json" \
      -d "{\\\"name\\\":\\\"Ada L. King\\\"}"`

    expect(response).to include("HTTP/1.1 200 OK")
    expect(response).to include('"name":"Ada L. King"')
  end

  # Removes a user with DELETE: 204 no content, an empty body.
  it "deletes a user" do
    created = `curl -s -i \
      -X POST \
      http://localhost:9292/users \
      -H "Content-Type: application/json" \
      -d "{\\\"name\\\":\\\"To Delete\\\",\\\"email\\\":\\\"delete-#{rand(1_000_000)}@example.com\\\",\\\"password\\\":\\\"secret123\\\",\\\"role\\\":\\\"user\\\"}"`
    user_id = JSON.parse(created.split(/\r?\n\r?\n/, 2).last)["user"]["id"]

    response = `curl -s -i \
      -X DELETE \
      http://localhost:9292/users/#{user_id}`

    expect(response).to include("HTTP/1.1 204 No Content")
  end

  # A user that does not exist: 404 not found.
  it "returns 404 for a user that does not exist" do
    response = `curl -s -i \
      http://localhost:9292/users/999999`

    expect(response).to include("HTTP/1.1 404 Not Found")
    expect(response).to include('"error":"User not found"')
  end

  # A user without a name is refused by the model: 400 bad request.
  it "rejects a user without a name" do
    response = `curl -s -i \
      -X POST \
      http://localhost:9292/users \
      -H "Content-Type: application/json" \
      -d "{\\\"email\\\":\\\"no-name-#{rand(1_000_000)}@example.com\\\",\\\"password\\\":\\\"secret123\\\",\\\"role\\\":\\\"user\\\"}"`

    expect(response).to include("HTTP/1.1 400 Bad Request")
    expect(response).to include('"error":"Validation failed"')
  end

  # The email identifies the user, so a repeated email is refused: 400.
  it "rejects a user with an email that is already taken" do
    email = "duplicated-#{rand(1_000_000)}@example.com"

    `curl -s -i \
      -X POST \
      http://localhost:9292/users \
      -H "Content-Type: application/json" \
      -d "{\\\"name\\\":\\\"First User\\\",\\\"email\\\":\\\"#{email}\\\",\\\"password\\\":\\\"secret123\\\",\\\"role\\\":\\\"user\\\"}"`

    response = `curl -s -i \
      -X POST \
      http://localhost:9292/users \
      -H "Content-Type: application/json" \
      -d "{\\\"name\\\":\\\"Second User\\\",\\\"email\\\":\\\"#{email}\\\",\\\"password\\\":\\\"secret123\\\",\\\"role\\\":\\\"user\\\"}"`

    expect(response).to include("HTTP/1.1 400 Bad Request")
    expect(response).to include("has already been taken")
  end
end
