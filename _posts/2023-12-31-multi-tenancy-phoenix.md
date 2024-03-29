---
title: Multi-Tenancy w/Phoenix
tags: [c++, elixir, flume, phoenix, postgres]
categories: devlog
image: /assets/img/posters/multi-tenancy-phoenix.png
---

The past week of development has been focused on supporting multi-tenancy in
[Phoenix](https://www.phoenixframework.org/). The goal was to include
per-schema tenancy using the Postgres
[Ecto](https://hexdocs.pm/ecto_sql/Ecto.Adapters.Postgres.html)
adapter (schema here referring to database schemas, *not* Ecto schemas). This
post will cover the main components implemented to support this functionality:

## Models

Two models, the `Tenant` and the `User`, were introduced to support
multi-tenancy:
```elixir
@schema_prefix "public"
schema "tenants" do
  field :name, :string
  field :schema, :string

  timestamps(type: :utc_datetime)
end

schema "users" do
  field :email, :string
  field :tenant, :string, virtual: true
  field :password, :string, virtual: true, redact: true
  field :hashed_password, :string, redact: true
  field :confirmed_at, :naive_datetime
  field :is_owner, :boolean

  timestamps(type: :utc_datetime)
end
```
When a user registers with Flume, a new `Tenant` and Postgres schema are
created. A `Tenant` is one-to-one with a Postgres schema. At the time of
writing, a `Tenant` can only have one user, represented by the sole record of
the new schema's `users` table. Notice the `@schema_prefix` attribute associated
with the `Tenant` model. Whereas the `users` table will exist in multiple
locations, the `public.tenants` table is meant to be "shared". If an entry
exists in the `public.tenants` table, Flume can be confident the corresponding
schema was successfully bootstrapped.

## Migrations

The above hints that we have two different types of migrations. There are those
that exist in the shared `public` schema and those that exist per-tenant. This
distinction is also reflected in the project structure, in which there exists
`priv/repo/public_migrations` and `priv/repo/tenant_migrations` directories.
By default, Ecto assumes that there is only one migrations directory at
`priv/repo/migrations` so a few settings needed to be adjusted.

First, any invocations to `ecto.migrate` need to include an explicit
`--migrations-path` flag, e.g.:
```bash
$ ecto.migrate --migrations-path priv/repo/public_migrations
```

Second, tests need to run migrations prior to actually executing. This second
change ended up being difficult to figure out how to do correctly:

### Fixing Tests

My initial attempt was to run the [Ecto.Migrator](https://hexdocs.pm/ecto_sql/Ecto.Migrator.html)
from within an [ExUnit](https://hexdocs.pm/ex_unit/main/ExUnit.html) `setup`
call. Unfortunately, the `Ecto.Migrator` is incompatible with the
[sandbox database adapter](https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html)
typically used within Phoenix tests (the migrator requires two distinct database
connections whereas the sandbox requires sharing a single connection). In
response I tried forgoing tenancy from tests altogether, running
`tenant_migrations` against `public` alongside `public_migrations`. This felt a
bit too cheap for my liking though.

An alternative approach altogether was to just adjust how the `test` alias found
in `mix.exs` is invoked. Something like the following worked to a degree:
```elixir
test: [
  "ecto.create --quiet",
  "ecto.migrate --quiet --migrations-path priv/repo/public_migrations",
  fn _ -> Mix.Task.reenable("ecto.migrate") end,
  [
    "tenant.create",
    "--dbname",
    "flume_test",
    "--tenant",
    System.get_env("TEST_TENANT", "test_tenant"),
    "--schema",
    System.get_env("TEST_SCHEMA", "test_schema")
  ]
  |> Enum.join(" "),
  "test"
],
```
Where `tenant.create` is a thin wrapper around the following three tasks:
```elixir
Mix.Task.run("app.start")

Mix.Task.run("psql", [
  "-d",
  dbname,
  "-c",
  "'
    BEGIN;
    CREATE SCHEMA IF NOT EXISTS #{schema};
    INSERT INTO orgs (name, schema, inserted_at, updated_at)
      VALUES ($$#{tenant}$$, $$#{schema}$$, NOW(), NOW())
      ON CONFLICT DO NOTHING;
    COMMIT;
  '"
])

Mix.Task.run("ecto.migrate", [
  "--quiet",
  "--migrations-path",
  "priv/repo/tenant_migrations",
  "--prefix",
  schema
])
```
This approach served as just a temporary placeholder though. I still needed a
mechanism to create migrations dynamically on account registration. Since `Mix`
is not available from within an Elixir [release](https://hexdocs.pm/mix/1.12/Mix.Tasks.Release.html)
(the mechanism I plan to deploy Flume with), an alternative approach needed to
be found. Fortunately I stumbled across this [blog post](https://underjord.io/ecto-multi-tenancy-prefixes-part-3.html)
which introduced me to the concept of [dynamic repos](https://hexdocs.pm/ecto/replicas-and-dynamic-repositories.html).

### Dynamic Repos

The following snippet shows the actual approach used for dynamic tenant
creation. It is reused across tests, custom tasks, and the user registration
flow:
```elixir
def run(%{
      name: name,
      email: email,
      password: password
    }) do
  schema = create_schema()

  config =
    Application.get_env(:flume, Repo)
    # When name is `nil`, we need to match of the result of `start_link` to
    # retrieve the PID and pass that to `put_dynamic_repo`.
    |> Keyword.put(:name, nil)
    # In order to run migrations, at least two database connections are
    # necessary. One is used to lock the "schema_migrations" table and the
    # other one to effectively run the migrations. This allows multiple
    # nodes to run migrations at the same time, but guarantee that only one
    # of them will effectively migrate the database.
    |> Keyword.put(:pool_size, 2)
    |> Keyword.put(:migration_default_prefix, schema)
    |> Keyword.put(:prefix, schema)
    |> Keyword.delete(:pool)

  original = Repo.get_dynamic_repo()
  {:ok, pid} = Repo.start_link(config)

  user_res =
    try do
      Repo.put_dynamic_repo(pid)

      Ecto.Migrator.run(
        Repo,
        "priv/repo/tenant_migrations",
        :up,
        all: true,
        dynamic_repo: pid,
        prefix: schema
      )

      Accounts.register_user(
        %{
          email: email,
          tenant: name,
          password: password,
          is_owner: true
        },
        prefix: schema
      )
    after
      Repo.put_dynamic_repo(original)
      Supervisor.stop(pid)
    end

  with {:ok, user} <- user_res,
       {:ok, tenant} <- create_tenant(%{name: name, schema: schema}) do
    {:ok, tenant, user}
  end
end
```
An important caveat with the above is that schema/user creation cannot be
wrapped inside a transaction - the dynamic repo creates new database connections
that transcend any transaction I may attempt to wrap the schema creation code
with. To compensate, we invoke `create_tenant`, which adds a new entry to the
`public.tenants` table, only if we were able to correctly run migrations and add
a new user against the newly created schema. This means it's possible for there
to exist half-migrated schemas. This isn't a problem in practice though since
Flume will never refer to schemas that do no have a `public.tenants` entry.

## Authentication

Most of the authentication code was generated using the [phx.gen.auth](https://hexdocs.pm/phoenix/mix_phx_gen_auth.html)
generator. Though nice to have all the authentication code directly accessible
from within the application, migrating all the generated code to support
multi-tenancy was a slow process. Two little tricks made me more confident in
the correctness of the migration.

First, though a `%User` struct can exist before being persisted to the database,
it should never have an `id` associated with it until it does. To distinguish
between persisted `Users` and transient ones, I used the following signatures:
```elixir
def func(%User{id: id} = user) when is_integer(id) do ... end
def func(%User{} = user) do ... end
```
This distinction between `%User` state leads to the second trick. If a `User`
is persisted, Ecto will track the schema the `%User` exists in. This means that
in function bodies with signatures matching the first pattern, I could safely
use `Ecto.get_meta(user, :prefix)` to determine tenancy. This avoided having to
explicitly pass too many `prefix:` values throughout the various generated
function calls.

## UI

The result of this week of work is not visually too impressive. The only
noticeable difference between the pages automatically generated by
`mix phx.gen.auth` and the augmented pages is an "Organization" field in the
various registration/login pages, e.g.

![registration-form](/assets/img/multi-tenancy-phoenix/registration-form.png)

**Organization** is the user-facing term I settled on to describe a tenant.
Additionally, I included the user's tenant name in the navbar:

![tenancy-navbar](/assets/img/multi-tenancy-phoenix/tenancy-navbar.png)

Hopefully this name will serve as a useful reminder of the various advantages
multi-tenancy will bring to subsequent iterations of the project.
