# frozen_string_literal: true

# Project Rake tasks.
#
# Loads the environment (application and database connection) and registers the
# sinatra-activerecord tasks, such as `rake db:migrate` and `rake db:schema:dump`.
#
# `require "rake"` comes first on purpose: config/environment.rb skips the
# startup initializers when Rake is already loaded, and it can only tell that if
# Rake was required before it. That is what lets `rake db:migrate` run on a
# database that does not exist yet - the very thing they complain about.
require "rake"

require_relative "config/environment"
require "sinatra/activerecord/rake"

# Code checking. It stays a task of the language (Ruby) because the checker is
# specific to the language: `rake lint` runs RuboCop with the rules of
# .rubocop.yml.
#
# RuboCop belongs to the development dependencies, which may be left out
# (`bundle install --without development`). The task still exists in that case
# and says so, instead of the whole Rakefile failing to load - losing `db:migrate`
# and every other task because a linter is missing would be a poor trade.
begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new(:lint)
rescue LoadError
  desc "Checks the code with RuboCop (not installed)"
  task :lint do
    abort "Error: RuboCop is not installed. Run bundle install to install the development dependencies."
  end
end
