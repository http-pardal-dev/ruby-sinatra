# Security

What this server does and does not protect, and what to keep in mind when
changing it.

## This API has no authentication

There is no login, no token, no session and no permission of any kind. **Every
route is open.** Anything that reaches the server can create, change and delete
users, products and payments.

Authentication is a concept for later. It is not something this server has, and
nothing in this project pretends otherwise.

## The only protection is where the server listens

The server binds to `127.0.0.1`, the loopback interface, which exists only inside
your own machine. No other computer on the same network — and nothing on the
internet, behind a router or a tunnel — can open a connection to it.

That single line is the whole security model. It is configured in
`config/puma.rb` and repeated where it is easy to miss: `bin/start` prints a
warning, and `.env.example` says it next to `PORT`.

**Do not change it to `0.0.0.0` or to any public address.** Do not run this
server on a shared machine, on a public server, or behind a tunnel or a port
forward. On any of those, anyone who finds the address can delete everything the
database holds, and there is no way to tell them apart.

## What the server does do

The input handling is real, even without authentication. It reduces what a
careless or hostile request can reach:

| Protection | What it stops |
| --- | --- |
| Request bodies over 64 KB are refused with `413` | A large body exhausting memory, checked both on the declared size and on what is actually read, so a chunked request cannot slip past it |
| Unknown fields are refused with `400` | Invented fields reaching the database, and `password_digest` being set by a client |
| `id` is checked before any query | A malformed id reaching the database; an id is never written into a query by hand |
| Sort columns come from a list | An arbitrary column name reaching the query |
| Every response field comes from a list | A column added later leaking by accident, including the password digest |
| Emails are stored normalised | Two addresses differing only in case or in spaces being treated as different users |
| Passwords are stored as a bcrypt digest | A readable password sitting in the database or in a backup |
| Unique indexes exist in the database | Two users with the same email, even under a race |
| A `500` answers with a generic message | The inside of the server reaching a client; the details stay in the log |
| SQL goes through ActiveRecord | Values being pasted into a query as text |

None of this is a substitute for authentication. It keeps a *mistake* from
becoming a `500` or a leak; it does not decide *who* is allowed to ask.

## What would have to be added before exposing this

Not a list of things to do "eventually" — a list of what is missing, so the
decision to expose it is an informed one.

- **Authentication.** Something that identifies the caller before any route runs.
- **Authorization.** Identifying a caller is not the same as deciding what it may
  do. Right now every caller may do everything.
- **A network position that is not loopback.** This one changes the risk from
  "theoretical" to "someone else's data".
- **HTTPS.** Passwords and personal data (`name`, `email`, `birthdate`) travel in
  clear text otherwise.
- **A real database.** SQLite with a single writer is a deliberate local choice.
  It is not what a concurrent, multi-user deployment wants.
- **Secrets outside the repository.** There is nothing to manage today, because
  there is nothing secret. The day there is, it does not go in `.env` under
  version control.
- **Rate limiting.** Nothing stops a local client from sending thousands of
  requests a second.

## Before changing the bind address

If the task really is to make the server reachable, treat it as a change to the
security model, not to a configuration value. Everything in the section above
applies, and the warning at the top of the `README.md` stops being true.

## Reporting a problem

This project is a local study server with no authentication, so most findings are
by design. If something looks like a genuine problem — data leaking between
requests, a password recoverable from the database, an injection — treat it as a
bug worth fixing, not as an accepted limitation.
