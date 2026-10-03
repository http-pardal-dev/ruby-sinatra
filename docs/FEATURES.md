# Features

What this API can do, resource by resource.

Every rule on this page is enforced by the server. A request that breaks one of
them never reaches the database: it is turned into an answer that says what was
wrong, and the server carries on.

## Rules shared by every resource

**Everything is JSON.** Both what the server sends and what it accepts. Even the
errors come back as JSON, so a client only ever has to parse one format.

**The body cannot be bigger than 64 KB.** Every request here carries a single
resource with a few short fields, so anything larger is either a mistake or an
abuse. It is refused with `413` before it is even read.

**Fields the resource does not know are refused.** If you send a field that is
not on the list above — including `id` and `password_digest`, which belong to
the server — you get a `400` that names every offending field. Nothing is
ignored quietly, because a typo in a field name that is silently dropped is one
of the harder mistakes to notice later.

**Passwords are never stored as typed.** The password is turned into a digest
(bcrypt) before it is saved. The digest never appears in an answer, and the
original password cannot be read back — not by a client, and not by the server.
That also means "change the password" always means "send a new one".

**Money travels as text, not as a number.** `"price":"159.90"` rather than
`"price":159.90`. The database stores exact decimals, and no ordinary floating
point number can represent every decimal exactly (`0.1` is not representable in
binary). A client that wants to do arithmetic with it has to convert on purpose,
which is the honest thing to do with money.

## Users

Creating, reading, changing and removing people.

### What a user looks like

| Field | Rule |
| --- | --- |
| `name` | Required. 2 to 100 characters |
| `email` | Required. A valid address, at most 254 characters, and unique |
| `password` | Required to create, at least 8 characters. Optional when changing |
| `role` | Required. Either `user` or `admin` |
| `birthdate` | Optional. A real date, `YYYY-MM-DD`, not in the future |
| `active` | Optional. `true` unless you say otherwise |

`password_confirmation` may be sent next to `password`, and then the two must
match.

The email is compared without case and without the spaces around it, so
`Ada@Example.com` and `ada@example.com` are the same person. Whichever is saved
first wins; the other one is refused with `409`.

A birthdate is checked before it is interpreted. `"2000-13-40"` looks like a date
but is not one, and it is refused with `400` instead of being quietly stored as
"no birthdate".

### The routes

| Method | Route | Answers |
| --- | --- | --- |
| `GET` | `/users` | `200` with every user |
| `GET` | `/users/:id` | `200` with that user, or `404` |
| `POST` | `/users` | `201` with the new user, or `400` / `409` |
| `PUT` | `/users/:id` | `200` with the updated user |
| `PATCH` | `/users/:id` | `200` with the updated user |
| `DELETE` | `/users/:id` | `204`, or `404` |

A `POST` also sends a `Location` header pointing at the user it just created, so
a client does not have to build that address itself.

### `PUT` and `PATCH` are not the same

`PUT` replaces the whole user, so it needs everything creating one needs:
`name`, `email` and `role`. Leaving one out is a `400`, not a partial change that
half happened. The password is the exception — you never have to send it again to
change something else.

`PATCH` changes only what you send. Send a name and only the name changes.

Both can be repeated safely: sending the same `PUT` twice leaves the user exactly
as it was after the first. So can `GET`, `PATCH` and `DELETE`. That property is
called **idempotence**, and it is what makes a request that arrives twice — a
retry, a flaky connection, an impatient client — harmless.

## Products

Listing things, with filters, sorting and pages.

### What a product looks like

| Field | Rule |
| --- | --- |
| `name` | Required. 2 to 100 characters |
| `description` | Optional. Up to 1000 characters |
| `category` | Required. 2 to 50 characters |
| `price` | Required. From 0 up to 99 999 999.99 |

That upper bound is not an arbitrary choice: it is the largest value the
`decimal(10,2)` column in the database can hold. A larger price is refused with
`400` before it reaches a column that would overflow.

### Listing products

Listing and querying are the same route. `GET /products` returns everything, and
the parameters below narrow it down.

| Parameter | Rule | A wrong value gives |
| --- | --- | --- |
| `category` | Text of at most 50 characters | `400` |
| `min_price`, `max_price` | A number | `400` |
| `sort` | One of `id`, `name`, `price`, `category`, `created_at`; prefix with `-` for descending | `400` |
| `page` | A whole number from 1 up | `400` |
| `limit` | A whole number from 1 to 100 (default 10) | `400` |

