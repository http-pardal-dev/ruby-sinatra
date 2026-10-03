# frozen_string_literal: true

require_relative "../spec_helper"

# Baseline behavior of the Payment model.
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
      expect(described_class.transition!(999_999, to: "paid")).to be(false)
    end

    # Two clients confirming the same payment. The state is part of the UPDATE,
    # so the second one matches no row and reports that it changed nothing -
    # which is what keeps one payment from being confirmed twice.
    it "lets only the first of two transitions on the same payment win" do
      payment = build_payment
      payment.save!

      first = described_class.transition!(payment.id, to: "paid")
      second = described_class.transition!(payment.id, to: "paid")

      expect([first, second]).to eq([true, false])
      expect(payment.reload.status).to eq("paid")
    end

    # A confirm and a cancel arriving together: the payment leaves "pending"
    # once, so only one of the two can hold.
    it "lets only one of a confirm and a cancel on the same payment win" do
      payment = build_payment
      payment.save!

      confirm = described_class.transition!(payment.id, to: "paid")
      cancel = described_class.transition!(payment.id, to: "cancelled")

      expect([confirm, cancel].count(true)).to eq(1)
      expect(payment.reload.status).to be_in(%w[paid cancelled])
    end
  end
end
