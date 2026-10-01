# frozen_string_literal: true

# Routes for the Users resource.
#
# Educational goal: CRUD and HTTP fundamentals.
# Concepts: CRUD, route parameters, JSON, status codes,
# validation and persistence.
#
# The route parameter is read from `params[:id]`, the request body from the
# `json_body` helper and the response is written with the `json` helper.
# Status codes: 200 ok, 201 created, 204 no content, 400 bad request,
# 404 not found.

class App < Sinatra::Base
  # GET /users - lists all users.
  get "/users" do
    json(users: User.all)
  end

  # GET /users/:id - finds a user by id.
  get "/users/:id" do
    user = User.find_by(id: params[:id])
    halt 404, { error: "User not found" }.to_json if user.nil?

    json(user: user)
  end

  # POST /users - creates a user.
  post "/users" do
    user = User.new(json_body)

    # The model validations (name and email presence, unique email) decide if
    # the request is accepted: 201 when valid, 400 with the messages otherwise.
    unless user.save
      halt 400, { error: "Validation failed", messages: user.errors.full_messages }.to_json
    end

    # Location points to the resource created by this request.
    headers "Location" => "/users/#{user.id}"
    json({ user: user }, 201)
  end

  # PUT /users/:id - updates a user.
  #
  # Note: ActiveRecord merges the attributes that are sent, so PUT and PATCH
  # behave the same here. Making PUT a full replacement (clearing the
  # attributes that are not sent) is a separate lesson.
  put "/users/:id" do
    user = User.find_by(id: params[:id])
    halt 404, { error: "User not found" }.to_json if user.nil?

    user.assign_attributes(json_body)
    unless user.save
      halt 400, { error: "Validation failed", messages: user.errors.full_messages }.to_json
    end

    json(user: user)
  end

  # PATCH /users/:id - partially updates a user.
  #
  # Only the sent attributes change, so the update does not need every field.
  patch "/users/:id" do
    user = User.find_by(id: params[:id])
    halt 404, { error: "User not found" }.to_json if user.nil?

    user.assign_attributes(json_body)
    unless user.save
      halt 400, { error: "Validation failed", messages: user.errors.full_messages }.to_json
    end

    json(user: user)
  end

  # DELETE /users/:id - removes a user.
  delete "/users/:id" do
    user = User.find_by(id: params[:id])
    halt 404, { error: "User not found" }.to_json if user.nil?

    user.destroy
    halt 204
  end
end
