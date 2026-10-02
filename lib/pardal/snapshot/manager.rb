# frozen_string_literal: true

require "fileutils"
require "pathname"
require "time"

module Pardal
  # Snapshots of the environment, kept in `.pardal/`.
  module Snapshot
    # Saves and restores the copy of the environment.
    #
    # The snapshot is a copy of the whole environment - code, configuration and
    # databases - and not only of the database. That is what allows changing,
    # deleting and breaking any file without fear: `reset` brings everything
    # back.
    #
    # `setup` saves the first snapshot when there is none, `snapshot` saves a
    # new one on demand, and `reset` restores the snapshot that exists.
    #
    # ```text
    # .pardal/
    # |-- created_at        # when the snapshot was saved
    # `-- snapshot/         # copy of the environment
    #     |-- .env
    #     |-- app.rb
    #     |-- bin/
    #     |-- config/
    #     |-- data/
    #     |-- db/
    #     |-- lib/
    #     |-- models/
    #     |-- routes/
    #     |-- spec/
    #     `-- storage/
    # ```
    class Manager
      # Folder of the project that keeps the snapshot.
      DIRECTORY = ".pardal"

      # Folder inside DIRECTORY that keeps the copy of the environment. What is
      # written next to it is about the snapshot and not part of the environment
      # - that is why it stays outside `path`, so it is not copied back on reset.
      SNAPSHOT = "snapshot"

      # What is left out of the snapshot:
      #
      # - `.git` and `.pardal` would be copied forever;
      # - the rest are user tools (editor and operating system), which do not
      #   belong to the environment and must not be deleted by the reset.
      EXCLUDED = %w[.git .pardal .idea .vscode .DS_Store Thumbs.db].freeze

      # File that records when the snapshot was saved.
      CREATED_AT = "created_at"

      def initialize(root:)
        @root = Pathname(root)
      end

      # Folder that keeps the snapshot and its data.
      def directory
        root.join(DIRECTORY)
      end

      # Path of the copy of the environment, used in the messages.
      def path
        directory.join(SNAPSHOT)
      end

      # Date when the snapshot was saved, for the user (nil when there is
      # none). The file keeps the ISO 8601 format; the message shows the date in
      # a readable way.
      def created_at
        file = directory.join(CREATED_AT)
        return unless file.file?

        Time.parse(file.read.strip).strftime("%Y-%m-%d at %H:%M")
      end

      # True when a snapshot is saved. The `created_at` file is written
      # last, so its presence means the snapshot finished being saved.
      def exist?
        path.directory? && directory.join(CREATED_AT).file?
      end

      # Saves the current environment as the snapshot.
      def save
        FileUtils.rm_rf(path)
        copy_tree(root, path)
        directory.join(CREATED_AT).write(Time.now.iso8601)

        self
      end

      # Brings the environment back to the snapshot: restores what was
      # changed or deleted and removes what was created afterwards.
      def restore
        remove_extra_files(root, path)
        copy_tree(path, root)

        self
      end

      private

      attr_reader :root

      # Copies a whole folder, skipping what is in EXCLUDED.
      def copy_tree(source, destination)
        prepare_directory(destination)

        Dir.children(source).each do |entry|
          next if EXCLUDED.include?(entry)

          from = source.join(entry)
          to = destination.join(entry)

          if from.directory?
            copy_tree(from, to)
          else
            # A file where a folder was (or the other way around) is deleted
            # first, so the old content does not mix with the new one.
            FileUtils.rm_rf(to) if to.directory?
            FileUtils.cp(from, to)
          end
        end
      rescue SystemCallError => e
        raise Error, copy_error_message(e)
      end

      def prepare_directory(destination)
        FileUtils.rm_rf(destination) if destination.exist? && !destination.directory?
        FileUtils.mkdir_p(destination)
      end

      # Removes what was created after the snapshot. Without this step, a
      # file created while experimenting would still exist after the reset, and
      # the environment would not go back to it.
      def remove_extra_files(directory, snapshot)
        Dir.children(directory).each do |entry|
          next if EXCLUDED.include?(entry)

          target = directory.join(entry)
          original = snapshot.join(entry)

          if target.directory? && original.directory?
            remove_extra_files(target, original)
          elsif !original.directory?
            FileUtils.rm_rf(target)
          end
        end
      rescue SystemCallError => e
        raise Error, copy_error_message(e)
      end

      def copy_error_message(error)
        "Could not apply the snapshot (#{error.class}). " \
        "On Windows, close the server and the editor before running the command."
      end
    end
  end
end