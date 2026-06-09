-- ============================================================
-- 40 · SCHEMA SIZE BREAKDOWN
-- ============================================================
-- What    : Storage consumed per schema — tables, indexes, and TOAST
-- Look for: Schemas growing unexpectedly (shadow tables, audit logs);
--           high index_size / table_size ratio (over-indexed schemas);
--           large toast_size relative to table_size (wide column schemas)
-- Action  : Investigate largest schemas for bloat (run 11, 12);
--           review index coverage for schemas with index_pct > 60%
-- ============================================================

SELECT
    n.nspname                                                                  AS schema,
    count(c.oid)                                                               AS table_count,
    pg_size_pretty(
        sum(pg_total_relation_size(c.oid))
    )                                                                          AS total_size,
    pg_size_pretty(
        sum(pg_relation_size(c.oid))
    )                                                                          AS table_size,
    pg_size_pretty(
        sum(pg_indexes_size(c.oid))
    )                                                                          AS index_size,
    pg_size_pretty(
        sum(pg_total_relation_size(c.oid))
        - sum(pg_relation_size(c.oid))
        - sum(pg_indexes_size(c.oid))
    )                                                                          AS toast_size,
    round(
        sum(pg_indexes_size(c.oid))::numeric
        / nullif(sum(pg_total_relation_size(c.oid)), 0) * 100, 1
    )                                                                          AS index_pct
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'r'
  AND n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
GROUP BY n.nspname
ORDER BY sum(pg_total_relation_size(c.oid)) DESC;
