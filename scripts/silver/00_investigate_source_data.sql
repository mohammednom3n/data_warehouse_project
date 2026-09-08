-- ============================================================================
-- CRM CUSTOMERS
-- ============================================================================

-- 1.Inspect customers data before defining transformation rules

SELECT *
FROM bronze.crm_cust_info_raw
LIMIT 1000;

-- 2. Check total rows

SELECT COUNT(*) AS total_row
FROM bronze.crm_cust_info_raw;

-- 3. Check for duplicate cst_id

SELECT
    cst_id,
    COUNT(*) AS record_count
FROM bronze.crm_cust_info_raw
GROUP BY cst_id
HAVING COUNT(*) > 1
ORDER BY record_count DESC;

-- 4. Check for NULL cst_id's

SELECT COUNT(*) AS null_cst_id
FROM bronze.crm_cust_info_raw
WHERE NULLIF(TRIM(cst_id), '') IS NULL;

-- 5. Then inspect the categorical columns

SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info_raw
ORDER BY cst_gndr;

SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info_raw
ORDER BY cst_marital_status;

-- 6. Inspect possible whitespace problems

SELECT 
    cst_id,
    cst_firstname,
    cst_lastname
FROM bronze.crm_cust_info_raw
WHERE 
    cst_firstname <> TRIM(cst_firstname) -- to compare original fname with trimmed version.
    OR cst_lastname <> TRIM(cst_lastname) -- <> means 'not equal to' in SQL

-- Investigate

SELECT *
FROM bronze.crm_cust_info_raw
WHERE cst_id IN ('29466', '29483', '29473', '29433', '29449')
ORDER BY cst_id;

SELECT *
FROM bronze.crm_cust_info_raw
WHERE cst_id IS NULL;

-- Check data types

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'bronze'
  AND table_name = 'crm_cust_info_raw'
ORDER BY ordinal_position;


-- ============================================================================
-- CRM PRODUCTS
-- ============================================================================

-- Inspect product data before defining transformation rules
SELECT *
FROM bronze.crm_prd_info_raw
LIMIT 20;

-- check for total rows
SELECT COUNT(*) AS total_rows
FROM bronze.crm_prd_info _raw;

-- Check for NULL product IDs
SELECT COUNT(*) AS null_product_ids
FROM bronze.crm_prd_info_raw
WHERE NULLIF(TRIM(prd_id), '') IS NULL;

-- check for duplicate prd_id
SELECT 
    prd_id,
    COUNT(*) AS record_count
FROM bronze.crm_prd_info_raw
GROUP BY prd_id
HAVING COUNT(*) > 1;

-- check for duplicate prd_key
SELECT 
    prd_key,
    COUNT(*) AS record_count
FROM bronze.crm_prd_info_raw
GROUP BY prd_key
HAVING COUNT(*) > 1
ORDER BY record_count DESC;

-- check for whitespace in product fields
SELECT
    prd_id,
    prd_key,
    prd_nm
FROM bronze.crm_prd_info_raw
WHERE prd_key <> TRIM(prd_key) 
   OR prd_nm <> TRIM(prd_nm)
   OR prd_id <> TRIM(prd_id);

-- check product date range
SELECT
    MIN(prd_start_dt) AS earliest_start,
    MAX(prd_start_dt) AS latest_start,
    MIN(prd_end_dt) AS earliest_end,
    MAX(prd_end_dt) AS latest_end
FROM bronze.crm_prd_info_raw;

-- check for NULL/negative product costs
SELECT
    COUNT(*) FILTER (WHERE prd_cost IS NULL) AS null_cost,
    COUNT(*) FILTER (WHERE prd_cost::NUMERIC < 0 ) AS negative_cost
FROM bronze.crm_prd_info_raw;

-- Check distinct product line values
SELECT DISTINCT
    TRIM(prd_line) AS product_line
FROM bronze.crm_prd_info_raw
ORDER BY product_line;

-- check for whitespace in product fields
SELECT prd_line
FROM bronze.crm_prd_info_raw
WHERE prd_line <> TRIM(prd_line);

-- Check for invalid date ranges
SELECT C
FROM bronze.crm_prd_info_raw
WHERE prd_start_dt::DATE > prd_end_dt::DATE
ORDER BY
LIMIT 20;

-- LEAD(): gets the value from the next row within each product
-- Used here to determine when the current product version should end

SELECT
    prd_key,
    prd_start_dt::DATE AS start_date,

    LEAD(prd_start_dt::DATE) OVER (
        PARTITION BY prd_key
        ORDER BY prd_start_dt::DATE
    ) AS next_start_date

