-- =====================================================
-- Bronze Layer: Raw tables
-- Source systems: CRM, ERP
-- Rule: No transformations, TEXT columns only
-- =====================================================


CREATE TABLE IF NOT EXISTS bronze.crm_cust_info_raw (
    cst_id TEXT,
    cst_key TEXT,
    cst_firstname TEXT,
    cst_lastname TEXT,
    cst_marital_status TEXT,
    cst_gndr TEXT,
    cst_create_date TEXT
);

CREATE TABLE IF NOT EXISTS bronze.crm_prd_info_raw (
    prd_id TEXT,
    prd_key TEXT,
    prd_nm TEXT,
    prd_cost TEXT,
    prd_line TEXT,
    prd_start_dt TEXT,
    prd_end_dt TEXT
);

CREATE TABLE IF NOT EXISTS bronze.crm_sales_details_raw (
    sls_ord_num TEXT,
    sls_prd_key TEXT,
    sls_cust_id TEXT,
    sls_order_dt TEXT,
    sls_ship_dt TEXT,
    sls_due_dt TEXT,
    sls_sales TEXT,
    sls_quantity TEXT,
    sls_price TEXT
);

CREATE TABLE IF NOT EXISTS bronze.erp_cust_az12_raw (
    cid TEXT,
    bdate TEXT,
    gen TEXT
);

CREATE TABLE IF NOT EXISTS bronze.erp_loc_a101_raw (
    cid TEXT,
    cntry TEXT
);

CREATE TABLE IF NOT EXISTS bronze.erp_px_cat_g1v2_raw (
    id TEXT,
    cat TEXT,
    subcat TEXT,
    maintenance TEXT
);
