/*
================================================================================
Script: 03_validate_gold.sql
Layer: Gold
Purpose:
    Validate Gold data quality and integrity.
================================================================================
*/

-- Check Gold row counts

SELECT 'dim_customers' AS table_name, COUNT(*) AS row_count
FROM gold.dim_customers

UNION ALL

SELECT 'dim_products', COUNT(*)
FROM gold.dim_products

UNION ALL

SELECT 'fact_sales', COUNT(*)
FROM gold.fact_sales;


-- Check duplicate customer keys
SELECT customer_id, COUNT(*)
FROM gold.dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Check duplicate product IDs
SELECT product_id, COUNT(*)
FROM gold.dim_products
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Check duplicate sales lines
SELECT order_number, product_key, COUNT(*)
FROM gold.fact_sales
GROUP BY order_number, product_key
HAVING COUNT(*) > 1;

-------------------------
-------------------------

-- Check sales with no matching customer

SELECT f.*
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- Check sales with no matching product

SELECT f.*
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
WHERE p.product_key IS NOT NULL;





-- Check sales match exactly one valid product version

SELECT
    f.order_number,
    f.product_key,
    f.order_date,
    COUNT(p.product_id) AS matching_versions
FROM gold.fact_sales AS f
JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
   AND f.order_date >= p.start_date
   AND (f.order_date <= p.end_date OR p.end_date IS NULL)
GROUP BY
    f.order_number,
    f.product_key,
    f.order_date
HAVING COUNT(p.product_id) <> 1;