# frozen_string_literal: true

# Application error handling.
#
# Registered in the application with `register Errors` (see app.rb).
# Error responses are JSON too.
#
# The application answers unexpected input with 4xx before ActiveRecord is
# involved (see app/helpers/records.rb and app/helpers/params.rb), so reaching these
# handlers with a 500 means a bug. Two races are handled as responses anyway:
# a uniqueness conflict lost between the validation and the insert answers
# 409, and an unknown attribute (a column the allowlist missed) answers 400.
module Errors
  # Route patterns of the application, per HTTP method: the 405 answer below
  # matches the request path against them, the same way Sinatra dispatches a
  # route. Mustermann has no `match?`: `params` returns nil when the path does
  # not fit. The table is filled by app.rb after every route file has loaded
  # (see Errors.snapshot_routes!), because lib/errors/errors.rb loads before
  # the route files (app/*/routes.rb) and the handler itself cannot reach the
  # class routes.
  #
  # It is a module attribute and not a constant because it is written after this
  # file is loaded: a frozen constant would be the wrong shape for a table that
  # is still being filled.
  @patterns = {}

  class << self
    attr_reader :patterns
  end

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
        Errors.render_method_not_allowed(self, allowed)
      else
        { error: "Resource not found" }.to_json
      end
    end

    # Unexpected errors. The exception decides the response: a lost uniqueness
    # race is a 409, an attribute the allowlist missed is a 400, and anything
    # else stays a generic 500 so internals never leak to the client.
    app.error do
      content_type :json

      Errors.render_failure(self, env["sinatra.error"])
    end
  end

  # 405, with the methods the path does accept. The `Allow` header is part of
  # the answer: without it a client has to guess what to try instead.
  def self.render_method_not_allowed(app, allowed)
    allow = allowed.sort.join(", ")
    app.headers("Allow" => allow)
    app.status 405

    { error: "Method not allowed", allow: allow }.to_json
  end

  # The body of a 500. The status is already 500 and the message is generic on
  # purpose: the exception itself is dumped to the error stream, never to the
  # client.
  def self.render_failure(app, failure)
    case failure
    when ActiveRecord::RecordNotUnique
      app.status 409
      { error: "Resource already exists" }.to_json
    when ActiveRecord::UnknownAttributeError
      app.status 400
      { error: "Unknown fields", messages: [failure.message] }.to_json
    else
      { error: "Internal server error" }.to_json
    end
  end

  # Copies the route patterns of `app` into the table above, one entry per
  # method: app.rb calls this after requiring every route file.
  def self.snapshot_routes!(app)
    @patterns = app.routes.transform_values do |routes|
      routes.map(&:first)
    end
  end

  # HTTP methods whose routes match `path`, for the 405 answer above. HEAD is
  # served by Rack from every GET route, so a path with GET also allows HEAD.
  def self.methods_for(path)
    normalized = path.empty? ? "/" : path
    methods = @patterns.select do |method, patterns|
      method != "HEAD" && patterns.any? { |pattern| matches?(pattern, normalized) }
    end.keys
    methods << "HEAD" if methods.include?("GET")

    methods
  end

  # Whether a route pattern accepts the path. A pattern that cannot even be
  # asked (a malformed one) simply does not match: it must not take the answer
  # down with it.
  def self.matches?(pattern, path)
    !pattern.params(path).nil?
  rescue StandardError
    false
  end
end
