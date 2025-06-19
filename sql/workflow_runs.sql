-- ----------------------------------------
-- Helpful SQL statements for workflow_runs
-- ----------------------------------------

-- BEGIN: HYPER TABLES

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

-- This columnar format enables fast scanning and aggregation, optimizing performance for analytical workloads while also saving significant storage space.
-- In the columnstore conversion, hypertable chunks are compressed by more than 90%, and organized for efficient, large-scale queries.
CALL add_columnstore_policy('workflow_runs', after => INTERVAL '1d');

-- END: HYPER TABLES

-- BEGIN: TIME BUCKETS

SELECT time_bucket('5 minutes', time) AS bucket, avg(duration)
FROM workflow_runs
JOIN repositories ON repositories.id = workflow_runs.repository_id
GROUP BY bucket
ORDER BY bucket DESC;

SELECT time_bucket('5 minutes', time) AS five_min, avg(cpu)
FROM metrics
GROUP BY five_min
ORDER BY five_min DESC LIMIT 10;

-- Grafana query
SELECT time_bucket_gapfill('$bucket_interval', time) AS time,
  (r.org_id, r.name) AS "metric",
  AVG(EXTRACT(epoch FROM duration)) AS "value"
FROM workflow_runs wr
JOIN repositories r ON wr.repository_id = r.id
WHERE repository_id in ($repository)
  AND time >= $__timeFrom()::timestamptz AND time < $__timeTo()::timestamptz
GROUP BY r.org_id, r.name, time_bucket_gapfill('$bucket_interval', time)
ORDER BY time;

-- END: TIME BUCKETS

-- BEGIN: CONTINUOUS AGGREGATES

CREATE MATERIALIZED VIEW workflow_run_duration_stats_daily
WITH (timescaledb.continuous) AS
SELECT
  time_bucket('1 day', "time") AS day,
  repository_id,
  max(duration) AS high,
  avg(duration) AS avg,
  min(duration) AS low,
  sum(duration) AS total,
  count(duration) AS count
FROM workflow_runs wr
GROUP BY day, repository_id
ORDER BY day DESC;

SELECT day, r.name AS repository_name, high, count, avg
FROM workflow_run_duration_stats_daily wrs
JOIN repositories r ON wrs.repository_id = r.id
ORDER BY day, repository_name DESC;

-- TODO: Create refresh policy for CA

SELECT * FROM workflow_run_duration_stats_daily;

-- END: CONTINUOUS AGGREGATES

-- BEGIN: GENERATE DATA

SELECT generate_series(now() - interval '1 month', now(), interval '5 minute') AS time,
        floor(random() * (3) + 1)::int as repository_id,
        make_interval(secs := (random()*100)::int) AS duration,
        md5(random()::text) AS workflow_name

-- END: GENERATE DATA

-- BEGIN: TIMESCALE HELPERS

SELECT * FROM timescaledb_information.jobs;

SELECT pg_size_pretty(before_compression_total_bytes) AS "before",
pg_size_pretty(after_compression_total_bytes) AS "after"
FROM hypertable_compression_stats('workflow_runs');

-- END: TIMESCALE HELPERS
