# frozen_string_literal: true

module Pardal
  module Commands
    # `console` - opens an interactive console with the application loaded.
    #
    # The console runs in a new process, because the CLI itself never loads the
    # application (loading it in every command would make them all much slower -
    # see the README). Loading `config/environment` gives the console the app,
    # the models and the database connection of the current environment.
    class Console < Base
      # Application entry point, loaded from the root (`-I`).
      ENVIRONMENT = "config/environment"

      def call
        announce("Opening the console (IRB) with the application loaded")
        puts "    The application, the models and the database connection are ready."
        puts

        # `exec` replaces the process, and a buffered message would go with it.
        $stdout.flush

        # `-I` puts the root on the load path, so `-rconfig/environment` finds
        # the application; IRB then gives the prompt.
        exec(*bundle_command("exec", "ruby", "-I", root.to_s, "-r#{ENVIRONMENT}", "-rirb", "-e", "IRB.start"))
      rescue SystemCallError => e
        raise Error, "Could not open the console (#{e.message})."
      end
    end
  end
end
