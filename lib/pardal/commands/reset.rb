# frozen_string_literal: true

module Pardal
  module Commands
    # `reset` - brings the environment back to the initial state saved in
    # `.pardal/`.
    #
    # The initial state is saved by `setup`. Since the restore discards what is
    # in the environment, the command asks before doing it, unless it is called
    # with `--force`.
    class Reset < Base
      def initialize(root:, shell:, force: false)
        super(root: root)
        @shell = shell
        @force = force
      end

      # Restores the environment and returns the exit status of the command.
      def call
        snapshot = Snapshot::Manager.new(root: root)
        raise Error, missing_snapshot_message unless snapshot.exist?

        unless confirm
          puts
          puts "Nothing was changed. Use --force to restore without being asked."

          return 0
        end

        announce("Restoring the initial state (#{Snapshot::Manager::DIRECTORY}/)")
        snapshot.restore

        puts
        puts "Environment restored to the state of #{snapshot.created_at}."
        puts "Changes and files created after that were discarded."

        0 # exit status of the command
      end

      private

      attr_reader :shell

      # The restore discards whatever was done after the initial state, so it
      # only happens after the confirmation - unless the command comes with
      # --force.
      def confirm
        return true if @force

        shell.yes?("This discards the changes and the files created after the " \
                   "initial state. Continue? [y/N]")
      end

      def missing_snapshot_message
        "No initial state in #{Snapshot::Manager::DIRECTORY}/. " \
        "Run bin/pardal setup to prepare the environment and save the initial state."
      end
    end
  end
end