# frozen_string_literal: true

# Routes for the Payments resource.
#
# Educational goal: lifecycle.
# Planned concepts: states, actions, transitions, headers and idempotency.
#
# At this stage only the route structure is prepared: the blocks are
# empty and the behavior will be implemented in later steps.

class App < Sinatra::Base
  # POST /payments - creates a payment.
  post "/payments" do
    # TODO: create the payment from the JSON body (201).
  end

  # GET /payments - lists payments, optionally filtered by state.
  #   - GET /payments?status=... -> filter by state
  get "/payments" do
    # TODO: interpret the status query parameter and return the list (200).
  end

  # GET /payments/:id - finds a payment by id.
  get "/payments/:id" do
    # TODO: return the payment (200) or 404 when it does not exist.
  end

  # POST /payments/:id/confirm - confirms a payment.
  post "/payments/:id/confirm" do
    # TODO: apply the transition to the confirmed state.
  end

  # POST /payments/:id/cancel - cancels a payment.
  post "/payments/:id/cancel" do
    # TODO: apply the transition to the cancelled state.
  end
end
