CREATE TABLE IF NOT EXISTS workflow_runs (
  time            TIMESTAMPTZ       NOT NULL,
  repository_name TEXT              NOT NULL,
  workflow_name    TEXT              NOT NULL,
  duration        INT               NULL
)
WITH (
  timescaledb.hypertable,
  timescaledb.partition_column='time',
  timescaledb.segmentby='repository_name'
);

CALL add_columnstore_policy('workflow_runs', after => INTERVAL '1d');