# frozen_string_literal: true

# Creates the `products` table, used by the Products resource (queries).
#
# Columns chosen for the planned concepts:
#   - category          -> filter by category (?category=...)
#   - price             -> filter by range and sorting (?min_price, ?max_price, ?sort=...)
#   - name/description  -> partial update (PATCH)
class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name
      t.text :description
      t.string :category
      t.decimal :price, precision: 10, scale: 2

      t.timestamps
    end
  end
end
