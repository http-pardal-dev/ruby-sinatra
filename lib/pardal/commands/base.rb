# frozen_string_literal: true

require "pathname"

module Pardal
  module Commands
    # Common base of the commands: the package root, how the steps are written
    # and how the commands of the project are run.
    class Base
      def initialize(root:)
        @root = Pathname(root)
      end

      private

      attr_reader :root

      def announce(message)
        puts "\n==> #{message}"
      end

      # Bundler called by Ruby itself (`ruby -S bundle`), which behaves the
      # same on Windows, macOS and Linux.
      def bundle_command(*args)
        [Gem.ruby, "-S", "bundle", *args]
      end

      # Runs a command in the package root. `quiet` hides the output, used when
      # only the exit status matters, and `env` sets the environment variables.
      def run(*command, env: {}, quiet: false)
        options = { chdir: root }
        options.merge!(out: File::NULL, err: File::NULL) if quiet

        system(env, *command, **options)
      end
    end
  end
end