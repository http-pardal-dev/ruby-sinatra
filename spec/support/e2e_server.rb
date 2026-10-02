# frozen_string_literal: true

require "net/http"
require "puma/server"
require "timeout"

# Lifecycle of the real server used by the E2E specs.
#
# The E2E examples make their requests with `curl`, so they need a real server
# listening on a port. This file only starts and stops that server: it does not
# build, send or hide any request.
module E2EServer
  HOST = "127.0.0.1"
  PORT = 9292
  URL = "http://localhost:#{PORT}".freeze

  class << self
    # Starts the server once and waits until it answers.
    def start
      return if @server

      @server = Puma::Server.new(App, nil, log_writer: Puma::LogWriter.null)
      @server.add_tcp_listener(HOST, PORT)
      @server.run
      wait_until_ready
    end

    # Stops the server at the end of the suite.
    def stop
      return if @server.nil?

      @server.stop(true)
      @server = nil
    end

    private

    # Waits until the server answers, so the first `curl` never races the boot.
    def wait_until_ready
      Timeout.timeout(10) do
        Net::HTTP.get_response(URI("#{URL}/"))
      rescue StandardError
        sleep 0.1
        retry
      end
    end
  end
end

RSpec.configure do |config|
  # The server starts only when the suite has E2E examples, and stops once at
  # the end of the run.
  config.before(:context, type: :e2e) { E2EServer.start }
  config.after(:suite) { E2EServer.stop }
end
