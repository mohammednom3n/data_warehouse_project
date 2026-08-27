-- 1. Inspect sample records
SELECT *
FROM bronze.crm_cust_info_raw
LIMIT 1000;

SELECT *
FROM bronze.crm_prd_info_raw
LIMIT 1000;

SELECT *
FROM bronze.crm_sales_details_raw
LIMIT 1000;

SELECT *
FROM bronze.erp_cust_az12_raw
LIMIT 1000;

SELECT *
FROM bronze.erp_loc_a101_raw
LIMIT 1000;

SELECT *
FROM bronze.erp_px_cat_g1v2_raw
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
WHERE cst_id IS NULL;

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
    OR cst_lastname <> TRIM(cst_lastname)

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