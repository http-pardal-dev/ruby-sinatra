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
end
