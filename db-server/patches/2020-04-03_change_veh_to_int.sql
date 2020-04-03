/*
 * This patch changes the "veh" field from smallint to integer.
 *
 * Arttu K 2020-04-03
 */
\set ON_ERROR_STOP on

BEGIN;

SET CONSTRAINTS ALL DEFERRED;

ALTER TABLE bus ALTER COLUMN veh SET DATA TYPE integer;
ALTER TABLE tl_bus ALTER COLUMN veh SET DATA TYPE integer;
ALTER TABLE tram ALTER COLUMN veh SET DATA TYPE integer;
ALTER TABLE tl_tram ALTER COLUMN veh SET DATA TYPE integer;
ALTER TABLE metro ALTER COLUMN veh SET DATA TYPE integer;
ALTER TABLE train ALTER COLUMN veh SET DATA TYPE integer;

COMMIT;
