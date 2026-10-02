# frozen_string_literal: true

require "fileutils"

module Pardal
  module Commands
    # `setup` - prepares the initial environment and saves the initial state.
    #
    # The steps are idempotent: running the command twice cannot break an
    # environment that is already ready.
    #
    #   1. checks the Ruby version required by the Gemfile;
    #   2. installs the dependencies, when needed;
    #   3. creates `.env` from `.env.example`;
    #   4. creates `storage/`, where the SQLite databases live;
    #   5. runs the migrations of the `development` and `test` databases;
    #   6. saves the whole environment in `.pardal/`, used by `reset`.
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

        announce("Saving the initial state (#{Snapshot::Manager::DIRECTORY}/)")
        save_snapshot

        print_next_steps

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

      # The initial state is saved at the end, when the environment is already
      # ready - that is the state `reset` restores.
      def save_snapshot
        Snapshot::Manager.new(root: root).save

        puts "    Whole environment saved in .pardal/ for the reset command."
      end

      # --- helpers -----------------------------------------------------------

      # Version required by the Gemfile (ruby ">= 3.2"). The Gemfile is the only
      # source of the rule, so it does not need to be repeated here.
      def ruby_requirement
        gemfile = root.join("Gemfile")
        return DEFAULT_RUBY_REQUIREMENT unless gemfile.file?

        gemfile.read[/^\s*ruby\s+"([^"]+)"/, 1] || DEFAULT_RUBY_REQUIREMENT
      end

      def print_next_steps
        puts
        puts "Environment ready."
        puts
        puts "Next steps:"
        puts "  bin/pardal reset           # restores the initial environment"
        puts "  bundle exec puma           # starts the application at http://localhost:9292"
        puts "  bundle exec rspec          # runs the tests"
        puts "  curl http://localhost:9292/ # checks that the server responds"
      end
    end
  end
end