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
      def setup
        run_command(Commands::Setup)
      end

      desc "reset", "Restores the initial environment"
      method_option :force, type: :boolean, default: false, aliases: "-f",
                        desc: "Restores without asking for confirmation"
      def reset
        run_command(Commands::Reset, shell: shell, force: options[:force])
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