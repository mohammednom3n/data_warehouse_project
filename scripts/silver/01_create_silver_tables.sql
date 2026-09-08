/*
===============================================================================
Script: 01_create_silver_tables.sql
Layer: Silver
Purpose:
    Create the Silver layer tables used to store cleaned, standardized,
    and validated data from the Bronze layer.

Source Layer:
    - bronze

Target Tables:
    - silver.crm_cust_info
    - silver.crm_prd_info
    - silver.crm_sales_details
    - silver.erp_cust_az12
    - silver.erp_loc_a101
    - silver.erp_px_cat_g1v2

Transformations:
    - Convert raw TEXT columns into appropriate PostgreSQL data types
    - Clean and standardize source data
    - Handle NULL and invalid values
    - Remove duplicate records where required
    - Standardize categorical values
    - Preserve source business keys
    - Add warehouse metadata

Grain:
    - crm_cust_info: One row per customer
    - crm_prd_info: One row per product
    - crm_sales_details: One row per sales order line
    - erp_cust_az12: One row per ERP customer
    - erp_loc_a101: One row per customer location
    - erp_px_cat_g1v2: One row per product/category mapping

Design Principles:
    - Bronze preserves the raw source data.
    - Silver contains cleaned and standardized data.
    - Bronze data is never modified during Silver transformations.
    - Primary keys enforce uniqueness where the grain is known.
    - Foreign keys will be introduced only after relationships are validated.
===============================================================================
*/

-- CRM CUSTOMER

CREATE TABLE IF NOT EXISTS silver.crm_cust_info (
    customer_id INT PRIMARY KEY,
    customer_key TEXT,
    first_name TEXT,
    last_name TEXT,
    marital_status TEXT,
    gender TEXT,
    cst_create_date DATE,
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- CRM PRODUCTS

CREATE TABLE IF NOT EXISTS silver.crm_prd_info (
    product_id INT PRIMARY KEY,
    product_key TEXT,
    product_name TEXT,
    product_cost NUMERIC,
    product_line TEXT,
    start_date DATE,
    end_date DATE,
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- CRM SALES

CREATE TABLE IF NOT EXISTS silver.crm_sales_details (
    order_number TEXT,
    product_key TEXT,
    customer_id INT,
    order_date DATE,
    shipping_date DATE,
    due_date DATE,
    sales_amount NUMERIC,
    quantity INT,
    sls_price NUMERIC,
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ERP CUSTOMERS

CREATE TABLE IF NOT EXISTS silver.erp_cust_az12 (
    customer_key TEXT PRIMARY KEY,
    birth_date TEXT,
    gender TEXT,
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ERP CUSTOMER'S LOCATION

CREATE TABLE IF NOT EXISTS silver.erp_loc_a101 (
    customer_key TEXT PRIMARY KEY,
    country TEXT,
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ERP PRODUCTS INFO

CREATE TABLE IF NOT EXISTS silver.erp_px_cat_g1v2 (
    product_category_key TEXT PRIMARY KEY,
    category TEXT,
    subcategory TEXT,
    maintenance TEXT,
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    
);

