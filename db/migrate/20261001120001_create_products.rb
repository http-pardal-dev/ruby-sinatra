# frozen_string_literal: true

# Creates the `products` table, used by the Products resource (queries).
#
# Rules enforced by the Product model:
#   - name: 2-100 chars
#   - description: optional, max 1000 chars
#   - category: 2-50 chars
#   - price: greater than or equal to 0
class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.text :description
      t.string :category, null: false
      t.decimal :price, precision: 10, scale: 2, null: false

      t.timestamps
    end
  end
end
