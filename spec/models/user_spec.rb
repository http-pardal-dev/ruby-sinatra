# frozen_string_literal: true

require_relative "../spec_helper"

# Baseline behavior of the User model. These specs document what the model
# accepts, so a change that tightens a rule has to show itself here first.
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

  it "stores the email stripped and downcased" do
    user = build_user(email: "  Ada@Example.COM  ")
    user.save!

    expect(user.reload.email).to eq("ada@example.com")
  end

  it "rejects an email longer than 254 characters" do
    user = build_user(email: "#{"a" * 250}@x.com")

    expect(user).not_to be_valid
    expect(user.errors[:email]).not_to be_empty
  end

  it "rejects an email without a domain dot" do
    user = build_user(email: "ada@localhost")

    expect(user).not_to be_valid
    expect(user.errors[:email]).not_to be_empty
  end

  it "rejects a short password" do
    user = build_user(password: "short")

    expect(user).not_to be_valid
    expect(user.errors[:password]).not_to be_empty
  end

  it "rejects a birthdate that is not a real date" do
    user = build_user(birthdate: "not-a-date")

    expect(user).not_to be_valid
    expect(user.errors[:birthdate]).not_to be_empty
  end

  it "rejects an impossible birthdate" do
    user = build_user(birthdate: "2000-13-40")

    expect(user).not_to be_valid
    expect(user.errors[:birthdate]).not_to be_empty
  end

  it "rejects a birthdate in the future" do
    user = build_user(birthdate: (Date.today + 1).iso8601)

    expect(user).not_to be_valid
    expect(user.errors[:birthdate]).not_to be_empty
  end

  it "accepts a valid birthdate" do
    expect(build_user(birthdate: "2000-01-01")).to be_valid
  end

  it "exposes only the public attributes in JSON" do
    user = build_user
    user.save!

    expect(user.as_json.keys).to match_array(User::PUBLIC_ATTRIBUTES)
  end

  it "never exposes the password digest in JSON" do
    user = build_user
    user.save!

    expect(user.as_json.keys).not_to include("password_digest")
  end
end
