-- =====================================================
-- Layer: Bronze
-- Purpose: Load raw CRM and ERP source data into bronze tables
-- Rules:
--   - Truncate and reload
--   - No transformations
--   - Local files loaded using \copy
-- =====================================================


\set ON_ERROR_STOP on

BEGIN;

TRUNCATE TABLE
    bronze.crm_cust_info_raw,
    bronze.crm_prd_info_raw,
    bronze.crm_sales_details_raw,
    bronze.erp_cust_az12_raw,
    bronze.erp_loc_a101_raw,
    bronze.erp_px_cat_g1v2_raw;


-- CRM customer
SELECT clock_timestamp()::TIMESTAMP AS start_time \gset crm_

\copy bronze.crm_cust_info_raw FROM 'datasets/source_crm/cust_info.csv' CSV HEADER;

SELECT clock_timestamp()::TIMESTAMP AS end_time \gset crm_
SELECT COUNT(*)::INTEGER AS rows_loaded
FROM bronze.crm_cust_info_raw \gset crm_

CALL audit.log_load(
    'bronze',
    'crm_cust_info_raw',
    :'crm_start_time'::TIMESTAMP,
    :'crm_end_time'::TIMESTAMP,
    :crm_rows_loaded,
    'SUCCESS'
);


-- CRM product
SELECT clock_timestamp()::TIMESTAMP AS start_time \gset prd_

\copy bronze.crm_prd_info_raw FROM 'datasets/source_crm/prd_info.csv' CSV HEADER;

SELECT clock_timestamp()::TIMESTAMP AS end_time \gset prd_
SELECT COUNT(*)::INTEGER AS rows_loaded
FROM bronze.crm_prd_info_raw \gset prd_

CALL audit.log_load(
    'bronze',
    'crm_prd_info_raw',
    :'prd_start_time'::TIMESTAMP,
    :'prd_end_time'::TIMESTAMP,
    :prd_rows_loaded,
    'SUCCESS'
);


-- CRM sales
SELECT clock_timestamp()::TIMESTAMP AS start_time \gset sales_

\copy bronze.crm_sales_details_raw FROM 'datasets/source_crm/sales_details.csv' CSV HEADER;

SELECT clock_timestamp()::TIMESTAMP AS end_time \gset sales_
SELECT COUNT(*)::INTEGER AS rows_loaded
FROM bronze.crm_sales_details_raw \gset sales_

CALL audit.log_load(
    'bronze',
    'crm_sales_details_raw',
    :'sales_start_time'::TIMESTAMP,
    :'sales_end_time'::TIMESTAMP,
    :sales_rows_loaded,
    'SUCCESS'
);


-- ERP customer
SELECT clock_timestamp()::TIMESTAMP AS start_time \gset erp_cust_

\copy bronze.erp_cust_az12_raw FROM 'datasets/source_erp/CUST_AZ12.csv' CSV HEADER;

SELECT clock_timestamp()::TIMESTAMP AS end_time \gset erp_cust_
SELECT COUNT(*)::INTEGER AS rows_loaded
FROM bronze.erp_cust_az12_raw \gset erp_cust_

CALL audit.log_load(
    'bronze',
    'erp_cust_az12_raw',
    :'erp_cust_start_time'::TIMESTAMP,
    :'erp_cust_end_time'::TIMESTAMP,
    :erp_cust_rows_loaded,
    'SUCCESS'
);


-- ERP location
SELECT clock_timestamp()::TIMESTAMP AS start_time \gset erp_loc_

\copy bronze.erp_loc_a101_raw FROM 'datasets/source_erp/LOC_A101.csv' CSV HEADER;

SELECT clock_timestamp()::TIMESTAMP AS end_time \gset erp_loc_
SELECT COUNT(*)::INTEGER AS rows_loaded
FROM bronze.erp_loc_a101_raw \gset erp_loc_

CALL audit.log_load(
    'bronze',
    'erp_loc_a101_raw',
    :'erp_loc_start_time'::TIMESTAMP,
    :'erp_loc_end_time'::TIMESTAMP,
    :erp_loc_rows_loaded,
    'SUCCESS'
);


-- ERP product category
SELECT clock_timestamp()::TIMESTAMP AS start_time \gset erp_px_

\copy bronze.erp_px_cat_g1v2_raw FROM 'datasets/source_erp/PX_CAT_G1V2.csv' CSV HEADER;

SELECT clock_timestamp()::TIMESTAMP AS end_time \gset erp_px_
SELECT COUNT(*)::INTEGER AS rows_loaded
FROM bronze.erp_px_cat_g1v2_raw \gset erp_px_

CALL audit.log_load(
    'bronze',
    'erp_px_cat_g1v2_raw',
    :'erp_px_start_time'::TIMESTAMP,
    :'erp_px_end_time'::TIMESTAMP,
    :erp_px_rows_loaded,
    'SUCCESS'
);

COMMIT;

SELECT * FROM audit.load_log;
