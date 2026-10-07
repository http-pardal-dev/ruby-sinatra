# Errors

Every response is JSON, errors included. The machine-readable version of this
contract is [`contract/openapi.yml`](../contract/openapi.yml).

## Shapes

```json
{ "error": "Short readable reason", "messages": ["detail", "another detail"] }
```

- `error` — always present, one line.
- `messages` — only when a single reason is not enough (validation, bad
  parameters, unknown fields).
- `405` adds `"allow": "GET, HEAD, POST"`.

Example of a `400`:

```json
{ "error": "Validation failed", "messages": ["Name is too short (minimum is 2 characters)"] }
```

## Status codes

| Code | When | Raised by |
| --- | --- | --- |
| `400` | Malformed `:id`, invalid JSON body, unknown field, failed validation, invalid query parameter | `json_body`, `restrict_attributes`, `find_or_404`, `persist_or_halt`, `app/helpers/params.rb` |
| `404` | Well-formed id with no record, or an unknown path | `find_or_404`, `Errors.not_found` |
| `405` | Path exists for another verb (with `Allow` header) | `Errors.render_method_not_allowed` |
| `409` | Uniqueness race lost against the index, or payment not `pending` anymore | `persist_or_halt`, `Payment.transition!` |
| `413` | Body over 64 KB (`MAX_BODY_BYTES`) | `json_body` |
| `500` | Unexpected failure; body is always the same generic one | `Errors.render_failure` |

Order matters: the id format is checked **before** the lookup, so a malformed
id is `400` and a missing record is `404` — a broken request and a missing
resource are different things to the client.

## 404 or 405?

When no route matches, Sinatra calls the `not_found` handler, which decides by
the request method:

1. The path matches a route **of this method** and the route answered `404`
   itself → its body passes through untouched.
2. The path matches a route **of another method** → `405` with `Allow`.
3. No method matches → `404`, `{"error": "Resource not found"}`.

## 500

The body never carries internals: `{"error": "Internal server error"}`. The
exception itself is written to the error stream for debugging.

Two races are turned into responses instead of bugs:

| Exception | Response |
| --- | --- |
| `ActiveRecord::RecordNotUnique` | `409` — resource already exists |
| `ActiveRecord::UnknownAttributeError` | `400` — unknown fields |

Examples of each response are in [resources/](resources/).
