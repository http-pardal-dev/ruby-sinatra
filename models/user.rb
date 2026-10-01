# frozen_string_literal: true

require "active_record"

# User model of the educational server.
#
# The `users` table is created by the migrations in db/migrate.
class User < ActiveRecord::Base
  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
end
