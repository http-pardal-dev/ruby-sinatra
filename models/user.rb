# frozen_string_literal: true

require "active_record"

# User model of the educational server.
#
# The `users` table is created by the migrations in db/migrate.
#
# Educational goal: CRUD and HTTP fundamentals.
# Concepts: CRUD, route parameters, JSON, status codes,
# validation and persistence.
class User < ActiveRecord::Base
  # Roles a user can have.
  ROLES = %w[user admin].freeze

  # Longest email the server accepts: 254 characters, the longest address the
  # mail standards allow. Longer values are rejected before the database, even
  # though the column itself has no limit.
  MAX_EMAIL_LENGTH = 254

  # Passwords are stored as a digest (bcrypt). `password` and
  # `password_confirmation` are virtual attributes, never real columns.
  has_secure_password

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :email, presence: true,
                    length: { maximum: MAX_EMAIL_LENGTH },
                    format: { with: /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/ },
                    uniqueness: { case_sensitive: false }
  # allow_nil so an update does not need to send the password again.
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :role, inclusion: { in: ROLES }
  validates :birthdate, comparison: { less_than_or_equal_to: -> { Date.today } }, allow_nil: true
  validate :birthdate_must_be_a_real_date

  # Emails compare case-insensitively, so they are stored the way they are
  # compared: stripped and downcased. Without this, "Ada@Example.com" and
  # "ada@example.com" would look like different addresses until the
  # uniqueness validation rejected one of them.
  before_validation :normalize_email

  # Public representation of the user: an explicit allowlist, so a column
  # added later (or the password digest) is never exposed by accident.
  PUBLIC_ATTRIBUTES = %w[id name email role active birthdate created_at updated_at].freeze

  def as_json(options = nil)
    super((options || {}).merge(only: PUBLIC_ATTRIBUTES))
  end

  # Assigns the birthdate keeping the raw value when it is not a real date.
  # ActiveRecord casts date columns on assignment, turning garbage into nil
  # silently; the validation below then sees the raw value and rejects it.
  def birthdate=(value)
    @raw_birthdate = value
    super
  end

  private

  def normalize_email
    self.email = email.strip.downcase if email.is_a?(String)
  end

  # Rejects birthdates that are not real dates ("not-a-date", "2000-13-40").
  # The comparison validation only runs on values that survived the cast, so
  # without this check an invalid string would pass as nil.
  def birthdate_must_be_a_real_date
    return if @raw_birthdate.nil? || @raw_birthdate == ""
    return if @raw_birthdate.is_a?(Date)
    return if birthdate.is_a?(Date) && @raw_birthdate == birthdate.iso8601

    errors.add(:birthdate, "must be a valid date in YYYY-MM-DD format")
  end
end
