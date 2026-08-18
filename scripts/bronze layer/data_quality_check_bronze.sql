--===============================================================================================================================
-- SCRIPT        : Bronze Layer Data Quality Checks & Transformations
-- DESCRIPTION   : Performs data quality validation, consistency checks, and data standardization
--                 across CRM and ERP source tables in the Bronze Layer.
--                 Includes identification and modification of NULLs, duplicates, invalid dates,
--                 unwanted spaces, inconsistent values, and data integrity issues.
-- LAYER         : Bronze
-- OBJECTIVE     : Validate and prepare raw source data for the Silver Layer.
--===============================================================================================================================

--=====================================================================================================================================
--Quality Checking & Modification in Bronze Layer

-- Quality Checking & Modification in Customer Information Table in Bronze Layer
--=====================================================================================================================================

SELECT *
FROM bronze.crm_cust_info

-- Check for nulls or duplicates in primary key
-- Expectation: No result

SELECT
	cst_id,
	COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL

-- Modify It

SELECT
    *
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY cst_id
            ORDER BY cst_create_date DESC
        ) AS flag_last
    FROM bronze.crm_cust_info
    WHERE cst_id IS NOT NULL
) t
WHERE flag_last = 1;

-- Check for unwanted Spaces
-- Expectation : No Results

SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

-- Check for unwanted Spaces
-- Expectation: No Results

SELECT cst_lastname
FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

-- Check for unwanted Spaces
-- Expectation: No Results

SELECT cst_gndr
FROM bronze.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr);

-- Data Standardization & Consistency
-- Expectation: No result

SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info

-- Modify the data 

SELECT 
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    CASE 
        WHEN UPPER(cst_marital_status) = 'M' THEN 'Married'
        WHEN UPPER(cst_marital_status) = 'S' THEN 'Single'
        ELSE 'N/A'
    END AS cst_marital_status,
    CASE 
        WHEN UPPER(cst_gndr) = 'F' THEN 'Female'
        WHEN UPPER(cst_gndr) = 'M' THEN 'Male'
        ELSE 'N/A'
    END AS cst_gndr,
    cst_create_date
FROM 
(
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY cst_id
            ORDER BY cst_create_date DESC
        ) AS flag_last
    FROM bronze.crm_cust_info
    WHERE cst_id IS NOT NULL
) t
WHERE flag_last = 1;


--==============================================================================================================
-- Quality Checking and Modification of Product Information table IN Bronze Layer
--==============================================================================================================

SELECT 
    prd_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
FROM bronze.crm_prd_info

-- checking duplicates
-- Expectation: No result

SELECT
	prd_id,
	COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL

-- SPLIT THE COLUMN prd_key

SELECT
    prd_key,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') as cat_id,
    SUBSTRING(prd_key, 7, LEN(prd_key)) as prd_key
FROM bronze.crm_prd_info


-- JOIN THE TABLES Between Product information & Px_cat_g1v1 (ERP) 

SELECT
    prd_key,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') as cat_id
FROM bronze.crm_prd_info
WHERE REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') NOT IN
    (SELECT DISTINCT id 
    FROM bronze.erp_px_cat_g1v2)

-- JOIN THE TABLES Between Product Information & Sales Dedails

SELECT
    prd_key,
    SUBSTRING(prd_key, 7, LEN(prd_key)) as prd_key
FROM bronze.crm_prd_info
WHERE SUBSTRING(prd_key, 7, LEN(prd_key)) IN
    (SELECT sls_prd_key
    FROM bronze.crm_sales_details)

-- CHECK UNWANTED SPACES
-- Expectation: No result

SELECT prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

-- check for nulls or negative numbers
-- Expectation: No result

SELECT prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

-- Data standardization & Consistency
-- Expectation: No result

SELECT DISTINCT prd_line
FROM bronze.crm_prd_info

-- Check for invalid date orders
-- Expectation: No result

SELECT *
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt

-- Modify the End date 

SELECT 
    prd_id,
    prd_key,
    prd_nm,
    prd_start_dt,
    prd_end_dt,
    LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS prd_end_dt_test
FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509')

-- Modify the data 

SELECT 
    prd_id,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') as cat_id,
    SUBSTRING(prd_key, 7, LEN(prd_key)) as prd_key,
    prd_nm,
    ISNULL(prd_cost, 0) AS prd_cost,
    CASE
        WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
        WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
        WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
        WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
        ELSE 'N/A'
    END as prd_line, 
    CAST(prd_start_dt AS DATE) AS prd_start_dt,
    CAST(LEAD(prd_start_dt) 
    OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE) AS prd_end_dt
