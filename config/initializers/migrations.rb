# frozen_string_literal: true

# Startup initializer: every migration has to have run on the current
# environment.
#
# A missing migration is silent otherwise: the server starts, and the first
# query on the new table fails. The initializer reads the schema the database has
# now and compares it with the versions on disk.
module Migrations
  # Raised with a message meant to be read by the person using the server, not
  # to be debugged. config.ru prints it on its own and exits, without a stack
  # trace.
  class Error < StandardError; end

  # Where the migrations of the project live.
  PATH = File.expand_path("../../db/migrate", __dir__)

  def self.verify!
    context = ActiveRecord::MigrationContext.new([PATH])
    pending = context.pending_migration_versions
    return if pending.empty?

    raise Error, <<~MESSAGE
      The #{ENV.fetch("APP_ENV", "development")} database is missing #{pending.size} migration(s): #{pending.join(", ")}
      They are applied by: bundle exec rake db:migrate
    MESSAGE
  end
end
