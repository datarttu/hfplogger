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
CREATE TYPE tlp_requesttype AS enum('NORMAL', 'DOOR_CLOSE',
                                    'DOOR_OPEN', 'ADVANCE');
CREATE TYPE tlp_prioritylevel AS enum('normal', 'high', 'norequest');
CREATE TYPE tlp_reason AS enum('GLOBAL', 'AHEAD', 'LINE', 'PRIOEXEP');
CREATE TYPE tlp_decision AS enum('ACK', 'NAK');

/*
A simple table for logging insert events.
*/
CREATE TABLE insert_log (
  ts              timestamptz       DEFAULT now(),
  target          text,
  staging_rows    integer,
  inserted_rows   integer,
  PRIMARY KEY (target, ts)
);

CREATE FUNCTION geom_setter()
RETURNS trigger
LANGUAGE PLPGSQL
AS
$$
BEGIN
  NEW.geom := ST_Transform(
    ST_SetSRID(
      ST_MakePoint(NEW.long, NEW.lat),
      4326),
    3067);
  RETURN NEW;
END;
$$;
COMMENT ON FUNCTION geom_setter() IS
'Sets the point geometry field value of a row using `long` and `lat` coordinates.';

/*
The following tables can store values from the event types that are related to
vehicle position, stop and door events on service journeys:
vp, due, arr, dep, ars, pde, pas, wait, doo, doc.
No topic fields are included, only payload fields + event type.
*/
CREATE TABLE bus (
  desi            text,
  dir             smallint,
  oper            smallint          NOT NULL,
  veh             integer           NOT NULL,
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
  -- dr-type is left out
  event_type      event_type        NOT NULL,
  received        timestamptz       NOT NULL  DEFAULT now(),
  geom            geometry(POINT, 3067),
  PRIMARY KEY (tst, oper, veh, event_type, received)
);

CREATE TRIGGER set_geom_field BEFORE INSERT ON bus FOR EACH ROW EXECUTE PROCEDURE geom_setter();

/*
Timescale hypertable automatically distributes the main table into
chunk partitions.
Note that the below chunk size of 1 hour is arbitrary
and may need adjustments for better performance.
*/
SELECT create_hypertable('bus',
                         'tst',
                         chunk_time_interval => interval '1 hour');

/*
In addition to timestamp-based queries,
oday as well as route & dir are assumed important filter attributes
for common queries.
*/
CREATE INDEX bus_oday_idx ON bus USING brin (oday);
CREATE INDEX bus_route_dir_idx ON bus (route, dir);
CREATE INDEX ON bus USING GIST (geom);

/*
Separate table for traffic light events (bus).
*/
CREATE TABLE tl_bus (
  desi            text,
  dir             smallint,
  oper            smallint          NOT NULL,
  veh             integer           NOT NULL,
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
-- dr-type is left out
  tlp_requestid   smallint,
  tlp_requesttype tlp_requesttype,
  tlp_prioritylevel tlp_prioritylevel,
  tlp_reason      tlp_reason,
  tlp_att_seq     smallint,
  tlp_decision    tlp_decision,
  sid             integer,
  signal_groupid  integer,
  tlp_signalgroupnbr integer,
  -- tlp_lineconfigid and tlp_point_configid are left out since
  -- they seem to be always empty
  -- tlp_frequency and tlp_protocol are left out for now
  event_type      event_type        NOT NULL,
  received        timestamptz       NOT NULL  DEFAULT now(),
  geom            geometry(POINT, 3067),
  PRIMARY KEY (tst, oper, veh, event_type, received)
);
CREATE TRIGGER set_geom_field BEFORE INSERT ON tl_bus FOR EACH ROW EXECUTE PROCEDURE geom_setter();
SELECT create_hypertable('tl_bus',
                         'tst',
                         chunk_time_interval => interval '1 hour');
CREATE INDEX tl_bus_oday_idx ON tl_bus USING brin (oday);
CREATE INDEX tl_bus_route_dir_idx ON tl_bus (route, dir);
CREATE INDEX ON tl_bus USING GIST (geom);

/*
Currently, data is split to tables according to the transit mode;
the table structure is the same however.
*/
CREATE TABLE tram AS (SELECT * FROM bus) WITH NO DATA;
ALTER TABLE tram ADD PRIMARY KEY (tst, oper, veh, event_type, received);
CREATE TRIGGER set_geom_field BEFORE INSERT ON tram FOR EACH ROW EXECUTE PROCEDURE geom_setter();
SELECT create_hypertable('tram',
                         'tst',
                         chunk_time_interval => interval '1 hour');
CREATE INDEX tram_oday_idx ON tram USING brin (oday);
CREATE INDEX tram_route_dir_idx ON tram (route, dir);
CREATE INDEX ON tram USING GIST (geom);

CREATE TABLE tl_tram AS (SELECT * FROM tl_bus) WITH NO DATA;
ALTER TABLE tl_tram ADD PRIMARY KEY (tst, oper, veh, event_type, received);
CREATE TRIGGER set_geom_field BEFORE INSERT ON tl_tram FOR EACH ROW EXECUTE PROCEDURE geom_setter();
SELECT create_hypertable('tl_tram',
                         'tst',
                         chunk_time_interval => interval '1 hour');
CREATE INDEX tl_tram_oday_idx ON tl_tram USING brin (oday);
CREATE INDEX tl_tram_route_dir_idx ON tl_tram (route, dir);
CREATE INDEX ON tl_tram USING GIST (geom);

CREATE TABLE train AS (SELECT * FROM bus) WITH NO DATA;
ALTER TABLE train ADD PRIMARY KEY (tst, oper, veh, event_type, received);
CREATE TRIGGER set_geom_field BEFORE INSERT ON train FOR EACH ROW EXECUTE PROCEDURE geom_setter();
SELECT create_hypertable('train',
                         'tst',
                         chunk_time_interval => interval '1 hour');
CREATE INDEX train_oday_idx ON train USING brin (oday);
CREATE INDEX train_route_dir_idx ON train (route, dir);
CREATE INDEX ON train USING GIST (geom);

CREATE TABLE metro AS (SELECT * FROM bus) WITH NO DATA;
ALTER TABLE metro ADD PRIMARY KEY (tst, oper, veh, event_type, received);
CREATE TRIGGER set_geom_field BEFORE INSERT ON metro FOR EACH ROW EXECUTE PROCEDURE geom_setter();
SELECT create_hypertable('metro',
                         'tst',
                         chunk_time_interval => interval '1 hour');
CREATE INDEX metro_oday_idx ON metro USING brin (oday);
CREATE INDEX metro_route_dir_idx ON metro (route, dir);
CREATE INDEX ON metro USING GIST (geom);
