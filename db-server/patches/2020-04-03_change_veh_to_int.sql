/*
 * This patch changes the "veh" field from smallint to integer.
 * NOTE: This does not seem to work with fully populated database
 *       due to memory / disk space issues.
 *
 * Arttu K 2020-04-03, 2020-06-05
 */
\set ON_ERROR_STOP on

ALTER TABLE bus ALTER COLUMN veh SET DATA TYPE integer;
ALTER TABLE tl_bus ALTER COLUMN veh SET DATA TYPE integer;
ALTER TABLE tram ALTER COLUMN veh SET DATA TYPE integer;
ALTER TABLE tl_tram ALTER COLUMN veh SET DATA TYPE integer;
ALTER TABLE metro ALTER COLUMN veh SET DATA TYPE integer;
ALTER TABLE train ALTER COLUMN veh SET DATA TYPE integer;
