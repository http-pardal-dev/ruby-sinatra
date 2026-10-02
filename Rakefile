# frozen_string_literal: true

# Project Rake tasks.
#
# Loads the environment (application and database connection) and registers the
# sinatra-activerecord tasks, such as `rake db:migrate` and `rake db:schema:dump`.
require_relative "config/environment"
require "sinatra/activerecord/rake"

# Code checking. It stays a task of the language (Ruby) instead of a command of
# `bin/`, because the checker is specific to the language: `rake lint` runs
# RuboCop with the rules of .rubocop.yml.
require "rubocop/rake_task"
RuboCop::RakeTask.new(:lint)
