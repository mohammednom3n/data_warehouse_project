/*
================================================================================
Script: 02_create_log_procedure.sql
Purpose:
    Create a reusable procedure for recording pipeline load results.
================================================================================
*/

CREATE OR REPLACE PROCEDURE audit.log_load(
    p_layer_name   TEXT,
    p_table_name   TEXT,
    p_start_time   TIMESTAMP,
    p_end_time     TIMESTAMP,
    p_rows_loaded  INTEGER,
    p_status       TEXT,
    p_error_message TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO audit.load_log (
        layer_name,
        table_name,
        start_time,
        end_time,
        rows_loaded,
        status,
        error_message
    )
    VALUES (
        p_layer_name,
        p_table_name,
        p_start_time,
        p_end_time,
        p_rows_loaded,
        p_status,
        p_error_message
    );

END;
$$;
