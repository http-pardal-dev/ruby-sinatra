# frozen_string_literal: true

# Code behind the `bin/pardal` executable.
#
# The executable is the public interface of the package and only loads the
# runtime. The implementation of the commands lives in `lib/`, one file per
# command, keeping the interface (bin/) separate from the implementation (lib/).

module Pardal
  # Error expected while a command runs.
  #
  # The CLI catches the exception, writes the message without a stack trace and
  # exits with status 1. Unexpected errors still show up in full, because they
  # are bugs and must be fixed.
  class Error < StandardError; end
end

# Thor is required here because lib/pardal/ depends on it, and not only the
# executable: the CLI is the interface and the shell is also a Thor extension.
require "thor"

require_relative "pardal/commands"
require_relative "pardal/snapshot/manager"
require_relative "pardal/cli/shell"
require_relative "pardal/cli/runner"
