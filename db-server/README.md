# hfplogger: database

## Environment variables

- POSTGRES_PASSWORD: Password for user `postgres`.
Pass this when running the container, and you can connect to the database server using this user and password.
No other users are currently implemented.

## Build & run

To keep the data even when your container is stopped,
use a directory on your host machine as a volume pointing to `/var/lib/postgresql/data` in the container.

Example:

```
docker build -t hfp-db .
docker run --rm -it -v "$(pwd)/../data/db:/var/lib/postgresql/data" \
  -e POSTGRES_PASSWORD=postgres -p 127.0.0.1:5432:5432 hfp-db
```

To run in the backround in detached mode, replace `-it` with `-d`.

Now you should be able to use the psql client on your host machine:

```
psql -h localhost -p 5432 -d hfp -U postgres
```
