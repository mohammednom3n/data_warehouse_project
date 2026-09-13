SELECT COUNT(*) FROM silver.crm_cust_info;
SELECT COUNT(*) FROM silver.crm_prd_info;
SELECT COUNT(*) FROM silver.crm_sales_details;
SELECT COUNT(*) FROM silver.erp_cust_az12;
SELECT COUNT(*) FROM silver.erp_loc_a101;
SELECT COUNT(*) FROM silver.erp_px_cat_g1v2;


SELECT * FROM silver.crm_cust_info LIMIT 10;
SELECT * FROM silver.erp_cust_az12 LIMIT 10;
SELECT * FROM silver.erp_loc_a101 LIMIT 10;
SELECT * FROM silver.crm_prd_info LIMIT 10;
SELECT * FROM silver.erp_px_cat_g1v2 LIMIT 10;
SELECT * FROM silver.crm_sales_details LIMIT 10;



-- Check row counts after Silver load

SELECT 'crm_cust_info' AS table_name, COUNT(*) AS row_count
FROM silver.crm_cust_info

UNION ALL

SELECT 'crm_prd_info', COUNT(*)
FROM silver.crm_prd_info

UNION ALL

SELECT 'crm_sales_details', COUNT(*)
FROM silver.crm_sales_details

UNION ALL

SELECT 'erp_cust_az12', COUNT(*)
FROM silver.erp_cust_az12

UNION ALL

SELECT 'erp_loc_a101', COUNT(*)
FROM silver.erp_loc_a101

UNION ALL

SELECT 'erp_px_cat_g1v2', COUNT(*)
FROM silver.erp_px_cat_g1v2;




-- Check important columns for NULLs

SELECT
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE customer_key IS NULL) AS null_customer_key,
    COUNT(*) FILTER (WHERE first_name IS NULL) AS null_first_name,
    COUNT(*) FILTER (WHERE last_name IS NULL) AS null_last_name
FROM silver.crm_cust_info;

SELECT
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
    COUNT(*) FILTER (WHERE product_key IS NULL) AS null_product_key,
    COUNT(*) FILTER (WHERE product_name IS NULL) AS null_product_name,
    COUNT(*) FILTER (WHERE start_date IS NULL) AS null_start_date
FROM silver.crm_prd_info;

SELECT
    COUNT(*) FILTER (WHERE order_number IS NULL) AS null_order_number,
    COUNT(*) FILTER (WHERE product_key IS NULL) AS null_product_key,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE quantity IS NULL) AS null_quantity
FROM silver.crm_sales_details;


-- Check duplicate customer IDs
SELECT customer_id, COUNT(*)
FROM silver.crm_cust_info
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Check duplicate product IDs
SELECT product_id, COUNT(*)
FROM silver.crm_prd_info
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Check duplicate sales order lines
SELECT order_number, product_key, COUNT(*)
FROM silver.crm_sales_details
GROUP BY order_number, product_key
HAVING COUNT(*) > 1;

SELECT order_number, COUNT(*)
FROM silver.crm_sales_details
GROUP BY order_number
HAVING COUNT(*) > 1;

-- Check duplicate ERP customer keys
SELECT customer_key, COUNT(*)
FROM silver.erp_cust_az12
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- Check duplicate ERP location keys
SELECT customer_key, COUNT(*)
FROM silver.erp_loc_a101
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- Check duplicate category IDs
SELECT product_category_key, COUNT(*)
FROM silver.erp_px_cat_g1v2
GROUP BY product_category_key
HAVING COUNT(*) > 1;


-- Check Silver business rules

-- Sales amounts, quantities, and prices
SELECT *
FROM silver.crm_sales_details
WHERE sales_amount <= 0
   OR quantity <= 0
   OR sls_price <= 0;

-- Sales date relationships
SELECT *
FROM silver.crm_sales_details
WHERE shipping_date < order_date
   OR due_date < order_date;

-- Product validity periods
SELECT *
FROM silver.crm_prd_info
WHERE end_date IS NOT NULL
  AND end_date < start_date;


SELECT DISTINCT
    gender
FROM silver.crm_cust_info
