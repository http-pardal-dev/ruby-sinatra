# frozen_string_literal: true

require_relative "../spec_helper"

# Baseline behavior of the User model, before the validation hardening of the
# roadmap (§3). These specs document what the model accepts today so the
# hardening changes stay visible, one spec at a time.
RSpec.describe User do
  # Builds the smallest valid user: name, email and password decide validity,
  # and the remaining attributes fall back to their defaults.
  def build_user(overrides = {})
    described_class.new({
      name: "Ada Lovelace",
      email: "ada@example.com",
      password: "secret123"
    }.merge(overrides))
  end

  it "is valid with name, email and password" do
    expect(build_user).to be_valid
  end

  it "requires a name" do
    user = build_user(name: nil)

    expect(user).not_to be_valid
    expect(user.errors[:name]).not_to be_empty
  end

  it "requires an email" do
    user = build_user(email: nil)

    expect(user).not_to be_valid
    expect(user.errors[:email]).not_to be_empty
  end

  it "rejects a duplicated email" do
    build_user.save!
    duplicated = build_user(name: "Grace Hopper")

    expect(duplicated).not_to be_valid
    expect(duplicated.errors[:email]).not_to be_empty
  end

  it "rejects a short password" do
    user = build_user(password: "short")

    expect(user).not_to be_valid
    expect(user.errors[:password]).not_to be_empty
  end

  it "never exposes the password digest in JSON" do
    user = build_user
    user.save!

    expect(user.as_json.keys).not_to include("password_digest")
  end
end
