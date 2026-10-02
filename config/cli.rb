# frozen_string_literal: true

# Boot of the command interface (bin/pardal).
#
# The commands need almost nothing from the Gemfile: only Thor, to read the
# arguments and write the help. This boot therefore activates the bundle -
# `bundler/setup` only puts the gems of the lockfile in the load path - and
# does NOT load the gems themselves.
#
# config/boot.rb does load them, because the application needs them. Using it
# here would make every command pay for Sinatra, ActiveRecord and SQLite, which
# no command uses.

# Gemfile at the project root (one level above this file's folder).
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup"