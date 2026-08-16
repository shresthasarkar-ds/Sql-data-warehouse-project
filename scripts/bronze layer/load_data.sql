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



TRUNCATE TABLE bronze.crm_prd_info;
BULK INSERT bronze.crm_prd_info
FROM 'C:\SQL2025\datasets\source_crm\prd_info.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE bronze.crm_sales_details;
BULK INSERT bronze.crm_sales_details
FROM 'C:\SQL2025\datasets\source_crm\sales_details.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE bronze.erp_cust_az12;
BULK INSERT bronze.erp_cust_az12
FROM 'C:\SQL2025\datasets\source_erp\CUST_AZ12.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE bronze.erp_loc_a101;
BULK INSERT bronze.erp_loc_a101
FROM 'C:\SQL2025\datasets\source_erp\LOC_A101.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE bronze.erp_px_cat_g1v2;
BULK INSERT bronze.erp_px_cat_g1v2
FROM 'C:\SQL2025\datasets\source_erp\PX_CAT_G1V2.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

SELECT * FROM bronze.crm_prd_info;
GO
SELECT * FROM bronze.crm_sales_details;
GO
SELECT * FROM bronze.erp_cust_az12;
GO
SELECT * FROM bronze.erp_loc_a101;
GO
SELECT * FROM bronze.erp_px_cat_g1v2;
GO
