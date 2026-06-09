-- ============================================================
-- 39 · FUNCTION PERFORMANCE (PL/pgSQL & STORED PROCEDURES)
-- ============================================================
-- What    : Execution stats for user-defined functions and procedures
-- Look for: High total_time (top CPU consumers by function);
--           high self_time / total_time ratio (time inside the function,
--           not in callees — indicates inefficient function body);
--           high calls with low mean_ms (tight hot-loop candidates)
-- Action  : Profile the body of high-self_time functions;
--           cache repeated lookups; consider set-returning SQL rewrites
-- Requires: track_functions = 'pl' or 'all' in postgresql.conf
-- ============================================================

SELECT
    schemaname,
    funcname,
    calls,
    round(total_time::numeric, 2)                                             AS total_ms,
    round(self_time::numeric, 2)                                              AS self_ms,
    round((total_time / nullif(calls, 0))::numeric, 3)                        AS mean_ms,
    round((self_time / nullif(total_time, 0) * 100)::numeric, 1)              AS self_pct
FROM pg_stat_user_functions
WHERE calls > 0
ORDER BY total_time DESC
LIMIT 25;
