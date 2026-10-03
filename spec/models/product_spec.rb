# frozen_string_literal: true

require_relative "../spec_helper"

# Baseline behavior of the Product model, before the validation hardening of
# the roadmap (§3).
RSpec.describe Product do
  def build_product(overrides = {})
    described_class.new({
      name: "Keyboard",
      category: "peripherals",
      price: "159.90"
    }.merge(overrides))
  end

  it "is valid with name, category and price" do
    expect(build_product).to be_valid
  end

  it "requires a name" do
    product = build_product(name: nil)

    expect(product).not_to be_valid
    expect(product.errors[:name]).not_to be_empty
  end

  it "requires a category" do
    product = build_product(category: nil)

    expect(product).not_to be_valid
    expect(product.errors[:category]).not_to be_empty
  end

  it "rejects a negative price" do
    product = build_product(price: "-1")

    expect(product).not_to be_valid
    expect(product.errors[:price]).not_to be_empty
  end

  it "accepts a zero price" do
    expect(build_product(price: "0")).to be_valid
  end

  it "rejects a price above the column capacity" do
    product = build_product(price: "100000000")

    expect(product).not_to be_valid
    expect(product.errors[:price]).not_to be_empty
  end

  it "accepts the highest storable price" do
    expect(build_product(price: "99999999.99")).to be_valid
  end

  it "exposes only the public attributes in JSON" do
    product = build_product
    product.save!

    expect(product.as_json.keys).to match_array(Product::PUBLIC_ATTRIBUTES)
  end
end
