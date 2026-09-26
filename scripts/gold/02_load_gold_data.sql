/*
================================================================================
Script: 02_load_gold_tables.sql
Layer: Gold
Purpose:
    Load transformed and business-ready data into the Gold layer.

Source Layer:
    - Silver

Target Tables:
    - gold.dim_customers
    - gold.dim_products
    - gold.fact_sales

Transformations:
    - Combine related Silver sources
    - Apply business logic
    - Preserve product history
    - Build relationships for analytics
================================================================================
*/

\set ON_ERROR_STOP on

BEGIN;

-- Load Gold customer dimension
SELECT clock_timestamp()::TIMESTAMP AS start_time \gset customer_

TRUNCATE TABLE gold.dim_customers;

WITH customer AS (
    SELECT
        ci.customer_id,
        ci.customer_key,
        ci.first_name,
        ci.last_name,
        ci.marital_status,
        CASE 
            WHEN ci.gender != 'Unknown' THEN ci.gender
            ELSE COALESCE (ca.gender, 'Unknown')
        END AS gender, -- I have to choose the source table ci/ca and integrate data
        ca.birth_date,
        la.country,
        ci.cst_create_date
 
    FROM silver.crm_cust_info as ci
    LEFT JOIN silver.erp_cust_az12 as ca
        ON ci.customer_key = ca.customer_key
    LEFT JOIN silver.erp_loc_a101 as la
        ON ci.customer_key = la.customer_key
)


INSERT INTO gold.dim_customers(
    customer_id,
    customer_key,
    first_name,
    last_name,
    marital_status,
    gender,
    birth_date,
    country,
    create_date
)

SELECT
    customer_id,
    customer_key,
    first_name,
    last_name,
    marital_status,
    gender,
    birth_date,
    country,
    cst_create_date
FROM customer;

SELECT clock_timestamp()::TIMESTAMP AS end_time \gset customer_

SELECT COUNT(*)::INTEGER AS rows_loaded
FROM gold.dim_customers \gset customer_

CALL audit.log_load(
    'gold',
    'dim_customers',
    :'customer_start_time'::TIMESTAMP,
    :'customer_end_time'::TIMESTAMP,
    :customer_rows_loaded,
    'SUCCESS'
);

-- Load gold product dimension
SELECT clock_timestamp()::TIMESTAMP AS start_time \gset product_

TRUNCATE TABLE gold.dim_products;

WITH product AS (

    SELECT
        cp.product_id,
        cp.category_key,
        cp.product_key,
        cp.product_name,
        cp.product_cost,
        cp.product_line,
        ep.category,
        ep.subcategory,
        ep.maintenance,
        cp.start_date,
        cp.end_date

    FROM silver.crm_prd_info AS cp
    LEFT JOIN silver.erp_px_cat_g1v2 AS ep
        ON cp.category_key = ep.category_key

)

INSERT INTO gold.dim_products(
    product_id,
    category_key,
    product_key,
    product_name,
    product_cost,
    product_line,
    category,
    subcategory,
    maintenance,
    start_date,
    end_date
)

SELECT
    product_id,
    category_key,
    product_key,
    product_name,
    product_cost,
    product_line,
    category,
    subcategory,
    maintenance,
    start_date,
    end_date
FROM product;

SELECT clock_timestamp()::TIMESTAMP AS end_time \gset product_

SELECT COUNT(*)::INTEGER AS rows_loaded
FROM gold.dim_products \gset product_

CALL audit.log_load(
    'gold',
    'dim_products',
    :'product_start_time'::TIMESTAMP,
    :'product_end_time'::TIMESTAMP,
    :product_rows_loaded,
    'SUCCESS'
);


-- Load gold fact table
SELECT clock_timestamp()::TIMESTAMP AS start_time \gset sales_

TRUNCATE gold.fact_sales;

INSERT INTO gold.fact_sales (
    order_number,
    product_key,
    customer_id,
    order_date,
    shipping_date,
    due_date,
    sales_amount,
    quantity,
    price
)

SELECT
    order_number,
    product_key,
    customer_id,
    order_date,
    shipping_date,
    due_date,
    sales_amount,
    quantity,
    sls_price
FROM silver.crm_sales_details;

SELECT clock_timestamp()::TIMESTAMP AS end_time \gset sales_

SELECT COUNT(*)::INTEGER AS rows_loaded
FROM gold.fact_sales \gset sales_

CALL audit.log_load(
    'gold',
    'fact_sales',
    :'sales_start_time'::TIMESTAMP,
    :'sales_end_time'::TIMESTAMP,
    :sales_rows_loaded,
    'SUCCESS'
);

COMMIT;
