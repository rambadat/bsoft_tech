snowpipe
========
Flow of snowpipe
Blob uploaded → Event Grid detects event → System Topic (Event Grid) → Event Grid sends message to Azure Queue → Snowflake listens to Queue → Snowpipe triggers COPY INTO

1) In Azure, create Resource Group, storage account, container  
2) In Azure, We need to register Event Grid (if Event Grid is registered, then only we will get messages in Queue otherwise it will be empty)
   -Search for "Subscriptions" and open your current subscription.
   -In the left pane, select "Resource providers"
   -In the search box, type EventGrid.
   -Check the "Registration State" column:
   -Should show "Registered"
3) In Azure, Create Queue for Storage account [Receiver]
   -Navigate to Storage Account (prajstorage1)
   -Click on Storage Account
   -Navigate to Data Storage, Queue
   -Create Queue
   https://prajstorage1.queue.core.windows.net/prajsnowflakequeue
4) Create Topic 
   -Navigate to Event Grid
   -Go to Azure Service Events, Click on create under System Topics   
   -Fill below information
    Topic Types 	: Storage Account (Blob & GPv2)
	Subscription 	: Azure Subscription 1
	Resource Group 	: PrajResourceGroup1
	Resource 		: prajstorage1
	Note : We are creating only system topics with Blob Storage account and it is automatically created.
	We can create only one Topics for one storage account and same topics can be used for another different events.
4) In Azure, Create Event for Storage account [Sender]
   -Navigate to Storage Account (prajstorage1)
   -Navigate to Events (on left side)
   -Click +Event Subscription
   -Fill below details in Create Event Subscription 
	Name 			: prajsnowflakeevent
	Event Schema 	: Event Grid Schema
	Topic Type 		: Storage account
	Source Resource : prajstorage1
	Topic Name 		: prajsnowflaketopic
	Event Types 	: Blob created
	Endpoint Type   : Storage Queue
	Configure an Endpoint : We have to link Storage Account with required Queue.
     -subscription 	: Azure Subscription 1
	 -storage acct 	: prajstorage1
	 -Queue     	: Select Existing Queue (prajsnowflakequeue)
	 -Click on Create
5) Once Event has been created. To Cross check Azure Event (Spike entry in Graph) and Queue service (New message entry of uploaded file), we will upload file.
   -Navigate to Storage Account (prajstorage1)
   -Navigate to Data Storage, Container
   -Click on container (prajcontainer1)
   -Upload the file
6) In Snowflake, create notification integration 
   use role accountadmin;
   CREATE OR REPLACE NOTIFICATION INTEGRATION azure_notification_integration
   TYPE = QUEUE
   NOTIFICATION_PROVIDER = AZURE_STORAGE_QUEUE
   ENABLED = TRUE
   AZURE_STORAGE_QUEUE_PRIMARY_URI = 'https://prajstorage1.queue.core.windows.net/prajsnowflakequeue'
   AZURE_TENANT_ID = 'd1d874b6-63e2-494d-a5f2-00408239d47c';
7) In Azure,Access Control grant snowflakes notification integration (capqyssnowflakepacint) access to Storage Queue
   -Navigate to Storage Account (prajstorage1)
   -Navigate to Access Control (IAM)
   -Click on Add, Add Role Assignments, Select Storage Queue Data Contributor
   -Assign Access to : User, Group , Service Principal
   -Click Select Members (we need to fire in snowflake "Desc NOTIFICATION INTEGRATION azure_notification_integration,Copy value stored in AZURE_MULTI_TENANT_APP_NAME. Only take till prior to underscore")
8) In Snowflake, create Stage
   use role accountadmin
   CREATE OR REPLACE STAGE azure_stage1
   URL = 'azure://prajstorage1.blob.core.windows.net/prajcontainer1'
   STORAGE_INTEGRATION = azure_integration
   FILE_FORMAT = snflk_csv_format;
   
   list @azure_stage1;
   
   SELECT $1,$2,$3,$4,$5,$6,$7,$8,$9,$10
	FROM @azure_stage1/Covid_01012024.csv
	(FILE_FORMAT => 'snflk_csv_format');

