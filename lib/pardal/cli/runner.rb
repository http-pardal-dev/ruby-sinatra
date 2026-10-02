# frozen_string_literal: true

require "thor"

module Pardal
  module Cli
    # Command interface of the server, executed by `bin/pardal`.
    #
    # Thor only takes care of the interface - arguments, help and exit codes.
    # The work of each command lives in `lib/pardal/commands/`.
    class Runner < Thor
      # Exit codes defined by the project standards:
      #   0  success
      #   1  error while running
      #   2  invalid usage or arguments
      EXIT_SUCCESS = 0
      EXIT_ERROR   = 1
      EXIT_USAGE   = 2

      # Help flags. Thor understands these, but only before the command name;
      # `help_args` turns `pardal setup --help` into `pardal help setup`.
      HELP_FLAGS = %w[-h -? --help].freeze

      # Thor helper command that is not part of the project interface.
      remove_command "tree"

      # Without this Thor exits with 0 even when the run fails.
      def self.exit_on_failure?
        true
      end

      # Thor writes the error message and exits with status 1, also on invalid
      # usage. The shell keeps the fact that the message was written, which
      # allows returning status 2 on those cases, as the project standard asks.
      def self.start(given_args = ARGV, config = {})
        config[:shell] ||= Shell.new

        super(help_args(given_args), config)
      rescue SystemExit => e
        raise e unless config[:shell].invalid_usage?

        exit EXIT_USAGE
      end

      # Unknown options are a usage error, instead of being ignored.
      check_unknown_options!

      # The CLI help gets the usage line, which Thor does not write by itself.
      # The help of a command (`pardal setup --help`) remains Thor's.
      def self.help(shell, subcommand = false)
        return super if subcommand

        shell.say "Usage: bin/pardal COMMAND [options]"
        shell.say
        super
      end

      desc "setup", "Prepares the initial environment"
      method_option :install, type: :boolean,
                              desc: "Installs the dependencies even when they are already in place"
      method_option :skip_install, type: :boolean,
                                   desc: "Does not check nor install the dependencies"
      def setup
        if options[:install] && options[:skip_install]
          raise Thor::Error, "--install and --skip-install cannot be used together"
        end

        run_command(Commands::Setup, install: options[:install], skip_install: options[:skip_install])
      end

      desc "start", "Runs the application"
      def start
        run_command(Commands::Start)
      end

      desc "test", "Runs the tests"
      def test
        run_command(Commands::Test)
      end

      desc "console", "Opens an interactive console"
      def console
        run_command(Commands::Console)
      end

      desc "install", "Installs the dependencies of the project"
      def install
        run_command(Commands::Install)
      end

      desc "reset", "Restores the snapshot of the environment"
      method_option :force, type: :boolean, default: false, aliases: "-f",
                            desc: "Restores without asking for confirmation"
      def reset
        run_command(Commands::Reset, shell: shell, force: options[:force])
      end

      desc "snapshot", "Saves a restoration point of the environment"
      method_option :force, type: :boolean, default: false, aliases: "-f",
                            desc: "Replaces the snapshot that already exists"
      def snapshot
        run_command(Commands::Snapshot, force: options[:force])
      end

      no_commands do
        # Package root, used by the commands to find Gemfile, .env and storage/.
        def package_root
          File.expand_path("../../..", __dir__)
        end

        # Runs a command. An expected error becomes a message and exit status 1;
        # an unexpected error still shows up in full, because that is a bug.
        def run_command(command, **options)
          command.new(root: package_root, **options).call
        rescue Error => e
          warn "Error: #{e.message}"
          exit EXIT_ERROR
        end
      end

      # `pardal setup --help` becomes `pardal help setup`, which is how Thor
      # writes the help of a command. Without a command, the help is the own
      # help of the CLI.
      def self.help_args(args)
        command = args.index { |arg| !arg.start_with?("-") }
        return args unless command && args[command..].any? { |arg| HELP_FLAGS.include?(arg) }

        ["help", args[command]]
      end
      private_class_method :help_args
    end
  end
end
