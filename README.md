# ruby-sinatra — Sinatra HTTP server

HTTP server built with Ruby and Sinatra, serving a small JSON API over three
resources, each one showing a different set of HTTP concerns:

| Resource | Focus | Concepts |
| --- | --- | --- |
| **Users** | CRUD and fundamentals | CRUD, route parameters, JSON, status codes, validation and persistence |
| **Products** | Queries | query parameters, filters, sorting, pagination and partial update |
| **Payments** | Lifecycle | states, actions, atomic transitions, headers and idempotency |

The three resources are part of the **same** Ruby + Sinatra environment.

The project is ready to be experimented with: the Sinatra base, the default
JSON configuration, the **models**, the **migrations** that create the tables and
the routes of each resource in `routes/`. Each model carries the validations
required by its own table, and a request that breaks them receives a
`400 Bad Request` with the list of messages.

> ### This API has no authentication
>
> Every route is open: there is no login, no token and no permission of any kind.
> Anything that reaches the server can create, change and delete users, products
> and payments.
>
> The only protection is where the server listens: `127.0.0.1`, the loopback
> interface, which exists only inside your own machine (see `config/puma.rb`).
> **Do not change it to `0.0.0.0` or to a public address.** Do not run this server
> on a shared machine, on a public server, or behind a tunnel or a port forward.
>
> Authentication is a concept for later, not something this server has.

## Commands

The server is used through seven scripts in `bin/`: plain POSIX shell, with no
language runtime behind them, so they start instantly and depend only on what
the environment already needs.

| Command | Responsibility |
| --- | --- |
| `bin/setup` | Prepares the initial environment |
| `bin/start` | Runs the application |
| `bin/install` | Installs the dependencies of the project |
| `bin/snapshot` | Saves a restoration point |
| `bin/reset` | Restores the snapshot |
| `bin/test` | Runs the end-to-end tests |
| `bin/help` | Shows the commands and how to use them |

The scripts need a POSIX shell. On macOS and Linux they run directly:

```bash
bin/setup
```

On Windows they run from Git Bash (or any other POSIX shell), the same way:

```bash
sh bin/setup
```

Each script explains itself with `--help`, without depending on external
documentation:

```bash
bin/setup --help
bin/reset --help
```

`bin/help` is the starting point: it lists the commands, and with a command it
opens the help of that command:

```bash
bin/help
bin/help setup
```

Exit codes follow a fixed convention: `0` on success, `1` when the execution
fails, and `2` on invalid usage.

The dependencies are installed automatically when they are missing, so a fresh
clone runs `setup` without asking for a `bundle install` first.

The tests are shell scripts, so they have a command of their own
(`bin/test`), while the linter stays a task of the language:
`bundle exec rake lint` runs RuboCop (see `.rubocop.yml`).

### `bin/setup`

Prepares everything the environment needs:

1. checks the Ruby version required by the `Gemfile`;
2. installs the dependencies, when they are missing (see `bin/install`);
3. creates `.env` from `.env.example` when it does not exist yet;
4. creates `storage/`, where the SQLite databases live;
5. runs the migrations of the `development` and of the `test` databases;
6. saves the first **snapshot**, when there is none yet.

```bash
bin/setup
```

The command is idempotent: running it again on an environment that is already
ready changes nothing, so it can be used to recover a broken environment.

The step that installs the dependencies can be controlled with two flags:

| Flag | What it does |
| --- | --- |
| `--install` | Installs the dependencies, even when they are already in place |
| `--skip-install` | Does not check nor install the dependencies |

```bash
bin/setup --install
bin/setup --skip-install
```

The installation itself lives in `bin/install`, which is what `bin/setup` calls
when the dependencies are missing, and `bin/start` refuses to run without them,
pointing back to `bin/setup`.

### `bin/start`

Runs the application with Puma, in the foreground:

```bash
bin/start
```

