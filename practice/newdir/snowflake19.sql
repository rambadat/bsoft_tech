Time Travel
===========
Snowflake’s Time Travel feature lets you query, clone, and restore historical data from tables, schemas, and databases for a defined period of time. It’s extremely useful for recovering from mistakes, auditing changes, or analyzing historical trends.

Before understanding Time Travel, we should know what is Data Retention Period.

Retention Period
----------------
There is a limit to go back in time (Min : 1 days, Max : 90 days. Default : 1 day, This settings can be altered)
*Default retention = 1 day (24 hours) for all editions.
*Can be increased up to 90 days in Enterprise Edition and above.
Controlled by DATA_RETENTION_TIME_IN_DAYS parameter at table, schema, or database level.

ALTER TABLE my_table SET DATA_RETENTION_TIME_IN_DAYS = 7;  --Max is 90

Time Travel Retention : Default: 1 day. Max: 90 days (Enterprise Edition or higher)
Fail-safe Retention   : Fixed 7 days (cannot be changed).
Stage File Retention  : For files in internal stages (used in COPY INTO), it is Default = 7 days for loaded files (so they aren’t reloaded accidentally).
Query Result Caching Retention : Query results are cached for 24 hours by default.
Temporary Tables 	  : Retained only for the session.
Transient Tables 	  : No Fail-safe, and retention can be 0 days. Useful for scratch data.


Historical Data Access
----------------------
You can access data “as it was” at a specific point in the past using:
AT | BEFORE clause in queries.

-- Query table as of 1 hour ago
SELECT *  FROM my_table 
AT (OFFSET => -60*60);

-- Query table as it was before a timestamp
SELECT * FROM my_table 
BEFORE (TIMESTAMP => '2025-09-08 10:00:00');


Undrop Objects
--------------
You can restore accidentally dropped tables, schemas, or databases (within retention period):
UNDROP TABLE my_table;
UNDROP SCHEMA my_schema;
UNDROP DATABASE my_db;

Cloning Historical Data
-----------------------
You can create a zero-copy clone of a table, schema, or database at a historical point in time:

CREATE TABLE my_table_clone CLONE my_table;  --Normal cloning (Oracle --> create table my_table_clone select * from my_table)

CREATE TABLE my_table_clone CLONE my_table   --Historical data cloning
AT (TIMESTAMP => '2025-09-08 09:00:00');


Query Syntax for Time Travel
----------------------------
Three methods:
-AT | BEFORE TIMESTAMP → access as of a timestamp
-AT OFFSET (seconds) → access as of a relative time offset
-AT STATEMENT → access the data state as of a previous query’s QUERY_ID

Example with query ID:
SELECT query_id, query_text, start_time    --fetch the Query_id
FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
WHERE query_text ILIKE '%UPDATE%'
ORDER BY start_time DESC;

SELECT * FROM my_table 
AT (STATEMENT => '01a1234b-0000-1111-2222-abcdef123456');  --Table data prior to firing the specific Query

⚙️ Use Cases
Accidental Deletes/Updates 	→ Recover data without backup restore.
Auditing 					→ See what data looked like before a change.
Testing 					→ Clone historical states of data for dev/test.
Analytics 					→ Compare current vs. historical snapshots.

❌ Limitations
Only works within retention window.
Consumes storage → Historical versions are kept in Snowflake’s micro-partitions until retention expires.
Not supported for external tables or transient tables with 0-day retention.

Time Travel with Fail-safe
==========================

1. Time Travel
--------------
Lets you query, clone, or restore objects (tables, schemas, DBs) within the retention period.
Retention window: 
	-1 day (default)
	-Up to 90 days (Enterprise Edition and above).

Fully self-service: You can run SQL commands to recover data without Snowflake’s help.
-- Recover dropped table
UNDROP TABLE sales;

-- Restore table to previous state by cloning
CREATE OR REPLACE TABLE sales_clone CLONE sales 
BEFORE (TIMESTAMP => '2025-09-08 10:00:00');

2. Fail-safe (Time Travel beyond Retention Period of 7 days)
------------
Last line of defense after Time Travel retention expires.
Snowflake keeps all historical data for 7 days beyond retention.
Purpose: Disaster recovery only – not for analytics or ad-hoc queries.
You cannot access Fail-safe data directly. Only Snowflake Support can restore it.
Recovery may take time (hours to days) and is not guaranteed to be immediate.
Fail-safe is not a substitute for backups → it’s for emergencies like hardware failures or catastrophic mistakes.

