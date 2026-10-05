# frozen_string_literal: true

require "active_record"

# Startup checks.
#
# The mistakes that reach a local server are ordinary ones: a typo in APP_ENV, a
# database that was never created, a migration file that was added and never
# run. Each of them used to surface much later, as an error in the middle of the
# first request (or as a confusing stack trace from deep inside ActiveRecord).
# Here they stop the boot with a message that says what to do.
#
# The checks do NOT run when Rake loads the environment to run a task:
# `rake db:migrate` is exactly the command that fixes two of the problems
# reported here, so failing during the task would make the fix impossible.
module Checks
  # Raised with a message meant to be read by the person using the server, not
  # to be debugged. config.ru prints it on its own and exits, without a stack
  # trace.
  class Error < StandardError; end

  # Where the migrations of the project live.
  MIGRATIONS_PATH = File.expand_path("../db/migrate", __dir__)

  # Runs every check, stopping at the first problem found.
  def self.verify!
    verify_database!
    verify_migrations!
  end

  # The database file of the current environment, as an absolute path.
  #
  # It is read from the configuration ActiveRecord already loaded
  # (data/database.yml), never from a path written twice in the project. The
  # connection is only described here, not opened, so the check below can tell a
  # missing file from an existing one - SQLite would happily create it.
  def self.database_file
    configured = ActiveRecord::Base.connection_db_config.configuration_hash[:database]
    return nil if configured.nil? || configured == ":memory:"

    File.expand_path(configured, PROJECT_ROOT)
  end

  # The database of the current environment has to exist: it is created by the
  # migrations (`bundle exec rake db:migrate`), which also create the tables.
  # Without it every query would fail with "no such table", a long way from the
  # actual mistake.
  def self.verify_database!
    file = database_file
    return if file.nil? || File.exist?(file)

    raise Error, <<~MESSAGE
      The #{ENV.fetch("APP_ENV", "development")} database does not exist: #{file}
      Create it and its tables with: bundle exec rake db:migrate
    MESSAGE
  end

  # Every migration in db/migrate has to have run on the database of the
  # current environment. A missing migration is silent otherwise: the server
  # starts, and the first query on the new table fails.
  def self.verify_migrations!
    context = ActiveRecord::MigrationContext.new([MIGRATIONS_PATH])
    pending = context.pending_migration_versions
    return if pending.empty?

    raise Error, <<~MESSAGE
      The #{ENV.fetch("APP_ENV", "development")} database is missing #{pending.size} migration(s): #{pending.join(", ")}
      They are applied by: bundle exec rake db:migrate
    MESSAGE
  end
end
