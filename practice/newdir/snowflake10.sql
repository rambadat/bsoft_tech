Building data engineering pipelines with Python
===============================================

Build pipelines with below steps (As per snowpark Documentation)
----------------------------------------------------------------

Explanation : https://quickstarts.snowflake.com/guide/data_engineering_pipelines_with_snowpark_python/index.html#0

Code :
https://github.com/Snowflake-Labs/snowflake-demo-notebooks/blob/main/Data%20Engineering%20Pipelines%20with%20Snowpark%20Python/Data%20Engineering%20Pipelines%20with%20Snowpark%20Python.ipynb

1) Overview
2) QuickStart setup (Create GitHub Codespace)
3) Setup Snowflake
4) Load Raw  (loading POS and Customer data from AWS Parquet files to snowflake schema RAW_POS and RAW_CUSTOMER)
5) Load Weather (accessing weather data shared by Weather Source in Snowflake Marketplace)
6) Create POS View and Stream on View
7) Create Fahrenheit to Celsius UDF and Deploying snowpark UDF to snowflake through SnowCLI tool
8) Create Orders Update Sproc and Deploying snowpark procedure to snowflake through SnowCLI tool
9) Create Daily City Metrics Update Sproc and Deploying snowpark procedure to snowflake through SnowCLI tool
10)Orchestrate Jobs with Tasks
11)Process Incrementally
12)Deploy Via CI/CD
13)Teardown
14)Conclusion



Build pipelines to acheive the below points (Customized) 
--------------------------------------------------------
-Read data from Azure Blob Storage (CSV) → Snowflake stage.
-Read existing table (RAW_CUSTOMERS)
-Transform + Merge both sources.
-Write into target table.
-Run automatically with Task.

Below points needs to be taken care to acheive above
Create External stage for Azure Blob
Create Azure Queue + Event Subscription (for notifications)
Create Notification Integration (MY_NOTIF_INTEGRATION)
Create Logs table
Create Snowpark Python stored procedure (with try/except, logging, and failure notification)
Create Event-driven automation (runs when CSV lands) via Snowpipe + Task AFTER PIPE (Automated Job)
(Optional) Scheduled task as a fallback  (Schedule Job)

Flow:
Blob upload ➜ Event Grid ➜ Snowpipe loads rows ➜ Task (AFTER PIPE) ➜ calls procedure ➜ transforms ➜ writes curated ➜ logs + notifies on failure.

🔹 1) (One-time) Storage Integration + External Stage + File Format
-- A) Storage integration (Snowflake ↔ Azure Blob access)
CREATE OR REPLACE STORAGE INTEGRATION AZURE_INT
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = AZURE
  ENABLED = TRUE
  AZURE_TENANT_ID = '<YOUR-AZURE-TENANT-ID>'
  STORAGE_ALLOWED_LOCATIONS = ('azure://<storage-account>.blob.core.windows.net/<container>');

-- B) External stage pointing to your container/folder
CREATE OR REPLACE STAGE AZURE_STAGE
  URL = 'azure://<storage-account>.blob.core.windows.net/<container>/<optional-prefix>'
  STORAGE_INTEGRATION = AZURE_INT;

-- C) CSV file format (tweak as needed)
CREATE OR REPLACE FILE FORMAT CSV_FF
  TYPE = CSV
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  SKIP_HEADER = 1
  NULL_IF = ('\\N','NULL','null');

🔹 2) (One-time) Azure Queue + Event Subscription + Notification Integration
--Azure side (portal):
Create Storage Queue (e.g., snowflake-notifications) in your storage account.
Create an Event Grid subscription (or Logic App) to forward snowflake messages from this queue to Email/Teams (your choice).

--Snowflake side (notify you on failures):
CREATE OR REPLACE NOTIFICATION INTEGRATION MY_NOTIF_INTEGRATION
  TYPE = QUEUE
  ENABLED = TRUE
  AZURE_STORAGE_QUEUE_PRIMARY_URI = 'https://<storage-account>.queue.core.windows.net/snowflake-notifications'
  AZURE_TENANT_ID = '<YOUR-AZURE-TENANT-ID>';

🔹 3) (One-time) Staging Table for Auto-Ingest + Snowpipe
-- Landing/staging table into which Snowpipe loads CSV rows
CREATE OR REPLACE TABLE RAW_CUSTOMERS_STAGE (
  ID     INT,
  NAME   STRING,
  SPEND  FLOAT,
  STATUS STRING
);

