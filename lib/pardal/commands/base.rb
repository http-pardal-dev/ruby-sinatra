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

      # The manager that saves and restores the snapshot. The name is fully
      # qualified because the `snapshot` command has the same name as the
      # namespace of the manager.
      def snapshot_manager
        @snapshot_manager ||= Pardal::Snapshot::Manager.new(root: root)
      end

      # Folder that keeps the snapshot (".pardal").
      def snapshot_directory
        Pardal::Snapshot::Manager::DIRECTORY
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