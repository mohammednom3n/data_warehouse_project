/*
===============================================================================
Script: 02_load_silver_data.sql
Layer: Silver
Purpose:
    Clean, transform, validate, and load data from the Bronze layer
    into the Silver layer.

Source:
    - bronze.crm_cust_info_raw
    - bronze.crm_prd_info_raw
    - bronze.crm_sales_details_raw
    - bronze.erp_cust_az12_raw
    - bronze.erp_loc_a101_raw
    - bronze.erp_px_cat_g1v2_raw

Target:
    - silver.crm_cust_info
    - silver.crm_prd_info
    - silver.crm_sales_details
    - silver.erp_cust_az12
    - silver.erp_loc_a101
    - silver.erp_px_cat_g1v2

Main Responsibilities:
    - Clean and standardize raw values
    - Convert TEXT columns to appropriate PostgreSQL data types
    - Handle NULL and invalid values
    - Remove duplicate records
    - Apply business rules
    - Load transformed data into Silver
    - Validate the resulting Silver data

Important Principles:
    - Bronze data is never modified.
    - Transformations happen when loading into Silver.
    - Silver should contain clean, standardized, trusted data.
    - Each table must maintain its defined grain.
    - Transformations should be deterministic and safe to rerun.

PostgreSQL Patterns Used:
    - INSERT INTO ... SELECT
    - TRIM()
    - CASE
    - NULLIF()
    - CAST / ::type
    - ROW_NUMBER() OVER (...)
    - PARTITION BY
    - ORDER BY
    - CTEs (WITH)

Rerun Strategy:
    - Silver tables are fully refreshed during development.
    - Existing Silver data is removed before reloading.
    - The load should produce the same result when run repeatedly
      against the same Bronze snapshot.

Notes:
    - Do not modify Bronze data to fix quality issues.
    - Always profile Bronze before defining transformation rules.
    - Validate the Silver result after loading.
===============================================================================
*/
;
-- ============================================================================
-- CRM CUSTOMER
-- ============================================================================

-- Full refresh: remove previous Silver data before reloading
TRUNCATE TABLE silver.crm_cust_info;

WITH ranked_customers AS (
    
    SELECT
        cst_id,
        cst_key,

    --TRIM(): remove leading/trailing spaces    
        NULLIF(TRIM(cst_firstname), '') AS first_name, -- Return NULL if the two values are equal; otherwise return the first value.
        NULLIF(TRIM(cst_lastname), '') AS last_name, 
    
    -- Standardize marital status
        CASE
            WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
            WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Maried'
            ELSE 'Unknown'
        END AS marital_status,

    -- Standardize gender
        CASE
            WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
            WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
            ELSE 'Unknown'
        END AS gender,
    
    -- Converting TEXT to DATE
        NULLIF(TRIM(cst_create_date), '')::DATE AS create_date,
    
    -- ROW_NUMBER(): rank records within each customer
    -- Latest record receives row number 1
        ROW_NUMBER() OVER (
            PARTITION BY cst_id
            ORDER BY NULLIF(TRIM(cst_create_date), '')::DATE DESC
        ) AS row_num


    FROM bronze.crm_cust_info_raw
    WHERE NULLIF(TRIM(cst_id), '') IS NOT NULL 
)

INSERT INTO silver.crm_cust_info (
    customer_id,
    customer_key,
    first_name,
    last_name,
    marital_status,
    gender,
    cst_create_date
)

SELECT
    cst_id::INT,
    TRIM(cst_key),
    first_name,
    last_name,
    marital_status,
    gender,
    create_date

FROM ranked_customers

-- Keep only the latest record for each customer
WHERE row_num = 1;



-- ============================================================================
-- CRM PRODUCTS
-- ============================================================================

TRUNCATE TABLE silver.crm_prd_info;

WITH product_data AS (
    SELECT
        prd_id::INT,
    
    -- TRIM leading/trailing space
        TRIM(prd_key) AS product_key,
        TRIM(prd_nm) AS product_name,
    
    -- Replace NULL/invalid costs with 0
        COALESCE(NULLIF(TRIM(prd_cost), '')::NUMERIC, 0) AS product_cost,
    
    -- Standardize product line values
        CASE
            WHEN TRIM(prd_line) = 'R' THEN 'Road'
            WHEN TRIM(prd_line) = 'S' THEN 'Other sales'
            WHEN TRIM(prd_line) = 'M' THEN 'Mountin'
            WHEN TRIM(prd_line) = 'T' THEN 'Touring'
            ELSE 'Unknown'
        END AS product_line,

        prd_start_dt::DATE AS start_date,
    
    -- LEAD(): get the next version's start date
    -- Current version ends one day before the next version starts
        LEAD(prd_start_dt::DATE) OVER(
            PARTITION BY prd_key
            ORDER BY prd_start_dt::DATE
        ) - INTERVAL '1 day' AS end_date

    FROM bronze.crm_prd_info_raw

)

INSERT INTO silver.crm_prd_info(
    product_id,
    product_key,
    product_name,
    product_cost,
    product_line,
    start_date,
    end_date
)

SELECT
    prd_id,
    product_key,
    product_name,
    product_cost,
    product_line,
    start_date,
    end_date
FROM 
    product_data;



-- ============================================================================
-- CRM SALES DETAILS
-- ============================================================================

