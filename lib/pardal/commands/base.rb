# frozen_string_literal: true

require "pathname"

module Pardal
  module Commands
    # Common base of the commands: the package root and how the steps are
    # written.
    class Base
      def initialize(root:)
        @root = Pathname(root)
      end

      private

      attr_reader :root

      def announce(message)
        puts "\n==> #{message}"
      end
    end
  end
end