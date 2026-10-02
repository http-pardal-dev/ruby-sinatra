# frozen_string_literal: true

module Pardal
  module Commands
    # `reset` - brings the environment back to the snapshot kept in `.pardal/`.
    #
    # The snapshot is saved by `setup` and by `snapshot`. This command only
    # restores it. Since the restore discards what is in the environment, it
    # asks before doing it, unless it is called with `--force`.
    class Reset < Base
      def initialize(root:, shell:, force: false)
        super(root: root)
        @shell = shell
        @force = force
      end

      # Restores the environment and returns the exit status of the command.
      def call
        raise Error, missing_snapshot_message unless snapshot_manager.exist?

        unless confirm
          puts
          puts "Nothing was changed. Use --force to restore without being asked."

          return 0
        end

        announce("Restoring the snapshot (#{snapshot_directory}/)")
        snapshot_manager.restore

        puts
        puts "Environment restored to the snapshot of #{snapshot_manager.created_at}."
        puts "Changes and files created after that were discarded."

        0 # exit status of the command
      end

      private

      attr_reader :shell

      # The restore discards whatever was done after the snapshot, so it only
      # happens after the confirmation - unless the command comes with --force.
      def confirm
        return true if @force

        shell.yes?("This discards the changes and the files created after the " \
                   "snapshot. Continue? [y/N]")
      end

      def missing_snapshot_message
        "No snapshot in #{snapshot_directory}/. " \
        "Run bin/pardal setup to prepare the environment and save the first snapshot."
      end
    end
  end
end