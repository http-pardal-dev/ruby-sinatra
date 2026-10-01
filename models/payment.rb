# frozen_string_literal: true

require "active_record"

# Payment model of the educational server.
#
# The `payments` table is created by the migrations in db/migrate.
#
# Educational goal: lifecycle.
# Concepts: states, actions, transitions, headers and idempotency.
class Payment < ActiveRecord::Base
  # Possible states of a payment (lifecycle).
  STATUSES = %w[pending paid failed cancelled].freeze

  # Initial state of a newly created payment.
  DEFAULT_STATUS = "pending"

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }
end