The server listens on `http://127.0.0.1:9292` and Ctrl+C stops it. The
dependencies are checked first, so a clone that still needs them gets a message
pointing to `bin/setup` instead of an error from Bundler.

The address is `127.0.0.1` on purpose — see the warning at the top of this file.
The port can be changed with the `PORT` environment variable:

```bash
PORT=3000 bin/start
```

Puma reads `config/puma.rb`, which is where the bind address and the port
default live.

### `bin/install`

Installs the dependencies declared in the `Gemfile`:

```bash
bin/install
```

The command runs `bundle install` directly: it is the installation that
`bin/setup` asks for when the dependencies are missing, and it can also be used
on its own. With everything already in place, it changes nothing.

### Console (IRB)

The interactive console with the application loaded is IRB itself, requiring
the environment:

```bash
bundle exec irb -r./config/environment
```

The application, the models and the database connection of the current
environment are ready, which is what the experiment needs:

```ruby
User.count  #=> number of users in the database
App         #=> the Sinatra application
```

### `bin/snapshot`

Saves a copy of the whole environment in `.snapshot/`, the point `reset` brings
it back to:

```bash
bin/snapshot
```

A snapshot that already exists is **not** replaced: it belongs to the user, and
replacing it silently would make `reset` take the environment back to a state
that was already left behind. Use `--force` to replace it on purpose:

```bash
bin/snapshot --force
```

**The server must be stopped.** While it runs, the SQLite files are open and can
change in the middle of the copy, and the result would be a snapshot of a
database that never existed. The command checks the port and refuses to run
instead.

### `bin/reset`

Restores the snapshot kept in `.snapshot/`, which is what allows creating,
changing, deleting and breaking **any file** without fear:

```bash
bin/reset
```

The reset brings the environment back to the snapshot:

- files that were **changed** are restored;
- files that were **deleted** come back;
- files and folders that were **created** are removed.

The reset replaces the current state of the environment, so the command asks
for confirmation. Use `--force` to restore without being asked, for example in
a script:

```bash
bin/reset --force
```

Before asking, it **lists the files it is about to remove**: they were created
after the snapshot and a file is often work nobody remembered making. To see
that list and change nothing, use `--dry-run`:

```bash
bin/reset --dry-run
```

Like `bin/snapshot`, the reset requires the server to be stopped: replacing the
database files underneath a running server would leave it writing to files that
are no longer there.

### `bin/help`

Lists the commands of the server, with what each one is for:

```bash
bin/help
```

With a command, it shows the help of that command - the same as
`bin/setup --help`:

```bash
bin/help setup
```

### How the snapshot flows

```text
setup     saves the first snapshot, only when there is none
snapshot  saves a new one, replacing it only with --force
reset     restores the snapshot that exists
```

The snapshot is a copy of the whole environment, not only of the database, and
it is stored in `.snapshot/`, which is not versioned:

```text
.snapshot/
├── created_at        # when the snapshot was saved (metadata, not restored)
├── .env
├── app.rb
├── bin/
├── config/
├── data/
├── db/
├── models/
├── routes/
├── test/
└── storage/
    ├── development.sqlite3
    └── test.sqlite3
```

The version control (`.git`) and the tools of the user (`.idea`, `.vscode`,
`.DS_Store`, `Thumbs.db`) are never part of the snapshot and are never
removed by the reset.

## Getting started

The shortest path is a single command, which performs every step described
below:

```bash
bin/setup
```

The steps are also described one by one, so each part of the environment can be
understood on its own.

### Requirements

- Ruby >= 3.2
- Bundler
- A POSIX shell (`sh`) — on Windows, Git Bash
- `curl`, used by `bin/test` and by the checks in `bin/snapshot` and `bin/reset`

### Installation

```bash
bundle install
```

or, equivalently, `bin/setup`, which also prepares the databases and takes the
first snapshot.

### Configuration

The environment is chosen with `APP_ENV`, which accepts three values:

