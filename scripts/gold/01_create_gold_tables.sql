/*
================================================================================
Script: 01_create_gold_tables.sql
Layer: Gold
Purpose:
    Create the Gold layer tables used for analytics and reporting.

Source Layer:
    - Silver

Target Tables:
    - gold.dim_customers
    - gold.dim_products
    - gold.fact_sales

Design:
    - Star schema
    - Dimensions provide descriptive business context
    - Fact table stores measurable business events
================================================================================
*/

-- Create Gold customer dimensions table

CREATE TABLE IF NOT EXISTS gold.dim_customers(
    customer_id INT PRIMARY KEY,
    customer_key TEXT,
    first_name TEXT,
    last_name TEXT,
    marital_status TEXT,
    gender TEXT,
    birth_date DATE,
    country TEXT,
    create_date DATE,
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Gold product dimension table

CREATE TABLE IF NOT EXISTS gold.dim_products (
    product_id INT PRIMARY KEY,
    category_key TEXT,
    product_key TEXT,
    product_name TEXT,
    product_cost NUMERIC,
    product_line TEXT,
    category TEXT,
    subcategory TEXT,
    maintenance TEXT,
    start_date DATE,
    end_date DATE,
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Gold sales fact table
-- Grain = onw row per sales order line

CREATE TABLE IF NOT EXISTS gold.fact_sales (
    order_number TEXT,
    product_key TEXT,
    customer_id INT,
    order_date DATE,
    shipping_date DATE,
    due_date DATE,
    sales_amount NUMERIC,
    quantity INT,
    price NUMERIC,
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (order_number, product_key)
);

ALTER TABLE silver.erp_cust_az12
ALTER COLUMN birth_date TYPE DATE;
