# frozen_string_literal: true

# Creates the `users` table, used by the Users resource (CRUD and fundamentals).
#
# Rules enforced by the User model:
#   - name: 2-100 chars
#   - email: valid, unique (also protected by the unique index below)
#   - password: minimum 8 chars (stored as a bcrypt digest)
#   - role: user or admin
#   - birthdate: cannot be in the future
class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :role, null: false, default: "user"
      t.boolean :active, null: false, default: true
      t.date :birthdate

      t.timestamps
    end

    # The email identifies the user, so the database also refuses duplicates.
    add_index :users, :email, unique: true
  end
end