| Value | Database | What it is for |
| --- | --- | --- |
| `development` (default) | `storage/development.sqlite3` | day to day work: SQL logs and request logging |
| `test` | `storage/test.sqlite3` | the automated tests |
| `production` | `storage/production.sqlite3` | a quiet run, with no logging |

Copy the example file to `.env` and adjust it if needed:

```bash
cp .env.example .env
```

Any other value stops the boot with a message naming the ones the server knows —
a typo such as `dev` would otherwise pick the wrong database and fail much later,
far from the name that is actually wrong.

The database connection is configured in `data/database.yml` (SQLite), with the
connection pool and the busy timeout written next to it.

### Ports

| Variable | Default | What it is for |
| --- | --- | --- |
| `PORT` | `9292` | the development server (`bin/start`) |
| `E2E_PORT` | `9393` | the server the end-to-end tests start |

The two are deliberately different, so a `bin/start` left open can never answer
the tests with the development database. `bin/snapshot` and `bin/reset` check
both ports and refuse to run while either one answers.

### Database setup

Create the tables from the migrations:

```bash
bundle exec rake db:migrate
```

Prepare the test database as well:

```bash
APP_ENV=test bundle exec rake db:migrate
```

`bin/setup` does both. Running the server without a ready database stops the
boot with a message saying so, instead of failing on the first request.

### Running the server

```bash
bin/start
```

or directly:

```bash
bundle exec puma
```

Either way the server listens on `http://127.0.0.1:9292` — the address comes
from `config/puma.rb`, and it is not meant to be changed to `0.0.0.0`.

Confirm the server is up:

```bash
curl http://127.0.0.1:9292/
```

### Tests

```bash
bin/test
```

The whole suite runs in the `test` environment. The unit and request specs run
on their own:

```bash
bundle exec rspec
```

## Routes

Routes live in `routes/`, one file per resource, loaded by `app.rb`.

### Health check

| Method | Route | Concept |
| --- | --- | --- |
| `GET` | `/` | server is up |

Used to confirm the server is running. Returns a small JSON with the service
name and its status.

### Users (`routes/users.rb`) — CRUD and fundamentals

| Method | Route | Concept |
| --- | --- | --- |
| `GET` | `/users` | list |
| `GET` | `/users/:id` | route parameter |
| `POST` | `/users` | creation |
| `PUT` | `/users/:id` | full update |
| `PATCH` | `/users/:id` | partial update |
| `DELETE` | `/users/:id` | removal |

`PUT` replaces the resource, so it requires everything the creation requires:
`name`, `email` and `role`. A missing one is a `400`, not a silent partial
update. The password is optional on an update — it never needs to be sent
again. To change a single attribute, use `PATCH`.

Repeating the same `PUT` leaves the user in the same state, which is what
idempotent means. The same holds for `GET`, `PATCH` and `DELETE`.

### Products (`routes/products.rb`) — queries

| Method | Route | Concept |
| --- | --- | --- |
| `GET` | `/products` | list |
| `GET` | `/products/:id` | find by id |
| `GET` | `/products?category=...` | filter by category |
| `GET` | `/products?min_price=...&max_price=...` | filter by price range |
| `GET` | `/products?sort=...` | sorting |
| `GET` | `/products?page=...&limit=...` | pagination |
| `POST` | `/products` | creation |
| `PATCH` | `/products/:id` | partial update |

> Filters, sorting and pagination use the same `GET /products` route,
> distinguished by the query parameters.

Every parameter of that route is validated before it reaches the query:

| Parameter | Rule | Wrong value |
| --- | --- | --- |
| `page` | integer from 1 up | `400` |
| `limit` | integer from 1 to `MAX_LIMIT` (100), default 10 | `400` |
| `sort` | a column of the allowlist, `-` prefix for descending | `400` |
| `category` | text of at most 50 characters | `400` |
| `min_price`, `max_price` | a number | `400` |

