/*
================================================================================
Script: 01_create_audit_table.sql
Purpose:
    Store pipeline load history and execution results.
================================================================================
*/

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

SELECT *
FROm audit.load_log

INSERT INTO audit.load_log (
    layer_name,
    table_name,
    start_time,
    end_time,
    rows_loaded,
    status
    )

VALUES (
    'Silver',
    'crm_cust_info',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    '15007',
    'SUCCESS'
);