# frozen_string_literal: true

require "active_record"

# Payment model of the educational server.
#
# The `payments` table is created by the migrations in db/migrate.
#
# Educational goal: lifecycle.
# Concepts: states, actions, transitions, headers and idempotency.
class Payment < ActiveRecord::Base
  # States a payment can be in. A payment is created `pending` and moves to
  # `paid` (confirm) or `cancelled` (cancel); there is no other transition.
  STATUSES = %w[pending paid cancelled].freeze

  # Initial state of a newly created payment.
  DEFAULT_STATUS = "pending"

  # Highest amount the server accepts: the `amount` column is a decimal(10, 2),
  # so 99_999_999.99 is the largest value it can store. Larger values are
  # rejected before the database, where they would overflow the column.
  MAX_AMOUNT = BigDecimal("99999999.99")

  validates :amount, presence: true,
                     numericality: { greater_than: 0, less_than_or_equal_to: MAX_AMOUNT }
  validates :status, inclusion: { in: STATUSES }

  # Public representation of the payment: an explicit allowlist, so a column
  # added later is never exposed by accident.
  PUBLIC_ATTRIBUTES = %w[id amount status created_at updated_at].freeze

  def as_json(options = nil)
    super((options || {}).merge(only: PUBLIC_ATTRIBUTES))
  end

  # Moves the payment to `to`, but only when its current state is `from`.
  # The state is part of the UPDATE itself, so the check and the change are a
  # single atomic statement: of two concurrent transitions on the same
  # payment, exactly one matches the row and wins, and the other changes
  # nothing. Returns true when this call performed the transition.
  def self.transition!(id, to:, from: DEFAULT_STATUS)
    updated = where(id: id, status: from).update_all(status: to, updated_at: Time.now.utc)

    updated == 1
  end
end
