-- database.sql
--
-- Schema of the API implemented by this project. It mirrors db/migrate and
-- db/schema.rb: the three resources are users, products and payments, and
-- there are no relations between them.
--
-- Dialect: SQLite, the adapter used in data/database.yml. The same DDL runs on
-- PostgreSQL with the types mapped as noted in each column.

PRAGMA foreign_keys = OFF;

-- users
--
-- password_digest is the only form of the password that is stored (bcrypt).
-- `password` and `password_confirmation` are virtual attributes of the model
-- and have no column. The unique index is the last line of defence for the
-- email: the model validates uniqueness, but only the database can refuse a
-- duplicate when two requests are validated at the same time.
CREATE TABLE users (
    id              INTEGER     PRIMARY KEY AUTOINCREMENT,
    name            VARCHAR     NOT NULL,
    email           VARCHAR     NOT NULL,
    password_digest VARCHAR     NOT NULL,
    role            VARCHAR     NOT NULL DEFAULT 'user',
    active          BOOLEAN     NOT NULL DEFAULT TRUE,
    birthdate       DATE,
    created_at      DATETIME    NOT NULL,
    updated_at      DATETIME    NOT NULL,
    CONSTRAINT index_users_on_email UNIQUE (email)
);

-- products
--
-- price is stored with 2 decimal places. It is serialized to the client as
-- text, never as a JSON number.
CREATE TABLE products (
    id          INTEGER  PRIMARY KEY AUTOINCREMENT,
    name        VARCHAR  NOT NULL,
    description TEXT,
    category    VARCHAR  NOT NULL,
    price       DECIMAL(10, 2) NOT NULL,
    created_at  DATETIME NOT NULL,
    updated_at  DATETIME NOT NULL
);

-- payments
--
-- status is the state of the payment. It starts as 'pending' and only moves to
-- 'paid' (confirm) or 'cancelled' (cancel); there is no other transition.
CREATE TABLE payments (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    amount     DECIMAL(10, 2) NOT NULL,
    status     VARCHAR     NOT NULL DEFAULT 'pending',
    created_at DATETIME    NOT NULL,
    updated_at DATETIME    NOT NULL
);