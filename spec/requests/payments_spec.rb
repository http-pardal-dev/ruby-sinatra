# frozen_string_literal: true

require_relative "../spec_helper"

# Baseline behavior of the Payments routes, before the transition hardening of
# the roadmap (§5).
RSpec.describe "Payments requests", type: :request do
  def create_payment(overrides = {})
    post_json "/payments", { "amount" => "99.90" }.merge(overrides)
    expect(last_response.status).to eq(201)
    json_response["payment"]
  end

  it "POST /payments creates a pending payment with 201 and a Location header" do
    post_json "/payments", { "amount" => "99.90" }

    expect(last_response.status).to eq(201)
    expect(last_response.headers["Location"]).to match(%r{\A/payments/\d+\z})
    expect(json_response["payment"]["status"]).to eq("pending")
  end

  it "GET /payments/:id finds a payment by id" do
    payment = create_payment("amount" => "123.45")

    get "/payments/#{payment["id"]}"

    expect(last_response.status).to eq(200)
    expect(json_response["payment"]["amount"]).to eq("123.45")
  end

  it "POST /payments/:id/confirm moves a pending payment to paid" do
    payment = create_payment

    post "/payments/#{payment["id"]}/confirm"

    expect(last_response.status).to eq(200)
    expect(json_response["payment"]["status"]).to eq("paid")
  end

  it "POST /payments/:id/cancel moves a pending payment to cancelled" do
    payment = create_payment

    post "/payments/#{payment["id"]}/cancel"

    expect(last_response.status).to eq(200)
    expect(json_response["payment"]["status"]).to eq("cancelled")
  end

  it "POST /payments/:id/confirm refuses a payment that is not pending" do
    payment = create_payment
    post "/payments/#{payment["id"]}/confirm"

    post "/payments/#{payment["id"]}/confirm"

    expect(last_response.status).to eq(409)
  end

  it "POST /payments/:id/cancel refuses a payment that is not pending" do
    payment = create_payment
    post "/payments/#{payment["id"]}/cancel"

    post "/payments/#{payment["id"]}/cancel"

    expect(last_response.status).to eq(409)
  end

  it "GET /payments/:id returns 404 for a payment that does not exist" do
    get "/payments/999999"

    expect(last_response.status).to eq(404)
    expect(json_response["error"]).to eq("Payment not found")
  end

  it "POST /payments returns 400 for a zero amount" do
    post_json "/payments", { "amount" => "0" }

    expect(last_response.status).to eq(400)
    expect(json_response["error"]).to eq("Validation failed")
  end

  it "GET /payments filters by status" do
    payment = create_payment

    get "/payments?status=pending"

    expect(last_response.status).to eq(200)
    expect(json_response["payments"].map { |item| item["id"] }).to include(payment["id"])
  end

  it "GET /payments returns 400 for an unknown status" do
    get "/payments?status=unknown"

    expect(last_response.status).to eq(400)
    expect(json_response["error"]).to eq("Invalid parameter")
    expect(json_response["messages"].first).to include("status")
  end

  it "POST /payments/:id/confirm refuses a cancelled payment with 409" do
    payment = create_payment
    post "/payments/#{payment["id"]}/cancel"

    post "/payments/#{payment["id"]}/confirm"

    expect(last_response.status).to eq(409)
    expect(json_response["error"]).to include("cancelled")
  end

  it "POST /payments/:id/cancel refuses a paid payment with 409" do
    payment = create_payment
    post "/payments/#{payment["id"]}/confirm"

    post "/payments/#{payment["id"]}/cancel"

    expect(last_response.status).to eq(409)
    expect(json_response["error"]).to include("paid")
  end

  it "lets exactly one of two concurrent transitions win" do
    payment_id = create_payment["id"]

    # Two requests race on the same pending payment: the conditional UPDATE
    # makes the database the judge, so one answers 200 and the other 409,
    # whatever the interleaving.
    sessions = Array.new(2) { Rack::Test::Session.new(Rack::MockSession.new(App)) }
    barrier = Queue.new
    results = sessions.map do |session|
      Thread.new do
        barrier.pop
        session.post "/payments/#{payment_id}/confirm"
        session.last_response.status
      end
    end
    2.times { barrier.push(true) }

    expect(results.map(&:value).sort).to eq([200, 409])
    expect(Payment.find(payment_id).status).to eq("paid")
  end

  it "lets exactly one of a concurrent confirm and cancel win" do
    payment_id = create_payment["id"]

    confirm = Rack::Test::Session.new(Rack::MockSession.new(App))
    cancel = Rack::Test::Session.new(Rack::MockSession.new(App))
    barrier = Queue.new
    confirm_thread = Thread.new do
      barrier.pop
      confirm.post "/payments/#{payment_id}/confirm"
      confirm.last_response.status
    end
    cancel_thread = Thread.new do
      barrier.pop
      cancel.post "/payments/#{payment_id}/cancel"
      cancel.last_response.status
    end
    2.times { barrier.push(true) }

    expect([confirm_thread.value, cancel_thread.value].sort).to eq([200, 409])
    expect(%w[paid cancelled]).to include(Payment.find(payment_id).status)
  end

  it_behaves_like "a hardened JSON endpoint" do
    let(:path) { "/payments" }
    let(:valid_body) { { "amount" => "99.90" } }

    def request(body)
      post_json "/payments", body
    end
  end
end
