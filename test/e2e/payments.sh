#!/usr/bin/env sh
#
# payments - end-to-end examples of payments (lifecycle).
#
# Every example sends its own requests with curl to the real server started by
# bin/test. The whole command is written out in each example on purpose: the
# method, the URL, the headers and the body stay visible, with no helper hiding
# how the request is built.
#
# `\"` is the shell escaping for the JSON quotes inside the double-quoted body,
# so the command reaches curl exactly as it would be typed in a terminal.
# `-s` only silences curl's progress meter; `-i` keeps the status line and the
# headers, which are part of what the example checks.
#
# Exit codes: 0 when every example passes, 1 when at least one fails.

. "$(dirname -- "$0")/../support.sh"

suite "Payments (lifecycle)"

# Creates a payment; a new payment always starts as "pending".
example "creates a payment"
response=$(curl -s -i \
  -X POST \
  "$base_url/payments" \
  -H "Content-Type: application/json" \
  -d "{\"amount\":\"99.90\"}")

expect_contains "$response" "HTTP/1.1 201 Created"
expect_contains_ci "$response" "location: /payments/"
expect_contains "$response" '"status":"pending"'

# Finds the payment created by the request above.
example "finds a payment by id"
created=$(curl -s -i \
  -X POST \
  "$base_url/payments" \
  -H "Content-Type: application/json" \
  -d "{\"amount\":\"123.45\"}")
payment_id=$(extract_id "$created")

response=$(curl -s -i \
  "$base_url/payments/$payment_id")

expect_contains "$response" "HTTP/1.1 200 OK"
expect_contains "$response" '"amount":"123.45"'

# Confirms a payment: the action moves it from "pending" to "paid".
example "confirms a payment"
created=$(curl -s -i \
  -X POST \
  "$base_url/payments" \
  -H "Content-Type: application/json" \
  -d "{\"amount\":\"99.90\"}")
payment_id=$(extract_id "$created")

response=$(curl -s -i \
  -X POST \
  "$base_url/payments/$payment_id/confirm")

expect_contains "$response" "HTTP/1.1 200 OK"
expect_contains "$response" '"status":"paid"'

# Cancels a payment: the action moves it from "pending" to "cancelled".
example "cancels a payment"
created=$(curl -s -i \
  -X POST \
  "$base_url/payments" \
  -H "Content-Type: application/json" \
  -d "{\"amount\":\"50.00\"}")
payment_id=$(extract_id "$created")

response=$(curl -s -i \
  -X POST \
  "$base_url/payments/$payment_id/cancel")

expect_contains "$response" "HTTP/1.1 200 OK"
expect_contains "$response" '"status":"cancelled"'

# A payment that is not "pending" cannot be confirmed again: 409 conflict.
example "refuses to confirm a payment that is not pending"
created=$(curl -s -i \
  -X POST \
  "$base_url/payments" \
  -H "Content-Type: application/json" \
  -d "{\"amount\":\"99.90\"}")
payment_id=$(extract_id "$created")

curl -s -i \
  -X POST \
  "$base_url/payments/$payment_id/confirm" > /dev/null

response=$(curl -s -i \
  -X POST \
  "$base_url/payments/$payment_id/confirm")

expect_contains "$response" "HTTP/1.1 409 Conflict"

# A payment that is not "pending" cannot be cancelled again: 409 conflict.
example "refuses to cancel a payment that is not pending"
created=$(curl -s -i \
  -X POST \
  "$base_url/payments" \
  -H "Content-Type: application/json" \
  -d "{\"amount\":\"99.90\"}")
payment_id=$(extract_id "$created")

curl -s -i \
  -X POST \
  "$base_url/payments/$payment_id/cancel" > /dev/null

response=$(curl -s -i \
  -X POST \
  "$base_url/payments/$payment_id/cancel")

expect_contains "$response" "HTTP/1.1 409 Conflict"

# A payment that does not exist: 404 not found.
example "returns 404 for a payment that does not exist"
response=$(curl -s -i \
  "$base_url/payments/999999")

expect_contains "$response" "HTTP/1.1 404 Not Found"
expect_contains "$response" '"error":"Payment not found"'

# An invalid amount is refused by the model: 400 bad request.
example "rejects a payment with an invalid amount"
response=$(curl -s -i \
  -X POST \
  "$base_url/payments" \
  -H "Content-Type: application/json" \
  -d "{\"amount\":\"0\"}")

expect_contains "$response" "HTTP/1.1 400 Bad Request"
expect_contains "$response" '"error":"Validation failed"'

# Lists the payments filtered by state through a query parameter.
example "lists payments filtered by status"
created=$(curl -s -i \
  -X POST \
  "$base_url/payments" \
  -H "Content-Type: application/json" \
  -d "{\"amount\":\"77.77\"}")
payment_id=$(extract_id "$created")

response=$(curl -s -i \
  "$base_url/payments?status=pending")

expect_contains "$response" "HTTP/1.1 200 OK"
expect_contains "$response" "\"id\":$payment_id"
expect_contains "$response" '"status":"pending"'

# A state that does not exist is refused instead of answering with an empty
# list, which would look exactly like "there is no payment in that state".
example "rejects an unknown status filter"
response=$(curl -s -i \
  "$base_url/payments?status=failed")

expect_contains "$response" "HTTP/1.1 400 Bad Request"
expect_contains "$response" "status must be one of:"

# The two actions are exclusive. A cancelled payment is not "pending" anymore,
# so it cannot be confirmed: the same rule as repeating an action, seen from the
# other side.
example "refuses to confirm a payment that was cancelled"
created=$(curl -s -i \
  -X POST \
  "$base_url/payments" \
  -H "Content-Type: application/json" \
  -d "{\"amount\":\"42.00\"}")
payment_id=$(extract_id "$created")

curl -s -i \
  -X POST \
  "$base_url/payments/$payment_id/cancel" > /dev/null

response=$(curl -s -i \
  -X POST \
  "$base_url/payments/$payment_id/confirm")

expect_contains "$response" "HTTP/1.1 409 Conflict"
expect_contains "$response" '"error":"A payment with status cancelled cannot be confirmed"'

# Two clients confirming the same payment at the same time. The transition is a
# single UPDATE that only matches a "pending" row, so exactly one of them can
# win: the other changes nothing and answers 409. Reading the state first and
# writing it afterwards would let both read "pending" and both confirm.
example "lets only one of two concurrent confirms win"
created=$(curl -s -i \
  -X POST \
  "$base_url/payments" \
  -H "Content-Type: application/json" \
  -d "{\"amount\":\"31.00\"}")
payment_id=$(extract_id "$created")

# `-w` prints the status code and nothing else, and the `&` puts both requests
# in the background so they really are in flight together.
curl -s -o /dev/null -w '%{http_code}' \
  -X POST "$base_url/payments/$payment_id/confirm" > "$suite_dir/first" &
curl -s -o /dev/null -w '%{http_code}' \
  -X POST "$base_url/payments/$payment_id/confirm" > "$suite_dir/second" &
wait

first_code=$(cat "$suite_dir/first")
second_code=$(cat "$suite_dir/second")

if [ "$first_code" = "200" ] && [ "$second_code" = "409" ]; then
  :
elif [ "$first_code" = "409" ] && [ "$second_code" = "200" ]; then
  :
else
  fail_expectation "expected one 200 and one 409, but got: $first_code and $second_code"
fi

# Whichever one won, the payment ended in a single state - never in both and
# never in neither.
response=$(curl -s -i \
  "$base_url/payments/$payment_id")

expect_contains "$response" "HTTP/1.1 200 OK"
expect_contains "$response" '"status":"paid"'

summary