| Feature         | Time Travel                                    | Fail-safe                                 |
| --------------- | ---------------------------------------------- | ----------------------------------------- |
| **Access**      | Self-service via SQL (`UNDROP`, `CLONE`, `AT`) | Only Snowflake Support can restore        |
| **Retention**   | 1–90 days (configurable)                       | Fixed 7 days beyond Time Travel retention |
| **Use Cases**   | Query history, audit, restore dropped objects  | Disaster recovery                         |
| **Cost**        | Uses storage for historical micro-partitions   | Uses storage for additional 7 days        |
| **Granularity** | Timestamp / Query ID / Offset                  | Whole object restore                      |

3. Lifecycle of Data in Snowflake
---------------------------------
Active Data 	   → Available in current tables.
Time Travel Period → Historical versions available for queries/restores.
Fail-safe (7 days) → Only Snowflake can help restore if you raise a support request.
Permanent Deletion → Data is purged from Snowflake after Fail-safe expires.

✅ In short:
Time Travel = Self control, flexible, short-term recovery.
Fail-safe   = Snowflake’s control, emergency-only, last resort.

Fail Over (This is a snowflake Admin job)
=========
Snowflake Failover (Business Continuity & Disaster Recovery)

1. What is Failover?
--------------------
Failover in Snowflake is the ability to switch operations to a replicated database, schema, or even the entire account in another region or cloud provider if the primary region becomes unavailable.

It works together with Replication:
Replication = Continuously copies your Snowflake objects & data to another region/cloud/account.
Failover = Switches your live workloads to use the replica if the primary fails.

2. Objects that Support Failover
--------------------------------
Snowflake allows replication and failover for different granularities:
Account-level Failover  → Entire Snowflake account (all DBs, users, roles, warehouses).
Database-level Failover → Specific databases (with data + metadata).
Schema-level Failover   → Selected schemas.

3. How it Works
---------------

Step 1: Set up Replication
Create a replica in another region/cloud/account.
CREATE DATABASE mydb_replica CLONE mydb;
ALTER DATABASE mydb ENABLE REPLICATION TO ACCOUNTS my_secondary_account;

Step 2: Keep Replicas Updated
Schedule periodic refreshes so replica stays in sync:
ALTER DATABASE mydb REFRESH;

Step 3: Failover to Replica
If the primary becomes unavailable, issue a failover command:
ALTER DATABASE mydb_primary FAILOVER TO mydb_replica;

The replica becomes the new primary → all workloads can now run on it.
Step 4: Failback (Optional)
Once the original region is healthy, you can reverse the process:
ALTER DATABASE mydb_replica FAILOVER TO mydb_primary;

4. Key Benefits
✅ High Availability → Workloads keep running even during outages.
✅ Disaster Recovery (DR) → Business continuity across regions or clouds.
✅ Cross-Cloud Portability → Move workloads between AWS, Azure, and GCP.
✅ Minimal Downtime → Fast switchover (depends on replication refresh frequency).

Cloning
=======
Cloning in Snowflake means creating a new object (database, schema, or table) that is a copy of an existing one, but:
It is created almost instantly (no data movement).
It consumes very little extra storage at creation time.
Because Snowflake uses metadata pointers to the same micro-partitions.
This is also called a Zero-Copy Clone.

When you create a clone, Snowflake doesn’t physically copy the data.
Both original and clone share the same underlying data files.
Only changes made after cloning create new micro-partitions.
This is done through a Copy-on-Write (CoW) mechanism.

-- Clone a table
CREATE TABLE sales_clone CLONE sales;
-- Clone a schema
CREATE SCHEMA reporting_clone CLONE reporting;
-- Clone a database
CREATE DATABASE finance_clone CLONE finance;

Key Properties
--------------
Instantaneous: No matter how big the source is, the clone is created in seconds.
Zero-Copy: No extra storage except for changes after the clone.
Independent: Once cloned, you can query, modify, or drop independently.
Time Travel Aware: You can even clone an object as of a point in time.

-- Clone table as it existed yesterday
CREATE TABLE sales_yesterday CLONE sales
BEFORE (TIMESTAMP => '2025-09-08 00:00:00');

Cloning Example
---------------
Scenario: Cloning Prod into Test
Step 1: You have a Production database
USE ROLE SYSADMIN;
CREATE OR REPLACE DATABASE PROD_DB;
USE DATABASE PROD_DB;

