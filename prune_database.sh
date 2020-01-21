#!/usr/bin/env bash
# Drop hypertable chunks older than 7 days
# in the database.
# This applies to ALL tables having a hypertable definition.
# Database connection params must be available in user's
# ~/.pgpass.
envpath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )""/.env"
source "$envpath"

# We post every log entry to Slack here since this script is run ~ once a day.
log() {
  logentry="[$(date +'%Y-%m-%d %H:%M:%S%:z')] $1"
  echo "$logentry"
}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DD="${HFPV2_ROOTDIR:-DIR}/data"
LOG_FILE="$DD/logs/prune_db.log"
touch "$LOG_FILE"
exec 1>>"$LOG_FILE"
exec 2>&1
sql="SELECT drop_chunks(interval '7 days');"
log "prune_database.sh: \`""$sql""\`"
psql -h localhost -p "${HFPV2_PORT:-5432}" -d hfp -U postgres -c "$sql" || log "Failed to prune database: see ""$LOG_FILE"
