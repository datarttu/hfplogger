#!/usr/bin/env bash
# Execute hypertable size logging in db.
# Run this regularly in crontab.
# Database connection params must be available in user's
# ~/.pgpass.
set -e
sql="SELECT save_current_table_sizes(); SELECT save_current_row_estimates();"
psql -h localhost -p "${HFPV2_PORT:-5432}" -d hfp -U postgres -c "$sql"
