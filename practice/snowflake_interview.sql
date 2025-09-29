Interview Preperation Foundation
================================
0.1) What is the contribution to the project
     -We are into ELT activities 
	 -Extraction & Loading Data into Snowflake (Bulk Load/snowpipe/snowpipe Streaming/Data Sharing & Stream (CDC operation within snowflake))
	 -CDC Tool Oracle Golden Gate (CDC captures redo logs)
	 -Applying Transfromations using DBT (Staging/Models/Marts), snowflake scripting, snowpark using python
1.1) How do we check which database, schema and role we are into 
1.2) Where we can get metadata of our created objects in snowflake
2.1) What is Storage integration
     -is a secure object 
	 -stores authentication credentials & configuration required to access external cloud storage (AWS S3/Azure Blob/GCP).
     -It acts as a bridge between Snowflake and external storage without exposing access keys/passwords directly to users
2.2) Parameters considered while creating Storage integration
	 type of stage|storage_provider|AZURE_TENANT_ID|ENABLED|STORAGE_ALLOWED_LOCATIONS
2.3) Steps to establish connection between snowflake and azure (Pl use ssh key and make it private)
     -create storage integration [type of stage|storage_provider|AZURE_TENANT_ID|ENABLED|STORAGE_ALLOWED_LOCATIONS]
	 -create file format [type|field delimiter|skip header|nullif|compression]
	 -create stage [Azure container url|storage integration|file format] [AccountAdmin role]
	 -Azure : Grant access to snowflake
	 -copy into table from @azure_stage1/ OR @azure_stage1/Covid_01012021.csv [file_format| on_error]  --This is Bulk Loading Multiple files/Single files
2.4) Can we load multiple files into single staging table from Azure? Yes
2.5) In one staging (azure_stage1), can we load data into multiple tables with different structures. The csv files are bank_transactions_20250726.csv,   
     bank_transactions_20250727.csv have same structure and customer_joined_20250726.csv, customer_joined_20250727.csv is having different structure
	 Yes, We can but with the help of PATTERN
	 FILE_FORMAT = (FORMAT_NAME = 'bank_txn_format')
     PATTERN = '.*bank_transactions_.*\.csv'
	 FILE_FORMAT = (FORMAT_NAME = 'customer_data_format')
	 PATTERN = '.*customer_joined_.*\.csv'
2.6) For different file formats like csv, json, parqut,  is it possible to use same stage ?
     Yes, ✅ you can use the same stage (like @azure_stage1) to store and load different file formats (CSV, JSON, PARQUET, etc.) in Snowflake.
2.7) Can i reload the file again even if it was already loaded into snowflake.
     Generally, snowflake will not reload the same file data. But if we want to do so, then FORCE=TRUE should be specified.
     COPY INTO bank_transactions
 	 FROM @azure_stage1/
	 FILE_FORMAT = (FORMAT_NAME = 'csv_format')
	 PATTERN = '.*bank_transactions_.*\.csv'
	 FORCE = TRUE
	 ON_ERROR = 'CONTINUE';	 
2.8) How to identify bad records while loading data into table. Pl capture bad records in error table
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
2.9)Create stored procedure to perform copy into operations and accordingly create a task and schedule it
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

	🔹 Create Task to Run Daily at 2 AM
	CREATE OR REPLACE TASK task_daily_load_bank_txns
	  WAREHOUSE = my_wh
	  SCHEDULE = 'USING CRON 0 2 * * * Asia/Kolkata'
	AS
	  CALL sp_load_bank_transactions();

	🔹 Start the Task
	ALTER TASK task_daily_load_bank_txns RESUME;
	
2.10)Steps to Schedule Task which calls Procedure to load data into snowflake table from stage (Bulk Load)
     -Create Stage (Storage Integration,File Fromat)
	 -Create Procedure
	 -Create Task and then Activate Task  (Similar to Autosys Job scheduler which trigger at specific Days and time)

2.11)Can we use the same stage for different file formats (Csv/Json/Txt/Parquet)
     Yes, you can use the same stage (internal or external), because a stage is just a pointer to a storage location (Snowflake-managed or S3/Azure/GCS).
     A stage itself does not lock to a single file format.
	 However, in practice, we often separate by folders or patterns to avoid mixing file formats accidentally.

You decide the file format at the time of COPY INTO (or by assigning a default file format when creating the stage).
	
3.1) How Snowpipe with AUTO_INGEST is different from Bulk Load
     -Bulk Load only required for fixed scheduler
	 -Snowpipe with Auto_Ingest acts instantly on file upload in Azure Blob
  	  CREATE OR REPLACE PIPE pipe_bank_transactions
	  AUTO_INGEST = TRUE
	  AS
	  COPY INTO bank_transactions_pipe
	  FROM @azure_stage_pipe
	  FILE_FORMAT = (FORMAT_NAME = 'csv_format')
	  PATTERN = '.*bank_transactions_.*\.csv';
4.1)Steps to create Notification Integration	  
    TYPE|NOTIFICATION_PROVIDER|ENABLED|AZURE_STORAGE_QUEUE_PRIMARY_URI|AZURE_TENANT_ID
4.2)Setting up snowpipe
    -Create Container (Resource Group-storage account)
	-Register Event Grid & Create Queue/Topic/Event [Queue : Receiver, Event : Sender]
	-Create Notification Integration (snowflake) & provide access to Storage Queue
	-Create Stage
	-Create Snowpipe with Auto Ingest (In Bulk Load, here we used to create Procedure and Task, Snowpipe will auto run based on file availability in azure)
4.3) Types of Stage
     -External Stage
	 -Internal Stage
	 -User Stage
	 -Table Stage
5.1) What is Stream 
     A bank has a transactions table where millions of records come in daily from multiple payment systems.
     Downstream, Finance needs a reconciliation fact table (fact_transactions) for reporting.
     Instead of reloading the whole source table every time (expensive + slow), they just want incremental inserts/updates/deletes.
5.2) What is snowpipe streaming
     Snowpipe Streaming is all about letting a source application (or CDC connector) push data directly into a Snowflake table through an API, instead of dropping files into cloud storage first.
5.3) Can we take base table of oracle or some other database and create stream in snowflake ?
5.4) Can oracle golden gate load data directly from oracle table to Azure Blob as csv file : Yes
5.5) Can oracle golden gate load data directly from oracle table to Snowflake table : Yes with Snowpipe Streaming API
 
	 
	 
	 
