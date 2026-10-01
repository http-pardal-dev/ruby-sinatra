# frozen_string_literal: true

# Routes for the Products resource.
#
# Educational goal: queries.
# Concepts: query parameters, filters, sorting, pagination and partial update.
#
# Everything sent in the query string is read from `params`.

class App < Sinatra::Base
  # GET /products - lists products.
  #
  # Query parameters:
  #   - category=...                  -> filter by category
  #   - min_price=...&max_price=...   -> filter by price range
  #   - sort=name|price (prefix "-")  -> sorting ("-" means descending)
  #   - page=...&limit=...            -> pagination
  get "/products" do
    products = Product.all

    # Filters.
    products = products.where(category: params[:category]) if params[:category]
    products = products.where(price: params[:min_price]..) if params[:min_price]
    products = products.where(price: ..params[:max_price]) if params[:max_price]

    # Sorting: a leading "-" means descending order. Unknown columns are
    # ignored, so the column name can never reach the query unchecked.
    sort = params[:sort] || "id"
    direction = sort.start_with?("-") ? :desc : :asc
    column = sort.delete_prefix("-")
    products = products.order(column => direction) if Product.column_names.include?(column)

    # Pagination: page is 1-based and both values are at least 1.
    page = [params.fetch(:page, 1).to_i, 1].max
    limit = [params.fetch(:limit, 10).to_i, 1].max
    total = products.count

    data = {
      products: products.offset((page - 1) * limit).limit(limit),
      pagination: { page: page, limit: limit, total: total }
    }
    json(data)
  end

  # GET /products/:id - finds a product by id.
  get "/products/:id" do
    product = Product.find_by(id: params[:id])
    halt 404, { error: "Product not found" }.to_json if product.nil?

    json(product: product)
  end

  # POST /products - creates a product.
  post "/products" do
    product = Product.new(json_body)
    unless product.save
      halt 400, { error: "Validation failed", messages: product.errors.full_messages }.to_json
    end

    # Location points to the resource created by this request.
    headers "Location" => "/products/#{product.id}"
    json({ product: product }, 201)
  end

  # PATCH /products/:id - partially updates a product.
  #
  # Only the sent attributes change, so the update does not need every field.
  patch "/products/:id" do
    product = Product.find_by(id: params[:id])
    halt 404, { error: "Product not found" }.to_json if product.nil?

    unless product.update(json_body)
      halt 400, { error: "Validation failed", messages: product.errors.full_messages }.to_json
    end

    json(product: product)
  end
end
