/*
 * This patch installs the PostGIS extension
 * and adds point geometry fields to the HFP observation tables,
 * as well as indexes on them.
 * Note that we use metric ETRS-TM35 coordinate system
 * that makes geometry operations and calculations easier than with WGS84.
 * An UPDATE statement is a heavy operation on large tables,
 * so we do not do it here.
 * Instead, new data being imported after running this patch will get geometry values.
 */
BEGIN;

CREATE EXTENSION IF NOT EXISTS postgis;

DROP FUNCTION IF EXISTS geom_setter();
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

ALTER TABLE bus ADD COLUMN geom geometry(POINT, 3067);
CREATE TRIGGER set_geom_field BEFORE INSERT ON bus FOR EACH ROW EXECUTE PROCEDURE geom_setter();
CREATE INDEX ON bus USING GIST (geom);

ALTER TABLE tl_bus ADD COLUMN geom geometry(POINT, 3067);
CREATE TRIGGER set_geom_field BEFORE INSERT ON tl_bus FOR EACH ROW EXECUTE PROCEDURE geom_setter();
CREATE INDEX ON tl_bus USING GIST (geom);

ALTER TABLE tram ADD COLUMN geom geometry(POINT, 3067);
CREATE TRIGGER set_geom_field BEFORE INSERT ON tram FOR EACH ROW EXECUTE PROCEDURE geom_setter();
CREATE INDEX ON tram USING GIST (geom);

ALTER TABLE tl_tram ADD COLUMN geom geometry(POINT, 3067);
CREATE TRIGGER set_geom_field BEFORE INSERT ON tl_tram FOR EACH ROW EXECUTE PROCEDURE geom_setter();
CREATE INDEX ON tl_tram USING GIST (geom);

ALTER TABLE train ADD COLUMN geom geometry(POINT, 3067);
CREATE TRIGGER set_geom_field BEFORE INSERT ON train FOR EACH ROW EXECUTE PROCEDURE geom_setter();
CREATE INDEX ON train USING GIST (geom);

ALTER TABLE metro ADD COLUMN geom geometry(POINT, 3067);
CREATE TRIGGER set_geom_field BEFORE INSERT ON metro FOR EACH ROW EXECUTE PROCEDURE geom_setter();
CREATE INDEX ON metro USING GIST (geom);

COMMIT;
