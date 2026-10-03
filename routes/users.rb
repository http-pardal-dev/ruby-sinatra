# frozen_string_literal: true

# Routes for the Users resource.
#
# Educational goal: CRUD and HTTP fundamentals.
# Concepts: CRUD, route parameters, JSON, status codes,
# validation and persistence.
#
# The request body is read with the `json_body` helper and filtered with
# `restrict_attributes`, so only the attributes of USER_CREATE_ATTRIBUTES (or
# USER_UPDATE_ATTRIBUTES) reach the model; anything else is a 400. Records are
# found with `find_or_404` and persisted with `persist_or_halt`.
# Status codes: 200 ok, 201 created, 204 no content, 400 bad request,
# 404 not found, 409 conflict.

class App < Sinatra::Base
  # GET /users - lists all users.
  get "/users" do
    json(users: User.all)
  end

  # GET /users/:id - finds a user by id.
  get "/users/:id" do
    user = find_or_404(User, params[:id])

    json(user: user)
  end

  # POST /users - creates a user.
  post "/users" do
    # The model validations (name, email, password, role, birthdate) decide if
    # the request is accepted: 201 when valid, 400 with the messages
    # otherwise, 409 when the email lost a uniqueness race.
    user = persist_or_halt(User.new(restrict_attributes(json_body, USER_CREATE_ATTRIBUTES)))

    # Location points to the resource created by this request.
    headers "Location" => "/users/#{user.id}"
    json({ user: user }, 201)
  end

  # PUT /users/:id - updates a user.
  #
  # PUT replaces the resource, so it requires every attribute the creation
  # requires: a missing name, email or role is a 400, while the password is
  # optional (an update never needs to send it again). Sending the whole
  # resource keeps PUT idempotent: repeating the same request leaves the
  # resource in the same state. For a change to a single attribute, use PATCH.
  put "/users/:id" do
    user = find_or_404(User, params[:id])
    attributes = restrict_attributes(json_body, USER_UPDATE_ATTRIBUTES)
    %w[name email role].each do |required|
      attributes[required] = nil unless attributes.key?(required)
    end

    user.assign_attributes(attributes)
    persist_or_halt(user)

    json(user: user)
  end

  # PATCH /users/:id - partially updates a user.
  #
  # Only the sent attributes change, so the update does not need every field.
  patch "/users/:id" do
    user = find_or_404(User, params[:id])

    user.assign_attributes(restrict_attributes(json_body, USER_UPDATE_ATTRIBUTES))
    persist_or_halt(user)

    json(user: user)
  end

  # DELETE /users/:id - removes a user.
  delete "/users/:id" do
    user = find_or_404(User, params[:id])

    user.destroy
    halt 204
  end
end
