# frozen_string_literal: true

require "active_record"

require_relative "initializers/database"
require_relative "initializers/migrations"

# Startup initializers.
#
# The mistakes that reach a local server are ordinary ones: a typo in APP_ENV, a
# database that was never created, a migration file that was added and never
# run. Each of them used to surface much later, as an error in the middle of the
# first request (or as a confusing stack trace from deep inside ActiveRecord).
# Here they stop the boot with a message that says what to do.
#
# This file only loads them. Each one carries its own error and its own reason,
# and config/environment.rb calls them one by one, in the order a broken
# environment is reported: without a database the migrations cannot be read
# either, so the database comes first.
