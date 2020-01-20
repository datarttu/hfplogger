#!/bin/bash
# Import HFP events to database
# using predefined csv file structures:
# This script assumest that
# - bus and tram csv files contain ALL payload fields
# - train and metro csv files contain all except traffic light related fields and dr-type.
# Db "hfp" must be available at localhost through port 5432,
# and password for user "postgres" must be provided in the current user's ~/.pgpass.
# Required positional parameters:
# 1) Full path of csv file to import.
#    Must contain transit mode bus, tram, train or metro, e.g. '_metro_'.
#    For bus and tram, traffic light events are imported to separate tables.
set -e
if [[ -z "$1" ]]; then
  exit 1 "No csv path provided"
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S%:z')] Copy $1 to database"

# Detect transit mode from file path
if [[ "$1" == *'_bus_'* ]]; then
  transitmode='bus'
elif [[ "$1" == *'_tram_'* ]]; then
  transitmode='tram'
elif [[ "$1" == *'_train_'* ]]; then
  transitmode='train'
elif [[ "$1" == *'_metro_'* ]]; then
  transitmode='metro'
else
  exit 1 "Csv path contains no transit mode"
fi

columns_def="
desi            text,
dir             smallint,
oper            smallint,
veh             smallint,
tst             timestamptz,
tsi             integer,
spd             real,
hdg             smallint,
lat             double precision,
long            double precision,
acc             real,
dl              integer,
odo             integer,
drst            boolean,
oday            date,
jrn             integer,
line            smallint,
start           time,
loc             location_source,
stop            integer,
route           text,
occu            smallint,
seq             smallint,
ttarr           timestamptz,
ttdep           timestamptz
"

if [[ "$transitmode" == 'bus' || "$transitmode" == 'tram' ]]; then
  columns_def="$columns_def"",
  tlp_requestid   smallint,
  tlp_requesttype tlp_requesttype,
  tlp_prioritylevel tlp_prioritylevel,
  tlp_reason      tlp_reason,
  tlp_att_seq     integer,
  tlp_decision    tlp_decision,
  sid             integer,
  signal_groupid  integer,
  tlp_signalgroupnbr integer,
  event_type      event_type
  "
else
  columns_def="$columns_def"",
  event_type      event_type
  "
fi

if [[ "$transitmode" == 'bus' || "$transitmode" == 'tram' ]]; then
  insert_clause="
  WITH inserted AS (
    INSERT INTO $transitmode (
    desi, dir, oper, veh, tst, tsi, spd, hdg, lat, long,
    acc, dl, odo, drst, oday, jrn, line, start, loc,
    stop, route, occu, seq, ttarr, ttdep,
    event_type
    ) (
    SELECT desi, dir, oper, veh, tst, tsi, spd, hdg, lat, long,
    acc, dl, odo, drst, oday, jrn, line, start, loc::location_source,
    stop, route, occu, seq, ttarr, ttdep,
    event_type::event_type
    FROM staging
    WHERE event_type NOT IN ('TLR'::event_type, 'TLA'::event_type)
    )
    ON CONFLICT DO NOTHING
    RETURNING *)
  INSERT INTO insert_log (target, staging_rows, inserted_rows)
  SELECT
    '$transitmode' AS target,
    s.cnt AS staging_rows,
    i.cnt AS inserted_rows
  FROM (SELECT count(*) AS cnt FROM inserted) i
  JOIN (SELECT count(*) AS cnt FROM staging) s
  ON TRUE;
  WITH inserted AS (
    INSERT INTO tl_$transitmode (
    desi, dir, oper, veh, tst, tsi, spd, hdg, lat, long,
    acc, dl, odo, drst, oday, jrn, line, start, loc,
    stop, route, occu, seq, ttarr, ttdep,
    tlp_requestid, tlp_requesttype, tlp_reason,
    tlp_att_seq, tlp_decision, sid, signal_groupid, tlp_signalgroupnbr,
    event_type
    ) (
    SELECT desi, dir, oper, veh, tst, tsi, spd, hdg, lat, long,
    acc, dl, odo, drst, oday, jrn, line, start, loc::location_source,
    stop, route, occu, seq, ttarr, ttdep,
    tlp_requestid, tlp_requesttype::tlp_requesttype, tlp_reason::tlp_reason,
    tlp_att_seq, tlp_decision::tlp_decision, sid, signal_groupid, tlp_signalgroupnbr,
    event_type::event_type
    FROM staging
    WHERE event_type IN ('TLR'::event_type, 'TLA'::event_type)
    )
    ON CONFLICT DO NOTHING
    RETURNING *)
  INSERT INTO insert_log (target, staging_rows, inserted_rows)
  SELECT
    'tl_$transitmode' AS target,
    s.cnt AS staging_rows,
    i.cnt AS inserted_rows
  FROM (SELECT count(*) AS cnt FROM inserted) i
  JOIN (SELECT count(*) AS cnt FROM staging) s
  ON TRUE;
  "
else
  insert_clause="
  WITH inserted AS (
    INSERT INTO $transitmode (
    SELECT desi, dir, oper, veh, tst, tsi, spd, hdg, lat, long,
    acc, dl, odo, drst, oday, jrn, line, start, loc::location_source,
    stop, route, occu, seq, ttarr, ttdep,
    event_type::event_type
    FROM staging
    )
    ON CONFLICT DO NOTHING
    RETURNING *
    )
  INSERT INTO insert_log (target, staging_rows, inserted_rows)
  SELECT
    '$transitmode' AS target,
    s.cnt AS staging_rows,
    i.cnt AS inserted_rows
  FROM (SELECT count(*) AS cnt FROM inserted) i
  JOIN (SELECT count(*) AS cnt FROM staging) s
  ON TRUE;
  "
fi

sql="
BEGIN;
CREATE TEMPORARY TABLE staging (
$columns_def
) ON COMMIT DROP;
COPY staging FROM STDIN WITH DELIMITER ',' CSV HEADER;
$insert_clause
COMMIT;
"

# For bus and tram, we need both tl and non-tl entries from log.
if [[ "$transitmode" == 'bus' || "$transitmode" == 'tram' ]]; then
  sql="$sql""
SELECT * FROM insert_log
WHERE target LIKE '%$transitmode'
ORDER BY ts DESC
LIMIT 2;
  "
else
  sql="$sql""
SELECT * FROM insert_log
WHERE target = '$transitmode'
ORDER BY ts DESC
LIMIT 1;
  "
fi

cat "$1" | psql -w -h localhost -p 5431 -d hfp -U postgres -c "$sql"