CREATE OR REPLACE SCHEMA SALES;
CREATE OR REPLACE TABLE SALES.ORDERS (
    ORDER_ID INT,
    CUSTOMER STRING,
    AMOUNT NUMBER(10,2)
);

INSERT INTO SALES.ORDERS VALUES 
(1, 'Alice', 200.50),
(2, 'Bob',   150.75),
(3, 'Charlie', 99.99);

✅ Now we have PROD_DB.SALES.ORDERS with 3 rows.

Step 2: Clone PROD into TEST
CREATE DATABASE TEST_DB CLONE PROD_DB;

This runs instantly (even if PROD had TBs of data).
No extra storage (TEST_DB shares the same micro-partitions as PROD_DB).

Step 3: Validate clone contents
SELECT * FROM TEST_DB.SALES.ORDERS;

Output:

1 | Alice   | 200.50
2 | Bob     | 150.75
3 | Charlie |  99.99

✅ TEST_DB has the same data as PROD_DB at the time of cloning.


Step 4: Make changes in PROD
INSERT INTO PROD_DB.SALES.ORDERS VALUES (4, 'David', 300.00);

This creates a new micro-partition in PROD.
TEST_DB is unaffected (still has only 3 rows).

Step 5: Check independence
SELECT COUNT(*) FROM PROD_DB.SALES.ORDERS; -- 4
SELECT COUNT(*) FROM TEST_DB.SALES.ORDERS; -- 3

✅ Now PROD and TEST have diverged.

Only the changes consume extra storage.

The first 3 rows are still shared between PROD and TEST.

Step 6: Make changes in TEST
DELETE FROM TEST_DB.SALES.ORDERS WHERE ORDER_ID = 2;

TEST_DB creates its own new micro-partition without Bob’s record.
PROD still has Bob’s record.

Step 7: Storage Impact
At clone creation → Almost 0 storage increase.
After changes → Only the deltas (new partitions) consume storage.
This is Snowflake’s Copy-on-Write mechanism.

✅ Summary
Clone Creation → Instant + zero storage.
After Divergence → Each DB/table keeps its own changes.
Use Cases → Perfect for Dev/Test, point-in-time backups, or quick recovery.


Replication vs. Cloning in Snowflake
====================================
1. Replication
Replication means keeping a copy of a database, schema, or account in another region or cloud provider, and synchronizing it periodically.
Purpose: Business continuity, disaster recovery, cross-region availability, cross-cloud portability.
It supports Failover & Failback (switching primary/secondary).

-- Enable replication
ALTER DATABASE sales ENABLE REPLICATION TO ACCOUNTS my_secondary_account;
-- Create a replica
CREATE DATABASE sales_replica AS REPLICA OF my_primary_account.sales;
-- Refresh replica (pull new changes)
ALTER DATABASE sales_replica REFRESH;

✅ Key Point: Replica is read-only until promoted via failover.


2. Cloning
Cloning means creating a zero-copy copy of an object (DB, schema, or table) within the same account.
Purpose: Quick dev/test environments, backups, what-if analysis, point-in-time snapshots.
Uses copy-on-write → No extra storage initially; only new/changed data consumes space.

-- Create a clone of a table
CREATE TABLE sales_clone CLONE sales;
-- Create a clone of a DB at a point in time
CREATE DATABASE sales_clone CLONE sales
BEFORE (TIMESTAMP => '2025-09-08 10:00:00');

✅ Key Point: Clone is read-write immediately, but shares storage with source until changes are made.


| Feature          | **Replication**                            | **Cloning**                          |
| ---------------- | ------------------------------------------ | ------------------------------------ |
| **Scope**        | Cross-region / cross-cloud / cross-account | Same account only                    |
| **Purpose**      | DR, HA, failover, geo-distribution         | Dev/Test, backup, point-in-time copy |
| **Data Copy**    | Physically copied (async updates)          | Zero-copy (metadata pointers)        |
| **Initial Cost** | Storage + compute (for sync)               | Minimal storage (changes only)       |
| **Updates**      | Requires `REFRESH` to sync changes         | Independent after creation           |
| **Read/Write**   | Replica = read-only (until failover)       | Clone = fully read/write             |
| **Performance**  | Depends on refresh frequency               | Instant creation, no sync required   |


Topics to cover
===============
Time Travel, Fail Safe, Fail Over
Cloning, Replication, Sharing
Data classification, Data Masking, Data Encryption, Data Marketplace, Data Exchange, Data Clean Room
Query Tuning, Query semi structured data, query acceleration service, search optimization, Estimation and sampling