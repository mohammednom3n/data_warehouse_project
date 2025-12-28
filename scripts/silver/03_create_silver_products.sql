/*
===========================================================
 Script: 03_create_silver_products.sql
 Layer: Silver
 Purpose:
   Create the silver.products table containing a clean,
   integrated, entity-centric view of products.

 Source Tables:
   - bronze.crm_prd_info_raw
   - bronze.erp_px_cat_g1v2_raw

 Target Table:
   - silver.products

 Grain:
   One row per product (CRM product ID)

===========================================================
*/

CREATE TABLE IF NOT EXISTS silver.products (
    product_id          INT PRIMARY KEY,
    product_key         TEXT,
    product_name        TEXT,
    product_line        TEXT,
    product_cost        NUMERIC(12,2),
    category            TEXT,
    subcategory         TEXT,
    maintenance_flag    BOOLEAN,
    start_date          DATE,
    end_date            DATE
)