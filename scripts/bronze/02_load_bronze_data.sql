-- =====================================================
-- Layer: Bronze
-- Purpose: Load raw CRM and ERP source data into bronze tables
-- Rules:
--   - Truncate and reload
--   - No transformations
--   - Local files loaded using \copy
-- =====================================================

TRUNCATE TABLE bronze.crm_cust_info_raw;
TRUNCATE TABLE bronze.crm_prd_info_raw;
TRUNCATE TABLE bronze.crm_sales_details_raw;
TRUNCATE TABLE bronze.erp_cust_az12_raw;
TRUNCATE TABLE bronze.erp_loc_a101_raw;
TRUNCATE TABLE bronze.erp_px_cat_g1v2_raw;

\copy bronze.crm_cust_info_raw FROM 'datasets/source_crm/cust_info.csv' CSV HEADER;
\copy bronze.crm_prd_info_raw FROM 'datasets/source_crm/prd_info.csv' CSV HEADER;
\copy bronze.crm_sales_details_raw FROM 'datasets/source_crm/sales_details.csv' CSV HEADER;
\copy bronze.erp_cust_az12_raw FROM 'datasets/source_erp/CUST_AZ12.csv' CSV HEADER;
\copy bronze.erp_loc_a101_raw FROM 'datasets/source_erp/LOC_A101.csv' CSV HEADER;
\copy bronze.erp_px_cat_g1v2_raw FROM 'datasets/source_erp/PX_CAT_G1V2.csv' CSV HEADER;