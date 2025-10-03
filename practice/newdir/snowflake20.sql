Data Sharing in Snowflake
=========================
Data sharing in Snowflake allows you to securely share live data with other Snowflake accounts (or even external users) without copying or moving the data.
No ETL, no duplication, no file transfers.
*The consumer always sees the latest version of the data you’ve shared.
Powered by Snowflake’s multi-cluster shared data architecture.

There are two main players:
Provider → Owns the data, decides what to share.
Consumer → Receives the share and can query it.

Provider
--------
-- Create a share
CREATE SHARE my_share;

-- Add objects (e.g., schema, tables, views)
GRANT USAGE ON DATABASE sales_db TO SHARE my_share;
GRANT USAGE ON SCHEMA sales_db.public TO SHARE my_share;
GRANT SELECT ON TABLE sales_db.public.orders TO SHARE my_share;

-- Grant access to consumer account
ALTER SHARE my_share ADD ACCOUNT = my_consumer_account;

consumer
--------
-- Consumer creates a DB from provider's share
CREATE DATABASE sales_from_provider FROM SHARE provider_account.my_share;

-- Query the shared data
SELECT * FROM sales_from_provider.public.orders;

Key Benefits
------------
No Data Copies → Unlike replication or ETL, data is queried live.
Always Fresh → Consumer queries the latest version in real time.
Secure & Granular → Providers control exactly which objects are shared.
Cross-Organization Collaboration → Great for partners, vendors, clients.

| Feature        | **Sharing**                                  | **Cloning**                            | **Replication**                                   |
| -------------- | -------------------------------------------- | -------------------------------------- | --------------------------------------------------|
| **Purpose**    | Share data with others (external/internal)   | Copy data for dev/test/backup          | Sync data across regions/accounts for DR          |
| **Data Move?** | No (live access, zero-copy)                  | No (copy-on-write inside same account) | Yes (physically copied to another account/region) |
| **Consumer**   | Read-only (unless using DB repli 4 write)    | Full read-write after clone            | Read-only until failover promoted                 |
| **Scope**      | Across accounts/orgs                         | Within same account                    | Across regions/clouds/accounts                    |


✅ So in short:
Sharing in Snowflake = Securely granting other accounts live, read-only access to your data without copying it.

❄️ Types of Data Sharing in Snowflake
=====================================
1. Direct Sharing (Account-to-Account Sharing)
2. Reader Accounts (No Snowflake License Needed)
3. Snowflake Marketplace (Public or Private Exchange)
4. Data Exchange (Private Exchange)
5. Cross-Region and Cross-Cloud Data Sharing

| Sharing Type           | Who Can Consume?                        | Provider Pays?             | Key Use Case                          |
| ---------------------- | --------------------------------------- | ---------------------------| ------------------------------------- |
| **Direct Sharing**     | Another Snowflake account (same region) | ❌ Consumer pays           | Simple B2B sharing                    |
| **Reader Account**     | Partner with no Snowflake acct          | ✅ Provider pays           | Small clients/vendors                 |
| **Marketplace**        | Any Snowflake user                      | ❌ Consumer (free or paid) | Public or monetized datasets          |
| **Data Exchange**      | Controlled group (private hub)          | ❌ Consumer pays           | Enterprise-wide or consortium sharing |
| **Cross-Cloud/Region** | Accounts in different clouds/regions    | Depends                    | Geo-distributed data access           |


1. Direct Sharing (Account-to-Account Sharing)
----------------------------------------------
	The most basic type.
	You (the Provider) create a share object and grant access to another Snowflake Consumer account in the same cloud region.
	Consumer creates a database from that share and queries data directly.

	👉 Example:

	-- Provider side
	CREATE SHARE sales_share;
	GRANT USAGE ON DATABASE sales_db TO SHARE sales_share;
	GRANT SELECT ON TABLE sales_db.public.orders TO SHARE sales_share;
	ALTER SHARE sales_share ADD ACCOUNT = consumer_account;

	-- Consumer side
	CREATE DATABASE sales_data FROM SHARE provider_account.sales_share;
	SELECT * FROM sales_data.public.orders;

	✅ Use case: Simple 1-to-1 sharing between business partners, vendors, or internal accounts.


