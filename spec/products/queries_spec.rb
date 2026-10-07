# frozen_string_literal: true

require_relative "../spec_helper"

# Baseline behavior of the Products routes.
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

  it "GET /products/:id returns 400 for an id that is not a positive integer" do
    get "/products/abc"

    expect(last_response.status).to eq(400)
    expect(json_response["error"]).to eq("Invalid id")
  end

  it "POST /products returns 400 for a negative price" do
    post_json "/products", product_body("price" => "-1")

    expect(last_response.status).to eq(400)
    expect(json_response["error"]).to eq("Validation failed")
  end

  it "GET /products returns 400 for a non-numeric page" do
    get "/products?page=abc"

    expect(last_response.status).to eq(400)
    expect(json_response["error"]).to eq("Invalid parameter")
    expect(json_response["messages"].first).to include("page")
  end

  it "GET /products returns 400 for a zero limit" do
    get "/products?limit=0"

    expect(last_response.status).to eq(400)
    expect(json_response["error"]).to eq("Invalid parameter")
    expect(json_response["messages"].first).to include("limit")
  end

  it "GET /products returns 400 for a limit above the maximum" do
    get "/products?limit=101"

    expect(last_response.status).to eq(400)
    expect(json_response["error"]).to eq("Invalid parameter")
    expect(json_response["messages"].first).to include("limit")
  end

  it "GET /products returns 400 for an array page" do
    get "/products?page[]=1"

    expect(last_response.status).to eq(400)
    expect(json_response["error"]).to eq("Invalid parameter")
  end

  it "GET /products returns 400 for an unknown sort column" do
    get "/products?sort=hack"

    expect(last_response.status).to eq(400)
    expect(json_response["error"]).to eq("Invalid parameter")
    expect(json_response["messages"].first).to include("sort")
  end

  it "GET /products returns 400 for a non-numeric min_price" do
    get "/products?min_price=cheap"

    expect(last_response.status).to eq(400)
    expect(json_response["error"]).to eq("Invalid parameter")
    expect(json_response["messages"].first).to include("min_price")
  end

  it "GET /products keeps pages stable with the id tiebreak" do
    create_product("name" => "Same Price A", "price" => "10.00")
    create_product("name" => "Same Price B", "price" => "10.00")

    get "/products?sort=price&limit=1&page=1"
    first_page = json_response["products"].map { |item| item["id"] }
    get "/products?sort=price&limit=1&page=2"
    second_page = json_response["products"].map { |item| item["id"] }

    expect(first_page & second_page).to be_empty
    expect((first_page + second_page).sort).to eq(Product.order(:id).limit(2).pluck(:id))
  end

  it_behaves_like "a hardened JSON endpoint" do
    let(:path) { "/products" }
    let(:valid_body) { product_body }

    def request(body)
      post_json "/products", body
    end
  end
end
