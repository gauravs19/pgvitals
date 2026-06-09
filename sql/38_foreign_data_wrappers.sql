-- ============================================================
-- 38 · FOREIGN DATA WRAPPERS & FOREIGN TABLES
-- ============================================================
-- What    : FDW servers, user mappings, and foreign tables
-- Look for: Stale or unconfigured user mappings (broken cross-DB links);
--           foreign tables with no active server (queries will error);
--           unexpected remote servers you don't recognise
-- Action  : DROP SERVER <name> CASCADE for decommissioned remotes;
--           verify user mapping credentials are still valid;
--           audit foreign table ownership for access-control gaps
-- ============================================================

SELECT
    fs.srvname                                                                 AS server_name,
    fdw.fdwname                                                                AS fdw_type,
    fs.srvoptions                                                              AS server_options,
    ft.foreign_table_schema,
    ft.foreign_table_name,
    ft.foreign_server_name,
    um.umoptions                                                               AS user_mapping_options
FROM information_schema.foreign_tables ft
JOIN pg_foreign_server fs ON fs.srvname = ft.foreign_server_name
JOIN pg_foreign_data_wrapper fdw ON fdw.oid = fs.srvfdw
LEFT JOIN pg_user_mappings um
    ON um.srvname = fs.srvname
   AND um.usename = current_user
ORDER BY fs.srvname, ft.foreign_table_schema, ft.foreign_table_name;