2. Reader Accounts (No Snowflake License Needed)
------------------------------------------------
	Reader accounts are very useful when your consumer (client/partner) does not have their own Snowflake subscription. You, as the provider, create a Snowflake-managed account for them and control the billing.

	🔹 Step 1: Provider Creates a Reader Account
	The provider must have ACCOUNTADMIN role to create reader accounts.

	-- Create a reader account
	CREATE MANAGED ACCOUNT reader_account_1
	ADMIN_NAME = reader_admin
	ADMIN_PASSWORD = 'StrongPassword@123'
	TYPE = READER;

	-- Show accounts (verify)
	SHOW MANAGED ACCOUNTS;
	👉 Output will show something like:
	name                region       cloud   url
	------------------  -----------  ------  ---------------------------------------
	READER_ACCOUNT_1    AWS_US_EAST  AWS     https://reader_account_1.snowflakecomputing.com
	✅ The url is what your consumer will use to log in.


	🔹 Step 2: Provider Creates a Share for the Reader
	You now create a share that exposes the data objects.
	-- Create a share
	CREATE SHARE sales_share;

	-- Grant privileges on DB, schema, and table
	GRANT USAGE ON DATABASE sales_db TO SHARE sales_share;
	GRANT USAGE ON SCHEMA sales_db.public TO SHARE sales_share;
	GRANT SELECT ON TABLE sales_db.public.orders TO SHARE sales_share;

	-- Add the reader account to the share
	ALTER SHARE sales_share ADD ACCOUNT = reader_account_1;


	🔹 Step 3: Consumer (Reader Account) Creates a Database from the Share
	Now your partner logs into their Reader Account (with the credentials you gave).
	Inside their account, they can attach the shared data:

	-- In Reader Account (Consumer side)
	-- Create a DB from the share
	CREATE DATABASE sales_data FROM SHARE provider_account.sales_share;

	-- Query the shared table
	SELECT * FROM sales_data.public.orders;

	✅ The consumer can now query the data as if it was their own, but they cannot modify it.


	🔹 Step 4: Optional – Consumer Creates Their Own Tables (Local Copy)
	If they want a working copy they can modify:

	-- Consumer creates their own writable table from shared data
	CREATE TABLE my_orders AS
	SELECT * FROM sales_data.public.orders;

	-- Now they can do inserts/updates on this local table
	INSERT INTO my_orders VALUES ('C999', 'New Customer', 'Retail', 'North', CURRENT_DATE);

	🔑 Key Points about Reader Accounts
	Provider pays for compute and storage used by reader accounts.
	Reader accounts are read-only against shared data, unless consumer copies into their own tables.
	Great for smaller clients who don’t want to pay for their own Snowflake subscription.
	Provider controls everything (security, billing, privileges).

	✅ In short:
	Provider creates Reader Account.
	Provider creates Share and grants it to Reader Account.
	Consumer (in Reader Account) attaches share as a database and queries data.

3. Snowflake Marketplace (Public or Private Exchange)
-----------------------------------------------------
	Marketplace and Exchanges are built on top of Snowflake’s Sharing feature, but with extra governance, discoverability, and (optionally) monetization.

	🔹 Step 1: Provider Prepares Data for Sharing
	As a Provider, you first prepare the dataset(s) you want to publish.

	-- Create a dedicated share
	CREATE SHARE market_sales_share;

	-- Grant usage and access on objects
	GRANT USAGE ON DATABASE sales_db TO SHARE market_sales_share;
	GRANT USAGE ON SCHEMA sales_db.public TO SHARE market_sales_share;
	GRANT SELECT ON TABLE sales_db.public.orders TO SHARE market_sales_share;

	At this point, market_sales_share contains the dataset you plan to publish in the Marketplace.


	🔹 Step 2: Register as a Provider in the Marketplace
	This step cannot be done in SQL — you do it via the Snowflake Web UI (Snowsight):

	Go to Marketplace / Data Exchange.
	Choose “Become a Provider”.
	Provide business details, description, logos, etc.
	✅ Once approved, you can publish listings.


	🔹 Step 3: Create a Listing
	Still in the Snowflake UI (not SQL):
	Create a New Listing.
	Choose your dataset (market_sales_share).
	Set visibility:
	Public → Available to all Snowflake accounts.
	Private Exchange → Only visible to invited accounts or within your org.
	(Optional) Set monetization (paid subscription model).
	Publish.


	🔹 Step 4: Consumer Accesses the Listing
	On the Consumer side:
	They go to Marketplace in Snowsight.
	Search for your listing (e.g., “Global Sales Orders Data”).
	Click Get Data → Snowflake automatically creates a database from the share.

	👉 Example (Consumer side, once added):
	-- Consumer now has access to the shared DB
	SHOW DATABASES LIKE 'GLOBAL_SALES_ORDERS';

	-- Query the data
	SELECT * FROM GLOBAL_SALES_ORDERS.public.orders LIMIT 10;


	✅ This database is read-only live data, same as direct sharing.

	🔑 Difference: Public vs Private Exchange
	Feature	Public Marketplace	Private Exchange
	Visibility	All Snowflake accounts	Restricted group (org/partners)
	Approval Needed	Snowflake approval as provider	You manage access directly
	Monetization	Supported (paid data products)	Not usually monetized
	Use Case	Public datasets, monetization	Enterprise-wide collaboration

	🔎 Example Use Cases
	Public Marketplace: Publish weather, financial, healthcare, or demographic data for global access.
	Private Exchange: Large enterprise with multiple subsidiaries (e.g., bank → share customer risk data between divisions securely).

	✅ In summary:
	Provider: Create a share → Register as Provider → Publish Listing (UI step).
	Consumer: Discover listing in Marketplace → Attach database → Query data (SQL step).


