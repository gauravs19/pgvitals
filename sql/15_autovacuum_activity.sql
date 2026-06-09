-- ============================================================
-- 15 · AUTOVACUUM WORKER ACTIVITY (LIVE)
-- ============================================================
-- What    : Vacuum workers currently running and their progress
-- Look for: Stuck workers (pct_done not advancing over time)
--           index_vacuum_count = 0 on large tables
-- Action  : Check autovacuum_max_workers; investigate I/O contention
-- ============================================================

SELECT
    pid,
    datname,
    relid::regclass                                                    AS table_name,
    phase,
    heap_blks_total,
    heap_blks_scanned,
    heap_blks_vacuumed,
    round(
        heap_blks_vacuumed::numeric / nullif(heap_blks_total, 0) * 100, 2
    )                                                                  AS pct_done,
    index_vacuum_count,
    coalesce(
        (to_jsonb(v) ->> 'max_dead_tuples')::bigint,
        (to_jsonb(v) ->> 'max_dead_tuple_bytes')::bigint
    )                                                                  AS max_dead_tuples_or_bytes,
    coalesce(
        (to_jsonb(v) ->> 'num_dead_tuples')::bigint,
        (to_jsonb(v) ->> 'num_dead_item_ids')::bigint
    )                                                                  AS num_dead_tuples_or_ids
FROM pg_stat_progress_vacuum v;

-- How many autovacuum workers are currently active
SELECT count(*) AS active_autovacuum_workers
FROM pg_stat_activity
WHERE backend_type = 'autovacuum worker';
