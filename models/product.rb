# frozen_string_literal: true

require "active_record"

# Product model of the educational server.
#
# The `products` table is created by the migrations in db/migrate.
#
# Educational goal: queries.
# Concepts: query parameters, filters, sorting, pagination and partial update.
class Product < ActiveRecord::Base
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :description, length: { maximum: 1000 }, allow_nil: true
  validates :category, presence: true, length: { minimum: 2, maximum: 50 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
