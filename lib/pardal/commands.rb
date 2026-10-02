# frozen_string_literal: true

module Pardal
  # Commands of the interface, one file each.
  #
  # Each command is a plain class, without Thor: Thor takes care of the
  # interface in `lib/pardal/cli/runner.rb`, which builds the command and
  # handles its result.
  module Commands
  end
end

require_relative "commands/base"
require_relative "commands/install"
require_relative "commands/setup"
require_relative "commands/reset"