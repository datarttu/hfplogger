CREATE DATABASE hfp;
\c hfp;

CREATE TYPE event_type AS enum(
  'VP', 'DUE', 'ARR', 'DEP', 'ARS', 'PDE', 'PAS', 'WAIT', 'DOO', 'DOC',
  'TLR', 'TLA', 'DA', 'DOUT', 'BA', 'BOUT', 'VJA', 'VJOUT'
);
/*
Enum types that are not used yet but might be useful
in future are commented out.
*/
--CREATE TYPE journey_type AS enum('journey', 'deadrun', 'signoff');
--CREATE TYPE transport_mode AS enum('bus', 'train', 'tram', 'metro', 'ferry');
CREATE TYPE location_source AS enum('GPS', 'ODO', 'MAN', 'N/A');
--CREATE TYPE tlp_requesttype AS enum('NORMAL', 'DOOR_CLOSE',
--                                     'DOOR_OPEN', 'ADVANCE');
--CREATE TYPE tlp_prioritylevel AS enum('normal', 'high', 'norequest');
--CREATE TYPE tlp_reason AS enum('GLOBAL', 'AHEAD', 'LINE', 'PRIOEXP');

/*
"hfp" can store values from the event types that are related to
vehicle position, stop and door events on service journeys:
vp, due, arr, dep, ars, pde, pas, wait, doo, doc.
No topic fields are included, only payload fields + event type.
*/
CREATE TABLE hfp (
  event_type      event_type        NOT NULL,
  desi            text,
  dir             smallint,
  oper            smallint          NOT NULL,
  veh             smallint          NOT NULL,
  tst             timestamptz       NOT NULL,
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
  ttdep           timestamptz,
  PRIMARY KEY (tst, oper, veh, event_type)
);

/*
Timescale hypertable automatically distributes the main table into
chunk partitions.
Note that the below chunk size of 1 hour is arbitrary
and may need adjustments for better performance.
*/
SELECT create_hypertable('hfp',
                         'tst',
                         chunk_time_interval => interval '1 hour');

/*
In addition to timestamp-based queries,
oday as well as route & dir are assumed important filter attributes
for common queries.
*/
CREATE INDEX hfp_oday_idx ON hfp USING brin (oday);
CREATE INDEX hfp_route_dir_idx ON hfp (route, dir);
