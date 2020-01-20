#!/bin/bash
#
# Batch copy HFP v2 csv files to Postgres db.

# Exit on any error.
# Clean up temp file(s) whenever exiting.
set -e
tempfile="$(mktemp -t csvtargets.XXX)"
cleanup() {
    rm -f "$tempfile"
}
trap cleanup EXIT

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S%:z')] $1"
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Redirect all output to log file with today date.
# This will fail and exit the script
# if the file path is not valid.
DD="${HFPV2_ROOTDIR:-DIR}/data"
LOG_FILE="$DD/logs/csv_to_db_$(date +%Y%m%d).log"
touch "$LOG_FILE"
exec 1>>"$LOG_FILE"
exec 2>&1

log "Start $0"

# If this env var has any value, csv files will be kept
# and compressed once copied to database.
# TODO !!!!! change -z to -n to invert if clause -> default to no gzs
if [[ -z "$HFPV2_CSV_KEEP_GZ" ]]; then
  CSV_KEEP=1
  mkdir -p "$DD""/gz"
  log "CSV files will be COMPRESSED AND DELETED once copied to database."
else
  CSV_KEEP=0
  log "CSV files will be DELETED once copied to database."
fi

# fuser returns empty string for files that are NOT opened by any process,
# thus directing to the "echo $fn" part.
# Running fuser for every file and using temp file to list the csv files
# to handle is not optimal but it works for now.
find "$DD""/raw" -name '*.csv' -type f | while read fn ; do fuser -s "$fn" || echo "$fn" ; done > "$tempfile"

while read csvpath; do
  if [[ "$CSV_KEEP" = 1 ]]; then
    gz_target=`basename $csvpath`
    log "Compressed: ""$DD""/gz/""$gz_target"".gz"
    gzip -c "$csvpath" > "$DD""/gz/""$gz_target.gz"
  fi
  "$DIR""/csv_to_db.sh" "$csvpath" && rm "$csvpath" || continue
done<"$tempfile"

log "End $0"
exit 0
