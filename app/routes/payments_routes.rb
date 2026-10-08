# frozen_string_literal: true

# Routes for the Payments resource.
#
# Focus: lifecycle.
# Concepts: states, actions, transitions, headers and idempotency.
#
# A payment starts as "pending" and moves to "paid" or "cancelled".
# The actions are sub-resources (`POST /payments/:id/confirm`), and the status
# code tells the client what happened: 200 ok, 201 created, 404 not found and
# 409 conflict (transition not allowed from the current state).
#
# The confirm and cancel actions are atomic: the current state is part of the
# UPDATE itself (see Payment.transition!), so of two concurrent transitions on
# the same payment, exactly one wins and the other answers 409.
#
# The actions are not idempotent: repeating a confirm (or a cancel) on a
# payment that already left "pending" answers 409, because the second request
# changes nothing and the client must know the first one already won. GET,
# PUT, PATCH and DELETE stay idempotent: repeating them leaves the resource in
# the same state.

class App < Sinatra::Base
  # POST /payments - creates a payment.
  post "/payments" do
    payment = persist_or_halt(Payment.new(restrict_attributes(json_body, PAYMENT_CREATE_ATTRIBUTES)))
    payment.status = Payment::DEFAULT_STATUS
    persist_or_halt(payment)

    # Location points to the resource created by this request.
    headers "Location" => "/payments/#{payment.id}"
    json({ payment: payment }, 201)
  end

  # GET /payments - lists payments, optionally filtered by state.
  #   - GET /payments?status=... -> filter by state
  get "/payments" do
    payments = Payment.all
    status = inclusion_param(params[:status], "status", Payment::STATUSES)
    payments = payments.where(status: status) if status

    json(payments: payments)
  end

  # GET /payments/:id - finds a payment by id.
  get "/payments/:id" do
    payment = find_or_404(Payment, params[:id])

    json(payment: payment)
  end

  # POST /payments/:id/confirm - confirms a payment (pending -> paid).
  post "/payments/:id/confirm" do
    payment = find_or_404(Payment, params[:id])

    # Only a "pending" payment can be confirmed; any other state is a
    # conflict. The transition is atomic (see Payment.transition!), so a
    # concurrent cancel cannot slip in between.
    unless Payment.transition!(payment.id, to: "paid")
      halt 409, { error: "A payment with status #{payment.reload.status} cannot be confirmed" }.to_json
    end

    json(payment: payment.reload)
  end

  # POST /payments/:id/cancel - cancels a payment.
  post "/payments/:id/cancel" do
    payment = find_or_404(Payment, params[:id])

    # Only a "pending" payment can be cancelled; any other state is a
    # conflict. The transition is atomic (see Payment.transition!), so a
    # concurrent confirm cannot slip in between.
    unless Payment.transition!(payment.id, to: "cancelled")
      halt 409, { error: "A payment with status #{payment.reload.status} cannot be cancelled" }.to_json
    end

    json(payment: payment.reload)
  end
end
