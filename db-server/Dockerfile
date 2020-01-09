FROM timescale/timescaledb:latest-pg11
# SQL scripts in docker-entrypoint-initdb.d/ are run automatically
# (in alphabetical order) when the container is started for the first time,
# so we can create
COPY ./init/* /docker-entrypoint-initdb.d/
VOLUME /var/lib/postgresql/data
EXPOSE 5432
