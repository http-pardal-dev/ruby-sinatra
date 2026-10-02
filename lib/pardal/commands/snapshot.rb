# frozen_string_literal: true

module Pardal
  module Commands
    # `snapshot` - saves a restoration point of the environment.
    #
    # The first snapshot is saved by `setup`, when there is none yet. This
    # command is for the moments that deserve a point of their own.
    #
    # It never replaces a snapshot that already exists unless `--force` says
    # so: the snapshot belongs to the user, and replacing it silently would
    # make `reset` take the environment back to a state he already left behind.
    class Snapshot < Base
      def initialize(root:, force: false)
        super(root: root)
        @force = force
      end

      # Saves the snapshot and returns the exit status of the command.
      def call
        return snapshot_kept if snapshot_manager.exist? && !@force

        announce("Saving the snapshot (#{snapshot_directory}/)")
        snapshot_manager.save

        puts "    Whole environment saved (#{snapshot_manager.created_at})."

        0 # exit status of the command
      end

      private

      def snapshot_kept
        puts
        puts "There is already a snapshot in #{snapshot_directory}/, saved at " \
             "#{snapshot_manager.created_at}. Nothing was changed."
        puts "Use --force to replace it."

        0
      end
    end
  end
end