4. Data Exchange (Private Exchange)
-----------------------------------
	A controlled sharing hub created by a Provider (like your company).
	Members of the exchange (partners, business units, subsidiaries) can publish and consume data securely.
	Works almost exactly like Marketplace, but is not public — only visible to members.


	🔹 As a Consumer (when you get data from a Private Exchange)
	When another account shares data with you through a private exchange, you’ll see a new database automatically created in your Snowflake account (just like you saw with Marketplace’s Weather dataset).

	🔹 Commands to Explore a Private Exchange Dataset
	Let’s say the provider published a dataset into your Private Exchange, and Snowflake created a new database for you called EXCHANGE_SALES_DB.

	1. List all databases (to confirm the new one)
	SHOW DATABASES;
	Look for something like EXCHANGE_SALES_DB.

	2. Use the Exchange DB
	USE DATABASE EXCHANGE_SALES_DB;

	3. Show schemas inside it
	SHOW SCHEMAS;

	4. Switch to the schema
	USE SCHEMA PUBLIC;   -- or whichever schema was shared

	5. List tables and views available
	SHOW TABLES;
	SHOW VIEWS;

	6. Query the data
	SELECT * 
	FROM EXCHANGE_SALES_DB.PUBLIC.CUSTOMER_ORDERS
	LIMIT 20;


	🔹 Key Notes on Private Exchange
	Data is read-only for consumers (same as Marketplace).
	If you want to manipulate or join it with your own tables → create a local copy:

	CREATE TABLE MY_CUSTOMER_ORDERS AS
	SELECT * FROM EXCHANGE_SALES_DB.PUBLIC.CUSTOMER_ORDERS;


	You can be both a Consumer and a Provider in the same Private Exchange.
	✅ Comparison:  Marketplace 			 		Private Exchange
	-------------------------------------------------------------------------------------
	Feature			Marketplace (Public)			Data Exchange (Private)
	Visibility		All Snowflake customers			Restricted to invited accounts/org
	Use Case		Public datasets, monetization	Enterprise-wide or partner sharing
	Setup			Register as provider in UI		Admin creates Private Exchange in UI
	Consumer View	Database auto-created			Database auto-created

	👉 So:
	For you as a consumer, Marketplace and Private Exchange feel the same (new DB shows up, explore with SHOW DATABASES/SCHEMAS/TABLES).
	The difference is who can see the listing (public vs private ecosystem).


	🔹 Step 1: Provider Creates a Share (SQL)
	You first define which database objects (schemas/tables/views) you want to publish.

	-- Create a share for the private exchange
	CREATE SHARE private_sales_share;

	-- Grant privileges on objects you want to share
	GRANT USAGE ON DATABASE sales_db TO SHARE private_sales_share;
	GRANT USAGE ON SCHEMA sales_db.public TO SHARE private_sales_share;
	GRANT SELECT ON TABLE sales_db.public.orders TO SHARE private_sales_share;

	Now you have a share private_sales_share ready for use.


	🔹 Step 2: Provider Publishes the Share into the Private Exchange (UI)
	This part is done in Snowsight UI (not SQL):
	Go to Data → Private Exchange.
	Select your Exchange (your org or consortium’s private exchange).
	Click Create Listing.
	Choose Existing Share → select private_sales_share.
	Add listing details (title, description, usage notes).
	Select who can access (specific accounts, or all members of the exchange).
	Publish.

	✅ At this point, the listing is visible to the invited consumers in the private exchange.


	🔹 Step 3: Consumer Gets the Data (SQL on Consumer Side)
	When consumers accept the listing, a database is auto-created in their Snowflake account.

	Example consumer commands:
	-- Consumer sees a new database (check with)
	SHOW DATABASES;

	-- Assume DB created is EXCHANGE_SALES_DB
	USE DATABASE EXCHANGE_SALES_DB;

	-- Explore schema
	SHOW SCHEMAS;

	-- Explore tables/views
	USE SCHEMA PUBLIC;
	SHOW TABLES;
	SHOW VIEWS;

	-- Query data
	SELECT * FROM EXCHANGE_SALES_DB.PUBLIC.ORDERS LIMIT 10;

	✅ Key Points
	Provider controls what’s shared via SQL (CREATE SHARE ...).
	Exchange UI is where the provider publishes the share as a listing and manages visibility.
	Consumer automatically gets a read-only database.
	For writable copies, consumers must CREATE TABLE ... AS SELECT ....

	🔎 Example Use Case
	Suppose Bank HQ runs a Private Exchange for all its subsidiaries.
	HQ creates a share private_sales_share.
	Publishes it in the Private Exchange.
	Subsidiaries see EXCHANGE_SALES_DB in their accounts → can query ORDERS.


