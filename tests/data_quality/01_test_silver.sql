/*
================================================================================
Script: 01_test_silver.sql
Purpose:
    Validate Silver data quality and integrity.
================================================================================
*/

-- Test: Customer primary key

DO $$
BEGIN
    IF EXISTS (
        SELECT customer_id
        FROM silver.crm_cust_info
        GROUP BY customer_id
        HAVING customer_id IS NULL
            OR COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'Invalid Silver customer primary key found';
    END IF;
END $$;


-- Test: Product primary key

DO $$
BEGIN
    IF EXISTS (
        SELECT product_id
        FROM silver.crm_prd_info
        GROUP BY product_id
        HAVING product_id IS NULL
            OR COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'Invalid Silver product primary key found';
    END IF;
END $$;


-- Test: Sales primary key

DO $$
BEGIN
    IF EXISTS (
        SELECT order_number, product_key
        FROM silver.crm_sales_details
        GROUP BY order_number, product_key
        HAVING order_number IS NULL
            OR product_key IS NULL
            OR COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'Invalid Silver sales primary key found';
    END IF;
END $$;

-- Test: Product validity periods must be valid

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM silver.crm_prd_info
        WHERE end_date IS NOT NULL
          AND end_date < start_date
    ) THEN
        RAISE EXCEPTION 'Invalid Silver product validity dates found';
    END IF;
END $$;


-- Test: Sales dates must be valid

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM silver.crm_sales_details
        WHERE shipping_date < order_date
           OR due_date < order_date
    ) THEN
        RAISE EXCEPTION 'Invalid Silver sales dates found';
    END IF;
END $$;


-- Test: Sales values must be positive

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM silver.crm_sales_details
        WHERE sales_amount <= 0
           OR quantity <= 0
           OR sls_price <= 0
    ) THEN
        RAISE EXCEPTION 'Invalid Silver sales values found';
    END IF;
END $$;


-- Test: Customer gender is standardized

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM silver.crm_cust_info
        WHERE gender NOT IN ('Male', 'Female', 'Unknown')
    ) THEN
        RAISE EXCEPTION 'Invalid customer gender found';
    END IF;
END $$;


-- Test: Customer marital status is standardized

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM silver.crm_cust_info
        WHERE marital_status NOT IN ('Married', 'Single', 'Unknown')
    ) THEN
        RAISE EXCEPTION 'Invalid marital status found';
    END IF;
END $$;


-- Test: ERP customer gender is standardized

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM silver.erp_cust_az12
        WHERE gender NOT IN ('Male', 'Female', 'Unknown')
    ) THEN
        RAISE EXCEPTION 'Invalid ERP customer gender found';
    END IF;
END $$;


-- Test: ERP location country is not blank

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM silver.erp_loc_a101
        WHERE country IS NULL
           OR TRIM(country) = ''
    ) THEN
        RAISE EXCEPTION 'Invalid country value found';
    END IF;
END $$;

-- Test: Product line is standardized

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM silver.crm_prd_info
        WHERE product_line NOT IN (
            'Mountain',
            'Road',
            'Other Sales',
            'Touring',
            'Unknown'
        )
    ) THEN
        RAISE EXCEPTION 'Invalid product line found';
    END IF;
END $$;

SELECT DISTINCT product_line
FROM silver.crm_prd_info;