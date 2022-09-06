# Cardano Rollback Monitor

This repository contains a SQL schema to deploy within the Cardano DB Sync's PostgreSQL instance to track ledger rollbacks.

When a rollback happens, a notification is sent to the `rollback_monitor` PostgresSQL channel. It can be handle by any third party program connected to the PostgreSQL instance.

## Usage

1. Connect to the PostgreSQL instance
1. Run:
```console
psql -U<user> -d<database> -h<host> -f ./schema.sql
```

And that's all.
