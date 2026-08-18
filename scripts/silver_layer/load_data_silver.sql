--===============================================================================================================================
-- SCRIPT        : Silver Layer Data Loading & Transformation
-- DESCRIPTION   : Loads cleansed and transformed data from the Bronze Layer into the Silver Layer tables.
--                 Applies data cleansing, standardization, deduplication, data type conversion, date validation,
--                 business-rule corrections, and derived field calculations during the transformation process.
--                 Processes CRM and ERP customer, product, sales, location, and product category information.
--                 Existing Silver Layer data is truncated before each load to ensure a fresh and consistent dataset.
--                 Post-load SELECT statements are included to verify the successfully transformed data.
-- LAYER         : Silver
-- OBJECTIVE     : Transform and cleanse raw Bronze Layer data into structured, standardized, and
--                 analysis-ready Silver Layer data for downstream Gold Layer processing.
--===============================================================================================================================
--==================================================================================================================================
-- Load data in Silver layer

-- Load data in Customer Information (CRM) Table in Silver Layer
--==================================================================================================================================
PRINT '>> Truncating Table: silver.crm_cust_info';
Truncate Table silver.crm_cust_info;
PRINT '>> Inserting Data Into: silver.crm_cust_info';
INSERT INTO silver.crm_cust_info (
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date)

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

SELECT * FROM silver.crm_cust_info


--===================================================================================================================================
-- Load Data in Product Information (CRM) Table in Silver Layer
--===================================================================================================================================
PRINT '>> Truncating Table: silver.crm_prd_info ';
Truncate Table silver.crm_prd_info ;
PRINT '>> Inserting Data Into: silver.crm_prd_info ';
INSERT INTO silver.crm_prd_info 
(
    prd_id,         
    cat_id,          
    prd_key,
    prd_nm,
    prd_cost,        
    prd_line,       
    prd_start_dt,    
    prd_end_dt
)

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


SELECT * FROM silver.crm_prd_info


--=====================================================================================================================================
-- Load Data in Sales Details Table (CRM) in Silver Layer
--===================================================================================================================================
PRINT '>> Truncating Table: silver.crm_sales_details';
Truncate Table silver.crm_sales_details ;
PRINT '>> Inserting Data Into: silver.crm_sales_details';
INSERT INTO silver.crm_sales_details
(
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
)

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

SELECT * FROM silver.crm_sales_details


--=====================================================================================================================
-- Load Data in CUSTOMER INFORMATION (ERP) Table in Silver Layer
--=====================================================================================================================
PRINT '>> Truncating Table: silver.erp_cust_az12';
Truncate Table silver.erp_cust_az12 ;
PRINT '>> Inserting Data Into: silver.erp_cust_az12';
INSERT INTO silver.erp_cust_az12 (
    cid,
    bdate,
    gen)

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

SELECT * FROM silver.erp_cust_az12 

--===========================================================================================================================
-- Load Data in LOCATION INFORMATION (ERP) Table in Silver Layer
--===========================================================================================================================
PRINT '>> Truncating Table: silver.erp_loc_a101';
Truncate Table silver.erp_loc_a101 ;
PRINT '>> Inserting Data Into: silver.erp_loc_a101';
INSERT INTO silver.erp_loc_a101 (
cid,
cntry
)
SELECT 
    REPLACE(cid, '-', '') AS cid,
    CASE
        WHEN TRIM(cntry) = 'DE' THEN 'Germany'
        WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
        WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A'
        ELSE TRIM(cntry)
    END AS cntry
FROM bronze.erp_loc_a101;

SELECT * FROM silver.erp_loc_a101

--===========================================================================================================================
-- Load Data in PRODUCT CATEGORY (ERP) Table in Silver Layer
--===========================================================================================================================
PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
Truncate Table silver.erp_px_cat_g1v2;
PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
INSERT INTO silver.erp_px_cat_g1v2
(
    id,
    cat,
    subcat,
    maintenance
)

SELECT 
    id,
    cat,
    subcat,
    maintenance
FROM bronze.erp_px_cat_g1v2;

SELECT * FROM silver.erp_px_cat_g1v2;
