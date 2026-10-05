# frozen_string_literal: true

# Entry point used by Rack/Puma.
#
# A startup problem is a mistake by the person using the server, not a bug in it:
# the message says what is wrong and what to run, so it is printed on its own. A
# Ruby stack trace on top of it would only bury it. Every initializer raises its
# own error (config/initializers/), so catching them by name keeps an unexpected
# failure a failure.
begin
  require_relative "config/environment"
rescue Database::Error, Migrations::Error => e
  warn "\n#{e.message}\n"
  exit 1
end

run App
