# ruby-sinatra — Sinatra HTTP server

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Ruby >= 3.2](https://img.shields.io/badge/Ruby-%3E%3D%203.2-red.svg)
![Sinatra 4.2](https://img.shields.io/badge/Sinatra-4.2-black.svg)
![Puma 8](https://img.shields.io/badge/Puma-8-lightgrey.svg)
![ActiveRecord 8.1](https://img.shields.io/badge/ActiveRecord-8.1-5c4f8d.svg)
![SQLite](https://img.shields.io/badge/SQLite-3-003b57.svg)
![No authentication](https://img.shields.io/badge/auth-NONE-critical)

An HTTP server built with Ruby and Sinatra, serving a JSON API over three
resources. Each one is there to make a different part of HTTP concrete:

| Resource | What it is about | What it shows |
| --- | --- | --- |
| **Users** | CRUD and fundamentals | Creating, reading, changing and removing records; JSON; status codes; validation |
| **Products** | Queries | Filters, sorting, pagination and partial update |
| **Payments** | Lifecycle | States, actions, atomic transitions, headers and idempotency |

The three live in the **same** Ruby + Sinatra application, sharing one
configuration, one database setup and one way of answering errors. There is
nothing hidden behind a framework default: every route, every helper and every
decision it makes is in a file you can open.

> ### This API has no authentication
>
> Every route is open: no login, no token, no permission of any kind. Anything
> that reaches the server can create, change and delete users, products and
> payments.
>
> The only protection is **where the server listens** — `127.0.0.1`, which exists
> only inside your own machine. **Do not change it to `0.0.0.0` or to a public
> address.**
>
> [docs/SECURITY.md](docs/SECURITY.md) explains what this means in full.

## Start here

**1. Prepare the environment.** This installs the dependencies, creates the
database and takes a first snapshot:

```bash
bin/setup
```

**2. Start the server:**

```bash
bin/start
```

It listens on `http://127.0.0.1:9292` and runs in the foreground — `Ctrl+C`
stops it.

**3. Confirm it answers:**

```bash
curl http://127.0.0.1:9292/
```

```json
{"service":"ruby-sinatra","status":"ok"}
```

**4. Create a user and read it back:**

```bash
curl -X POST http://127.0.0.1:9292/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Ada","email":"ada@example.com","password":"secret123","role":"user"}'

curl http://127.0.0.1:9292/users
```

That is the whole loop: prepare, start, send a request, read the answer.

### If you are on Windows

The commands are POSIX shell scripts. Run them from **Git Bash** (or any other
POSIX shell), prefixing with `sh`:

```bash
sh bin/setup
sh bin/start
```

`curl`, Ruby and Bundler have to be reachable from that shell as well.

### Requirements

- Ruby >= 3.2
- Bundler
- A POSIX shell (`sh`) — Git Bash on Windows
- `curl`, used by `bin/test`, `bin/snapshot` and `bin/reset`

## The commands

Seven scripts in `bin/`, all plain POSIX shell with no language runtime behind
them, so they start instantly and each one explains itself:

```bash
bin/help          # lists every command
bin/help setup    # the help of one command, same as bin/setup --help
```

| Command | What it does |
| --- | --- |
| `bin/setup` | Prepares the environment |
| `bin/start` | Runs the server |
| `bin/install` | Installs the dependencies |
| `bin/snapshot` | Saves a restoration point |
| `bin/reset` | Restores the snapshot |
| `bin/test` | Runs the end-to-end tests |
| `bin/help` | Shows the commands |

Every one of them answers `0` on success, `1` when it fails while running, and
`2` on invalid usage.

### `bin/setup`

Prepares everything the environment needs:

1. checks the Ruby version the `Gemfile` asks for;
2. installs the dependencies, when they are missing;
3. creates `.env` from `.env.example`, if it does not exist yet;
4. creates `storage/`, where the databases live;
5. runs the migrations of the `development` and `test` databases;
6. saves the first snapshot, if there is none yet.

It is idempotent: running it again on an environment that is already ready changes
nothing, which also makes it the way to recover a broken environment.

| Flag | What it does |
| --- | --- |
| `--install` | Installs the dependencies even when they are already in place |
| `--skip-install` | Neither checks nor installs them |

The installation itself lives in `bin/install`, which is what `bin/setup` calls
when something is missing. `bin/start` refuses to run without the dependencies
and points back to `bin/setup`, instead of showing a Bundler error.

### `bin/start`

Runs the server with Puma, in the foreground. The address is `127.0.0.1` and the
port comes from `PORT`, defaulting to `9292`:

```bash
PORT=3000 bin/start
```

### `bin/install`

Installs the dependencies declared in the `Gemfile`. It is the only command that
knows *how* they are installed, so a fresh clone works without a separate
`bundle install`.

### `bin/snapshot` and `bin/reset`

These two are what make the project safe to experiment in.

**`bin/snapshot`** saves a copy of the whole environment — code, configuration and
databases — into `.snapshot/`:

```bash
bin/snapshot
```

An existing snapshot is **not** replaced: it belongs to you, and replacing it
silently would make `reset` take the environment back to a state you had already
left behind. Use `--force` when replacing it is what you want.

**`bin/reset`** brings the environment back to that snapshot:

```bash
bin/reset
```

- files that were **changed** are restored;
- files that were **deleted** come back;
- files and folders that were **created** are removed.

Because it throws away whatever was done since, it lists the files it is about to
remove and asks before doing it. A file created after the snapshot is often work
nobody remembered making, which is why the list comes first.

| Flag | What it does |
| --- | --- |
| `--dry-run` | Shows that list and changes nothing |
| `--force` | Restores without asking — useful in a script |

**Both require the server to be stopped.** While it runs, the SQLite files are
open and can change in the middle of the copy, and the result would be a snapshot
of a database that never existed. Both commands check the ports and refuse to run
instead.

### Console

IRB with the environment loaded:

```bash
bundle exec irb -r./config/environment
```

The application, the models and the connection of the current environment are
ready to be used:

```ruby
User.count  #=> how many users are in the database
App         #=> the Sinatra application
```

## The API at a glance

Every route, with the idea it carries. The rules, the fields and the errors behind
each one are in **[docs/FEATURES.md](docs/FEATURES.md)**.

| Method | Route | Idea |
| --- | --- | --- |
| `GET` | `/` | The server is up |
| `GET` | `/users` | List |
| `GET` | `/users/:id` | Find by id |
| `POST` | `/users` | Create |
| `PUT` | `/users/:id` | Replace |
| `PATCH` | `/users/:id` | Change part of it |
| `DELETE` | `/users/:id` | Remove |
| `GET` | `/products` | List, filtered, sorted and paginated |
| `GET` | `/products/:id` | Find by id |
| `POST` | `/products` | Create |
| `PATCH` | `/products/:id` | Change part of it |
| `POST` | `/payments` | Create, always `pending` |
| `GET` | `/payments` | List, filtered by state |
| `GET` | `/payments/:id` | Find by id |
| `POST` | `/payments/:id/confirm` | `pending` → `paid` |
| `POST` | `/payments/:id/cancel` | `pending` → `cancelled` |

### Three ideas worth picking up

**`PUT` replaces, `PATCH` changes part.** `PUT /users/:id` needs everything
creating a user needs — `name`, `email` and `role`. Leaving one out is a `400`,
not a change that half happened. `PATCH` changes only what you send.

**Query parameters are validated before they reach the query.** `page=abc`,
`page=0`, `limit=101` and `sort=password_digest` are all `400`, each naming the
parameter and the rule it broke. A sort column is a name that reaches a query, so
only the ones on a list are accepted.

```bash
curl "http://127.0.0.1:9292/products?category=books&sort=-price&page=1&limit=20"
```

**Only one of two simultaneous transitions wins.** A payment leaves `pending`
exactly once, and the expected current state is part of the update itself, so the
database decides who wins. Two clients confirming the same payment at the same
time: one gets `200`, the other gets `409`. Reading the state first and writing it
afterwards would let both clients read `pending` and both confirm.

### The answers, and what they mean

Every answer is JSON, including the errors.

| Status | When |
| --- | --- |
| `200` | It worked |
| `201` | Created — with a `Location` header pointing at the new resource |
| `204` | Removed, nothing to send back |
| `400` | The request cannot be understood — the fix is on the client's side |
| `404` | The address or the record does not exist |
| `405` | The address exists under other methods — the answer carries an `Allow` header naming them |
| `409` | The request clashes with the current state |
| `413` | The body is over 64 KB |
| `500` | The server did not expect it — generic message, details in the log |

`400` and `404` are told apart by the id: `/users/abc` is a `400` (no record could
ever have that id, so no query is made), while a well-formed id with nothing
behind it is a `404`.

## Configuration

Everything is optional: a fresh clone runs with the defaults.

```bash
cp .env.example .env
```

| Variable | Default | What it decides |
| --- | --- | --- |
| `APP_ENV` | `development` | Which environment runs |
| `PORT` | `9292` | The port `bin/start` uses |
| `E2E_PORT` | `9393` | The port `bin/test` uses |

**The environments** each have their own database and their own logging:

| Value | Database | Logging |
| --- | --- | --- |
| `development` | `storage/development.sqlite3` | SQL and requests |
| `test` | `storage/test.sqlite3` | Silent |
| `production` | `storage/production.sqlite3` | Silent |

Any other value stops the boot with a message naming the three the server knows.
A typo such as `dev` would otherwise pick a database that does not exist and fail
much later, far from the name that is actually wrong.

The two ports are deliberately different, so a `bin/start` left open can never
answer the tests with the development database.

**The database** is SQLite, configured in `data/database.yml`. Running the server
without a ready database stops the boot with a message saying so, instead of
failing on the first request.

To prepare it by hand, without `bin/setup`:

```bash
bundle exec rake db:migrate          # the development database
APP_ENV=test bundle exec rake db:migrate   # and the test one
```

## Tests

```bash
bin/test
```

This rebuilds the test database, starts a server on port `9393`, waits until it
answers, runs every example with `curl` and stops the server.

| Suite | What it checks |
| --- | --- |
| `spec/unit/` | One model on its own: what it accepts and refuses |
| `spec/integration/` | The routes through Rack: status codes, bodies and headers |
| `test/e2e/` | A real server, with the method, URL, headers and body written out in each example |

The specs run in-process and start no server:

```bash
bundle exec rspec                        # everything
bundle exec rspec spec/unit              # only the models
bundle exec rspec spec/integration/payments_spec.rb
```

Two levels answer two different questions: *"is this rule true?"* and *"does a real
client see it?"*.

To check the style of the code:

```bash
bundle exec rake lint           # RuboCop, with the rules of .rubocop.yml
bundle exec rake lint:autocorrect
```

## How the project is arranged

```text
.
├── app.rb                  # the Sinatra application: settings, helpers, routes
├── bin/                    # the commands (plain shell)
├── config/
│   ├── boot.rb             # Bundler and the gems
│   ├── checks.rb           # startup checks: database and migrations
│   ├── environment.rb      # loads the application and the settings
│   ├── puma.rb             # the address and the port
│   └── environment/        # one file per environment
├── data/
│   └── database.yml        # the connection, per environment
├── db/
│   ├── migrate/            # the migrations that create the tables
│   └── schema.rb           # generated by the migrations
├── docs/                   # the documentation described below
├── errors/
│   └── errors.rb           # the 404, 405 and 500 answers, in JSON
├── helpers/
│   ├── json.rb             # JSON in and out, and the body limit
│   ├── records.rb          # finding, filtering and saving records
│   └── params.rb           # validating page, limit, sort and filters
├── models/                 # the rules of each resource
├── routes/                 # the endpoints, one file per resource
├── spec/                   # RSpec
├── test/                   # end-to-end examples, with curl
├── storage/                # the database files (generated)
├── .rubocop.yml
├── config.ru
├── Gemfile
├── LICENSE                 # MIT
├── Rakefile
└── README.md
```

**[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** walks through what each piece is
for and why the project is shaped this way.

## The documentation

| Document | What it answers |
| --- | --- |
| This file | How to run it, and what the commands do |
| [docs/FEATURES.md](docs/FEATURES.md) | What each resource does, field by field, and every rule that applies |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | How the project is put together, and the decisions behind it |
| [docs/SECURITY.md](docs/SECURITY.md) | The missing authentication, what protects the server, and what it does with input |

Each document stands on its own — read the one you need and ignore the rest.

## License

[MIT](LICENSE) © 2026 http-pardal-dev.

You may use, copy, modify, merge, publish, distribute, sublicense and sell copies
of it, for any purpose, with or without fee. The one condition is that the
copyright notice and this permission notice come along with every copy.

There is no warranty of any kind — the software is provided as it is, and
whoever uses it bears the consequences.




