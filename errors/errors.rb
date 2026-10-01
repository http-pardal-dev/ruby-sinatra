# frozen_string_literal: true

# Application error handling.
#
# Registered in the application with `register Errors` (see app.rb).
# Error responses are JSON too.
module Errors
  def self.registered(app)
    # Missing resource. Routes can answer 404 with their own message, so the
    # default body is only written when the route did not set one.
    app.not_found do
      content_type :json
      body({ error: "Resource not found" }.to_json) if response.body.empty?
    end

    # Unexpected errors.
    app.error do
      content_type :json
      { error: "Internal server error" }.to_json
    end
  end
end
