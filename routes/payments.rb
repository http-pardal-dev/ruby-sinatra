# frozen_string_literal: true

# Routes for the Payments resource.
#
# Educational goal: lifecycle.
# Concepts: states, actions, transitions, headers and idempotency.
#
# A payment starts as "pending" and moves to "confirmed" or "cancelled".
# The actions are sub-resources (`POST /payments/:id/confirm`), and the status
# code tells the client what happened: 200 ok, 201 created, 404 not found and
# 409 conflict (transition not allowed from the current state).

class App < Sinatra::Base
  # POST /payments - creates a payment.
  post "/payments" do
    payment = Payment.new(json_body)
    payment.status = Payment::DEFAULT_STATUS
    payment.save!

    # Location points to the resource created by this request.
    headers "Location" => "/payments/#{payment.id}"
    json({ payment: payment }, 201)
  end

  # GET /payments - lists payments, optionally filtered by state.
  #   - GET /payments?status=... -> filter by state
  get "/payments" do
    payments = Payment.all
    payments = payments.where(status: params[:status]) if params[:status]

    json(payments: payments)
  end

  # GET /payments/:id - finds a payment by id.
  get "/payments/:id" do
    payment = Payment.find_by(id: params[:id])
    halt 404, { error: "Payment not found" }.to_json if payment.nil?

    json(payment: payment)
  end

  # POST /payments/:id/confirm - confirms a payment.
  post "/payments/:id/confirm" do
    payment = Payment.find_by(id: params[:id])
    halt 404, { error: "Payment not found" }.to_json if payment.nil?

    # Only a "pending" payment can be confirmed; any other state is a conflict.
    unless payment.status == "pending"
      halt 409, { error: "A payment with status #{payment.status} cannot be confirmed" }.to_json
    end

    payment.update!(status: "confirmed")
    json(payment: payment)
  end

  # POST /payments/:id/cancel - cancels a payment.
  post "/payments/:id/cancel" do
    payment = Payment.find_by(id: params[:id])
    halt 404, { error: "Payment not found" }.to_json if payment.nil?

    # Only a "pending" payment can be cancelled; any other state is a conflict.
    unless payment.status == "pending"
      halt 409, { error: "A payment with status #{payment.status} cannot be cancelled" }.to_json
    end

    payment.update!(status: "cancelled")
    json(payment: payment)
  end
end
