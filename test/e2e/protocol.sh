#!/usr/bin/env sh
#
# protocol - end-to-end examples of the HTTP contract itself.
#
# The other examples (users, products, payments) exercise what each resource
# does. This one exercises what every request gets before any resource is
# reached: what happens when the route does not exist, when the method does not
# match, when the body is not JSON, when the body carries a field the resource
# does not accept, and when a parameter cannot mean what the route needs.
#
# Those are the answers a client has to be able to rely on, so they are checked
# through the real server exactly like the rest, with curl, written out.
#
# `\` is the shell escaping for the JSON quotes inside the double-quoted body.
#
# Exit codes: 0 when every example passes, 1 when at least one fails.

. "$(dirname -- "$0")/../support.sh"

suite "HTTP protocol (routes, methods and input)"

# The health check: the server is up.
example "answers the health check"
response=$(curl -s -i \
  "$base_url/")

expect_contains "$response" "HTTP/1.1 200 OK"
expect_contains "$response" '"status":"ok"'

# Every answer is JSON, including the errors.
example "answers JSON even when the route does not exist"
response=$(curl -s -i \
  "$base_url/does-not-exist")

expect_contains "$response" "HTTP/1.1 404 Not Found"
expect_contains_ci "$response" "content-type: application/json"
expect_contains "$response" '"error":"Resource not found"'

# The path exists, the method does not: 405 with the methods it does accept.
# The `Allow` header is part of the answer the client needs.
example "answers 405 with an Allow header for an unsupported method"
response=$(curl -s -i \
  -X DELETE \
  "$base_url/products")

expect_contains "$response" "HTTP/1.1 405 Method Not Allowed"
expect_contains_ci "$response" "allow:"
expect_contains "$response" '"error":"Method not allowed"'

# The same, for a path with a parameter in it: /payments/:id/confirm only
# answers POST, so asking it with PUT is a 405 and not a 404 - the address is
# right and only the verb is wrong.
example "answers 405 for an unsupported method on a parameterized path"
response=$(curl -s -i \
  -X PUT \
  "$base_url/payments/1/confirm" \
  -H "Content-Type: application/json" \
  -d "{}")

expect_contains "$response" "HTTP/1.1 405 Method Not Allowed"
expect_contains_ci "$response" "allow: POST"

# A body that is not JSON at all never reaches a model.
example "answers 400 for a body that is not JSON"
response=$(curl -s -i \
  -X POST \
  "$base_url/products" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Broken\",")

expect_contains "$response" "HTTP/1.1 400 Bad Request"
expect_contains "$response" '"error":"Invalid JSON"'

# Valid JSON, but not an object: the route expects attributes, not a list.
example "answers 400 for a JSON body that is not an object"
response=$(curl -s -i \
  -X POST \
  "$base_url/products" \
  -H "Content-Type: application/json" \
  -d "[1,2,3]")

expect_contains "$response" "HTTP/1.1 400 Bad Request"
expect_contains "$response" '"error":"JSON body must be an object"'

# An attribute the resource does not accept is refused, naming the field. It is
# a 400 and never a 500: the client sent a mistake, not the server.
example "answers 400 for an unknown field"
response=$(curl -s -i \
  -X POST \
  "$base_url/products" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Keyboard\",\"category\":\"peripherals\",\"price\":\"10.00\",\"colour\":\"black\"}")

expect_contains "$response" "HTTP/1.1 400 Bad Request"
expect_contains "$response" '"error":"Unknown fields"'
expect_contains "$response" "colour"

# A field the client must never set: the id and the password digest are decided
# by the server. The allowlist refuses them like any other unknown field, which
# is what keeps a client from choosing its own id.
example "answers 400 for a protected field"
response=$(curl -s -i \
  -X POST \
  "$base_url/users" \
  -H "Content-Type: application/json" \
  -d "{\"id\":999,\"name\":\"Ada Lovelace\",\"email\":\"ada-protected-$(unique_id)@example.com\",\"password\":\"secret123\",\"role\":\"user\"}")

expect_contains "$response" "HTTP/1.1 400 Bad Request"
expect_contains "$response" '"error":"Unknown fields"'
expect_contains "$response" "id"

# An id that is not a positive integer is a malformed address (400), not a
# missing resource (404): no record could ever have that id.
example "answers 400 for an id that is not a positive integer"
response=$(curl -s -i \
  "$base_url/users/abc")

expect_contains "$response" "HTTP/1.1 400 Bad Request"
expect_contains "$response" '"error":"Invalid id"'

# The same for a well formed id with no record behind it: now it is 404.
example "answers 404 for a well formed id that does not exist"
response=$(curl -s -i \
  "$base_url/users/999999")

expect_contains "$response" "HTTP/1.1 404 Not Found"
expect_contains "$response" '"error":"User not found"'

# A query parameter sent as a list (`limit[]=1&limit[]=2`) arrives as an Array
# instead of a text. The route only understands a single value, and reading the
# Array as if it were a text would change the meaning of the query, so it is
# refused.
example "answers 400 for a query parameter sent as a list"
response=$(curl -s -i \
  "$base_url/products?limit[]=1&limit[]=2")

expect_contains "$response" "HTTP/1.1 400 Bad Request"
expect_contains "$response" '"error":"Invalid parameter"'
expect_contains "$response" "limit must be a positive integer"

# A body larger than the limit is refused before it is parsed. The body goes
# through a file because a command line cannot carry 70 KB of it on Windows.
#
# Only the code of the status is checked, not its text: 413 was "Payload Too
# Large" in RFC 7231 and is "Content Too Large" in RFC 9110, so the phrase
# depends on the HTTP vocabulary of the server and changes between versions.
example "answers 413 for a body larger than the limit"
padding=$(awk 'BEGIN { while (i++ < 70000) printf "x" }')
printf '{"padding":"%s"}' "$padding" > "$suite_dir/oversized.json"

response=$(curl -s -i \
  -X POST \
  "$base_url/products" \
  -H "Content-Type: application/json" \
  --data-binary "@$suite_dir/oversized.json")

expect_contains "$response" "HTTP/1.1 413"
expect_contains "$response" '"error":"Request body too large"'

summary