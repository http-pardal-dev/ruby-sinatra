# frozen_string_literal: true

# Routes for the Products resource.
#
# Educational goal: queries.
# Planned concepts: query parameters, filters, sorting, pagination and
# partial update.
#
# At this stage only the route structure is prepared: the blocks are
# empty and the behavior will be implemented in later steps.

class App < Sinatra::Base
  # GET /products - lists products.
  #
  # Same route, different concepts depending on the query parameters:
  #   - GET /products                              -> listing
  #   - GET /products?category=...                 -> filter by category
  #   - GET /products?min_price=...&max_price=...  -> filter by price range
  #   - GET /products?sort=...                     -> sorting
  #   - GET /products?page=...&limit=...           -> pagination
  get "/products" do
    # TODO: interpret the query parameters and return the list (200).
  end

  # GET /products/:id - finds a product by id.
  get "/products/:id" do
    # TODO: return the product (200) or 404 when it does not exist.
  end

  # POST /products - creates a product.
  post "/products" do
    # TODO: create the product from the JSON body (201).
  end

  # PATCH /products/:id - partially updates a product.
  patch "/products/:id" do
    # TODO: partially update the product or 404 when it does not exist.
  end
end
