/*
================================================================================
Script: 01_test_gold.sql
Purpose:
    Validate Gold data quality and referential integrity.
================================================================================
*/

-- Test: Every sale has a matching customer
DO $$

BEGIN
    IF EXISTS (
        SELECT 1
        FROM gold.fact_sales AS f
        LEFT JOIN gold.dim_customers AS c
            ON f.customer_id = c.customer_id
        WHERE c.customer_id IS NULL 
    ) THEN
        RAISE EXCEPTION 'Sales contain unmatched customers';
    END IF;

END $$;



-- Test: Every sale has a matching product
DO $$

BEGIN
    IF EXISTS (
        SELECT 1
        FROM gold.fact_sales AS f 
        LEFT JOIN gold.dim_products AS p 
            ON f.product_key = p.product_key
        WHERE p.product_key IS NULL

    ) THEN
        RAISE EXCEPTION 'Sales contain unmatched products';
    END IF;

END $$;


---------------- Next: test primary-key uniqueness and NULLs.------------------


-- Test: Customer primary key is unique and not NULL
DO $$

BEGIN
    IF EXISTS (
        SELECT customer_id
        FROM gold.dim_customers
        GROUP BY customer_id
        HAVING COUNT(*) > 1 
            OR customer_id IS NULL
    ) THEN
        RAISE EXCEPTION 'Invalid customer primary key found';
    END IF;

END $$;


-- Test: Product primary key is unique and not NULL
DO $$

BEGIN
    IF EXISTS (
        SELECT product_id
        FROM gold.dim_products
        GROUP BY product_id
        HAVING product_id IS NULL 
            OR COUNT(*) > 1
    ) THEN 
        RAISE EXCEPTION 'Invalid product primary key found';
    END IF; 

END $$;

-- Test: Sales primary key is unique
DO $$

BEGIN
    IF EXISTS (
        SELECT 
            product_key,
            order_number
        FROM gold.fact_sales
        GROUP BY product_key, order_number
        HAVING product_key IS NULL
            OR order_number IS NULL 
            OR COUNT(*) > 1
    ) THEN 
        RAISE EXCEPTION 'Invalid sales primary key found';
    END IF; 

END $$;


-------------- Next: business-rule tests ---------------

-- Test: Sales values must be positive
DO $$

BEGIN
    IF EXISTS (
        SELECT 1
        FROM gold.fact_sales
            WHERE sales_amount <= 0
            OR quantity <= 0
            OR price <= 0
    ) THEN
        RAISE EXCEPTION 'Invalid sales values found';
    END IF;

END $$;

-- Test: Sales dates must be valid
DO $$

BEGIN

    IF EXISTS (
        SELECT 1
        FROM gold.fact_sales
        WHERE shipping_date < order_date
           OR due_date < order_date
    ) THEN
        RAISE EXCEPTION 'Invalid sales dates found';
    END IF;

END $$;

-- Test: Product validity periods must be valid
DO $$

BEGIN
    IF EXISTS (
        SELECT 1
        FROM gold.dim_products
        WHERE end_date IS NOT NULL
          AND end_date < start_date
    ) THEN
        RAISE EXCEPTION 'Invalid product validity dates found';
    END IF;

END $$;

