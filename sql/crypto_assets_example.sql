CREATE TABLE crypto_ticks (
  "time" TIMESTAMPTZ,
  symbol TEXT,
  price DOUBLE PRECISION,
  day_volume NUMERIC
) WITH (
   tsdb.hypertable,
   tsdb.partition_column='time',
   tsdb.segmentby = 'symbol'
);

CREATE INDEX ix_symbol_time ON crypto_ticks (symbol, time DESC);

CREATE TABLE crypto_assets (
 symbol TEXT NOT NULL,
 name TEXT NOT NULL
);

SELECT * FROM crypto_ticks srt
WHERE symbol='ETH/USD'
ORDER BY time DESC
LIMIT 10;

CALL add_columnstore_policy('crypto_ticks', after => INTERVAL '1d');

CREATE MATERIALIZED VIEW assets_candlestick_daily
WITH (timescaledb.continuous) AS
SELECT
  time_bucket('1 day', "time") AS day,
  symbol,
  max(price) AS high,
  first(price, time) AS open,
  last(price, time) AS close,
  min(price) AS low
FROM crypto_ticks srt
GROUP BY day, symbol;


SELECT add_continuous_aggregate_policy('assets_candlestick_daily',
start_offset => INTERVAL '3 weeks',
end_offset => INTERVAL '24 hours',
schedule_interval => INTERVAL '3 hours');

SELECT * FROM assets_candlestick_daily
ORDER BY day DESC, symbol
LIMIT 10;

SELECT pg_size_pretty(before_compression_total_bytes) AS "before",
pg_size_pretty(after_compression_total_bytes) AS "after"
FROM hypertable_compression_stats('crypto_ticks');