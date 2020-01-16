#!/bin/bash
#
# Batch copy HFP v2 csv files to Postgres db.

# Exit on any error.
# Clean up temp file(s) whenever exiting.
set -e
tempfile="$(mktemp -t csvtargets)"
cleanup() {
    rm -f "$tempfile"
}
trap cleanup EXIT

# Setting the project root is obligatory,
# since this script might be executed from within a directory other
# than where the script is.
if [[ -z "$HFPV2_ROOTDIR" ]]; then
  echo "ERROR:"
  echo "env var HFPV2_ROOTDIR is not set!"
  exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Redirect all output to log file with today date.
# This will fail and exit the script
# if the file path is not valid.
DD="${HFPV2_ROOTDIR:-DIR}/subscriber/data"
LOG_FILE="$DD/logs/csv_to_db_$(date +%Y%m%d).log"
touch "$LOG_FILE"
exec 1>>$LOG_FILE
exec 2>&1

echo "Start $0 at $(date +'%Y-%m-%d %H:%M:%S%:z')"

# If this env var has any value, csv files will be kept
# and compressed once copied to database.
# TODO !!!!! change -z to -n to invert if clause -> default to no gzs
if [[ -z "$HFPV2_CSV_KEEP_GZ" ]]; then
  CSV_KEEP=1
  mkdir -p "$DD/gz"
  echo "CSV files will be COMPRESSED AND DELETED once copied to database."
else
  CSV_KEEP=0
  echo "CSV files will be DELETED once copied to database."
fi

# fuser returns empty string for files that are NOT opened by any process,
# thus directing to the "echo $fn" part.
# Running fuser for every file and using temp file to list the csv files
# to handle is not optimal but it works for now.
find $DD/raw -name '*.csv' -type f | while read fn ; do fuser -s $fn || echo "$fn" ; done > "$tempfile"

while read csvpath; do
  if [[ $CSV_KEEP = 1 ]]; then
    gz_target=`basename $csvpath`
    echo "$DD/gz/$gz_target.gz compressed"
    gzip -c "$csvpath" > "$DD/gz/$gz_target.gz"
  fi
  rm "$csvpath"
  # TODO: mapping between raw data files and SQL COPY script for each type of data???
  # TODO: for each file for which there is a mapping, do
  #       - psql: copy contents to temp table, insert valid rows from temp table to prod table, echo results
  #       - if psql exit status was successful:
  #         - if keep_and_compress==true, gzip the csv file to data/gz/
  #         - delete the csv file
  #       - else (if psql failed):
  #         - gzip the csv file to data/gz/
  #         - record error/warning to log
  #         - delete the csv file
done<"$tempfile"

echo "End $0 at $(date +'%Y-%m-%d %H:%M:%S%:z')"
exit 0