FROM bronze.crm_prd_info


--==============================================================================================================================================
--Quality Checking & Modification in Sales Details Table in Bronze Layer
--==============================================================================================================================================

SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
FROM bronze.crm_sales_details

-- CHECK UNWANTED SPACES
-- Expectation: No result

SELECT
    sls_ord_num
FROM bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num)

-- CHECK INTIGRATY
-- Expectation: No result

SELECT sls_prd_key
FROM bronze.crm_sales_details
WHERE sls_prd_key NOT IN 
(
    SELECT prd_key 
    FROM silver.crm_prd_info
)

SELECT sls_cust_id
FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN 
(
    SELECT cst_id 
    FROM silver.crm_cust_info
)

--Check for Invalid order Dates
-- Expectation: No result

SELECT 
sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0

--Modify it

SELECT 
NULLIF(sls_order_dt, 0) as sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 

-- --Check for Invalid order Dates (Other Issue)
-- Expectation: No result

SELECT 
sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0
OR LEN(sls_order_dt) != 8 
OR sls_order_dt > 20270101 
OR sls_order_dt < 19000101

-- Modify it

SELECT
    CASE
        WHEN sls_order_dt <= 0 OR LEN(sls_order_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_order_dt AS varchar) AS date)
    END AS sls_order_dt
FROM bronze.crm_sales_details

--Check for Invalid shipping Dates 
-- Expectation: No result

SELECT 
sls_ship_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0
OR LEN(sls_ship_dt) != 8 
OR sls_ship_dt > 20270101 
OR sls_ship_dt < 19000101

-- Modify it

SELECT
    CASE
        WHEN sls_ship_dt <= 0 OR LEN(sls_ship_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_ship_dt AS varchar) AS date) 
    END  AS sls_ship_dt
FROM bronze.crm_sales_details

--Check for Invalid due Dates 
-- Expectation: No result

SELECT 
sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0
OR LEN(sls_due_dt) != 8 
OR sls_due_dt > 20270101 
OR sls_due_dt < 19000101

-- Modify it

SELECT
    CASE
        WHEN sls_due_dt <= 0 OR LEN(sls_due_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_due_dt AS varchar) AS date) 
    END AS sls_due_dt
FROM bronze.crm_sales_details

--Check for Invalid Dates 
-- Expectation: No result

SELECT 
sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt 
OR sls_order_dt > sls_due_dt 

-- Check Data Consistency: Between Sales, Quantity, and Price
-- >> Sales = Quantity * Price
-- >> Values must not be NULL, zero, or negative.

SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM bronze.crm_sales_details
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

--Modify it

SELECT DISTINCT
    sls_sales AS old_sls_sales,
    sls_quantity,
    sls_price AS old_sls_price,
    CASE
        WHEN sls_sales IS NULL
          OR sls_sales <= 0
          OR sls_sales != sls_quantity * ABS(sls_price)
        THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,
    CASE
    WHEN sls_price IS NULL OR sls_price <= 0
        THEN sls_sales / NULLIF(sls_quantity, 0)
    ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL
   OR sls_quantity IS NULL
   OR sls_price IS NULL
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0;

--- Overall MODIFICATION in Sales Details Table

SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    CASE
        WHEN sls_order_dt <= 0 OR LEN(sls_order_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_order_dt AS varchar) AS date)
    END AS sls_order_dt,
    CASE
        WHEN sls_ship_dt <= 0 OR LEN(sls_ship_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_ship_dt AS varchar) AS date) 
    END  AS sls_ship_dt,
    CASE
        WHEN sls_due_dt <= 0 OR LEN(sls_due_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_due_dt AS varchar) AS date) 
    END AS sls_due_dt,
    CASE
        WHEN sls_sales IS NULL OR sls_sales <= 0
            OR sls_sales != sls_quantity * ABS(sls_price)
        THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,
    sls_quantity,
    CASE
        WHEN sls_price IS NULL OR sls_price <= 0
        THEN sls_sales / NULLIF(sls_quantity, 0)
    ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details

--===============================================================================================================================
-- Quality Checking & Modification in Customer Information (ERP) in bronze layer
--===============================================================================================================================


