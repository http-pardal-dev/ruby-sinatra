# frozen_string_literal: true

require "fileutils"

module Pardal
  module Commands
    # `setup` - prepares the initial environment and saves the first snapshot.
    #
    # The steps are idempotent: running the command twice cannot break an
    # environment that is already ready.
    #
    #   1. checks the Ruby version required by the Gemfile;
    #   2. installs the dependencies, when needed;
    #   3. creates `.env` from `.env.example`;
    #   4. creates `storage/`, where the SQLite databases live;
    #   5. runs the migrations of the `development` and `test` databases;
    #   6. saves the first snapshot in `.pardal/`, if there is none yet.
    class Setup < Base
      # Environments of the project (config/environment.rb and data/database.yml).
      ENVIRONMENTS = %w[development test].freeze

      # Used only when the Gemfile does not declare the Ruby version.
      DEFAULT_RUBY_REQUIREMENT = ">= 3.2"

      # `install` forces the installation, `skip_install` skips the check and
      # the installation. Without them the dependencies are installed only when
      # they are missing.
      def initialize(root:, install: false, skip_install: false)
        super(root: root)
        @install = install
        @skip_install = skip_install
        @installer = Install.new(root: root)
      end

      # Runs every step, one by one, and returns the exit status (0).
      def call
        announce("Checking the Ruby version")
        check_ruby

        install_dependencies

        announce("Preparing the local configuration (.env)")
        create_env_file

        announce("Preparing the databases directory (storage/)")
        create_storage

        ENVIRONMENTS.each do |env|
          announce("Creating the tables of the #{env} database (db:migrate)")
          migrate(env)
        end

        save_initial_state

        puts
        puts "Environment ready."

        0 # exit status of the command
      end

      private

      attr_reader :installer

      # --- steps -------------------------------------------------------------

      def check_ruby
        requirement = ruby_requirement
        version = Gem::Version.new(RUBY_VERSION)

        return if Gem::Requirement.new(requirement).satisfied_by?(version)

        raise Error,
              "Ruby #{version} installed, but the project requires #{requirement} (Gemfile). " \
              "Install a compatible version: https://www.ruby-lang.org/en/downloads/"
      end

      # The installation itself belongs to the `install` command: setup only
      # decides when it is needed.
      #
      #   - `--skip-install` skips both the check and the installation;
      #   - `--install` always installs, even when the gems are already in place;
      #   - by default it installs only when `bundle check` finds them missing.
      def install_dependencies
        return if @skip_install
        return dependencies_already_installed if !@install && installer.installed?

        installer.call
      end

      def dependencies_already_installed
        announce("Checking the dependencies")

        puts "    The dependencies are already installed."
      end

      def create_env_file
        example = root.join(".env.example")
        raise Error, "File .env.example not found in #{example}." unless example.file?

        env = root.join(".env")

        if env.exist?
          puts "    .env already exists and was kept."
          return
        end

        FileUtils.cp(example, env)
        puts "    .env created from .env.example."
      end

      def create_storage
        storage = root.join("storage")

        if storage.directory?
          puts "    storage/ already exists."
          return
        end

        FileUtils.mkdir_p(storage)
        puts "    storage/ created."
      end

      def migrate(env)
        return if run(*bundle_command("exec", "rake", "db:migrate"), env: { "APP_ENV" => env })

        raise Error, "`rake db:migrate` failed for the #{env} environment. " \
                     "Review the migrations in db/migrate."
      end

      # The first snapshot is saved at the end, when the environment is already
      # ready. It is saved only when there is none: from then on it belongs to
      # the user, who can replace it with `snapshot --force`.
      def save_initial_state
        if snapshot_manager.exist?
          announce("Keeping the snapshot (#{snapshot_directory}/)")
          puts "    The snapshot of #{snapshot_manager.created_at} was kept."

          return
        end

        announce("Saving the first snapshot (#{snapshot_directory}/)")
        snapshot_manager.save

        puts "    Whole environment saved for the reset command."
      end

      # --- helpers -----------------------------------------------------------

      # Version required by the Gemfile (ruby ">= 3.2"). The Gemfile is the only
      # source of the rule, so it does not need to be repeated here.
      def ruby_requirement
        gemfile = root.join("Gemfile")
        return DEFAULT_RUBY_REQUIREMENT unless gemfile.file?

        gemfile.read[/^\s*ruby\s+"([^"]+)"/, 1] || DEFAULT_RUBY_REQUIREMENT
      end
    end
  end
end
