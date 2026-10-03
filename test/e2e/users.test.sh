#!/usr/bin/env sh
#
# users.test.sh - end-to-end examples of users (CRUD and HTTP fundamentals).
#
# Every example sends its own requests with curl to the real server started by
# bin/test. The whole command is written out in each example on purpose: the
# method, the URL, the headers and the body stay visible, with no helper hiding
# how the request is built.
#
# `\"` is the shell escaping for the JSON quotes inside the double-quoted body,
# so the command reaches curl exactly as it would be typed in a terminal.
# unique_id only makes the email unique between runs, because the email of a
# user cannot repeat (see the "already taken" example further down).
#
# Exit codes: 0 when every example passes, 1 when at least one fails.

. "$(dirname -- "$0")/../support.sh"

suite "Users (CRUD)"

# Creates a user. The password is stored as a digest and is never returned.
example "creates a user"
response=$(curl -s -i \
  -X POST \
  "$base_url/users" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Ada Lovelace\",\"email\":\"ada-$(unique_id)@example.com\",\"password\":\"secret123\",\"role\":\"user\",\"birthdate\":\"2000-01-01\"}")

expect_contains "$response" "HTTP/1.1 201 Created"
expect_contains_ci "$response" "location: /users/"
expect_contains "$response" '"name":"Ada Lovelace"'
expect_not_contains "$response" "password_digest"

# Finds the user created by the request above.
example "finds a user by id"
created=$(curl -s -i \
  -X POST \
  "$base_url/users" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Grace Hopper\",\"email\":\"grace-$(unique_id)@example.com\",\"password\":\"secret123\",\"role\":\"user\",\"birthdate\":\"1906-12-09\"}")
user_id=$(extract_id "$created")

response=$(curl -s -i \
  "$base_url/users/$user_id")

expect_contains "$response" "HTTP/1.1 200 OK"
expect_contains "$response" '"name":"Grace Hopper"'

# Lists every user.
example "lists users"
curl -s -i \
  -X POST \
  "$base_url/users" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Alan Turing\",\"email\":\"alan-$(unique_id)@example.com\",\"password\":\"secret123\",\"role\":\"user\",\"birthdate\":\"1912-06-23\"}" > /dev/null

response=$(curl -s -i \
  "$base_url/users")

expect_contains "$response" "HTTP/1.1 200 OK"
expect_contains "$response" '"name":"Alan Turing"'

# Replaces a user with PUT.
example "replaces a user"
created=$(curl -s -i \
  -X POST \
  "$base_url/users" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Ada Lovelace\",\"email\":\"ada-$(unique_id)@example.com\",\"password\":\"secret123\",\"role\":\"user\",\"birthdate\":\"2000-01-01\"}")
user_id=$(extract_id "$created")

response=$(curl -s -i \
  -X PUT \
  "$base_url/users/$user_id" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Ada King\",\"email\":\"ada.king-$(unique_id)@example.com\",\"role\":\"admin\"}")

expect_contains "$response" "HTTP/1.1 200 OK"
expect_contains "$response" '"name":"Ada King"'
expect_contains "$response" '"role":"admin"'

# Partially updates a user with PATCH: only the sent field changes.
example "partially updates a user"
created=$(curl -s -i \
  -X POST \
  "$base_url/users" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Ada Lovelace\",\"email\":\"ada-$(unique_id)@example.com\",\"password\":\"secret123\",\"role\":\"user\",\"birthdate\":\"2000-01-01\"}")
user_id=$(extract_id "$created")

response=$(curl -s -i \
  -X PATCH \
  "$base_url/users/$user_id" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Ada L. King\"}")

expect_contains "$response" "HTTP/1.1 200 OK"
expect_contains "$response" '"name":"Ada L. King"'

# Removes a user with DELETE: 204 no content, an empty body.
example "deletes a user"
created=$(curl -s -i \
  -X POST \
  "$base_url/users" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"To Delete\",\"email\":\"delete-$(unique_id)@example.com\",\"password\":\"secret123\",\"role\":\"user\"}")
user_id=$(extract_id "$created")

response=$(curl -s -i \
  -X DELETE \
  "$base_url/users/$user_id")

expect_contains "$response" "HTTP/1.1 204 No Content"

# A user that does not exist: 404 not found.
example "returns 404 for a user that does not exist"
response=$(curl -s -i \
  "$base_url/users/999999")

expect_contains "$response" "HTTP/1.1 404 Not Found"
expect_contains "$response" '"error":"User not found"'

# A user without a name is refused by the model: 400 bad request.
example "rejects a user without a name"
response=$(curl -s -i \
  -X POST \
  "$base_url/users" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"no-name-$(unique_id)@example.com\",\"password\":\"secret123\",\"role\":\"user\"}")

expect_contains "$response" "HTTP/1.1 400 Bad Request"
expect_contains "$response" '"error":"Validation failed"'

# The email identifies the user, so a repeated email is refused: 400.
example "rejects a user with an email that is already taken"
email="duplicated-$(unique_id)@example.com"

curl -s -i \
  -X POST \
  "$base_url/users" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"First User\",\"email\":\"$email\",\"password\":\"secret123\",\"role\":\"user\"}" > /dev/null

response=$(curl -s -i \
  -X POST \
  "$base_url/users" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Second User\",\"email\":\"$email\",\"password\":\"secret123\",\"role\":\"user\"}")

expect_contains "$response" "HTTP/1.1 400 Bad Request"
expect_contains "$response" "has already been taken"

# A field the server decides cannot be set by the client. `id` is refused like
# any other unknown field, which is what keeps a client from choosing its own id.
example "rejects an attempt to set the id"
response=$(curl -s -i \
  -X POST \
  "$base_url/users" \
  -H "Content-Type: application/json" \
  -d "{\"id\":999,\"name\":\"Ada Lovelace\",\"email\":\"ada-id-$(unique_id)@example.com\",\"password\":\"secret123\",\"role\":\"user\"}")

expect_contains "$response" "HTTP/1.1 400 Bad Request"
expect_contains "$response" '"error":"Unknown fields"'

# An email longer than the mail standards allow is refused by the model.
example "rejects an email that is too long"
long_email="$(awk 'BEGIN { while (i++ < 250) printf "a" }')@example.com"
response=$(curl -s -i \
  -X POST \
  "$base_url/users" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Ada Lovelace\",\"email\":\"$long_email\",\"password\":\"secret123\",\"role\":\"user\"}")

expect_contains "$response" "HTTP/1.1 400 Bad Request"
expect_contains "$response" '"error":"Validation failed"'

# A birthdate that is not a real date is refused instead of being read as "no
# birthdate": ActiveRecord turns an unreadable date into nothing, and the
# validation catches the raw value before that happens.
example "rejects a birthdate that is not a real date"
response=$(curl -s -i \
  -X POST \
  "$base_url/users" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Ada Lovelace\",\"email\":\"ada-birth-$(unique_id)@example.com\",\"password\":\"secret123\",\"role\":\"user\",\"birthdate\":\"2000-13-40\"}")

expect_contains "$response" "HTTP/1.1 400 Bad Request"
expect_contains "$response" "must be a valid date"

summary
