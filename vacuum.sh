#!/usr/bin/env bash
# VACUUM ANALYZE hfp tables.
# This applies to ALL tables.
# Database connection params must be available in user's
# ~/.pgpass.
envpath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )""/.env"
source "$envpath"
log() {
  logentry="[$(date +'%Y-%m-%d %H:%M:%S%:z')] $1"
  echo "$logentry"
}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DD="${HFPV2_ROOTDIR:-DIR}/data"
LOG_FILE="$DD/logs/vacuum.log"
touch "$LOG_FILE"
exec 1>>"$LOG_FILE"
exec 2>&1
sql="VACUUM ANALYZE;"
log "Start VACUUM ANALYZE"
psql -h localhost -p "${HFPV2_PORT:-5432}" -d hfp -U postgres -c "$sql" || log "Failed to vacuum"
log "End VACUUM ANALYZE"
