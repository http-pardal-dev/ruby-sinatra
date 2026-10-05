# frozen_string_literal: true

# Startup initializer: the database of the current environment has to exist.
#
# It is created by the migrations (`bundle exec rake db:migrate`), which also
# create the tables. Without it every query would fail with "no such table", a
# long way from the actual mistake.
module Database
  # Raised with a message meant to be read by the person using the server, not
  # to be debugged. config.ru prints it on its own and exits, without a stack
  # trace.
  class Error < StandardError; end

  def self.verify!
    file = database_file
    return if file.nil? || File.exist?(file)

    raise Error, <<~MESSAGE
      The #{ENV.fetch("APP_ENV", "development")} database does not exist: #{file}
      Create it and its tables with: bundle exec rake db:migrate
    MESSAGE
  end

  # The database file of the current environment, as an absolute path.
  #
  # It is read from the configuration ActiveRecord already loaded
  # (data/database.yml), never from a path written twice in the project. The
  # connection is only described here, not opened, so the initializer above can
  # tell a missing file from an existing one - SQLite would happily create it.
  def self.database_file
    configured = ActiveRecord::Base.connection_db_config.configuration_hash[:database]
    return nil if configured.nil? || configured == ":memory:"

    File.expand_path(configured, PROJECT_ROOT)
  end
end
