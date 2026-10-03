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

  it "starts as pending by default" do
    expect(described_class::DEFAULT_STATUS).to eq("pending")
  end
end
