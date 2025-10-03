use WAREHOUSE wh060725;
use role developer060725;
use database db060725;
use SCHEMA sch060725;

select current_warehouse(),current_database(), current_schema(),current_user(),current_role() from dual;

grant create table ON SCHEMA db060725.sch060725 to role developer060725;
use role accountadmin;

use role developer060725;

CREATE TABLE COVID_DATA_2021
(
FIPS	                 INT,
Admin2	                 STRING,
Province_State	         STRING,
Country_Region	         STRING,
Last_Update	             DATETIME,
Lat	                     DOUBLE,
Long_	                 DOUBLE,
Confirmed                INT,	
Deaths	                 INT,
Recovered	             INT,
Active	                 INT,
Combined_Key	         STRING,
INCIDENT_RATE            DOUBLE,
Case_Fatality_Ratio      DOUBLE
);


-- change role to accountadmin and execute the following
use role accountadmin;
create or replace storage integration azure_integration
type = external_stage
storage_provider = 'AZURE'
AZURE_TENANT_ID = 'd1d874b6-63e2-494d-a5f2-00408239d47c'
ENABLED = TRUE
STORAGE_ALLOWED_LOCATIONS = ('azure://prajstorage1.blob.core.windows.net/prajcontainer1');

SHOW STORAGE INTEGRATIONS;
DESCRIBE INTEGRATION azure_integration;

CREATE OR REPLACE FILE FORMAT snflk_csv_format
TYPE = 'CSV'
FIELD_DELIMITER = ','
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
SKIP_HEADER = 1
NULL_IF = ('NULL','null')
COMPRESSION = 'AUTO';

-- change role to accountadmin
CREATE OR REPLACE STAGE azure_stage1
URL = 'azure://prajstorage1.blob.core.windows.net/prajcontainer1'
STORAGE_INTEGRATION = azure_integration
FILE_FORMAT = snflk_csv_format;



GRANT USAGE, READ, WRITE ON STAGE db060725.sch060725.azure_stage1 TO ROLE developer060725;
GRANT CREATE STAGE ON SCHEMA db060725.sch060725 TO ROLE developer060725;

--Azure Process
We need to grant access to snowflake so that it can read files in Azure Storage
-Go to Storage account
-Access Control
-Add role assignment
-Privilege Storage Blob Data Contributor needs to be given to yu6iipsnowflakepacint
-Describe storage integration and click on AZURE_CONSENT_URL (Accept it)
-Azure_Multi_Tenant_APP_NAME : yu6iipsnowflakepacint (Take string Till Before Underscore)

-- as ROLE developer060725
use role developer060725;
COPY INTO COVID_DATA_2021
FROM @azure_stage1/Covid_01012021.csv
FILE_FORMAT = (FORMAT_NAME = 'snflk_csv_format')
ON_ERROR = 'CONTINUE';

SELECT * FROM COVID_DATA_2021;

Bulk Loading is nothing but COPY INTO (Manual/Scheduled).

===============================================
--Interview questions
===============================================
Question 1 : Can we load multiple files into single staging table from Azure
Yes, ✅ you can load multiple files into the same table in Snowflake — in fact, it’s one of Snowflake’s strengths.
If your files are in the same stage (e.g., @azure_stage1) and have a common pattern or extension, you can load them all at once:

COPY INTO covid_data_all
FROM @azure_stage1/
FILE_FORMAT = (FORMAT_NAME = 'snflk_csv_format')
ON_ERROR = 'CONTINUE';

This command loads all CSV files in the stage @azure_stage1.

Question 2 : In Azure, daily the file will get uploaded eg bank_transactions_20250726,bank_transactions_20250727 and so on
customer_joined_20250726,customer_joined_20250727 and so on

COPY INTO Bank_Transactions
FROM @azure_stage1/bank_transactions_20250726.csv
FILE_FORMAT = (FORMAT_NAME = 'snflk_csv_format')
ON_ERROR = 'CONTINUE';

COPY INTO Customer_Transactions
FROM @azure_stage1/customer_joined_20250726.csv
FILE_FORMAT = (FORMAT_NAME = 'snflk_csv_format')
ON_ERROR = 'CONTINUE';