FROM bronze.crm_prd_info_raw
ORDER BY prd_key, start_date;




-- ============================================================================
-- CRM SALES DETAILS
-- ============================================================================

-- Inspect sales data before defining transformation rules
SELECT *
FROM bronze.crm_sales_details_raw
LIMIT 20;

-- Check for NULLs in sls_ord_num | No NULLS
SELECT COUNT(*) AS null_order_numbers
FROM bronze.crm_sales_details_raw
WHERE NULLIF(TRIM(sls_ord_num), '') IS NULL;


-- Check for duplicate order number

SELECT 
    sls_ord_num,
    COUNT(*) AS count
FROM bronze.crm_sales_details_raw
GROUP BY sls_ord_num
HAVING COUNT(*) > 1
ORDER BY count DESC;

-- Check whether order + product uniquely identifies a sales line
SELECT
    sls_ord_num,
    sls_prd_key,
    COUNT(*) AS count
FROM bronze.crm_sales_details_raw
GROUP BY sls_ord_num, sls_prd_key
HAVING COUNT(*) > 1
ORDER BY count DESC;

-- Check for NULL dates
SELECT
    COUNT(*) FILTER (WHERE NULLIF(TRIM(sls_order_dt), '') IS NULL) AS null_order_date,
    COUNT(*) FILTER (WHERE NULLIF(TRIM(sls_ship_dt), '') IS NULL) AS null_ship_date,
    COUNT(*) FILTER (WHERE NULLIF(TRIM(sls_due_dt), '') IS NULL) AS null_due_date
FROM bronze.crm_sales_details_raw;

-- Check for invalid date sequences
SELECT *
FROM bronze.crm_sales_details_raw
WHERE TRIM(sls_order_dt)::DATE < TRIM(sls_ship_dt)::DATE
   OR TRIM(sls_ship_dt)::DATE < TRIM(sls_due_dt)::DATE;

-- Check for invalid date sequences
SELECT *
FROM bronze.crm_sales_details_raw
WHERE sls_order_dt::DATE > sls_ship_dt::DATE
   OR sls_ship_dt::DATE > sls_due_dt::DATE;


-- Check for invalid date sequences
SELECT *
FROM bronze.crm_sales_details_raw
WHERE to_date(NULLIF(TRIM(sls_order_dt), '0'), 'YYYYMMDD') 
        > to_date(NULLIF(TRIM(sls_ship_dt), '0'), 'YYYYMMDD') 
   OR to_date(NULLIF(TRIM(sls_ship_dt), '0'), 'YYYYMMDD') 
        > to_date(NULLIF(TRIM(sls_due_dt), '0'), 'YYYYMMDD') 


SELECT
    sls_order_dt,
    COUNT(*) AS record_count
FROM bronze.crm_sales_details_raw
WHERE LENGTH(TRIM(sls_order_dt)) <> 8
GROUP BY sls_order_dt
ORDER BY record_count DESC;

SELECT
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt
FROM bronze.crm_sales_details_raw
WHERE LENGTH(TRIM(sls_order_dt)) <> 8;

-- Check for NULL and negative numeric values

SELECT
    COUNT(*) FILTER (WHERE NULLIF(TRIM(sls_sales), '') IS NULL) AS null_sales, 
    COUNT(*) FILTER (WHERE NULLIF(TRIM(sls_quantity), '') IS NULL) AS null_quantities, 
    COUNT(*) FILTER (WHERE NULLIF(TRIM(sls_price), '') IS NULL) AS null_prices, 
    
    COUNT(*) FILTER (WHERE NULLIF(TRIM(sls_price), '')::NUMERIC < 0) AS negative_sales, 
    COUNT(*) FILTER (WHERE NULLIF(TRIM(sls_price), '')::NUMERIC < 0) AS negative_quantities, 
    COUNT(*) FILTER (WHERE NULLIF(TRIM(sls_price), '')::NUMERIC < 0) AS negative_prices

FROM bronze.crm_sales_details_raw;

-- Check sales calculation. whether sales = quantity × price
SELECT
    sls_sales,
    sls_quantity,
    sls_price
FROM bronze.crm_sales_details_raw
WHERE TRIM(sls_sales)::NUMERIC * TRIM(sls_quantity)::NUMERIC = TRIM(sls_price)::NUMERIC;

-- Inspect all records with negative sales/quantity/price
SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_sales,
    sls_quantity,
    sls_price
