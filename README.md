# ruby-sinatra — educational server

Educational server for learning about servers, backend and HTTP, built with
Ruby and Sinatra. The environment brings together **three resources**, each one
used to teach a different set of HTTP concepts:

| Resource | Focus | Planned concepts |
| --- | --- | --- |
| **Users** | CRUD and fundamentals | CRUD, route parameters, JSON, status codes, validation and persistence |
| **Products** | Queries | query parameters, filters, sorting, pagination and partial update |
| **Payments** | Lifecycle | states, actions, transitions, headers and idempotency |

The three resources are part of the **same** Ruby + Sinatra environment.

The environment is ready to be experimented with: the Sinatra base, the default
JSON configuration, the **models**, the **migrations** that create the tables and
the routes of each resource in `routes/`. Each model carries the validations
required by its own table, and a request that breaks them receives a
`400 Bad Request` with the list of messages.

## Commands

The server is used through four scripts in `bin/`: plain POSIX shell, with no
language runtime behind them, so they start instantly and depend only on what
the environment already needs.

| Command | Responsibility |
| --- | --- |
| `bin/setup` | Prepares the initial environment |
| `bin/start` | Runs the application |
| `bin/snapshot` | Saves a restoration point |
| `bin/reset` | Restores the snapshot |

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

Exit codes follow a fixed convention: `0` on success, `1` when the execution
fails, and `2` on invalid usage.

The dependencies are installed automatically when they are missing, so a fresh
clone runs `setup` without asking for a `bundle install` first.

The test suite and the linter stay tasks of the language, not commands of
`bin/`: `bundle exec rspec` runs the tests and `bundle exec rake lint` runs
RuboCop (see `.rubocop.yml`).

### `bin/setup`

Prepares everything the environment needs:

1. checks the Ruby version required by the `Gemfile`;
2. installs the dependencies, when they are missing;
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

The installation itself lives only here: Bundler does it (`bundle install`),
and `bin/start` refuses to run when the dependencies are missing, pointing
back to `bin/setup`.

### `bin/start`

Runs the application with Puma, in the foreground:

```bash
bin/start
```

The server listens on `http://localhost:9292` and Ctrl+C stops it. The
dependencies are checked first, so a clone that still needs them gets a message
pointing to `bin/setup` instead of an error from Bundler.

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

Saves a copy of the whole environment in `.pardal/`, the point `reset` brings
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

### `bin/reset`

Restores the snapshot kept in `.pardal/`, which is what allows creating,
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

### How the snapshot flows

```text
setup     saves the first snapshot, only when there is none
snapshot  saves a new one, replacing it only with --force
reset     restores the snapshot that exists
```

The snapshot is a copy of the whole environment, not only of the database, and
it is stored in `.pardal/`, which is not versioned:

```text
.pardal/
├── created_at        # when the snapshot was saved
└── snapshot/         # copy of the whole environment
    ├── .env
    ├── app.rb
    ├── bin/
    ├── config/
    ├── data/
    ├── db/
    ├── models/
    ├── routes/
    ├── spec/
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

### Installation

```bash
bundle install
```

### Configuration

The only environment variable is `APP_ENV` (`development` or `test`). Copy the
example file to `.env` and adjust it if needed:

```bash
cp .env.example .env
```

The database connection is configured in `data/database.yml` (SQLite).

### Database setup

Create the tables from the migrations:

```bash
bundle exec rake db:migrate
```

Prepare the test database as well:

```bash
APP_ENV=test bundle exec rake db:migrate
```

### Running the server

```bash
bundle exec puma
```

By default Puma listens on `http://localhost:9292`. To use another port, pass
`-p`, for example `bundle exec puma -p 3000`.

Confirm the server is up:

```bash
curl http://localhost:9292/
```

### Tests

```bash
bundle exec rspec
```

The whole suite runs in the `test` environment.

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

### Payments (`routes/payments.rb`) — lifecycle

| Method | Route | Concept |
| --- | --- | --- |
| `POST` | `/payments` | creation |
| `GET` | `/payments/:id` | find by id |
| `POST` | `/payments/:id/confirm` | confirm action |
| `POST` | `/payments/:id/cancel` | cancel action |
| `GET` | `/payments?status=...` | filter by state |

## Default configuration (JSON)

The server is configured to work only with JSON:

- every response uses the `application/json` content-type (setting `default_content_type`);
- the request body is read as JSON by the `json_body` helper;
- responses are serialized by the `json(data, status = 200)` helper;
- errors also return JSON: `400` (invalid JSON), `404` (not found) and `500` (internal error).

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
validates `name` (2-100 chars), `email` (valid and unique), `password` (minimum
8 chars), `role` (`user` or `admin`) and `birthdate` (cannot be in the future).
The digest is never part of a response.

`Product` validates `name` (2-100 chars), `description` (optional, max 1000
chars), `category` (2-50 chars) and `price` (greater than or equal to 0).

`Payment` validates `amount` (greater than 0) and includes the **state
constants** of the lifecycle:

- `Payment::STATUSES` → `["pending", "paid", "failed", "cancelled"]`;
- `Payment::DEFAULT_STATUS` → `"pending"`.

The rule about *when* a payment may change state (only from `"pending"`) lives in
`routes/payments.rb`.

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
- `test.rb` — SQL logs silenced and request logging disabled.

The database used also depends on `APP_ENV`:

- `development` → `storage/development.sqlite3`;
- `test` → `storage/test.sqlite3`.

## Tests (RSpec)

The tests live in `spec/` and run in the `test` environment:

```bash
bundle exec rspec
```

The options of RSpec itself are available when the output needs to be tuned (a
file, an example, ...).

- `.rspec` configures loading the `spec_helper` and the output format;
- `spec/spec_helper.rb` sets `APP_ENV=test`, loads the application and includes
  the `Rack::Test` helpers;
- `spec/e2e/` holds the end-to-end examples: they start a real server
  (`spec/support/e2e_server.rb`) and send their requests with `curl`.

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
│   ├── snapshot            # saves a restoration point
│   └── reset               # restores the snapshot
├── config/
│   ├── boot.rb             # boot of the application: Bundler and gems
│   ├── environment.rb      # loads the application and settings
│   └── environment/
│       ├── development.rb  # development settings
│       └── test.rb         # test settings
├── data/
│   └── database.yml        # SQLite connection per environment
├── db/
│   ├── migrate/            # migrations (table creation)
│   └── schema.rb           # database schema (generated by the migrations)
├── errors/
│   └── errors.rb           # error handling (JSON)
├── helpers/
│   └── json.rb             # JSON helpers (json and json_body)
├── models/
│   ├── user.rb             # User model (users)
│   ├── product.rb          # Product model (products)
│   └── payment.rb          # Payment model (payments) + states
├── routes/
│   ├── users.rb            # Users routes (CRUD and fundamentals)
│   ├── products.rb         # Products routes (queries)
│   └── payments.rb         # Payments routes (lifecycle)
├── spec/
│   ├── e2e/                # end-to-end examples (curl against the server)
│   ├── integration/        # request examples (Rack::Test)
│   ├── unit/               # model examples
│   ├── support/
│   │   └── e2e_server.rb   # starts/stops the server used by spec/e2e
│   └── spec_helper.rb      # RSpec configuration
├── storage/                # database files (generated)
├── .rspec
├── .rubocop.yml            # rules of the lint task
├── config.ru
├── Gemfile
├── Rakefile
└── README.md
```
