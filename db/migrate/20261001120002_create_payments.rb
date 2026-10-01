# frozen_string_literal: true

# Creates the `payments` table, used by the Payments resource (lifecycle).
#
# The `status` column represents the payment state and starts as "pending".
# The possible states are also listed in Payment::STATUSES.
class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.decimal :amount, precision: 10, scale: 2
      t.string :status, null: false, default: "pending"

      t.timestamps
    end
  end
end