Question 2 : in one staging (azure_stage1), can we load data into multiple tables with different structures. The csv files are bank_transactions_20250726.csv,bank_transactions_20250727.csv have same structure and customer_joined_20250726.csv, customer_joined_20250727.csv is having different structure

Yes, Prajeesh — ✅ you can absolutely use a single external stage (like @azure_stage1) to load different CSV files into different tables with different structures, even if all files are stored in the same container/folder.

But since the files have different schemas, you’ll need to filter the files using PATTERN or load them explicitly using separate COPY INTO statements for each group.

bank_transactions_20250726.csv, bank_transactions_20250727.csv → same structure → go to bank_transactions table
customer_joined_20250726.csv, customer_joined_20250727.csv → different structure → go to customer_data table

COPY INTO bank_transactions
FROM @azure_stage1/
FILE_FORMAT = (FORMAT_NAME = 'bank_txn_format')
PATTERN = '.*bank_transactions_.*\.csv'
ON_ERROR = 'CONTINUE';

COPY INTO customer_data
FROM @azure_stage1/
FILE_FORMAT = (FORMAT_NAME = 'customer_data_format')
PATTERN = '.*customer_joined_.*\.csv'
ON_ERROR = 'CONTINUE';

Question 3 : For different file formats like csv, json, parqut,  is it possible to use same stage ?
Yes, ✅ you can use the same stage (like @azure_stage1) to store and load different file formats (CSV, JSON, PARQUET, etc.) in Snowflake.

--create stage without file format
CREATE OR REPLACE STAGE azure_stage1 
  URL = 'azure://<your-container-name>.blob.core.windows.net/<path>'
  STORAGE_INTEGRATION = your_azure_integration;
  
you have these files stored in a single stage (@azure_stage1):
bank_transactions_20250726.csv → CSV
customer_events_20250726.json → JSON
product_master_20250726.parquet → Parquet

Each file format will require:
A separate COPY INTO command
A matching file format definition (FILE_FORMAT)  

-- For CSV files
CREATE OR REPLACE FILE FORMAT csv_format
  TYPE = 'CSV'
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  SKIP_HEADER = 1;

-- For JSON files
CREATE OR REPLACE FILE FORMAT json_format
  TYPE = 'JSON';

-- For Parquet files
CREATE OR REPLACE FILE FORMAT parquet_format
  TYPE = 'PARQUET';


-- Load CSV into bank_transactions
COPY INTO bank_transactions
FROM @azure_stage1/
FILE_FORMAT = (FORMAT_NAME = 'csv_format')
PATTERN = '.*bank_transactions_.*\.csv'
ON_ERROR = 'CONTINUE';

-- Load JSON into customer_events
COPY INTO customer_events
FROM @azure_stage1/
FILE_FORMAT = (FORMAT_NAME = 'json_format')
PATTERN = '.*customer_events_.*\.json'
ON_ERROR = 'CONTINUE';

-- Load Parquet into product_master
COPY INTO product_master
FROM @azure_stage1/
FILE_FORMAT = (FORMAT_NAME = 'parquet_format')
PATTERN = '.*product_master_.*\.parquet'
ON_ERROR = 'CONTINUE';

Question 4 : Can i reload the file again even if it was already loaded into snowflake.

Generally, snowflake will not reload the same file data. But if we want to do so, then FORCE=TRUE should be specified.

COPY INTO bank_transactions
FROM @azure_stage1/
FILE_FORMAT = (FORMAT_NAME = 'csv_format')
PATTERN = '.*bank_transactions_.*\.csv'
FORCE = TRUE
ON_ERROR = 'CONTINUE';



Question 6 : How to identify bad records while loading data into table.

Step 1: Load Using ON_ERROR = 'CONTINUE'
COPY INTO bank_transactions
FROM @azure_stage1/bank_transactions_20250726.csv
FILE_FORMAT = (FORMAT_NAME = 'csv_format')
ON_ERROR = 'CONTINUE';

This will:
Load good records
Skip bad ones
Log the failed ones internally (but doesn’t load them)

Step 2: Run COPY INTO in Validation Mode
COPY INTO bank_transactions
FROM @azure_stage1/bank_transactions_20250726.csv
FILE_FORMAT = (FORMAT_NAME = 'csv_format')
VALIDATION_MODE = 'RETURN_ERRORS';

