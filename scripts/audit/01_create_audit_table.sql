/*
================================================================================
Script: 01_create_audit_table.sql
Purpose:
    Store pipeline load history and execution results.
================================================================================
*/
CREATE SCHEMA IF NOT EXISTS audit;

CREATE TABLE IF NOT EXISTS audit.load_log (
    load_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    layer_name     TEXT,
    table_name     TEXT,
    start_time     TIMESTAMP,
    end_time       TIMESTAMP,
    rows_loaded    INTEGER,
    status         TEXT,
    error_message  TEXT
);
