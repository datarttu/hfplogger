/*
 * This patch installs the PostGIS extension
 * and adds point geometry fields to the HFP observation tables,
 * as well as indexes on them.
 * Note that we use metric ETRS-TM35 coordinate system
 * that makes geometry operations and calculations easier than with WGS84.
 */
CREATE EXTENSION postgis;
