-- ============================================================
-- 31 · CHECKPOINT & WAL PRESSURE
-- ============================================================
-- What    : Whether checkpoints are forced too frequently and
--           whether backends are writing directly to WAL
-- Look for: forced_pct > 10% → increase max_wal_size
--           buffers_backend_fsync > 0 → critical, backends are
--           fsyncing (shared_buffers or bgwriter can't keep up)
-- Action  : Increase max_wal_size; set checkpoint_completion_target=0.9
-- ============================================================

WITH checkpointer_data AS (
    SELECT
        coalesce(
            (to_jsonb(bg) ->> 'checkpoints_timed')::bigint,
            (SELECT (xpath('/row/num_timed/text()', x))[1]::text::bigint
             FROM (SELECT unnest(xpath('/table/row', query_to_xml('SELECT num_timed FROM pg_stat_checkpointer', true, false, ''))) AS x) AS f)
        ) AS checkpoints_timed,
        coalesce(
            (to_jsonb(bg) ->> 'checkpoints_req')::bigint,
            (SELECT (xpath('/row/num_requested/text()', x))[1]::text::bigint
             FROM (SELECT unnest(xpath('/table/row', query_to_xml('SELECT num_requested FROM pg_stat_checkpointer', true, false, ''))) AS x) AS f)
        ) AS checkpoints_req,
        coalesce(
            (to_jsonb(bg) ->> 'checkpoint_write_time')::numeric,
            (SELECT (xpath('/row/write_time/text()', x))[1]::text::numeric
             FROM (SELECT unnest(xpath('/table/row', query_to_xml('SELECT write_time FROM pg_stat_checkpointer', true, false, ''))) AS x) AS f)
        ) AS checkpoint_write_time,
        coalesce(
            (to_jsonb(bg) ->> 'checkpoint_sync_time')::numeric,
            (SELECT (xpath('/row/sync_time/text()', x))[1]::text::numeric
             FROM (SELECT unnest(xpath('/table/row', query_to_xml('SELECT sync_time FROM pg_stat_checkpointer', true, false, ''))) AS x) AS f)
        ) AS checkpoint_sync_time,
        coalesce(
            (to_jsonb(bg) ->> 'buffers_checkpoint')::bigint,
            (SELECT (xpath('/row/buffers_written/text()', x))[1]::text::bigint
             FROM (SELECT unnest(xpath('/table/row', query_to_xml('SELECT buffers_written FROM pg_stat_checkpointer', true, false, ''))) AS x) AS f)
        ) AS buffers_checkpoint,
        coalesce(
            (to_jsonb(bg) ->> 'buffers_backend')::bigint,
            (SELECT (xpath('/row/buffers/text()', x))[1]::text::bigint
             FROM (SELECT unnest(xpath('/table/row', query_to_xml('SELECT sum(writes) AS buffers FROM pg_stat_io WHERE context = ''normal'' AND object = ''relation''', true, false, ''))) AS x) AS f)
        ) AS buffers_backend,
        coalesce(
            (to_jsonb(bg) ->> 'buffers_backend_fsync')::bigint,
            (SELECT (xpath('/row/fsyncs/text()', x))[1]::text::bigint
             FROM (SELECT unnest(xpath('/table/row', query_to_xml('SELECT sum(fsyncs) AS fsyncs FROM pg_stat_io WHERE context = ''normal'' AND object = ''relation''', true, false, ''))) AS x) AS f)
        ) AS buffers_backend_fsync,
        buffers_clean,
        maxwritten_clean,
        buffers_alloc,
        now() - stats_reset AS stats_age
    FROM pg_stat_bgwriter bg
)
SELECT
    checkpoints_timed,
    checkpoints_req,
    round(
        checkpoints_req::numeric
        / nullif(checkpoints_timed + checkpoints_req, 0) * 100, 2
    )                                                                 AS forced_pct,
    round((checkpoint_write_time / 1000)::numeric, 2)                AS write_time_sec,
    round((checkpoint_sync_time / 1000)::numeric, 2)                 AS sync_time_sec,
    buffers_checkpoint,
    buffers_clean,
    maxwritten_clean,
    buffers_backend,
    buffers_backend_fsync,
    buffers_alloc,
    stats_age
FROM checkpointer_data;
