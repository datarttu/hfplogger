/*
 * This patch adds the "received" timestamptz field to the existing tables
 * and makes it part of their composite primary keys.
 *
 * Arttu K 2020-03-31
 */
\set ON_ERROR_STOP on

BEGIN;

SET CONSTRAINTS ALL DEFERRED;

ALTER TABLE bus ADD COLUMN received timestamptz DEFAULT now();
ALTER TABLE bus DROP CONSTRAINT bus_pkey;
ALTER TABLE bus ADD PRIMARY KEY (tst, oper, veh, event_type, received);

ALTER TABLE tl_bus ADD COLUMN received timestamptz DEFAULT now();
ALTER TABLE tl_bus DROP CONSTRAINT tl_bus_pkey;
ALTER TABLE tl_bus ADD PRIMARY KEY (tst, oper, veh, event_type, received);

ALTER TABLE tram ADD COLUMN received timestamptz DEFAULT now();
ALTER TABLE tram DROP CONSTRAINT tram_pkey;
ALTER TABLE tram ADD PRIMARY KEY (tst, oper, veh, event_type, received);

ALTER TABLE tl_tram ADD COLUMN received timestamptz DEFAULT now();
ALTER TABLE tl_tram DROP CONSTRAINT tl_tram_pkey;
ALTER TABLE tl_tram ADD PRIMARY KEY (tst, oper, veh, event_type, received);

ALTER TABLE metro ADD COLUMN received timestamptz DEFAULT now();
ALTER TABLE metro DROP CONSTRAINT metro_pkey;
ALTER TABLE metro ADD PRIMARY KEY (tst, oper, veh, event_type, received);

ALTER TABLE train ADD COLUMN received timestamptz DEFAULT now();
ALTER TABLE train DROP CONSTRAINT train_pkey;
ALTER TABLE train ADD PRIMARY KEY (tst, oper, veh, event_type, received);

COMMIT;
