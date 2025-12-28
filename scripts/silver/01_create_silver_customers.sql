/*
===========================================================
 Script: 01_create_silver_customers.sql
 Layer: Silver
 Purpose:
   Create the silver.customers table containing a clean,
   integrated, entity-centric view of customers.

 Source Tables:
   - bronze.crm_cust_info_raw
   - bronze.erp_cust_az12_raw
   - bronze.erp_loc_a101_raw

 Target Table:
   - silver.customers

 Grain:
   One row per customer (CRM customer ID)

===========================================================
*/

CREATE TABLE IF NOT EXISTS silver.customers (
    customer_id      INT PRIMARY KEY,
    customer_key     TEXT,
    first_name       TEXT,
    last_name        TEXT,
    gender           TEXT,
    marital_status   TEXT,
    birth_date       DATE,
    country          TEXT,
    created_date     DATE
);
