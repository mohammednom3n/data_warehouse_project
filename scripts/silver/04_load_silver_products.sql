/*
===========================================================
 Script: 04_load_silver_products.sql
 Layer: Silver
 Purpose:
   Populate silver.products by integrating CRM product data
   with ERP category information, applying standardization,
   typing, and basic data quality rules.

 Source Tables:
   - bronze.crm_prd_info_raw
   - bronze.erp_px_cat_g1v2_raw

 Target Table:
   - silver.products

 Grain:
   One row per product (CRM product ID)

 Transformations:
   - Trim product names
   - Cast numeric and date fields
   - Standardize maintenance flag
   - Enrich products with category and subcategory

 Idempotent:
   Yes (TRUNCATE + INSERT)

===========================================================
*/

TRUNCATE TABLE silver.products;

INSERT INTO silver.products (
    product_id,
    product_key,
    product_name,
    product_line,
    product_cost,
    category,
    subcategory,
    maintenance_flag,
    start_date,
    end_date
)
SELECT
    p.prd_id::INT                                AS product_id,
    p.prd_key                                   AS product_key,
    TRIM(p.prd_nm)                              AS product_name,
    TRIM(p.prd_line)                            AS product_line,

    -- Cost typing (default to 0 if missing)
    COALESCE(NULLIF(p.prd_cost, '')::NUMERIC, 0) AS product_cost,

    -- ERP category enrichment
    TRIM(e.cat)                                 AS category,
    TRIM(e.subcat)                              AS subcategory,

    -- Maintenance flag standardization
    CASE
        WHEN LOWER(e.maintenance) IN ('y', 'yes', 'true', '1') THEN TRUE
        WHEN LOWER(e.maintenance) IN ('n', 'no', 'false', '0') THEN FALSE
        ELSE NULL
    END                                         AS maintenance_flag,

    -- Product lifecycle dates
    p.prd_start_dt::DATE                        AS start_date,
    p.prd_end_dt::DATE                          AS end_date

FROM bronze.crm_prd_info_raw p
LEFT JOIN bronze.erp_px_cat_g1v2_raw e
       ON p.prd_key = e.id;