SELECT
    cid,
    bdate,
    gen
FROM bronze.erp_cust_az12

SELECT cid
FROM bronze.erp_cust_az12
WHERE cid = 'NAS%'

-- Modify & join with the customer infomation table (crm) in silver layer

SELECT
    cid,
    CASE
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid
    END AS cid,
    bdate,
    gen
FROM bronze.erp_cust_az12
WHERE CASE
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid
       END  NOT IN
(
    SELECT DISTINCT cst_key
    FROM silver.crm_cust_info
)

-- Identify Out-of-Range Dates

SELECT bdate
FROM bronze.erp_cust_az12
WHERE bdate > GETDATE()

--Modify it

SELECT
    CASE
        WHEN bdate > GETDATE() THEN NULL
        ELSE bdate
    END AS bdate,
    gen
FROM bronze.erp_cust_az12;

--Data Standardization & Consistency

SELECT DISTINCT gen
FROM bronze.erp_cust_az12

-- modify it

SELECT DISTINCT 
gen,
CASE
    WHEN UPPER(TRIM(gen))  IN ('F', 'FEMALE') THEN 'Female'
    WHEN UPPER(TRIM(gen))  IN ('M', 'MALE') THEN 'Male'
    ELSE 'N/A'
END AS gen
FROM bronze.erp_cust_az12

--- Modify whole table

SELECT
    CASE
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid
    END AS cid,
    CASE
        WHEN bdate > GETDATE() THEN NULL
        ELSE bdate
    END AS bdate,
    CASE
    WHEN UPPER(TRIM(gen))  IN ('F', 'FEMALE') THEN 'Female'
    WHEN UPPER(TRIM(gen))  IN ('M', 'MALE') THEN 'Male'
    ELSE 'N/A'
END AS gen
FROM bronze.erp_cust_az12;

--===============================================================================================================================
-- Quality Checking & Modification in Location Information (ERP) in bronze layer
--===============================================================================================================================

SELECT 
cid,
cntry
FROM bronze.erp_loc_a101;

-- Identify the difference between location info (erp) & customer info (crm)

SELECT 
cid
FROM bronze.erp_loc_a101;

SELECT cst_key FROM silver.crm_cust_info;

--Modify it

SELECT 
    REPLACE(cid, '-', '') AS cid
FROM bronze.erp_loc_a101;

-- Check the join 

SELECT 
    REPLACE(cid, '-', '') AS cid
FROM bronze.erp_loc_a101
WHERE REPLACE(cid, '-', '') NOT IN
(SELECT cst_key FROM silver.crm_cust_info);

-- Data Standardization & consistency

SELECT DISTINCT cntry
FROM bronze.erp_loc_a101
ORDER BY cntry;

-- Modify it

SELECT DISTINCT
    cntry,
    CASE
        WHEN TRIM(cntry) = 'DE' THEN 'Germany'
        WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
        WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
        ELSE TRIM(cntry)
    END AS cntry
FROM bronze.erp_loc_a101;

-- MODIFICATION WHOLE TABLE

SELECT 
    REPLACE(cid, '-', '') AS cid,
    CASE
        WHEN TRIM(cntry) = 'DE' THEN 'Germany'
        WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
        WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
        ELSE TRIM(cntry)
    END AS cntry
FROM bronze.erp_loc_a101;

--===============================================================================================================================
-- Quality Checking & Modification in Product Category (ERP) in bronze layer
--===============================================================================================================================

SELECT 
    id,
    cat,
    subcat,
    maintenance
FROM bronze.erp_px_cat_g1v2;

-- identify the difference between product category (erp) & product info (crm)

SELECT 
    id
FROM bronze.erp_px_cat_g1v2;

SELECT cat_id FROM silver.crm_prd_info;

--Check the join

SELECT 
    id
FROM bronze.erp_px_cat_g1v2
WHERE id  IN
(SELECT cat_id FROM silver.crm_prd_info);

-- Check for unwanted spaces

SELECT * FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) 
OR subcat != TRIM(subcat) 
OR maintenance != TRIM(maintenance)

-- Data Standardization & Consistency

SELECT DISTINCT cat
FROM bronze.erp_px_cat_g1v2;

SELECT DISTINCT subcat
FROM bronze.erp_px_cat_g1v2;

SELECT DISTINCT maintenance
FROM bronze.erp_px_cat_g1v2;

-- Don't need to Modify anything to this table.
