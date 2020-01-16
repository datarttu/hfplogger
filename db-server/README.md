# hfplogger: database

## Install and run

### On host machine

Install PostgreSQL and TimescaleDB by following the [instructions](https://docs.timescale.com/latest/getting-started/installation/ubuntu/installation-apt-ubuntu) in TimescaleDB documentation.
We recommend using PostgreSQL 11.

Along with the installation, `postgres` OS user is created, and you must assume its identity to connect to the Postgres server by default.
See more on peer autenthication in [this gist](https://gist.github.com/AtulKsol/4470d377b448e56468baef85af7fd614).
To make `postgres` DB user available for other OS users as well, you must first create a password for it in the database and then enable connecting as that user with a password.

```
$ sudo su postgres
$ psql # By default, connects to localhost:5432, database postgres, user postgres.
#> ALTER ROLE postgres PASSWORD 'replacethiswithpassword';
```

Quit `psql` and `postgres` OS identity, and run:

```
$ sudo su
# nano /etc/postgresql/11/main/pg_hba.conf
```

In the conf file, change the first line `local all postgres peer` into `local all postgres md5`.
This means you must provide the password even when connecting as OS user `postgres`.
Exit nano, and exit root identity.

Restart the database server: `sudo service postgresql restart`

Assuming you're in `hfplogger/db-server`, run the database schema initialization script:

```
psql -U postgres -f init/01_init_schema.sql
```

`psql` will ask for the password interactively.
To avoid this, make a file called `~/.pgpass` (must be in your home directory), set connection parameters there according to the [PostgreSQL documentation](https://www.postgresql.org/docs/current/libpq-pgpass.html), and ensure correct file permissions by running `chmod 0600 ~/.pgpass`.
Now `psql` should be able to read the password from there, given that the other connection parameters match as well.

### Using Docker

You may want to experiment with a different database software version, for example, in which case it is handy to spin up a Docker container.

To keep the data even when your container is stopped, use a directory on your host machine as a volume pointing to `/var/lib/postgresql/data` in the container, as in the example below.

If you already have a Postgres cluster available through port 5432, you must make the container available through a different port number.
Below we are using port number 5431 on the host machine but still the default port inside the container.

Example, assuming you're inside `hfplogger/db-server/`:

```
docker build -t hfp-db .
docker run -it -v "$(pwd)/volume:/var/lib/postgresql/data" \
  -e POSTGRES_PASSWORD=replacethiswithpassword -p 127.0.0.1:5431:5432 hfp-db
```

To run in the backround in detached mode, replace `-it` with `-d`.

`POSTGRES_PASSWORD`: Password for user `postgres`.
Pass this when running the container so you can connect to the database server using this user and password.
No other users are currently implemented.

When you run the built image for the first time, DDL scripts in `init/` are run automatically, and you should then have the `hfp` database available.

Now you should be able to use the psql client on your host machine.

## Connecting to database

```
$ psql -h localhost -p 5432 -d hfp -U postgres
```
