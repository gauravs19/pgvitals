-- ============================================================
-- 37 · EXTENSION INVENTORY
-- ============================================================
-- What    : All installed extensions with version, schema, and
--           whether a newer version is available in the catalog
-- Look for: installed_version != default_version (upgrade available);
--           extensions installed in public schema (security risk);
--           unexpected extensions you didn't knowingly install
-- Action  : Run ALTER EXTENSION <name> UPDATE; for stale versions;
--           move security-sensitive extensions to a dedicated schema
-- ============================================================

SELECT
    e.extname                                                                  AS extension,
    e.extversion                                                               AS installed_version,
    ae.default_version                                                         AS latest_version,
    e.extversion <> ae.default_version                                         AS upgrade_available,
    n.nspname                                                                  AS schema,
    e.extrelocatable                                                           AS relocatable,
    obj_description(e.oid, 'pg_extension')                                    AS description
FROM pg_extension e
JOIN pg_available_extensions ae ON ae.name = e.extname
JOIN pg_namespace n ON n.oid = e.extnamespace
ORDER BY upgrade_available DESC, e.extname;
