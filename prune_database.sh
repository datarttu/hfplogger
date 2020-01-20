#!/usr/bin/env bash
# Drop hypertable chunks older than 7 days
# in the database.
# This applies to ALL tables having a hypertable definition.
# Database connection params must be available in user's
# ~/.pgpass.
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S%:z')] $1"
}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DD="${HFPV2_ROOTDIR:-DIR}/data"
LOG_FILE="$DD/logs/prune_db.log"
touch "$LOG_FILE"
exec 1>>"$LOG_FILE"
exec 2>&1
log "Run drop_chunks"
psql -h localhost -p 5431 -d hfp -U postgres -c "SELECT drop_chunks(interval '7 days');"
