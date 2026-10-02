# frozen_string_literal: true

module Pardal
  module Commands
    # `start` - runs the application.
    #
    # The server runs in the foreground, so the terminal keeps showing its
    # output (the `development` environment logs every request) and Ctrl+C
    # stops it.
    #
    # The process is replaced by Puma (`exec`) instead of waiting for it: with
    # the server in the process itself, Ctrl+C reaches Puma directly, without a
    # CLI in between holding the signal.
    class Start < Base
      # Address of the server, Puma's default port (see the README).
      URL = "http://localhost:9292"

      def call
        announce("Starting the server (Puma on #{URL})")
        puts "    Press Ctrl+C to stop."
        puts

        # `exec` replaces the process, and a buffered message would go with it.
        $stdout.flush

        exec(*bundle_command("exec", "puma"))
      rescue SystemCallError => e
        raise Error, "Could not start the server (#{e.message})."
      end
    end
  end
end
