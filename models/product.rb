# frozen_string_literal: true

require "active_record"

# Product model of the educational server.
#
# The `products` table is created by the migrations in db/migrate.
#
# Educational goal: queries.
# Planned concepts (to be implemented in later steps): query parameters,
# filters, sorting, pagination and partial update.
#
# At this stage only the model structure is prepared; there are no business
# rules or validations yet.
class Product < ActiveRecord::Base
end
