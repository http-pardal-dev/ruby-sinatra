# frozen_string_literal: true

# Creates the `users` table, used by the Users resource (CRUD and fundamentals).
class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email

      t.timestamps
    end
  end
end
