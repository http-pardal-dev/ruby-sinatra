# frozen_string_literal: true

# Routes for the Products resource.
#
# Educational goal: queries.
# Concepts: query parameters, filters, sorting, pagination and partial update.
#
# Everything sent in the query string is read from `params` and validated
# with the helpers of helpers/params.rb: page and limit must be positive
# integers (limit at most MAX_LIMIT), sort must be a known column with an
# optional "-" prefix, and the filters must have the expected types. The
# request body is filtered with `restrict_attributes`, records are found with
# `find_or_404` and persisted with `persist_or_halt`.

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
    category = text_param(params[:category], "category", max_length: 50)
    products = products.where(category: category) if category
    min_price = decimal_param(params[:min_price], "min_price")
    products = products.where(price: min_price..) if min_price
    max_price = decimal_param(params[:max_price], "max_price")
    products = products.where(price: ..max_price) if max_price

    # Sorting: a leading "-" means descending order. The column comes from an
    # allowlist (PRODUCT_SORT_COLUMNS), and the id breaks ties, so pages are
    # stable: walking them never skips nor repeats a record.
    sorting = sort_param(params[:sort], PRODUCT_SORT_COLUMNS, default: { "id" => :asc })
    sorting["id"] = sorting.values.first unless sorting.key?("id")
    products = products.order(sorting)

    # Pagination: page is 1-based and both values are at least 1.
    page = integer_param(params[:page], "page", default: 1)
    limit = integer_param(params[:limit], "limit", default: 10, max: MAX_LIMIT)
    total = products.count

    data = {
      products: products.offset((page - 1) * limit).limit(limit),
      pagination: { page: page, limit: limit, total: total }
    }
    json(data)
  end

  # GET /products/:id - finds a product by id.
  get "/products/:id" do
    product = find_or_404(Product, params[:id])

    json(product: product)
  end

  # POST /products - creates a product.
  post "/products" do
    product = persist_or_halt(Product.new(restrict_attributes(json_body, PRODUCT_CREATE_ATTRIBUTES)))

    # Location points to the resource created by this request.
    headers "Location" => "/products/#{product.id}"
    json({ product: product }, 201)
  end

  # PATCH /products/:id - partially updates a product.
  #
  # Only the sent attributes change, so the update does not need every field.
  patch "/products/:id" do
    product = find_or_404(Product, params[:id])

    product.assign_attributes(restrict_attributes(json_body, PRODUCT_UPDATE_ATTRIBUTES))
    persist_or_halt(product)

    json(product: product)
  end
end
