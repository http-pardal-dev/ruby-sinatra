# frozen_string_literal: true

# Shared validation of query parameters: pagination, sorting and filters.
#
# Query parameters always arrive as Strings (or Arrays/Hashes when the client
# repeats or nests a key). These helpers accept only the shapes the routes
# understand and stop the request with 400 otherwise, so an unexpected type
# can never reach a query and silently change its meaning.
module Helpers
  module Params
    # How many records a paginated list returns at most. A client that needs
    # more walks the pages; the cap keeps a single request from dumping the
    # whole table.
    MAX_LIMIT = 100

    # Columns a client may sort products by. The allowlist keeps the column
    # name from ever reaching the query unchecked.
    PRODUCT_SORT_COLUMNS = %w[id name price category created_at].freeze

    # Reads a pagination parameter: a positive integer, or the default when
    # the client did not send it. Anything else is a 400 naming the parameter
    # and the rule it broke.
    def integer_param(raw, name, default:, max: nil)
      return default if raw.nil?

      unless raw.is_a?(String) && raw.match?(/\A[1-9]\d*\z/)
        halt 400, {
          error: "Invalid parameter",
          messages: ["#{name} must be a positive integer"]
        }.to_json
      end

      value = raw.to_i
      if max && value > max
        halt 400, {
          error: "Invalid parameter",
          messages: ["#{name} must be at most #{max}"]
        }.to_json
      end

      value
    end

    # Reads a numeric filter parameter: a decimal number as the client would
    # write it ("10", "10.5", "-3", ".5"). Anything else is a 400 naming the
    # parameter.
    def decimal_param(raw, name)
      return nil if raw.nil?

      unless raw.is_a?(String) && raw.match?(/\A[+-]?(?:\d+(?:\.\d+)?|\.\d+)\z/)
        halt 400, {
          error: "Invalid parameter",
          messages: ["#{name} must be a number"]
        }.to_json
      end

      raw
    end

    # Reads a sorting parameter: a column of the allowlist, with an optional
    # "-" prefix for descending order. Anything else is a 400 listing the
    # accepted values.
    def sort_param(raw, allowed, default:)
      return default if raw.nil?

      unless raw.is_a?(String)
        halt 400, {
          error: "Invalid parameter",
          messages: ["sort must be one of: #{allowed.join(", ")}"]
        }.to_json
      end

      column = raw.delete_prefix("-")
      unless allowed.include?(column)
        halt 400, {
          error: "Invalid parameter",
          messages: ["sort must be one of: #{allowed.join(", ")}"]
        }.to_json
      end

      { column => raw.start_with?("-") ? :desc : :asc }
    end

    # Reads a filter parameter against an allowlist of values (a String the
    # client may send, such as a status). Anything else is a 400 listing the
    # accepted values.
    def inclusion_param(raw, name, allowed)
      return nil if raw.nil?

      unless raw.is_a?(String) && allowed.include?(raw)
        halt 400, {
          error: "Invalid parameter",
          messages: ["#{name} must be one of: #{allowed.join(", ")}"]
        }.to_json
      end

      raw
    end

    # Reads a text filter parameter: a String within the length the model
    # accepts. A longer value could never match (the model forbids storing
    # it), and a non-String would change the meaning of the query.
    def text_param(raw, name, max_length:)
      return nil if raw.nil?

      unless raw.is_a?(String) && raw.length <= max_length
        halt 400, {
          error: "Invalid parameter",
          messages: ["#{name} must be a text of at most #{max_length} characters"]
        }.to_json
      end

      raw
    end
  end
end
