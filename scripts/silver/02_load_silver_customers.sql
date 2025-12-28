/*
===========================================================
 Script: 02_load_silver_customers.sql
 Layer: Silver
 Purpose:
   Populate silver.customers by integrating CRM and ERP
   customer data, applying standardization, typing, and
   basic data quality rules.

 Source Tables:
   - bronze.crm_cust_info_raw
   - bronze.erp_cust_az12_raw
   - bronze.erp_loc_a101_raw

 Target Table:
   - silver.customers

 Grain:
   One row per customer (CRM customer ID)

 Transformations:
   - Standardize gender and marital status
   - Trim customer names
   - Cast dates to DATE type
   - Enrich customers with ERP attributes

 Idempotent:
   Yes (TRUNCATE + INSERT)

===========================================================
*/


TRUNCATE TABLE silver.customers;

INSERT INTO silver.customers (
    customer_id,
    customer_key,
    first_name,
    last_name,
    gender,
    marital_status,
    birth_date,
    country,
    created_date
)
SELECT
    c.cst_id::INT                                  AS customer_id,
    c.cst_key                                     AS customer_key,
    TRIM(c.cst_firstname)                          AS first_name,
    TRIM(c.cst_lastname)                           AS last_name,

    -- Gender standardization
    CASE
        WHEN LOWER(c.cst_gndr) IN ('m', 'male') THEN 'Male'
        WHEN LOWER(c.cst_gndr) IN ('f', 'female') THEN 'Female'
        ELSE 'Unknown'
    END                                            AS gender,

    -- Marital status standardization
    CASE
        WHEN LOWER(c.cst_marital_status) = 'm' THEN 'Married'
        WHEN LOWER(c.cst_marital_status) = 's' THEN 'Single'
        ELSE 'Unknown'
    END                                            AS marital_status,

    -- ERP enrichment
    NULLIF(e.bdate, '')::DATE                      AS birth_date,
    l.cntry                                        AS country,

    c.cst_create_date::DATE                        AS created_date

FROM bronze.crm_cust_info_raw c
LEFT JOIN bronze.erp_cust_az12_raw e
       ON c.cst_id = e.cid
LEFT JOIN bronze.erp_loc_a101_raw l
       ON c.cst_id = l.cid;