9) In snowflake, create snowpipe
	CREATE OR REPLACE PIPE pipe_covid_transactions
	  AUTO_INGEST = TRUE
	AS
	COPY INTO COVID_DATA_2021
	FROM @azure_stage1
	FILE_FORMAT = (FORMAT_NAME = 'snflk_csv_format')
	PATTERN = '.*Covid_.*\.csv';
	
10) Look for Errors
   select SYSTEM$PIPE_STATUS('pipe_covid_transactions');
   
   SELECT *
	FROM TABLE(
	  INFORMATION_SCHEMA.COPY_HISTORY(
		TABLE_NAME => 'COVID_DATA_2021',
		START_TIME => DATEADD(DAY, -10, CURRENT_TIMESTAMP())
	  )
	)
	ORDER BY last_load_time DESC;


Note :
If you create the event subscription without the queue, and instead try to push the event somewhere else (e.g., a webhook or function), Snowflake wont know about it.
-Snowflake listens only to Azure Storage Queues via the NOTIFICATION INTEGRATION. [Most Important]
-Snowflake dosent have anything to do with Event. It only listens to Queue.

📌 Snowflake does not directly subscribe to Event Grid; it expects messages to be pushed to a queue where Snowflake polls and processes them.

✅ So Why Create the Queue First?
You create the Azure Queue first, because:
Event Grid needs to know where to send notifications (you provide the queue URI).
Snowflake needs that queue URI to set up its Notification Integration.
Snowpipe can only process files if Snowflake sees a valid message in the queue.

✅ Without the queue: Snowflake will never know a file arrived
So the queue acts as the bridge between Azure Blob Storage and Snowflake Snowpipe.

We cannot create the event subscription before the queue. (Because here Event is the Sender and Queue is the Receiver, and then Queue pushes to snowflake)
❌ Why?
When you create an Event Grid subscription targeting a queue, Azure needs to verify the destination queue exists and can receive messages.
So, if the queue doesnt exist yet:
The event subscription creation will fail.
Or, it will be invalid and unable to deliver any events.

✅ Correct Order for Snowpipe Auto-Ingest Setup:
1.Create Azure Storage Queue (e.g., prajsnowflakequeue)
2.Create Event Grid Subscription
  Source: Your blob container (e.g., prajcontainer1)
  Event Type: BlobCreated
  Destination: The storage queue created above
3.Create Snowflake Notification Integration  (linked to the queue URI)
4.Create Stage, Pipe, and Load


Stage
=====
CREATE OR REPLACE STAGE my_internal_stage;  --Internal stage
-User Stage		@~					Each user gets a default personal stage
-Table Stage	@%my_table			Each table has a stage for related files
-Named Stage	@my_internal_stage	Explicitly created internal stage

User Stage
----------
Every Snowflake user has a personal stage automatically created for them.It is private to the user and is often used for quick testing or personal data loading.

snowsql -q "PUT file://test.csv @~"    --Uploading csv file
COPY INTO my_table  				   --Loading file into table
FROM @~
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

Table Stage
-----------
Every table in Snowflake has a dedicated internal stage for loading and unloading data specifically related to that table. 
It’s automatically created when the table is created.
@%COVID_DATA_2021

snowsql -q "PUT file://transactions.csv @%bank_transactions" 
COPY INTO bank_transactions
FROM @%bank_transactions
FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1);

Custom Stage
------------
This is a custom stage you define and manage explicitly. You can share it across tables, users, or even for scripts or pipelines. It gives you more flexibility and control (like defining default file format or encryption).

CREATE OR REPLACE STAGE my_internal_stage
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

snowsql -q "PUT file://sales.csv @my_internal_stage"
COPY INTO sales_table
FROM @my_internal_stage;



CREATE OR REPLACE STAGE my_external_stage   --External stage
  URL = 'azure://mycontainer.blob.core.windows.net/myfolder'
  STORAGE_INTEGRATION = my_azure_integration;
