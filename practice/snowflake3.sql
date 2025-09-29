How bulk loading can be scheduled ?
1) Using Snowflake Native Scheduling – Tasks
2) Use External Scheduler (Airflow, ADF, etc.)
3) Script + Unix Cron Job


Steps in Using Snowflake Native Scheduling – Tasks
-Create stored procedure
-Create Task & Enable it


-Write a stored procedure to perform COPY INTO:
CREATE OR REPLACE PROCEDURE sp_load_bank_txn()
RETURNS STRING
LANGUAGE SQL
AS
$$
COPY INTO bank_transactions
FROM @azure_stage1
FILE_FORMAT = (FORMAT_NAME = 'csv_format')
ON_ERROR = 'CONTINUE';
RETURN 'Load complete';
$$;

-Create a task to schedule it:
CREATE OR REPLACE TASK task_load_bank_txn
WAREHOUSE = my_wh
SCHEDULE = '1 HOUR'  -- every hour
WHEN SYSTEM$STREAM_HAS_DATA('your_stream') = FALSE -- optional
AS
CALL sp_load_bank_txn();
Start the task:

-Enabling task
ALTER TASK task_load_bank_txn RESUME;

=Please show complete working example with Snowflake Task + Procedure
✅ Creating a stored procedure
✅ Creating a task to schedule loading using COPY INTO
✅ Automatically loading files from a stage
✅ Handling common options like error tolerance and file pattern

✅ Scenario
Stage: @azure_stage1 (external stage pointing to Azure Blob Storage)
Files: bank_transactions_20250726.csv, bank_transactions_20250727.csv, etc.
Target table: bank_transactions
File format: 'csv_format'
Schedule: Every day at 2 AM

🔧 Step-by-Step Setup
🔹 1. Create File Format (if not already)
CREATE OR REPLACE FILE FORMAT csv_format
  TYPE = 'CSV'
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  SKIP_HEADER = 1
  NULL_IF = ('NULL', 'null');

🔹 2. Create Target Table
CREATE OR REPLACE TABLE bank_transactions (
  txn_id STRING,
  customer_id STRING,
  txn_date DATE,
  amount NUMBER(10,2),
  status STRING
);

🔹 3. Create Stored Procedure for COPY INTO
CREATE OR REPLACE PROCEDURE sp_load_bank_transactions()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
  COPY INTO bank_transactions
  FROM @azure_stage1
  FILE_FORMAT = (FORMAT_NAME = 'csv_format')
  PATTERN = '.*bank_transactions_.*\.csv'
  ON_ERROR = 'CONTINUE';
  RETURN 'COPY complete';
END;
$$;
✅ PATTERN ensures only matching files are loaded.
✅ ON_ERROR = 'CONTINUE' skips bad records but logs them.

🔹 4. Create Task to Run Daily at 2 AM
CREATE OR REPLACE TASK task_daily_load_bank_txns
  WAREHOUSE = my_wh
  SCHEDULE = 'USING CRON 0 2 * * * Asia/Kolkata'
AS
  CALL sp_load_bank_transactions();

🔹 5. Start the Task
ALTER TASK task_daily_load_bank_txns RESUME;

✅ Monitoring & Logs
Use SHOW TASKS to check status
Query task history:
SELECT *
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
  TASK_NAME => 'TASK_DAILY_LOAD_BANK_TXNS'
))
ORDER BY SCHEDULED_TIME DESC;
=============
End-to-end example for Snowpipe with Azure Event Grid setup

Here is a complete end-to-end Snowpipe setup example with Azure Blob Storage and Event Grid. This enables automated, real-time data loading into Snowflake whenever new files (like bank_transactions_*.csv) are uploaded to your Azure container.

🔄 Overview of Flow
New CSV file uploaded to Azure Blob container
Azure Event Grid sends notification to Snowflake
Snowpipe loads data into target table in near real time

✅ Prerequisites
You have an Azure Blob container
You’ve already created an external storage integration in Snowflake (e.g., azure_int)
You have admin privileges in both Snowflake and Azure

🔧 Step-by-Step Snowpipe Setup
🔹 1. Create Target Table
CREATE OR REPLACE TABLE bank_transactions_pipe (
  txn_id STRING,
  customer_id STRING,
  txn_date DATE,
  amount NUMBER(10,2),
  status STRING
);

🔹 2. Create File Format
CREATE OR REPLACE FILE FORMAT csv_format
  TYPE = 'CSV'
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  SKIP_HEADER = 1;

🔹 3. Create External Stage
CREATE OR REPLACE STAGE azure_stage_pipe
  URL = 'azure://<your-container>.blob.core.windows.net/<path>'
  STORAGE_INTEGRATION = azure_int;

Replace:
<your-container> with your container name
<path> with the folder (or leave empty if root)

🔹 4. Create Snowpipe with AUTO_INGEST
CREATE OR REPLACE PIPE pipe_bank_transactions
  AUTO_INGEST = TRUE
  AS
  COPY INTO bank_transactions_pipe
  FROM @azure_stage_pipe
  FILE_FORMAT = (FORMAT_NAME = 'csv_format')
  PATTERN = '.*bank_transactions_.*\.csv';
✅ This is the core object that listens for file events.

🔹 5. Get Notification Channel from Snowflake
DESC PIPE pipe_bank_transactions;
Copy the value under notification_channel — it will look like:
AZURE_EVENT_GRID_TOPIC: <long-URL-string>

🔹 6. Azure Setup (via Portal or CLI)
📌 A. Go to Azure Portal
Navigate to your Blob Storage container
Go to Events → + Event Subscription
📌 B. Create Event Subscription
Name: snowflakepipe-sub
Event Types: Only Blob Created

Endpoint Type: Web Hook

Endpoint URL: Paste the notification_channel from Step 5 (without quotes)

🔒 Azure will validate the URL automatically with Snowflake.

🔹 7. Test: Upload a File to Azure
Upload a test file like bank_transactions_20250727.csv into the linked blob container.

🔹 8. Check Load Status in Snowflake
SELECT *
FROM TABLE(INFORMATION_SCHEMA.LOAD_HISTORY(
  PIPE_NAME => 'PIPE_BANK_TRANSACTIONS'
))
ORDER BY LAST_LOAD_TIME DESC;

=============
What is Snowpipe?
Snowpipe is a continuous data ingestion mechanism in Snowflake that:
-Automatically loads files from external stages (like Azure Blob, AWS S3, GCS)
-Loads data as soon as new files arrive
-Requires no manual trigger (COPY INTO) once set up


