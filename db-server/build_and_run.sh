#!/bin/bash
# Build and start database container,
# and test psql connection.
# NOTE:
# 1) For production environment, change the password!!
# 2) This version uses port 5431 on the host,
#    as the default postgres port 5432 may be taken already.
export PGPASSWORD=postgres
export PGHOSTPORT=5431
docker build -t hfp-db . && \
docker run --rm -d -v "$(pwd)/volume/db:/var/lib/postgresql/data" \
  --name hfp-db \
  -e POSTGRES_PASSWORD="$PGPASSWORD" -p 127.0.0.1:$PGHOSTPORT:5432 hfp-db
sleep 5
psql -h localhost -p $PGHOSTPORT -U postgres -d hfp \
  -c "SELECT 'Successfully connected';"
