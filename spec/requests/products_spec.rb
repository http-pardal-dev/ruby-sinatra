# frozen_string_literal: true

require_relative "../spec_helper"

# Baseline behavior of the Products routes, before the input hardening of the
# roadmap (§3).
RSpec.describe "Products requests", type: :request do
  def product_body(overrides = {})
    {
      "name" => "Keyboard",
      "category" => "peripherals",
      "price" => "159.90"
    }.merge(overrides)
  end

  def create_product(overrides = {})
    post_json "/products", product_body(overrides)
    expect(last_response.status).to eq(201)
    json_response["product"]
  end

  it "POST /products creates a product with 201 and a Location header" do
    post_json "/products", product_body

    expect(last_response.status).to eq(201)
    expect(last_response.headers["Location"]).to match(%r{\A/products/\d+\z})
    expect(json_response["product"]["name"]).to eq("Keyboard")
  end

  it "GET /products/:id finds a product by id" do
    product = create_product

    get "/products/#{product["id"]}"

    expect(last_response.status).to eq(200)
    expect(json_response["product"]["name"]).to eq("Keyboard")
  end

  it "GET /products paginates the list" do
    create_product

    get "/products?page=1&limit=2"

    expect(last_response.status).to eq(200)
    expect(json_response["pagination"]).to include("page" => 1, "limit" => 2)
  end

  it "GET /products filters by category" do
    create_product("category" => "e2e-category")

    get "/products?category=e2e-category"

    expect(last_response.status).to eq(200)
    expect(json_response["pagination"]["total"]).to eq(1)
  end

  it "GET /products sorts by price descending" do
    create_product("name" => "Laptop", "price" => "3500.00")

    get "/products?sort=-price"

    expect(last_response.status).to eq(200)
    expect(json_response["products"].first["name"]).to eq("Laptop")
  end

  it "PATCH /products/:id partially updates a product" do
    product = create_product

    patch_json "/products/#{product["id"]}", { "price" => "149.90" }

    expect(last_response.status).to eq(200)
    expect(json_response["product"]["price"]).to eq("149.9")
  end

  it "GET /products/:id returns 404 for a product that does not exist" do
    get "/products/999999"

    expect(last_response.status).to eq(404)
    expect(json_response["error"]).to eq("Product not found")
  end

  it "POST /products returns 400 for a negative price" do
    post_json "/products", product_body("price" => "-1")

    expect(last_response.status).to eq(400)
    expect(json_response["error"]).to eq("Validation failed")
  end
end