FROM bronze.crm_sales_details_raw
WHERE sls_sales::NUMERIC < 0
   OR sls_quantity::NUMERIC < 0
   OR sls_price::NUMERIC < 0;


SELECT
    sls_ord_num,
    sls_prd_key,
    sls_sales,
    sls_quantity,
    sls_price
FROM bronze.crm_sales_details_raw
WHERE sls_sales IS NULL
   OR sls_price IS NULL;


-- ============================================================================
-- ERP CUSTOMER DEMOGRAPHICS
-- ============================================================================

-- Inspect ERP customer data before defining transformation rules
SELECT *
FROM bronze.erp_cust_az12_raw
LIMIT 20;


-- Check for NULL customer keys
SELECT COUNT(*) AS null_customer_keys
FROM bronze.erp_cust_az12_raw
WHERE NULLIF(TRIM(cid), '') IS NULL;

-- Check whether customer key is unique
SELECT
    TRIM(cid) AS customer_key,
    COUNT(*) AS record_count
FROM bronze.erp_cust_az12_raw
GROUP BY TRIM(cid)
HAVING COUNT(*) > 1
ORDER BY record_count DESC;

-- Check for leading/trailing spaces
SELECT
    cid,
    bdate,
    gen
FROM bronze.erp_cust_az12_raw
WHERE cid <> TRIM(cid)
   OR bdate <> TRIM(bdate)
   OR gen <> TRIM(gen);

-- Check distinct gender values
SELECT DISTINCT
    TRIM(gen) AS gender
FROM bronze.erp_cust_az12_raw
ORDER BY gender;

-- Check birth-date values before converting TEXT to DATE
SELECT
    bdate,
    COUNT(*) AS record_count
FROM bronze.erp_cust_az12_raw
GROUP BY bdate
ORDER BY bdate;

-- Check for invalid birth dates
SELECT bdate
FROM bronze.erp_cust_az12_raw
WHERE bdate IS NOT NULL
  AND TRIM(bdate) !~ '^\d{4}-\d{2}-\d{2}$';



-- ============================================================================
-- ERP CUSTOMER LOCATION
-- ============================================================================

-- Inspect location data before defining transformation rules
SELECT *
FROM bronze.erp_loc_a101_raw
LIMIT 20;

-- total rows 
SELECT COUNT(*)
FROM bronze.erp_loc_a101_raw;

-- check for null customer keys
SELECT COUNT(*) AS null_customer_keys
FROM bronze.erp_loc_a101_raw
WHERE NULLIF(TRIM(cid), '') IS NULL

-- check for null country
SELECT COUNT(*) AS null_country
FROM bronze.erp_loc_a101_raw
WHERE NULLIF(TRIM(cntry), '') IS NULL


-- check for duplicate customer keys
SELECT 
    cid,
    COUNT(*) AS record_count
FROM bronze.erp_loc_a101_raw
GROUP BY cid 
HAVING COUNT(*) > 1
ORDER BY record_count DESC;

-- Check for leading/trailing spaces
SELECT
    cid,
    cntry
FROM bronze.erp_loc_a101_raw
WHERE TRIM(cid) <> cid OR 
      TRIM(cntry) <> cntry

-- check for distinct country values
SELECT DISTINCT cntry
FROM bronze.erp_loc_a101_raw;


-- ============================================================================
-- ERP PRODUCT CATEGORY
-- ============================================================================

-- Inspect product category data
SELECT *
FROM bronze.erp_px_cat_g1v2_raw
LIMIT 20;

-- check for null category keys: No null values
SELECT COUNT(*) AS null_category_keys
FROM bronze.erp_px_cat_g1v2_raw
WHERE NULLIF(TRIM(id), '') IS NULL;

-- check for duplicates category keys: id is unique

SELECT 
    id,
    COUNT(*) AS record_count
FROM bronze.erp_px_cat_g1v2_raw
GROUP BY id  
HAVING COUNT(*) > 1
ORDER BY record_count DESC;


-- Check distinct category/subcategory values
SELECT DISTINCT
    TRIM(cat) AS category,
    TRIM(subcat) AS subcategory,
    TRIM(maintenance) AS maintenance
FROM bronze.erp_px_cat_g1v2_raw

-- Check for leading/trailing spaces: No whitespace
SELECT
    id,
    cat,
    subcat,
    maintenance
FROM bronze.erp_px_cat_g1v2_raw
WHERE id <> TRIM(id)
   OR cat <> TRIM(cat)
   OR subcat <> TRIM(subcat)
   OR maintenance <> TRIM(maintenance);

