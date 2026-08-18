--===============================================================================================================================
-- SCRIPT        : Silver Layer Data Quality Checks & Validation
-- DESCRIPTION   : Performs comprehensive data quality and consistency checks across the Silver Layer tables.
--                 Validates duplicates, NULL values, unwanted spaces, invalid dates, referential integrity,
--                 data standardization, and consistency between related business attributes.
--                 Includes validation of CRM and ERP customer, product, sales, location, and product category data.
--                 Each check is designed to identify data anomalies before the data is consumed by the Gold Layer.
-- LAYER         : Silver
-- OBJECTIVE     : Ensure that transformed and cleansed Silver Layer data meets quality, consistency,
--                 integrity, and business-rule requirements before downstream analytical processing.
--===============================================================================================================================
--==================================================================================================================================================
--- CHECK THE OVERALL DATA QUALITY IN SILVER LAYER

--silver.crm_cust_info
--==================================================================================================================================================

--- Check Duplicates
--Expectation: No result

SELECT
	cst_id,
	COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL

-- Check for unwanted Spaces
-- Expectation : No Results

SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)
    
-- Check for unwanted Spaces
-- Expectation: No Results

SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

-- Check for unwanted Spaces
-- Expectation: No Results

SELECT cst_gndr
FROM silver.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr);

-- Data Standardization & Consistency
--Expectation: No result

SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info

--============================================================================================================================================
--silver.crm_prd_info
--============================================================================================================================================

-- checking duplicates
-- Expectation: No result

SELECT
	prd_id,
	COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL

-- CHECK UNWANTED SPACES
-- Expectation: No result

SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

-- check for nulls or negative numbers
-- Expectation: No result

SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

-- Data standardization & Consistency
-- Expectation: No result

SELECT DISTINCT prd_line
FROM silver.crm_prd_info

-- Check for invalid date orders
-- Expectation: No result

SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt


--============================================================================================================================================
--silver.crm_sales_details
--============================================================================================================================================



-- CHECK UNWANTED SPACES
-- Expectation: No result

SELECT
    sls_ord_num
FROM silver.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num)

-- CHECK INTIGRATY
-- Expectation: No result

SELECT sls_prd_key
FROM silver.crm_sales_details
WHERE sls_prd_key NOT IN 
(
    SELECT prd_key 
    FROM silver.crm_prd_info
)

SELECT sls_cust_id
FROM silver.crm_sales_details
WHERE sls_cust_id NOT IN 
(
    SELECT cst_id 
    FROM silver.crm_cust_info
)

--Check for Invalid Dates 
-- Expectation: No result

SELECT 
sls_order_dt
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt 
OR sls_order_dt > sls_due_dt 

-- Check Data Consistency: Between Sales, Quantity, and Price
-- >> Sales = Quantity * Price
-- >> Values must not be NULL, zero, or negative.

SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL
   OR sls_quantity IS NULL
   OR sls_price IS NULL
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0
ORDER BY 
    sls_sales,
    sls_quantity,
    sls_price


--================================================================================================
-- silver.erp_cust_az12
--================================================================================================

SELECT cid
FROM silver.erp_cust_az12
WHERE cid = 'NAS%'

SELECT bdate
FROM silver.erp_cust_az12
WHERE bdate > GETDATE()

SELECT DISTINCT gen
FROM silver.erp_cust_az12


--================================================================================================
-- silver.erp_loc_a101
--================================================================================================

-- Identify

SELECT 
cid
FROM silver.erp_loc_a101;

-- Data Standardization & consistency

SELECT DISTINCT cntry
FROM silver.erp_loc_a101
ORDER BY cntry;

--================================================================================================
-- silver.erp_px_cat_g1v1
--================================================================================================

-- identify the difference between product category (erp) & product info (crm)

SELECT 
    id
FROM silver.erp_px_cat_g1v2;

SELECT cat_id FROM silver.crm_prd_info;

-- Check for unwanted spaces

SELECT * FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat) 
OR subcat != TRIM(subcat) 
OR maintenance != TRIM(maintenance)

-- Data Standardization & Consistency

SELECT DISTINCT cat
FROM silver.erp_px_cat_g1v2;

SELECT DISTINCT subcat
FROM silver.erp_px_cat_g1v2;

SELECT DISTINCT maintenance
FROM silver.erp_px_cat_g1v2;