A value that is not what the route expects is never guessed: `page=abc`,
`page=0`, `limit=101` and `sort=password_digest` are all refused with a `400`
that names the parameter and the rule it broke. Sorting also breaks ties with
`id`, so walking the pages never skips nor repeats a product.

### Payments (`routes/payments.rb`) — lifecycle

| Method | Route | Concept |
| --- | --- | --- |
| `POST` | `/payments` | creation |
| `GET` | `/payments` | list |
| `GET` | `/payments/:id` | find by id |
| `POST` | `/payments/:id/confirm` | confirm action |
| `POST` | `/payments/:id/cancel` | cancel action |
| `GET` | `/payments?status=...` | filter by state |

A payment is created `pending` and moves to `paid` or `cancelled`. Nothing else
is possible: any other transition answers `409 Conflict`.

**The transition is atomic.** The current state is part of the `UPDATE` itself
(`Payment.transition!`), so of two clients confirming the same payment at the
same time, exactly one matches the row and wins; the other changes nothing and
answers `409`. Reading the state first and writing it afterwards would let both
clients read `pending` and both confirm.

**The actions are not idempotent.** Repeating a confirm (or a cancel) on a
payment that already left `pending` answers `409`, because the second request
changes nothing and the client has to know that the first one already won. That
is the difference between the two: an action that returns `200` twice would be
claiming two payments were made.

## Default configuration (JSON)

The server is configured to work only with JSON:

- every response uses the `application/json` content-type (setting `default_content_type`);
- the request body is read as JSON by the `json_body` helper;
- responses are serialized by the `json(data, status = 200)` helper;
- errors also return JSON, whatever the status.

### The body a request may carry

Every JSON body of this API is a single resource with short fields, so a body
larger than **64 KB** (`MAX_BODY_BYTES` in `helpers/json.rb`) is a mistake or an
abuse and is refused with `413` before it is parsed. The limit is enforced on the
declared length and on what is actually read, so a chunked request cannot get
around it either.

A body that is not JSON answers `400 Invalid JSON`, and valid JSON that is not an
object — an array, a string — answers `400`, because the routes expect attributes.

### What a request may set

Each resource has an explicit allowlist of the attributes it accepts
(`USER_CREATE_ATTRIBUTES` and friends, in `helpers/records.rb`). Anything else
is refused with `400 Unknown fields`, naming the offending keys — including `id`
and `password_digest`, which the server decides and the client never sets.

An unknown field is a mistake of the client, so it is a `400` and never a `500`.

### What a response shows

Each model serializes itself through an explicit allowlist (`PUBLIC_ATTRIBUTES`).
A column added later is not exposed until someone adds it to that list on
purpose, and `password_digest` is not part of it.

**Money is a string in the JSON**, not a number: `"price":"159.9"` and
`"amount":"99.9"`. The columns are `decimal(10,2)` and a float cannot represent
every value of a decimal exactly — `0.1` is not representable in binary — so
money travels as text to keep every value exact. A client that does arithmetic
with it has to convert deliberately, which is the honest thing to do with money.

## Errors

| Status | When |
| --- | --- |
| `400` | the request cannot be understood: invalid JSON, unknown field, wrong parameter, failed validation, malformed id |
| `404` | the address does not exist, or the record does not |
| `405` | the address exists under other methods, and not under this one (with an `Allow` header) |
| `409` | the request conflicts with the current state: a repeated email that lost a race, or a payment transition that is not allowed |
| `413` | the body is larger than the limit |
| `500` | the server did not expect it — generic message, the details stay in the log |

A `400` is the answer to almost everything a client can get wrong: a client that
sends a mistake gets a `4xx` with a message about what to fix, not a `500` from
the inside of the server.

`400` and `404` are told apart by the id: an id that is not a positive integer
could never exist (`400`, no query is even made), while a well formed id with no
record behind it is a `404`.

## Database (ActiveRecord)

