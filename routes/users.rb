# frozen_string_literal: true

# Routes for the Users resource.
#
# Educational goal: CRUD and HTTP fundamentals.
# Planned concepts: CRUD, route parameters, JSON, status codes,
# validation and persistence.
#
# At this stage only the route structure is prepared: the blocks are
# empty and the behavior will be implemented in later steps.

class App < Sinatra::Base
  # GET /users - lists all users.
  get "/users" do
    # TODO: return the list of users (200).
  end

  # GET /users/:id - finds a user by id.
  get "/users/:id" do
    # TODO: return the user (200) or 404 when it does not exist.
  end

  # POST /users - creates a user.
  post "/users" do
    # TODO: create the user from the JSON body (201).
  end

  # PUT /users/:id - fully updates a user.
  put "/users/:id" do
    # TODO: replace the user or 404 when it does not exist.
  end

  # PATCH /users/:id - partially updates a user.
  patch "/users/:id" do
    # TODO: partially update the user or 404 when it does not exist.
  end

  # DELETE /users/:id - removes a user.
  delete "/users/:id" do
    # TODO: remove the user or 404 when it does not exist.
  end
end
