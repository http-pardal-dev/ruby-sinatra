#!/usr/bin/env sh
#
# products - end-to-end examples of products (queries).
#
# Every example sends its own requests with curl to the real server started by
# bin/test. The whole command is written out in each example on purpose: the
# method, the URL, the headers and the body stay visible, with no helper hiding
# how the request is built.
#
# `\"` is the shell escaping for the JSON quotes inside the double-quoted body.
# A query string is quoted ("...?a=1&b=2") so the `&` never reaches the shell.
#
# Exit codes: 0 when every example passes, 1 when at least one fails.

. "$(dirname -- "$0")/../support.sh"

suite "Products (queries)"

# Creates a product.
example "creates a product"
response=$(curl -s -i \
  -X POST \
  "$base_url/products" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Keyboard\",\"category\":\"peripherals\",\"price\":\"159.90\"}")

expect_contains "$response" "HTTP/1.1 201 Created"
expect_contains_ci "$response" "location: /products/"
expect_contains "$response" '"name":"Keyboard"'

# Finds the product created by the request above.
example "finds a product by id"
created=$(curl -s -i \
  -X POST \
  "$base_url/products" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Mouse\",\"category\":\"peripherals\",\"price\":\"39.90\"}")
product_id=$(extract_id "$created")

response=$(curl -s -i \
  "$base_url/products/$product_id")

expect_contains "$response" "HTTP/1.1 200 OK"
expect_contains "$response" '"name":"Mouse"'

# Lists the products with pagination (page and limit).
example "lists products with pagination"
curl -s -i \
  -X POST \
  "$base_url/products" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Monitor\",\"category\":\"displays\",\"price\":\"900.00\"}" > /dev/null

response=$(curl -s -i \
  "$base_url/products?page=1&limit=2")

expect_contains "$response" "HTTP/1.1 200 OK"
expect_contains "$response" '"pagination":{"page":1,"limit":2'

# Filters the products by category. The category is unique, so exactly the
# product created above matches.
example "filters products by category"
category="e2e-category-$(unique_id)"

curl -s -i \
  -X POST \
  "$base_url/products" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Cable\",\"category\":\"$category\",\"price\":\"10.00\"}" > /dev/null

response=$(curl -s -i \
  "$base_url/products?category=$category")

expect_contains "$response" "HTTP/1.1 200 OK"
expect_contains "$response" "\"category\":\"$category\""
expect_contains "$response" '"total":1'

# Filters the products by price range (min_price and max_price).
example "filters products by price range"
curl -s -i \
  -X POST \
  "$base_url/products" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Headset\",\"category\":\"audio\",\"price\":\"250.00\"}" > /dev/null

response=$(curl -s -i \
  "$base_url/products?min_price=200&max_price=300")

expect_contains "$response" "HTTP/1.1 200 OK"
expect_contains "$response" '"name":"Headset"'

# Sorts the products by price, descending (the "-" prefix).
example "sorts products by price"
curl -s -i \
  -X POST \
  "$base_url/products" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Laptop\",\"category\":\"computers\",\"price\":\"3500.00\"}" > /dev/null

response=$(curl -s -i \
  "$base_url/products?sort=-price")

expect_contains "$response" "HTTP/1.1 200 OK"
expect_contains "$response" '"name":"Laptop"'

# Partially updates a product with PATCH: only the sent field changes.
example "partially updates a product"
created=$(curl -s -i \
  -X POST \
  "$base_url/products" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Webcam\",\"category\":\"video\",\"price\":\"180.00\"}")
product_id=$(extract_id "$created")

response=$(curl -s -i \
  -X PATCH \
  "$base_url/products/$product_id" \
  -H "Content-Type: application/json" \
  -d "{\"price\":\"149.90\"}")

expect_contains "$response" "HTTP/1.1 200 OK"
expect_contains "$response" '"price":"149.9"'

# A product that does not exist: 404 not found.
example "returns 404 for a product that does not exist"
response=$(curl -s -i \
  "$base_url/products/999999")

expect_contains "$response" "HTTP/1.1 404 Not Found"
expect_contains "$response" '"error":"Product not found"'

# A negative price is refused by the model: 400 bad request.
example "rejects a product with a negative price"
response=$(curl -s -i \
  -X POST \
  "$base_url/products" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Broken\",\"category\":\"misc\",\"price\":\"-1\"}")

expect_contains "$response" "HTTP/1.1 400 Bad Request"
expect_contains "$response" '"error":"Validation failed"'

summary
