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

## Getting started

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

- `.rspec` configures loading the `spec_helper` and the output format;
- `spec/spec_helper.rb` sets `APP_ENV=test`, loads the application and includes
  the `Rack::Test` helpers.

## Structure

```text
.
├── app.rb                  # Sinatra application (configuration + loads the routes)
├── bin/                    # executable scripts
├── config/
│   ├── boot.rb             # boot: Bundler and gems
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
│   └── spec_helper.rb      # RSpec configuration
├── storage/                # database files (generated)
├── .rspec
├── config.ru
├── Gemfile
├── Rakefile
└── README.md
```
