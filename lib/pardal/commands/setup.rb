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
    #   2. checks that Bundler is available;
    #   3. installs the dependencies declared in the Gemfile;
    #   4. creates `.env` from `.env.example`;
    #   5. creates `storage/`, where the SQLite databases live;
    #   6. runs the migrations of the `development` and `test` databases;
    #   7. saves the whole environment in `.pardal/`, used by `reset`.
    class Setup < Base
      # Environments of the project (config/environment.rb and data/database.yml).
      ENVIRONMENTS = %w[development test].freeze

      # Used only when the Gemfile does not declare the Ruby version.
      DEFAULT_RUBY_REQUIREMENT = ">= 3.2"

      # Runs every step, one by one, and returns the exit status (0).
      def call
        announce("Checking the Ruby version")
        check_ruby

        announce("Checking Bundler")
        check_bundler

        announce("Installing the dependencies (bundle install)")
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

      # --- steps -------------------------------------------------------------

      def check_ruby
        requirement = ruby_requirement
        version = Gem::Version.new(RUBY_VERSION)

        return if Gem::Requirement.new(requirement).satisfied_by?(version)

        raise Error,
              "Ruby #{version} installed, but the project requires #{requirement} (Gemfile). " \
              "Install a compatible version: https://www.ruby-lang.org/en/downloads/"
      end

      def check_bundler
        return if run(*bundle_command("--version"), quiet: true)

        raise Error, "Bundler not found. Install it with: gem install bundler"
      end

      def install_dependencies
        return if run(*bundle_command("install"))

        raise Error, "`bundle install` failed. Review the Gemfile and try again."
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

      # Bundler called by Ruby itself (`ruby -S bundle`), which behaves the
      # same on Windows, macOS and Linux.
      def bundle_command(*args)
        [Gem.ruby, "-S", "bundle", *args]
      end

      # Version required by the Gemfile (ruby ">= 3.2"). The Gemfile is the only
      # source of the rule, so it does not need to be repeated here.
      def ruby_requirement
        gemfile = root.join("Gemfile")
        return DEFAULT_RUBY_REQUIREMENT unless gemfile.file?

        gemfile.read[/^\s*ruby\s+"([^"]+)"/, 1] || DEFAULT_RUBY_REQUIREMENT
      end

      # Runs a command in the package root. `quiet` hides the output, used only
      # to check whether Bundler exists.
      def run(*command, env: {}, quiet: false)
        options = { chdir: root }
        options.merge!(out: File::NULL, err: File::NULL) if quiet

        system(env, *command, **options)
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