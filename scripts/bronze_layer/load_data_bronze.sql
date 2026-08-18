--===============================================================================================================================
-- SCRIPT        : Bronze Layer Data Loading & Date Format Handling
-- DESCRIPTION   : Loads raw CRM and ERP source data from CSV files into the corresponding Bronze Layer
--                 tables using BULK INSERT. Includes handling of date-format issues encountered during
--                 CSV ingestion by loading date values as text through staging tables and explicitly
--                 converting MM/DD/YYYY formatted dates before inserting them into the Bronze Layer.
--                 Existing data is truncated before loading to ensure a fresh and consistent raw-data load.
--                 The script also includes post-load verification queries to validate successful data loading.
-- LAYER         : Bronze
-- OBJECTIVE     : Populate the Bronze Layer with raw source data while preventing date-format conversion
--                 errors and verifying the successful completion of the data-loading process.
--===============================================================================================================================
--Load 1st table bronze.crm_cust_info
--===============================================================================================================================
----- if we have probem for date format then load the table by using this method----
---Step 1 — Create a staging table

IF OBJECT_ID('bronze.crm_cust_info_staging', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info_staging;
GO

CREATE TABLE bronze.crm_cust_info_staging (
    cst_id              INT,
    cst_key             NVARCHAR(50),
    cst_firstname       NVARCHAR(50),
    cst_lastname        NVARCHAR(50),
    cst_marital_status  NVARCHAR(50),
    cst_gndr            NVARCHAR(50),
    cst_create_date     NVARCHAR(50)
);
GO

---Step 2 — Bulk insert into staging

BULK INSERT bronze.crm_cust_info_staging
FROM 'C:\SQL2025\datasets\source_crm\cust_info.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    TABLOCK
);
GO

---Step 3 — Convert MM/DD/YYYY explicitly in your actual table

INSERT INTO bronze.crm_cust_info
(
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date
)
SELECT
    cst_id,
    TRIM(cst_key),
    TRIM(cst_firstname),
    TRIM(cst_lastname),
    TRIM(cst_marital_status),
    TRIM(cst_gndr),
    TRY_CONVERT(DATE, TRIM(cst_create_date), 101)
FROM bronze.crm_cust_info_staging;
GO

SELECT * FROM bronze.crm_cust_info
GO
--========================================================================================================================================
--Load 2nd table bronze.crm_prd_info
--=========================================================================================================================================	
TRUNCATE TABLE bronze.crm_prd_info;
BULK INSERT bronze.crm_prd_info
FROM 'C:\SQL2025\datasets\source_crm\prd_info.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

SELECT * FROM bronze.crm_prd_info;
GO	
--===========================================================================================================================================
--Load 3rd table bronze.crm_sales_details
--=========================================================================================================================================	

TRUNCATE TABLE bronze.crm_sales_details;
BULK INSERT bronze.crm_sales_details
FROM 'C:\SQL2025\datasets\source_crm\sales_details.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

SELECT * FROM bronze.crm_sales_details;
GO
--===========================================================================================================================================
--Load 4th table bronze.erp_cust_az12
--=========================================================================================================================================	
	
TRUNCATE TABLE bronze.erp_cust_az12;
BULK INSERT bronze.erp_cust_az12
FROM 'C:\SQL2025\datasets\source_erp\CUST_AZ12.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

SELECT * FROM bronze.erp_cust_az12;
GO	
--===========================================================================================================================================
--Load 5th table bronze.erp_loc_a101
--=========================================================================================================================================	
	
TRUNCATE TABLE bronze.erp_loc_a101;
BULK INSERT bronze.erp_loc_a101
FROM 'C:\SQL2025\datasets\source_erp\LOC_A101.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

SELECT * FROM bronze.erp_loc_a101;
GO	
--===========================================================================================================================================
--Load 6th table bronze.erp_px_cat_g1v2
--=========================================================================================================================================	
	
TRUNCATE TABLE bronze.erp_px_cat_g1v2;
BULK INSERT bronze.erp_px_cat_g1v2
FROM 'C:\SQL2025\datasets\source_erp\PX_CAT_G1V2.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

SELECT * FROM bronze.erp_px_cat_g1v2;
GO
