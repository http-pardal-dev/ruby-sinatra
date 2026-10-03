# frozen_string_literal: true

# Boot: prepares the Ruby runtime before the application is loaded.
#
# Its only responsibility is dependencies: it points Bundler at the project
# Gemfile and requires the declared gems. Loading the application and the
# environment-specific settings is the job of config/environment.rb.

# Gemfile at the project root (one level above this file's folder).
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

# Absolute path of the project root. Every other configuration that needs a path
# (data/database.yml, config/checks.rb) builds it from here, so none of them
# depends on the folder the command happened to be started from.
PROJECT_ROOT = File.expand_path("..", __dir__)

require "bundler/setup"
require "bundler"
Bundler.require(:default)
