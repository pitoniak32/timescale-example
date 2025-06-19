
-- Check compression savings for a table
SELECT pg_size_pretty(before_compression_total_bytes) AS "before",
pg_size_pretty(after_compression_total_bytes) AS "after"
FROM hypertable_compression_stats('github_workflow_runs');

-- Get info about jobs setup on your database
SELECT * FROM timescaledb_information.jobs;