# frozen_string_literal: true

require "active_record"

# Payment model of the educational server.
#
# The `payments` table is created by the migrations in db/migrate.
#
# Educational goal: lifecycle.
# Planned concepts (to be implemented in later steps): states, actions,
# transitions, headers and idempotency.
#
# At this stage only the model structure and the list of states are prepared;
# there are no business rules, validations or transitions yet.
class Payment < ActiveRecord::Base
  # Possible states of a payment (lifecycle).
  STATUSES = %w[pending confirmed cancelled].freeze

  # Initial state of a newly created payment.
  DEFAULT_STATUS = "pending"
end