-- Event-based ingestion: when a file lands in the stage, Snowpipe loads it here
CREATE OR REPLACE PIPE CUSTOMER_PIPE
  AUTO_INGEST = TRUE
AS
  COPY INTO RAW_CUSTOMERS_STAGE
  FROM @AZURE_STAGE
  FILE_FORMAT = (FORMAT_NAME = CSV_FF);


Note : After creating the pipe, complete Azure Event Grid hookup:
In Azure Portal, create an Event Grid Subscription on the storage account for Blob Created events.
Use the Snowflake-provided Snowpipe endpoint (from DESC PIPE CUSTOMER_PIPE) as the Webhook destination for event notifications.

🔹 4) (One-time) Logs Table
CREATE OR REPLACE TABLE PIPELINE_LOGS (
  RUN_ID STRING,
  RUN_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP,
  STATUS STRING,
  MESSAGE STRING
);

🔹 5) Snowpark Python Stored Procedure (with exception,logging + failure notification)
CREATE OR REPLACE PROCEDURE RUN_CUSTOMER_PIPELINE()
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'main'
AS
$$
import snowflake.snowpark as snowpark
from snowflake.snowpark.functions import col, upper, lit, when
import traceback, uuid

def main(session: snowpark.Session):
    run_id = str(uuid.uuid4())
    try:
        # ---- Context (optional if set via worksheet/role defaults) ----
        session.use_role("DEVELOPER060725")
        session.use_warehouse("WH060725")
        session.use_database("DB060725")
        session.use_schema("SCH060725")

        # ---- Ingest sources ----
        # A) Auto-ingested records from Snowpipe
        stage_df = session.table("RAW_CUSTOMERS_STAGE")

        # B) Existing application table (optional source)
        #    If you dont need it, comment the next line and use stage_df alone.
        base_df = session.table("RAW_CUSTOMERS")

        # ---- Combine (union) both sources (schemas must match) ----
        # If RAW_CUSTOMERS may be empty/missing columns, adjust schema/select to align.
        combined_df = base_df.union_all(stage_df)

        # ---- Transform ----
        transformed_df = (
            combined_df
              .filter(col("STATUS") == lit("active"))
              .with_column("NAME_UPPER", upper(col("NAME")))
              .with_column(
                  "SEGMENT",
                  when(col("SPEND") > 1000, lit("Premium")).otherwise(lit("Regular"))
              )
              .select("ID", "NAME_UPPER", "SPEND", "SEGMENT")
        )

        # ---- Load into curated table ----
        transformed_df.write.mode("overwrite").save_as_table("CURATED_CUSTOMERS")

        # ---- Log success ----
        session.table("PIPELINE_LOGS").insert(
            (run_id, None, "SUCCESS", "Pipeline executed successfully")
        )

        return "Pipeline executed successfully"

    except Exception:
        error_message = traceback.format_exc()

        # Log failure
        session.table("PIPELINE_LOGS").insert(
            (run_id, None, "FAILURE", error_message[:2000])
        )

        # Notify via Azure Queue integration (hook your Logic App/Teams/Email to this)
        session.sql(f"""
          call system$send_notification(
            'MY_NOTIF_INTEGRATION',
            'Customer pipeline FAILED',
            'Run ID: {run_id}\\nError: {error_message[:800]}'
          )
        """).collect()

        # Re-raise to surface the error to callers/tasks
        raise
$$;

🔹 6) Event-Driven Automation (runs when a file arrives)
When Snowpipe loads data into RAW_CUSTOMERS_STAGE, have a Task run right after the pipe and call the procedure:

CREATE OR REPLACE TASK CUSTOMER_PIPELINE_AFTER_PIPE
  WAREHOUSE = WH060725
  AFTER CUSTOMER_PIPE  ---This task will run automatically post customer_pipe completion
AS
  CALL RUN_CUSTOMER_PIPELINE();

-- Enable it
ALTER TASK CUSTOMER_PIPELINE_AFTER_PIPE RESUME;

🔹 7) (Optional) Scheduled Automation (fallback or in addition)
If you also want a daily safety run:
CREATE OR REPLACE TASK CUSTOMER_PIPELINE_DAILY
  WAREHOUSE = WH060725
  SCHEDULE = 'USING CRON 30 0 * * * Asia/Kolkata'  -- 6:00 AM IST
AS
  CALL RUN_CUSTOMER_PIPELINE();

ALTER TASK CUSTOMER_PIPELINE_DAILY RESUME;