This will not load any data, but instead return a list of the records that would fail, with:
Line number
Column number
Error message
Raw row data (if possible)

Step 3: Optionally Save These Errors to a Table
CREATE OR REPLACE TABLE bank_txn_load_errors (
  row_number INT,
  error_column NUMBER,
  error_message STRING,
  raw_record STRING
);

INSERT INTO bank_txn_load_errors
SELECT * FROM 
  TABLE(
    VALIDATE(
      TABLE_NAME => 'bank_transactions',
      LOCATION => '@azure_stage1/bank_transactions_20250726.csv',
      FILE_FORMAT => 'csv_format',
      VALIDATION_MODE => 'RETURN_ERRORS'
    )
  );
  
5.Can we use the same stage for different file formats? Yes
Yes, you can use the same stage (internal or external), because a stage is just a pointer to a storage location (Snowflake-managed or S3/Azure/GCS).
A stage itself does not lock to a single file format.
You decide the file format at the time of COPY INTO (or by assigning a default file format when creating the stage).

🔹 Example 1: Same stage, different file formats
-- Stage pointing to Azure Blob
CREATE OR REPLACE STAGE my_stage 
  url='azure://mycontainer.blob.core.windows.net/myfolder';

-- Copy CSV
COPY INTO my_table_csv
FROM @my_stage
FILE_FORMAT = (TYPE=CSV FIELD_OPTIONALLY_ENCLOSED_BY='"');

-- Copy JSON
COPY INTO my_table_json
FROM @my_stage
FILE_FORMAT = (TYPE=JSON);

-- Copy Parquet
COPY INTO my_table_parquet
FROM @my_stage
FILE_FORMAT = (TYPE=PARQUET);


🔹 Example 2: Stage with a default format (but override possible)
CREATE OR REPLACE STAGE my_stage_csv
  url='azure://mycontainer.blob.core.windows.net/csvfolder'
  FILE_FORMAT = (TYPE=CSV);

-- If files are CSV, you don’t need to specify file_format
COPY INTO my_table FROM @my_stage_csv;

-- But you can still override it
COPY INTO my_table_json
FROM @my_stage_csv
FILE_FORMAT = (TYPE=JSON);

⚠️ Best Practices
If your stage contains mixed file types (CSV + JSON + Parquet in the same folder), you should either:
Use pattern matching (PATTERN option) to select files by extension.
COPY INTO my_table
FROM @my_stage
FILE_FORMAT = (TYPE=CSV)
PATTERN = '.*[.]csv';
Or maintain separate subfolders/stages for clarity.

Yes, the same stage can be used for CSV, JSON, and Parquet because a stage is just a storage pointer. The file format is applied at COPY INTO time, and you can even override defaults. However, in practice, we often separate by folders or patterns to avoid mixing file formats accidentally.

6. When to go for Azure SAS Token and When to go for Storage Integration

| Feature / Aspect          | **Azure SAS Token**                                                                | **Snowflake Storage Integration**
| ------------------------- | ---------------------------------------------------------------------------------- | -----------------------------------------
| **Setup Effort**          | Easy and quick – just generate a token and paste into Snowflake stage.             | More setup – needs Azure AD service       
                                                                                                                 | principal, tenant ID, and 
																								                 |  Snowflake integration object. 
| **Security**              | Weaker – token is a string that can be shared/compromised if not secured properly. | Stronger – uses OAuth with Azure AD; 
                                                                                                                 | Snowflake never stores permanent secrets.
| **Credential Rotation**   | Manual – tokens expire and must be regenerated + updated in Snowflake.             | Automatic – handled via OAuth integration 
                                                                                                                 | with Azure AD. No manual rotation needed
| **Granularity of Access** | Fine-grained, but static. You decide expiry + permissions at generation time.      | Controlled via RBAC in Azure AD (service 
                                                                                                                 | principal roles), much better for 
																												 | enterprises. 

Choose SAS Token when you need quick, temporary access or for prototyping/POC. It’s fast but not scalable because tokens expire and need manual rotation.
Choose Storage Integration for production workloads. It’s secure, automated, integrates with Azure AD, and is much easier to manage at scale.
👉 In real projects, almost all production Snowflake–Azure setups use Storage Integration, while SAS tokens are kept only for short-lived cases.





