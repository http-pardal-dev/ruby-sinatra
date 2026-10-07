# ruby-sinatra — Sinatra HTTP server

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Ruby >= 3.2](https://img.shields.io/badge/Ruby-%3E%3D%203.2-red.svg)
![Sinatra 4.2](https://img.shields.io/badge/Sinatra-4.2-black.svg)
![SQLite](https://img.shields.io/badge/SQLite-3-003b57.svg)

An HTTP server built with Ruby and Sinatra, providing a JSON API with three resources. Each resource focuses on a different part of HTTP.

> **Note:** This API has no authentication. Every route is open and requires no login, token, or permissions. The server listens only on `127.0.0.1`. Do not expose it on `0.0.0.0` or a public address.

## API

### Server

`GET` `/` → Check that the server is up

---

### Users

**CRUD & Fundamentals**

`GET`    `/users`      → List users
`GET`    `/users/:id`  → Find by ID
`POST`   `/users`      → Create a user
`PUT`    `/users/:id`  → Replace a user
`PATCH`  `/users/:id`  → Change part of a user
`DELETE` `/users/:id`  → Remove a user

> Practice: JSON, status codes, validation, and CRUD operations.

---

### Products

**Queries**

`GET`   `/products`      → List, filter, sort, and paginate
`GET`   `/products/:id`  → Find by ID
`POST`  `/products`      → Create a product
`PATCH` `/products/:id`  → Change part of a product

> Practice: filtering, sorting, pagination, and partial updates.

---

### Payments

**Lifecycle**

`POST` `/payments`             → Create, always `pending`
`GET`  `/payments`             → List, filtered by state
`GET`  `/payments/:id`         → Find by ID
`POST` `/payments/:id/confirm` → `pending` → `paid`
`POST` `/payments/:id/cancel`  → `pending` → `cancelled`

> Practice: states, actions, transitions, headers, and idempotency.
