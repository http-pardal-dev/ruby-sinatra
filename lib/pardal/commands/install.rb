# frozen_string_literal: true

module Pardal
  module Commands
    # `install` - installs the dependencies declared in the Gemfile.
    #
    # This is the only place that knows how the dependencies are installed:
    # every command that needs the gems asks this one, so there is a single
    # place to change when the installation changes.
    class Install < Base
      def call
        announce("Installing the dependencies (bundle install)")

        raise Error, "`bundle install` failed. Review the Gemfile and try again." unless install

        puts "    Dependencies installed."
        puts "    Next step: bin/pardal setup prepares the environment."

        0 # exit status of the command
      end

      # True when the gems declared in the Gemfile are already installed.
      #
      # `bundle check` only looks at the local gems, so it is the cheap way to
      # know whether an install is needed - and it needs no network.
      def installed?
        run(*bundle_command("check"), quiet: true)
      end

      private

      def install
        run(*bundle_command("install"))
      end
    end
  end
end