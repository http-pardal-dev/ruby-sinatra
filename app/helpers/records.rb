# frozen_string_literal: true

# Shared resource behavior: lookup, attribute filtering and persistence.
#
# The routes stay explicit about what each request does; these helpers only
# remove the repetition of finding a record, rejecting unexpected input and
# turning persistence failures into HTTP responses.
module Helpers
  module Records
    # Allowed attributes of each resource, per write operation. Anything else
    # in the request body is not a column the client may set: it is rejected
    # with 400 before ActiveRecord ever sees it, so an unexpected key can
    # never raise ActiveRecord::UnknownAttributeError (a 500).
    USER_CREATE_ATTRIBUTES = %w[name email password password_confirmation role birthdate active].freeze
    USER_UPDATE_ATTRIBUTES = %w[name email password password_confirmation role birthdate active].freeze
    PRODUCT_CREATE_ATTRIBUTES = %w[name description category price].freeze
    PRODUCT_UPDATE_ATTRIBUTES = %w[name description category price].freeze
    PAYMENT_CREATE_ATTRIBUTES = %w[amount].freeze

    # Finds a resource by id, or stops the request. Every route that takes an
    # :id uses this, so an invalid id and a missing record always answer the
    # same way, in the same order.
    #
    #   - 400 when the id is not a positive integer: no record could ever have
    #     it, so the client sent a malformed address and the query is skipped
    #     entirely (an id is never interpolated into SQL);
    #   - 404 when the id is well formed but no record has it.
    #
    # The format is checked before the lookup because the two mean different
    # things to the client: one is a broken request, the other a missing
    # resource.
    def find_or_404(model, id)
      unless id.to_s.match?(/\A[1-9]\d*\z/)
        halt 400, { error: "Invalid id", messages: ["id must be a positive integer"] }.to_json
      end

      record = model.find_by(id: id)
      halt 404, { error: "#{model} not found" }.to_json if record.nil?

      record
    end

    # Keeps only the attributes the resource accepts. Unknown keys are
    # rejected with 400, naming every offending key, instead of being ignored
    # silently or raising a 500 inside ActiveRecord.
    def restrict_attributes(payload, allowed)
      unknown = payload.keys - allowed
      unless unknown.empty?
        halt 400, {
          error: "Unknown fields",
          messages: unknown.map { |field| "Unknown field: #{field}" }
        }.to_json
      end

      payload.slice(*allowed)
    end

    # Persists a record, or stops the request with the failure as an HTTP
    # response. Validation failures are a 400 with the model messages; a race
    # lost against the database unique constraints is a 409, because the
    # resource already exists even though the validations passed.
    def persist_or_halt(record)
      record.save!
      record
    rescue ActiveRecord::RecordInvalid
      halt 400, { error: "Validation failed", messages: record.errors.full_messages }.to_json
    rescue ActiveRecord::RecordNotUnique
      halt 409, { error: "#{record.class} already exists" }.to_json
    end
  end
end