5. Cross-Region and Cross-Cloud Data Sharing
--------------------------------------------
	This is an advanced but very powerful Snowflake capability: Cross-Region and Cross-Cloud Data Sharing.
	Here we’re combining Replication + Sharing to enable data consumers in another cloud or region (say AWS → Azure, or US East → Europe).


	🔹 Step 1: Enable Replication on Provider Side
	First, in your primary account/region, enable replication for the database you want to share.

	-- Enable replication on the provider database
	ALTER DATABASE sales_db 
	ENABLE REPLICATION TO ACCOUNTS consumer_account_in_other_region;


	🔹 Step 2: Create a Replica in Target Region/Cloud
	Now in the target account (in another region or cloud), create a replica of the provider’s DB.

	-- In consumer account (target region/cloud)
	CREATE DATABASE sales_db_replica 
	AS REPLICA OF provider_account.sales_db;

	👉 This gives the target account a read-only replicated copy of the DB.


	🔹 Step 3: Refresh the Replica to Sync Data
	Replication is asynchronous. To bring latest data, refresh periodically:

	ALTER DATABASE sales_db_replica REFRESH;


	🔹 Step 4: Create a Share in the Target Region (Provider Side)
	Now that the database exists in the target region, you can share it (just like normal direct sharing).

	-- On provider (in target region/cloud)
	CREATE SHARE cross_region_share;

	-- Grant privileges
	GRANT USAGE ON DATABASE sales_db_replica TO SHARE cross_region_share;
	GRANT USAGE ON SCHEMA sales_db_replica.public TO SHARE cross_region_share;
	GRANT SELECT ON TABLE sales_db_replica.public.orders TO SHARE cross_region_share;

	-- Add consumer account in target region
	ALTER SHARE cross_region_share 
	ADD ACCOUNT = consumer_account_in_target_region;


	🔹 Step 5: Consumer Creates DB from Share
	On the consumer account (in target region/cloud):

	-- Consumer creates DB from the provider's cross-region share
	CREATE DATABASE sales_data 
	FROM SHARE provider_account.cross_region_share;

	-- Query data
	SELECT * FROM sales_data.public.orders LIMIT 10;


	✅ Key Points
	Replication moves a copy of the database into another region/cloud.
	Sharing then exposes that replicated DB to consumers in that region.
	Consumers see the dataset as read-only live data, refreshed via replication.

	🔎 Example Scenario
	Provider runs in AWS US-EAST.
	Consumer runs in Azure EU-WEST.
	Provider enables replication → creates a replica in Azure EU-WEST.
	From there, provider shares with consumer → consumer queries without ETL.