Parameters combine freely:

```bash
curl "http://127.0.0.1:9292/products?category=books&max_price=50&sort=-price&page=1&limit=20"
```

The list answers with the products **and** a `pagination` block, so a client
always knows how much there is in total and does not have to guess whether it
reached the end:

```json
{
  "products": [ ... ],
  "pagination": { "page": 1, "limit": 20, "total": 43 }
}
```

Nothing is ever guessed. `page=abc`, `page=0`, `limit=101` and
`sort=password_digest` are all refused with a `400` that names the parameter and
the rule it broke — a sort column is a name that reaches the query, so only the
ones on the list are accepted.

Sorting also falls back to `id` to break ties. Two products with the same price
keep a stable relative order, which is what stops walking through the pages from
skipping one product or showing it twice.

### The routes

| Method | Route | Answers |
| --- | --- | --- |
| `GET` | `/products` | `200` with the list and its pagination |
| `GET` | `/products/:id` | `200` with that product, or `404` |
| `POST` | `/products` | `201` with the new product, or `400` |
| `PATCH` | `/products/:id` | `200` with the updated product |

## Payments

Moving a payment through its life.

### What a payment looks like

| Field | Rule |
| --- | --- |
| `amount` | Required. More than 0, up to 99 999 999.99 |
| `status` | Set by the server. `pending`, `paid` or `cancelled` |

The client only ever sends `amount`. The state is decided by the server, because
it is the server that owns the lifecycle.

### The life of a payment

```text
                 POST /payments/:id/confirm
        pending ─────────────────────────────▶ paid
           │
           │  POST /payments/:id/cancel
           └──────────────────────────────▶ cancelled
```

A payment is created `pending` and leaves that state exactly once. There is no
`failed` state and no way back: any other transition answers `409`.

| Method | Route | Answers |
| --- | --- | --- |
| `POST` | `/payments` | `201` with the new payment, `pending` |
| `GET` | `/payments` | `200`, optionally filtered by `?status=` |
| `GET` | `/payments/:id` | `200` with that payment, or `404` |
| `POST` | `/payments/:id/confirm` | `200` with the paid payment, or `409` |
| `POST` | `/payments/:id/cancel` | `200` with the cancelled payment, or `409` |

### Only one of two simultaneous requests wins

The current state is part of the update itself, so confirming and cancelling at
the same time is decided by the database and not by luck. Of two clients trying
the same thing on the same payment, exactly one matches the row and wins; the
other changes nothing and gets `409`.

Reading the state first and writing it afterwards would let both clients read
`pending`, both decide they are allowed, and both write — which is how a payment
ends up confirmed *and* cancelled at the same time.

### Why repeating a confirm is a 409 and not a 200

These actions are **not idempotent**, unlike everything else in this API, and
that is deliberate.

A repeated confirm changes nothing, so answering `200` would tell the client the
payment was confirmed — twice. If the client is a payment processor that already
charged a card, a `200` means "charge it again". `409` says the truth: this
request changed nothing, and the first one already won.

Repetition is still safe — no money moves twice — but the client is told to stop
instead of being told to charge again.

## Health check

| Method | Route | Answers |
| --- | --- | --- |
| `GET` | `/` | `200` with the service name and its status |

Used to find out whether the server is up, with no database involved:

```json
{"service":"ruby-sinatra","status":"ok"}
```

## Errors in one table

| Status | What it means here |
| --- | --- |
| `400` | The request cannot be understood: invalid JSON, unknown field, a parameter that breaks its rule, a value that fails a validation, a malformed id |
| `404` | The address does not exist, or the record behind it does not |
| `405` | The address exists under other methods, not under this one — the answer carries an `Allow` header naming them |
| `409` | The request clashes with the current state: an email already in use, or a payment that already left `pending` |
| `413` | The body is larger than 64 KB |
| `500` | The server did not expect it. The message is generic on purpose; the details stay in the log |

`400` and `404` are told apart by the id. An id that is not a positive integer
could never exist, so it is a `400` and no query is even made. A well-formed id
with no record behind it is a `404`.

