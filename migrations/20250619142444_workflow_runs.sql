CREATE TABLE IF NOT EXISTS repositories (
  id     SERIAL PRIMARY KEY NOT NULL,
  name   TEXT               NOT NULL,
  org_id UUID               NOT NULL
);

CREATE TABLE IF NOT EXISTS workflow_runs (
  time            TIMESTAMPTZ       NOT NULL,
  repository_id   INTEGER           NOT NULL,
  workflow_name    TEXT              NOT NULL,
  duration        INTERVAL          NOT NULL,
  FOREIGN KEY (repository_id) REFERENCES repositories (id)
)
WITH (
  timescaledb.hypertable,
  timescaledb.partition_column='time',
  timescaledb.segmentby='workflow_name'
);

-- -- This columnar format enables fast scanning and aggregation, optimizing performance for analytical workloads while also saving significant storage space.
-- -- In the columnstore conversion, hypertable chunks are compressed by more than 90%, and organized for efficient, large-scale queries.
CALL add_columnstore_policy('workflow_runs', after => INTERVAL '1d');