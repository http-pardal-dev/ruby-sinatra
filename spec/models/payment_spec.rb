# frozen_string_literal: true

require_relative "../spec_helper"

# Baseline behavior of the Payment model, before the transition hardening of
# the roadmap (§5).
RSpec.describe Payment do
  def build_payment(overrides = {})
    described_class.new({ amount: "99.90" }.merge(overrides))
  end

  it "is valid with an amount" do
    expect(build_payment).to be_valid
  end

  it "rejects a zero amount" do
    payment = build_payment(amount: "0")

    expect(payment).not_to be_valid
    expect(payment.errors[:amount]).not_to be_empty
  end

  it "rejects a negative amount" do
    payment = build_payment(amount: "-5")

    expect(payment).not_to be_valid
    expect(payment.errors[:amount]).not_to be_empty
  end

  it "rejects an amount above the column capacity" do
    payment = build_payment(amount: "100000000")

    expect(payment).not_to be_valid
    expect(payment.errors[:amount]).not_to be_empty
  end

  it "accepts the highest storable amount" do
    expect(build_payment(amount: "99999999.99")).to be_valid
  end

  it "starts as pending by default" do
    expect(described_class::DEFAULT_STATUS).to eq("pending")
  end

  it "lists exactly the reachable states" do
    expect(described_class::STATUSES).to eq(%w[pending paid cancelled])
  end

  it "exposes only the public attributes in JSON" do
    payment = build_payment
    payment.save!

    expect(payment.as_json.keys).to match_array(Payment::PUBLIC_ATTRIBUTES)
  end

  describe ".transition!" do
    it "moves a pending payment to paid" do
      payment = build_payment
      payment.save!

      expect(described_class.transition!(payment.id, to: "paid")).to be(true)
      expect(payment.reload.status).to eq("paid")
    end

    it "moves a pending payment to cancelled" do
      payment = build_payment
      payment.save!

      expect(described_class.transition!(payment.id, to: "cancelled")).to be(true)
      expect(payment.reload.status).to eq("cancelled")
    end

    it "refuses to move a paid payment" do
      payment = build_payment
      payment.save!
      described_class.transition!(payment.id, to: "paid")

      expect(described_class.transition!(payment.id, to: "cancelled")).to be(false)
      expect(payment.reload.status).to eq("paid")
    end

    it "refuses to move a cancelled payment" do
      payment = build_payment
      payment.save!
      described_class.transition!(payment.id, to: "cancelled")

      expect(described_class.transition!(payment.id, to: "paid")).to be(false)
      expect(payment.reload.status).to eq("cancelled")
    end

    it "returns false for a payment that does not exist" do
      expect(described_class.transition!(999999, to: "paid")).to be(false)
    end
  end
end
