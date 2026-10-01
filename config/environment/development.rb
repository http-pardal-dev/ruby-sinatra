# frozen_string_literal: true

# Development environment settings.

require "logger"

# Prints the SQL queries executed by ActiveRecord to the terminal.
ActiveRecord::Base.logger = Logger.new($stdout)

# Logs every incoming HTTP request.
App.set :logging, true
