# frozen_string_literal: true

require "active_record"

# Product model of the educational server.
#
# The `products` table is created by the migrations in db/migrate.
#
# Educational goal: queries.
# Concepts: query parameters, filters, sorting, pagination and partial update.
class Product < ActiveRecord::Base
  # Highest price the server accepts: the `price` column is a decimal(10, 2),
  # so 99_999_999.99 is the largest value it can store. Larger values are
  # rejected before the database, where they would overflow the column.
  MAX_PRICE = BigDecimal("99999999.99")

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :description, length: { maximum: 1000 }, allow_nil: true
  validates :category, presence: true, length: { minimum: 2, maximum: 50 }
  validates :price, presence: true,
                    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: MAX_PRICE }

  # Public representation of the product: an explicit allowlist, so a column
  # added later is never exposed by accident.
  PUBLIC_ATTRIBUTES = %w[id name description category price created_at updated_at].freeze

  def as_json(options = nil)
    super((options || {}).merge(only: PUBLIC_ATTRIBUTES))
  end
end
