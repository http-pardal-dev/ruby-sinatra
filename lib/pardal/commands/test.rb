# frozen_string_literal: true

module Pardal
  module Commands
    # `test` - runs the test suite.
    #
    # The tests live in `spec/` and run with RSpec in the `test` environment,
    # which `spec/spec_helper.rb` selects.
    class Test < Base
      def call
        announce("Running the tests (RSpec)")
        puts

        # The report of RSpec is written by another process: flush the message
        # above first, so it does not come out after the report.
        $stdout.flush

        # The report is the output of the command, so it is not hidden: only a
        # failure turns into a non-zero exit status.
        raise Error, "The tests failed. Review the output above." unless run(*bundle_command("exec", "rspec"))

        0 # exit status of the command
      end
    end
  end
end
