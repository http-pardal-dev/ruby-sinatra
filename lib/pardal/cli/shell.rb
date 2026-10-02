# frozen_string_literal: true

module Pardal
  module Cli
    # Shell used by the CLI (Thor).
    #
    # Besides writing the error message, it keeps the fact that it was written.
    # That is how the CLI knows Thor refused to run - invalid command or option -
    # and can swap exit status 1 for the 2 of the project standards.
    class Shell < Thor::Shell::Basic
      def initialize(*)
        super
        @invalid_usage = false
      end

      def error(statement)
        @invalid_usage = true
        super
      end

      # True when the error written came from an invalid use of the interface.
      def invalid_usage?
        @invalid_usage
      end
    end
  end
end
