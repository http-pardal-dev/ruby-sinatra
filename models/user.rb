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

  # Passwords are stored as a digest (bcrypt). `password` and
  # `password_confirmation` are virtual attributes, never real columns.
  has_secure_password

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :email, presence: true,
                    format: { with: /\A[^@\s]+@[^@\s]+\z/ },
                    uniqueness: { case_sensitive: false }
  # allow_nil so an update does not need to send the password again.
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :role, inclusion: { in: ROLES }
  validates :birthdate, comparison: { less_than_or_equal_to: -> { Date.today } }, allow_nil: true

  # The digest must never leave the server, so it is removed from every JSON
  # representation of the user.
  def as_json(options = nil)
    super((options || {}).merge(except: [:password_digest]))
  end
end