Database access uses the [`sinatra-activerecord`](https://github.com/sinatra-activerecord/sinatra-activerecord) gem:

- the extension is registered in `app.rb` (`register Sinatra::ActiveRecordExtension`);
- the connection is defined in `data/database.yml` (SQLite), loaded via
  `set :database_file` according to the environment;
- the database files live in `storage/`;
- the models live in `models/` and the migrations in `db/migrate`.

### Migrations (rake)

The tables are created by the migrations in `db/migrate`. The
`sinatra-activerecord` tasks are enabled by the `Rakefile`:

```bash
bundle exec rake db:migrate          # applies pending migrations
bundle exec rake db:migrate:status   # shows the migrations status
bundle exec rake db:schema:dump      # regenerates db/schema.rb
```

Migrations respect `APP_ENV` (the connection used depends on the environment),
so to prepare the test database:

```bash
APP_ENV=test bundle exec rake db:migrate
```

## Models

Each resource has an ActiveRecord model in `models/`:

| Model | Table | Role |
| --- | --- | --- |
| `User` | `users` | persistence for the Users resource |
| `Product` | `products` | data queried by the Products resource |
| `Payment` | `payments` | payment state (Payments resource) |

`User` stores the password as a bcrypt digest (`has_secure_password`) and
validates `name` (2-100 chars), `email` (valid, unique, at most 254 chars),
`password` (minimum 8 chars), `role` (`user` or `admin`) and `birthdate` (a real
date, not in the future). The email is stored stripped and downcased, which is
how it is compared — otherwise `Ada@Example.com` and `ada@example.com` would look
like two addresses. The digest is never part of a response.

`birthdate` is checked **before** the cast: ActiveRecord turns an unreadable date
into `nil` without complaining, so `"2000-13-40"` would be stored as "no
birthdate" instead of being refused.

`Product` validates `name` (2-100 chars), `description` (optional, max 1000
chars), `category` (2-50 chars) and `price` (from 0 up to `99 999 999.99`, which
is what the column can hold).

`Payment` validates `amount` (greater than 0, up to `99 999 999.99`) and holds
the **state constants** of the lifecycle:

- `Payment::STATUSES` → `["pending", "paid", "cancelled"]`;
- `Payment::DEFAULT_STATUS` → `"pending"`.

There is no `failed` state: a payment is created `pending` and leaves it once,
either to `paid` or to `cancelled`.

The rule about *when* a payment may change state lives in
`Payment.transition!`, as the `WHERE` of the update itself, and the routes decide
which status to answer when it does not hold.

## Environments

The runtime (Bundler and the gems) is prepared by `config/boot.rb`, required at
the top of `config/environment.rb`.

The commands in `bin/` do not use `config/boot.rb`: they are shell scripts and
do not load Ruby at all, calling it only when a step really needs the language
(`bundle check`, `bundle install`, `rake db:migrate`, `puma`). Starting the
server therefore costs only what the server itself costs, and a fresh clone
works because `bin/setup` installs the dependencies when they are missing.

Each environment has a file in `config/environment/`, loaded by
`config/environment.rb` according to `APP_ENV`:

- `development.rb` — SQL logs in the terminal and request logging enabled;
- `test.rb` — SQL logs silenced and request logging disabled;
- `production.rb` — silenced, like the test one, for a quiet run.

An unknown name stops the boot before anything else is loaded.

### Startup checks (`config/checks.rb`)

Three mistakes are ordinary enough to deserve their own message instead of a
stack trace from the middle of a request:

| Situation | Message |
| --- | --- |
| the database of the environment does not exist | created by `bin/setup` |
| a migration in `db/migrate` was never applied | applied by `bin/setup` |
| `APP_ENV` is not one of the three | the list of the ones the server knows |

The checks are skipped under Rake, which is what lets `rake db:migrate` run on
the database the checks complain about — running the fix must not require the
problem to be gone first.

The database used also depends on `APP_ENV`:

- `development` → `storage/development.sqlite3`;
- `test` → `storage/test.sqlite3`;
- `production` → `storage/production.sqlite3`.

## Tests

There are two suites, for two different reasons.

### Unit and request specs (`spec/`)

RSpec, against the models and through Rack (no server):

```bash
bundle exec rspec
```

- `spec/models/` — what each model accepts and refuses;
- `spec/requests/` — the HTTP contract of each route: status codes, response
  shapes and headers;
- `spec/support/` — the JSON helpers and the shared examples the request specs
  use.

They run in the `test` environment and clean the tables between examples, so one
example never sees the data of another.

### End-to-end tests (`bin/test`)

Shell examples that talk to a real server with `curl`:

```bash
bin/test
```

The command rebuilds the test database, starts a server on port `9393`, waits
until it answers, runs the examples and stops the server.

- `test/e2e/protocol.sh` — the HTTP contract itself: unknown route, unsupported
  method, body that is not JSON, unknown field, malformed id, oversized body;
- `test/e2e/users.sh`, `products.sh`, `payments.sh` — what each resource does,
  including two confirms racing over the same payment;
- `test/support.sh` — the assertions shared by the examples: every example is
  reported as `ok` or `FAIL`, and each file finishes with the total of
  `N examples, M failures`.

The examples reach the server through `E2E_BASE_URL`, which `bin/test` exports.
Running a file on its own, against a server started by hand, is then a matter of
pointing that variable at it:

```bash
E2E_BASE_URL=http://127.0.0.1:9292 sh test/e2e/products.sh
```

## Lint (RuboCop)

The code is checked by a task of the language, not by a command of `bin/`,
because the checker is specific to the language:

```bash
bundle exec rake lint
```

The rules live in `.rubocop.yml` and describe the style the project already
uses. `rake lint:autocorrect` applies the safe corrections.

## Structure

```text
.
├── app.rb                  # Sinatra application (configuration + loads the routes)
├── bin/
│   ├── setup               # prepares the environment
│   ├── start               # starts the server
│   ├── install             # installs the dependencies
│   ├── snapshot            # saves a restoration point
│   ├── reset               # restores the snapshot
│   ├── test                # runs the end-to-end tests
│   └── help                # shows the commands
├── config/
│   ├── boot.rb             # boot of the application: Bundler and gems
│   ├── checks.rb           # startup checks (database, migrations)
│   ├── environment.rb      # loads the application and settings
│   ├── puma.rb             # server: bind address and port
│   └── environment/
│       ├── development.rb  # development settings
│       ├── test.rb         # test settings
│       └── production.rb   # production settings
├── data/
│   └── database.yml        # SQLite connection per environment
├── db/
│   ├── migrate/            # migrations (table creation)
│   └── schema.rb           # database schema (generated by the migrations)
├── errors/
│   └── errors.rb           # error handling (JSON)
├── helpers/
│   ├── json.rb             # JSON in and out (json, json_body) + body limit
│   ├── records.rb          # find_or_404, restrict_attributes, persist_or_halt
│   └── params.rb           # validation of page, limit, sort and filters
├── models/
│   ├── user.rb             # User model (users)
│   ├── product.rb          # Product model (products)
│   └── payment.rb          # Payment model (payments) + states + transition
├── routes/
│   ├── users.rb            # Users routes (CRUD and fundamentals)
│   ├── products.rb         # Products routes (queries)
│   └── payments.rb         # Payments routes (lifecycle)
├── spec/                   # unit and request specs (RSpec)
│   ├── models/
│   ├── requests/
│   └── support/
├── test/
│   ├── e2e/                # end-to-end examples (curl against the server)
│   │   ├── protocol.sh     # routes, methods and input
│   │   ├── users.sh        # users (CRUD and fundamentals)
│   │   ├── products.sh     # products (queries)
│   │   └── payments.sh     # payments (lifecycle)
│   └── support.sh          # assertions shared by the examples
├── storage/                # database files (generated)
├── .rubocop.yml            # rules of the lint task
├── config.ru
├── Gemfile
├── Rakefile
└── README.md
```
