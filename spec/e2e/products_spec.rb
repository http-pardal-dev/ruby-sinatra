# frozen_string_literal: true

# E2E: Products (queries).
#
# Every example sends its own requests with `curl` to a real server started by
# spec/support/e2e_server.rb. The whole command is written out in each example
# on purpose: the method, the URL, the headers and the body stay visible, with
# no helper hiding how the request is built.
#
# `\\\"` is the Ruby escaping for the `\"` curl needs around a JSON value. A
# query string is quoted ("...?a=1&b=2") so the `&` never reaches the shell.
RSpec.describe "Products (queries)", type: :e2e do
  # Creates a product.
  it "creates a product" do
    response = `curl -s -i \
      -X POST \
      http://localhost:9292/products \
      -H "Content-Type: application/json" \
      -d "{\\\"name\\\":\\\"Keyboard\\\",\\\"category\\\":\\\"peripherals\\\",\\\"price\\\":\\\"159.90\\\"}"`

    expect(response).to include("HTTP/1.1 201 Created")
    expect(response.downcase).to include("location: /products/")
    expect(response).to include('"name":"Keyboard"')
  end

  # Finds the product created by the request above.
  it "finds a product by id" do
    created = `curl -s -i \
      -X POST \
      http://localhost:9292/products \
      -H "Content-Type: application/json" \
      -d "{\\\"name\\\":\\\"Mouse\\\",\\\"category\\\":\\\"peripherals\\\",\\\"price\\\":\\\"39.90\\\"}"`
    product_id = JSON.parse(created.split(/\r?\n\r?\n/, 2).last)["product"]["id"]

    response = `curl -s -i \
      http://localhost:9292/products/#{product_id}`

    expect(response).to include("HTTP/1.1 200 OK")
    expect(response).to include('"name":"Mouse"')
  end

  # Lists the products with pagination (page and limit).
  it "lists products with pagination" do
    `curl -s -i \
      -X POST \
      http://localhost:9292/products \
      -H "Content-Type: application/json" \
      -d "{\\\"name\\\":\\\"Monitor\\\",\\\"category\\\":\\\"displays\\\",\\\"price\\\":\\\"900.00\\\"}"`

    response = `curl -s -i \
      "http://localhost:9292/products?page=1&limit=2"`

    expect(response).to include("HTTP/1.1 200 OK")
    expect(response).to include('"pagination":{"page":1,"limit":2')
  end

  # Filters the products by category. The category is unique, so exactly the
  # product created above matches.
  it "filters products by category" do
    category = "e2e-category-#{rand(1_000_000)}"

    `curl -s -i \
      -X POST \
      http://localhost:9292/products \
      -H "Content-Type: application/json" \
      -d "{\\\"name\\\":\\\"Cable\\\",\\\"category\\\":\\\"#{category}\\\",\\\"price\\\":\\\"10.00\\\"}"`

    response = `curl -s -i \
      "http://localhost:9292/products?category=#{category}"`

    expect(response).to include("HTTP/1.1 200 OK")
    expect(response).to include("\"category\":\"#{category}\"")
    expect(response).to include('"total":1')
  end

  # Filters the products by price range (min_price and max_price).
  it "filters products by price range" do
    `curl -s -i \
      -X POST \
      http://localhost:9292/products \
      -H "Content-Type: application/json" \
      -d "{\\\"name\\\":\\\"Headset\\\",\\\"category\\\":\\\"audio\\\",\\\"price\\\":\\\"250.00\\\"}"`

    response = `curl -s -i \
      "http://localhost:9292/products?min_price=200&max_price=300"`

    expect(response).to include("HTTP/1.1 200 OK")
    expect(response).to include('"name":"Headset"')
  end

  # Sorts the products by price, descending (the "-" prefix).
  it "sorts products by price" do
    `curl -s -i \
      -X POST \
      http://localhost:9292/products \
      -H "Content-Type: application/json" \
      -d "{\\\"name\\\":\\\"Laptop\\\",\\\"category\\\":\\\"computers\\\",\\\"price\\\":\\\"3500.00\\\"}"`

    response = `curl -s -i \
      "http://localhost:9292/products?sort=-price"`

    expect(response).to include("HTTP/1.1 200 OK")
    expect(response).to include('"name":"Laptop"')
  end

  # Partially updates a product with PATCH: only the sent field changes.
  it "partially updates a product" do
    created = `curl -s -i \
      -X POST \
      http://localhost:9292/products \
      -H "Content-Type: application/json" \
      -d "{\\\"name\\\":\\\"Webcam\\\",\\\"category\\\":\\\"video\\\",\\\"price\\\":\\\"180.00\\\"}"`
    product_id = JSON.parse(created.split(/\r?\n\r?\n/, 2).last)["product"]["id"]

    response = `curl -s -i \
      -X PATCH \
      http://localhost:9292/products/#{product_id} \
      -H "Content-Type: application/json" \
      -d "{\\\"price\\\":\\\"149.90\\\"}"`

    expect(response).to include("HTTP/1.1 200 OK")
    expect(response).to include('"price":"149.9"')
  end

  # A product that does not exist: 404 not found.
  it "returns 404 for a product that does not exist" do
    response = `curl -s -i \
      http://localhost:9292/products/999999`

    expect(response).to include("HTTP/1.1 404 Not Found")
    expect(response).to include('"error":"Product not found"')
  end

  # A negative price is refused by the model: 400 bad request.
  it "rejects a product with a negative price" do
    response = `curl -s -i \
      -X POST \
      http://localhost:9292/products \
      -H "Content-Type: application/json" \
      -d "{\\\"name\\\":\\\"Broken\\\",\\\"category\\\":\\\"misc\\\",\\\"price\\\":\\\"-1\\\"}"`

    expect(response).to include("HTTP/1.1 400 Bad Request")
    expect(response).to include('"error":"Validation failed"')
  end
end
