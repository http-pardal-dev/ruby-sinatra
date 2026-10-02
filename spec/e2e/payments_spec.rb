# frozen_string_literal: true

# E2E: Payments (lifecycle).
#
# Every example sends its own requests with `curl` to a real server started by
# spec/support/e2e_server.rb. The whole command is written out in each example
# on purpose: the method, the URL, the headers and the body stay visible, with
# no helper hiding how the request is built.
#
# `\\\"` is the Ruby escaping for the `\"` curl needs around a JSON value, so
# the command reaches curl exactly as it would be typed in a terminal. `-s`
# only silences curl's progress meter; `-i` keeps the status line and the
# headers, which are part of the lesson.
RSpec.describe "Payments (lifecycle)", type: :e2e do
  # Creates a payment; a new payment always starts as "pending".
  it "creates a payment" do
    response = `curl -s -i \
      -X POST \
      http://localhost:9292/payments \
      -H "Content-Type: application/json" \
      -d "{\\\"amount\\\":\\\"99.90\\\"}"`

    expect(response).to include("HTTP/1.1 201 Created")
    expect(response.downcase).to include("location: /payments/")
    expect(response).to include('"status":"pending"')
  end

  # Finds the payment created by the request above.
  it "finds a payment by id" do
    created = `curl -s -i \
      -X POST \
      http://localhost:9292/payments \
      -H "Content-Type: application/json" \
      -d "{\\\"amount\\\":\\\"123.45\\\"}"`
    payment_id = JSON.parse(created.split(/\r?\n\r?\n/, 2).last)["payment"]["id"]

    response = `curl -s -i \
      http://localhost:9292/payments/#{payment_id}`

    expect(response).to include("HTTP/1.1 200 OK")
    expect(response).to include('"amount":"123.45"')
  end

  # Confirms a payment: the action moves it from "pending" to "paid".
  it "confirms a payment" do
    created = `curl -s -i \
      -X POST \
      http://localhost:9292/payments \
      -H "Content-Type: application/json" \
      -d "{\\\"amount\\\":\\\"99.90\\\"}"`
    payment_id = JSON.parse(created.split(/\r?\n\r?\n/, 2).last)["payment"]["id"]

    response = `curl -s -i \
      -X POST \
      http://localhost:9292/payments/#{payment_id}/confirm`

    expect(response).to include("HTTP/1.1 200 OK")
    expect(response).to include('"status":"paid"')
  end

  # Cancels a payment: the action moves it from "pending" to "cancelled".
  it "cancels a payment" do
    created = `curl -s -i \
      -X POST \
      http://localhost:9292/payments \
      -H "Content-Type: application/json" \
      -d "{\\\"amount\\\":\\\"50.00\\\"}"`
    payment_id = JSON.parse(created.split(/\r?\n\r?\n/, 2).last)["payment"]["id"]

    response = `curl -s -i \
      -X POST \
      http://localhost:9292/payments/#{payment_id}/cancel`

    expect(response).to include("HTTP/1.1 200 OK")
    expect(response).to include('"status":"cancelled"')
  end

  # A payment that is not "pending" cannot be confirmed again: 409 conflict.
  it "refuses to confirm a payment that is not pending" do
    created = `curl -s -i \
      -X POST \
      http://localhost:9292/payments \
      -H "Content-Type: application/json" \
      -d "{\\\"amount\\\":\\\"99.90\\\"}"`
    payment_id = JSON.parse(created.split(/\r?\n\r?\n/, 2).last)["payment"]["id"]

    `curl -s -i \
      -X POST \
      http://localhost:9292/payments/#{payment_id}/confirm`

    response = `curl -s -i \
      -X POST \
      http://localhost:9292/payments/#{payment_id}/confirm`

    expect(response).to include("HTTP/1.1 409 Conflict")
  end

  # A payment that is not "pending" cannot be cancelled again: 409 conflict.
  it "refuses to cancel a payment that is not pending" do
    created = `curl -s -i \
      -X POST \
      http://localhost:9292/payments \
      -H "Content-Type: application/json" \
      -d "{\\\"amount\\\":\\\"99.90\\\"}"`
    payment_id = JSON.parse(created.split(/\r?\n\r?\n/, 2).last)["payment"]["id"]

    `curl -s -i \
      -X POST \
      http://localhost:9292/payments/#{payment_id}/cancel`

    response = `curl -s -i \
      -X POST \
      http://localhost:9292/payments/#{payment_id}/cancel`

    expect(response).to include("HTTP/1.1 409 Conflict")
  end

  # A payment that does not exist: 404 not found.
  it "returns 404 for a payment that does not exist" do
    response = `curl -s -i \
      http://localhost:9292/payments/999999`

    expect(response).to include("HTTP/1.1 404 Not Found")
    expect(response).to include('"error":"Payment not found"')
  end

  # An invalid amount is refused by the model: 400 bad request.
  it "rejects a payment with an invalid amount" do
    response = `curl -s -i \
      -X POST \
      http://localhost:9292/payments \
      -H "Content-Type: application/json" \
      -d "{\\\"amount\\\":\\\"0\\\"}"`

    expect(response).to include("HTTP/1.1 400 Bad Request")
    expect(response).to include('"error":"Validation failed"')
  end

  # Lists the payments filtered by state through a query parameter.
  it "lists payments filtered by status" do
    created = `curl -s -i \
      -X POST \
      http://localhost:9292/payments \
      -H "Content-Type: application/json" \
      -d "{\\\"amount\\\":\\\"77.77\\\"}"`
    payment_id = JSON.parse(created.split(/\r?\n\r?\n/, 2).last)["payment"]["id"]

    response = `curl -s -i \
      "http://localhost:9292/payments?status=pending"`

    expect(response).to include("HTTP/1.1 200 OK")
    expect(response).to include("\"id\":#{payment_id}")
    expect(response).to include('"status":"pending"')
  end
end
