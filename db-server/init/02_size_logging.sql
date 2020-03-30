/*
 * Tables and functions for regular row count and table size logging.
 */

CREATE TABLE table_sizes (
  ts              timestamptz   DEFAULT now(),
  table_name      text,
  table_bytes     bigint,
  index_bytes     bigint,
  toast_bytes     bigint,
  total_bytes     bigint
);

CREATE INDEX ON table_sizes USING BRIN(ts);

CREATE FUNCTION save_current_table_sizes()
RETURNS VOID
LANGUAGE PLPGSQL
VOLATILE
AS $$
BEGIN
  INSERT INTO table_sizes (table_name, table_bytes, index_bytes, toast_bytes, total_bytes)
  (
    SELECT 'bus' AS table_name, table_bytes, index_bytes, toast_bytes, total_bytes
    FROM hypertable_relation_size('bus')
    UNION
    SELECT 'tl_bus' AS table_name, table_bytes, index_bytes, toast_bytes, total_bytes
    FROM hypertable_relation_size('tl_bus')
    UNION
    SELECT 'tram' AS table_name, table_bytes, index_bytes, toast_bytes, total_bytes
    FROM hypertable_relation_size('tram')
    UNION
    SELECT 'tl_tram' AS table_name, table_bytes, index_bytes, toast_bytes, total_bytes
    FROM hypertable_relation_size('tl_tram')
    UNION
    SELECT 'metro' AS table_name, table_bytes, index_bytes, toast_bytes, total_bytes
    FROM hypertable_relation_size('metro')
    UNION
    SELECT 'train' AS table_name, table_bytes, index_bytes, toast_bytes, total_bytes
    FROM hypertable_relation_size('train')
  );
END;
$$;

CREATE TABLE row_estimates (
  ts              timestamptz   DEFAULT now(),
  table_name      text,
  row_estimate    bigint
);

CREATE INDEX ON row_estimates USING BRIN(ts);

CREATE FUNCTION save_current_row_estimates()
RETURNS VOID
LANGUAGE PLPGSQL
VOLATILE
AS $$
BEGIN
  INSERT INTO row_estimates (table_name, row_estimate)
  (
    SELECT table_name, row_estimate
    FROM hypertable_approximate_row_count('bus')
    UNION
    SELECT table_name, row_estimate
    FROM hypertable_approximate_row_count('tl_bus')
    UNION
    SELECT table_name, row_estimate
    FROM hypertable_approximate_row_count('tram')
    UNION
    SELECT table_name, row_estimate
    FROM hypertable_approximate_row_count('tl_tram')
    UNION
    SELECT table_name, row_estimate
    FROM hypertable_approximate_row_count('metro')
    UNION
    SELECT table_name, row_estimate
    FROM hypertable_approximate_row_count('train')
  );
END;
$$;
