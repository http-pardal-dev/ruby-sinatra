# frozen_string_literal: true

# Application error handling.
#
# Registered in the application with `register Errors` (see app.rb).
# Error responses are JSON too.
module Errors
  def self.registered(app)
    # Missing resource.
    app.not_found do
      content_type :json
      { error: "Resource not found" }.to_json
    end

    # Unexpected errors.
    app.error do
      content_type :json
      { error: "Internal server error" }.to_json
    end
  end
end