-- Full refresh: remove previous Silver data before reloading
TRUNCATE TABLE silver.crm_sales_details;

WITH sales_data AS (

    SELECT
        -- Clean identifiers
        TRIM(sls_ord_num) AS order_number,
        TRIM(sls_prd_key) AS product_key,
        sls_cust_id::INTEGER AS customer_id,

        -- Convert YYYYMMDD text to DATE
        -- Invalid/malformed values are stored as NULL
        CASE
            WHEN TRIM(sls_order_dt) ~ '^[0-9]{8}$'
                THEN TO_DATE(TRIM(sls_order_dt), 'YYYYMMDD')
            ELSE NULL
        END AS order_date,

        CASE
            WHEN TRIM(sls_ship_dt) ~ '^[0-9]{8}$'
                THEN TO_DATE(TRIM(sls_ship_dt), 'YYYYMMDD')
            ELSE NULL
        END AS ship_date,

        CASE
            WHEN TRIM(sls_due_dt) ~ '^[0-9]{8}$'
                THEN TO_DATE(TRIM(sls_due_dt), 'YYYYMMDD')
            ELSE NULL
        END AS due_date,

        -- Calculate sales when the source value is NULL or non-positive
        -- ABS(): prevents incorrect negative prices from creating negative sales
        CASE
            WHEN NULLIF(TRIM(sls_sales), '')::NUMERIC IS NULL
                 OR NULLIF(TRIM(sls_sales), '')::NUMERIC <= 0
                THEN
                    NULLIF(TRIM(sls_quantity), '')::NUMERIC
                    * ABS(NULLIF(TRIM(sls_price), '')::NUMERIC)
            ELSE
                NULLIF(TRIM(sls_sales), '')::NUMERIC
        END AS sales_amount,

        -- Convert quantity from TEXT to INTEGER
        NULLIF(TRIM(sls_quantity), '')::INTEGER AS quantity,

        -- Calculate price when the source value is NULL or non-positive
        -- NULLIF(quantity, 0): prevents division by zero
        CASE
            WHEN NULLIF(TRIM(sls_price), '')::NUMERIC IS NULL
                 OR NULLIF(TRIM(sls_price), '')::NUMERIC <= 0
                THEN
                    ABS(NULLIF(TRIM(sls_sales), '')::NUMERIC)
                    / NULLIF(
                        NULLIF(TRIM(sls_quantity), '')::NUMERIC,
                        0
                    )
            ELSE
                NULLIF(TRIM(sls_price), '')::NUMERIC
        END AS price

    FROM bronze.crm_sales_details_raw
)

INSERT INTO silver.crm_sales_details (
    order_number,
    product_key,
    customer_id,
    order_date,
    shipping_date,
    due_date,
    sales_amount,
    quantity,
    sls_price
)


SELECT
    order_number,
    product_key,
    customer_id,
    order_date,
    ship_date,
    due_date,
    sales_amount,
    quantity,
    price

FROM sales_data;


-- ============================================================================
-- ERP CUSTOMER DEMOGRAPHICS
-- ============================================================================

-- Full refresh: remove previous Silver data before reloading
TRUNCATE TABLE silver.erp_cust_az12;

WITH customer_data AS (

    SELECT
        -- Clean customer key
        TRIM(cid) AS customer_key,

        -- Convert birth date from TEXT to DATE
        TRIM(bdate)::DATE AS birth_date,

        -- Standardize gender values
        CASE
            WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
            WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
            ELSE 'Unknown'
        END AS gender

    FROM bronze.erp_cust_az12_raw
)

INSERT INTO silver.erp_cust_az12 (
    customer_key,
    birth_date,
    gender
)

SELECT
    customer_key,
    birth_date,
    gender

FROM customer_data;


-- ============================================================================
-- ERP CUSTOMER LOCATION
-- ============================================================================

-- Full refresh: remove previous Silver data before reloading
TRUNCATE TABLE silver.erp_loc_a101;

WITH location_data AS (

    SELECT
        -- Clean customer key
        TRIM(cid) AS customer_key,

        -- Standardize country names and abbreviations
        CASE
            WHEN UPPER(TRIM(cntry)) IN ('US', 'USA', 'UNITED STATES')
                THEN 'United States'
            WHEN UPPER(TRIM(cntry)) = 'DE'
                THEN 'Germany'
            WHEN NULLIF(TRIM(cntry), '') IS NULL
                THEN 'Unknown'
            ELSE TRIM(cntry)
        END AS country

    FROM bronze.erp_loc_a101_raw
)

INSERT INTO silver.erp_loc_a101 (
    customer_key,
    country
)

SELECT
    customer_key,
    country

FROM location_data;


-- ============================================================================
-- ERP PRODUCT CATEGORY
-- ============================================================================

-- Full refresh: remove previous Silver data before reloading
TRUNCATE TABLE silver.erp_px_cat_g1v2;

WITH category_data AS (

    SELECT
        id AS category_id,
        cat AS category,
        subcat AS subcategory,
        maintenance

    FROM bronze.erp_px_cat_g1v2_raw
)

INSERT INTO silver.erp_px_cat_g1v2 (
    product_category_key,
    category,
    subcategory,
    maintenance
)

SELECT
    category_id,
    category,
    subcategory,
    maintenance

FROM category_data;




