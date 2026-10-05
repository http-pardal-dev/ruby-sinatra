# Architecture

How the server is put together, and why it is shaped this way.

This document explains the arrangement of the project. For what the API does, see
[FEATURES.md](FEATURES.md). For the missing authentication, see
[SECURITY.md](SECURITY.md).

## The shape of a request

Every request follows the same path, and knowing it makes any file in the project
easier to place:

```text
config.ru
  └─ loads config/environment.rb
        ├─ config/boot.rb          the language runtime (Bundler, gems)
        ├─ config/checks.rb        refuses to start on a broken setup
        └─ app.rb                  the Sinatra application
              ├─ errors/           what to answer when something fails
              ├─ helpers/          behaviour shared by the routes
              ├─ routes/           one file per resource
              └─ models/           the rules and storage of each resource
                    └─ data/database.yml + storage/*.sqlite3
```

The boot happens once, when the server starts. The database, the routes and the
helpers are wired during that boot; a request only travels through them.

## Where each piece lives

| Folder or file | What it is for |
| --- | --- |
| `app.rb` | The Sinatra application: default settings, which helpers exist, which routes are loaded |
| `routes/` | One file per resource. Each route says what it does, in order, without hiding it |
| `models/` | The rules of each resource: validations, the public representation, the payment lifecycle |
| `helpers/` | The repetition taken out of the routes: JSON, finding and saving records, validating parameters |
| `errors/` | The answers for `404`, `405` and `500`, all in JSON |
| `config/` | The boot, the checks, the environment settings and the server configuration |
| `db/migrate/` | The migrations that create the tables |
| `data/database.yml` | The connection, per environment |
| `spec/` | RSpec: models on their own, and routes through Rack |

## Decisions worth knowing

Each of these is a choice, not a constraint. This is what the project chose and
why.

**A modular application, not a single file.** The app is a `Sinatra::Base`
subclass rather than the top-level `Sinatra::Application`, which means the server
can be loaded inside a test without a web server around it.

**Routes stay explicit.** Each route reads like the steps of the request, in
order. The helpers remove the repetition, not the sequence — a reader can follow
one route top to bottom without jumping to another file to know what happens next.

**Two allowlists per resource.** What a client may *send* (`*_ATTRIBUTES` in
`helpers/records.rb`) and what a client may *see* (`PUBLIC_ATTRIBUTES` in each
model) are separate lists, written out in full.

Both exist for the same reason: a mistake should never become a `500`. A field
the client invented cannot reach the database, and a column added later cannot
appear in a response until someone decides it should. `password_digest` is
simply not on the second list.

**Unexpected input is refused before the database, not after.** A value that does
not match what the route expects gets a `400` that names the parameter and the
rule. This is why `page=abc` is a `400` and not a database error, and why a sort
column is checked against a list: a name that reaches a query is a name that has
to be safe there.

**An id is checked before it is looked up.** `400` when the id is not a positive
integer — no record could ever have it, so no query is made — and `404` when it
is well formed but nothing is behind it. The two mean different things to the
client: a broken request, and a missing resource.

**A payment transition is one statement.** `Payment.transition!` puts the
expected current state inside the update itself. Reading the state and then
writing it would be two statements, and a second client could act in between; one
statement means the database decides who wins. This is the only place in the
project where a correctness property depends on *how* something is written rather
than on what it returns.

**Errors are JSON like everything else.** A client parses one format for every
answer, whatever happened. A `500` carries a generic message and keeps the
details in the log, so an unexpected failure cannot leak the inside of the
server.

**The startup checks exist because these mistakes are ordinary.** A typo in
`APP_ENV`, a database that was never created, a migration that was never run —
each used to surface as an error in the middle of the first request, far from the
name that is actually wrong. They now stop the boot with a message that says what
to run.

The checks are skipped under Rake, and that is what allows `rake db:migrate` to
run on the very database the checks complain about. The fix must not require the
problem to be gone first.

## The three environments

The environment is chosen with `APP_ENV` and decides the database and the
logging:

| `APP_ENV` | Database | Logging |
| --- | --- | --- |
| `development` (default) | `storage/development.sqlite3` | SQL and requests |
| `test` | `storage/test.sqlite3` | Silent |
| `production` | `storage/production.sqlite3` | Silent |

Each has its own settings file in `config/environment/`. An unknown value stops
the boot before anything else is loaded, because a typo such as `dev` would
otherwise pick a database that does not exist and fail much later, with a message
that does not point at the name that is wrong.

## How the tests are arranged

Two suites, for two different reasons.

**`spec/unit/` — one model at a time.** What a model accepts and refuses,
exercised on its own.

**`spec/integration/` — the routes through Rack.** Requests go through
Rack::Test and the answer is checked as status code, body and headers. It is
fast, and a failure points straight at the code.

Both run in the `test` environment against `storage/test.sqlite3`, cleaned
between examples so each one sees an empty database. Because the examples begin
from an empty database, an example can never pass because of a record a previous
example left behind.

