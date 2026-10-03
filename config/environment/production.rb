# frozen_string_literal: true

# Production environment settings.
#
# This server has NO authentication and no authorization: every route is open
# to whoever reaches it, and it binds to the loopback interface only (see
# config/puma.rb). Running it with APP_ENV=production does not make it safe to
# expose - it only makes it quieter, which is what a production run needs.
#
# It exists so that "APP_ENV=production" is a valid answer instead of a boot
# error, and so that exercises about environments have a third one to look at.

# No SQL log, no request log: a production server does not write them to the
# terminal. Errors are still dumped to the error stream (see app.rb).
ActiveRecord::Base.logger = nil
App.set :logging, false