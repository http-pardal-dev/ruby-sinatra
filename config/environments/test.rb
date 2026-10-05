# frozen_string_literal: true

# Test environment settings.

# Silences the SQL queries executed by ActiveRecord.
ActiveRecord::Base.logger = nil

# Does not log HTTP requests during tests.
App.set :logging, false
