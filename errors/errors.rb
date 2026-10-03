# frozen_string_literal: true

# Application error handling.
#
# Registered in the application with `register Errors` (see app.rb).
# Error responses are JSON too.
#
# The application answers unexpected input with 4xx before ActiveRecord is
# involved (see helpers/records.rb and helpers/params.rb), so reaching these
# handlers with a 500 means a bug. Two races are handled as responses anyway:
# a uniqueness conflict lost between the validation and the insert answers
# 409, and an unknown attribute (a column the allowlist missed) answers 400.
module Errors
  # Route patterns of the application, per HTTP method: the 405 answer below
  # matches the request path against them, the same way Sinatra dispatches a
  # route. Mustermann has no `match?`: `params` returns nil when the path does
  # not fit. The table is filled by app.rb after every route file has loaded
  # (see Errors.snapshot_routes!), because errors/errors.rb loads before
  # routes/ and the handler itself cannot reach the class routes.
  PATTERNS = {}

  def self.registered(app)
    # The 404 answer. Sinatra calls this handler in two different situations,
    # and the request method tells them apart:
    #
    #   - the path matches a route of this method and the route answered 404
    #     itself (find_or_404): the route already chose status, headers and
    #     body, so nothing here may be touched;
    #   - the path matches no route at all (route_missing raises NotFound).
    #     Here the path decides the answer: another method would have matched,
    #     so the address exists and only the verb is wrong (405 with an Allow
    #     header); otherwise the address itself does not exist (404).
    #
    # `nil` in the first case keeps the body the route wrote: error_block!
    # skips a handler that returns nil, so nothing overwrites it.
    app.not_found do
      content_type :json
      allowed = Errors.methods_for(request.path_info)

      if allowed.include?(request.request_method)
        nil
      elsif allowed.any?
        allow = allowed.sort.join(", ")
        headers "Allow" => allow
        status 405
        { error: "Method not allowed", allow: allow }.to_json
      else
        { error: "Resource not found" }.to_json
      end
    end

    # Unexpected errors. The exception decides the response: a lost uniqueness
    # race is a 409, an attribute the allowlist missed is a 400, and anything
    # else stays a generic 500 so internals never leak to the client.
    app.error do
      content_type :json
      failure = env["sinatra.error"]
      case failure
      when ActiveRecord::RecordNotUnique
        status 409
        { error: "Resource already exists" }.to_json
      when ActiveRecord::UnknownAttributeError
        status 400
        { error: "Unknown fields", messages: [failure.message] }.to_json
      else
        { error: "Internal server error" }.to_json
      end
    end
  end

  # Copies the route patterns of `app` into PATTERNS, one entry per method:
  # app.rb calls this after requiring every route file.
  def self.snapshot_routes!(app)
    PATTERNS.replace(app.routes.transform_values do |routes|
      routes.map(&:first)
    end)
  end

  # HTTP methods whose routes match `path`, for the 405 answer above. HEAD is
  # served by Rack from every GET route, so a path with GET also allows HEAD.
  def self.methods_for(path)
    normalized = path.empty? ? "/" : path
    methods = PATTERNS.select do |method, patterns|
      method != "HEAD" && patterns.any? do |pattern|
        !pattern.params(normalized).nil?
      rescue StandardError
        false
      end
    end.keys
    methods << "HEAD" if methods.include?("GET") && !methods.include?("HEAD")

    methods
  end
end
