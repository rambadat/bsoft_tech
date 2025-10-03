Interview Preperation Foundation
================================
19.1) Time Travel
     -Default/Min Retention Period : 1 day (24 hours)
	 -Max : 90 days

19.2) Retention Period
		Time Travel Retention 	: Default: 1 day. Max: 90 days (Enterprise Edition or higher). Recovery done by developers.
		Fail-safe Retention   	: Fixed 7 days (cannot be changed). Snowflake Team does the recovery.
		Stage File Retention  	: For files in internal stages (used in COPY INTO), it is Default = 7 days for loaded files
		Qry Result Cache Retn 	: 24 hours by default
		Temporary Tables 	  	: Retained only for the session
		Transient Tables 	  	: No Fail-safe, and retention can be 0 days
		
		We can access data “as it was” at a specific point in the past => AT (OFFSET => -60*60) | BEFORE (TIMESTAMP => '2025-09-08 10:00:00') in queries
		We can restore accidentally dropped tables/schemas/databases (within retention period) => undrop
		We can do zero-copy clone of a table/schema/database at a historical point in time => CREATE TABLE c1 CLONE c AT (TIMESTAMP => '2025-09-08 09:00:00');

		| Stage Type                      | File Retention         | Managed By                               |
		| ------------------------------- | ---------------------- | ---------------------------------------- |
		| User Stage (`@~`)               | 7 days                 | Snowflake                                |
		| Table Stage (`@%table`)         | 7 days                 | Snowflake                                |
		| Named Internal Stage            | 7 days                 | Snowflake                                |
		| External Stage (S3, Azure, GCS) | No automatic retention | Cloud provider (you set lifecycle rules) |

		
19.3) Time Travel Queries
		-AT | BEFORE TIMESTAMP 	: access as of a timestamp               --SELECT * FROM my_table BEFORE (TIMESTAMP => '2025-09-08 10:00:00');
		-AT OFFSET (seconds) 	: access as of a relative time offset    --SELECT *  FROM my_table AT (OFFSET => -60*60);
		-AT STATEMENT 			: access the data state as of a previous query’s QUERY_ID	--SELECT * FROM my_table AT (STATEMENT => '01a1234b-0000-11');	

19.4) Time Travel vs Fail Safe
		Time Travel : Self control, flexible, short-term recovery till 90 days
		Fail-safe   : Snowflake’s control, emergency-only, last resort after 90 time travel days i.e till next 7 days
		Fail Over	: Snowflake admin job (switching to replicated database/schema/account region/cloud provider)

19.5) Cloning  
		Creating a zero-copy copy of an object (DB, schema, or table) within the same account (pointer reset)
		Clone a table 	  : CREATE TABLE sales_clone CLONE sales
		Clone a schema	  : CREATE SCHEMA reporting_clone CLONE reporting
		Clone a database  : CREATE DATABASE finance_clone CLONE finance
		
19.6) Cloning Features
		Instantaneous 	  : No matter how big the source is, the clone is created in seconds.
		Zero-Copy	  	  : No extra storage except for changes after the clone
		Independent	  	  : Once cloned, you can query, modify, or drop independently
		Time Travel Aware : You can even clone an object as of a point in time i.e. Historical cloning
		
19.7) Replication : Taken care by Admin
		Replication means keeping a copy of a database, schema, or account in another region or cloud provider, and synchronizing it periodically.
		Purpose: Business continuity, disaster recovery, cross-region availability, cross-cloud portability.
		It supports Failover & Failback (Failover : switching primary to secondary | Failback : switching secondary to primary).	

20.1) Data Sharing
		Data sharing allows to securely share live data with other Snowflake accounts (or even external users) without copying or moving the data
		Provider → Owns the data, decides what to share (creates share, Add objects to share. Grant access to consumer a/c)
		Consumer → Receives the share and can query it  (creates DB from providers share, query shared data)

20.2) Data Sharing Benefits
		No Data Copies 		: Unlike replication or ETL, data is queried live.
		Always Fresh 		: Consumer queries the latest version in real time.
		Secure & Granular 	: Providers control exactly which objects are shared.
		Cross-Organization Collaboration : Great for partners, vendors, clients.
		
20.3) Types of Data Sharing in Snowflake
		-Direct Sharing 		: Account-to-Account Sharing  (P->create share,add objects,grant access C->create db and query)
		-Reader Accounts 		: No Snowflake License Needed (P->create managed a/c, creates share, add objects,grant access R->create db and query)
		-Snowflake Marketplace 	: Public or Private Exchange (P->creates share, add objects,register as P in Mkt, create Listing C->get data and query)
		-Data Exchange 			: Private Exchange (P->creates share, add objects,create Listing C->get data and query)
		-Cross-Region and Cross-Cloud Data Sharing	:Different Region/Cloud


		-Direct Sharing 		: P->                     create share, add objects, grant access 						  C->create db and query
		-Reader Accounts 		: P-> create managed a/c, create share, add objects, grant access 					      R->create db and query
		-Snowflake Marketplace 	: P->                     create share, add objects, register as P in Mkt, create Listing C->get data and query
		-Data Exchange 			: P->				      create share, add objects,  					   create Listing C->get data and query
		-Cross-Region/Cross-Cloud : P->Enable Replication C-> create replica in target region/cloud, refresh replica
									P->                   create share, add objects, grant access 		C in Target region->create db and query
									
21.1) Query Tuning Strategies
        -Warehouse selection choice
		-Fewer compute credits
		-How data is stored (Permanent/Temporary)
		-select individial columns rather than select *
		-apply filteration at the beggining rather than aggregating using group and then applying filteration
		-define a clustering key to improve pruning for large tables involving various filterations  --ALTER TABLE sales CLUSTER BY (region, order_date);
		-use Materialized view which precomputes aggregates for faster access
		-use CTEs and Temp Tables Smartly. For very large intermediate results, store them in a temporary table instead of recalculating
		-Take advantage of Query Cache Results
		-use larger warehouse for heavy queries and use multi-cluster warehouse for high concurrency
		-use Query Profile in Snowsight to see execution details (Similar to oracle Explain plan)
		-use cluster to group data so fewer partitions are scanned which in turn makes the query faster & cheaper cost.Without cluster,It scans all partitions
		-use Multi-Cluster Warehouse (Horizontal scaling) for Prod and use Single-Cluster Warehouse (Vertical Scaling) for Development environments.

21.2) What is the Warehouse setups done for Dev, Uat and Prod		
    	Dev : Single Cluster warehouse, Meduim Warehouse size
		Prod : Multi Cluster warehouse, Min 1 cluster, Max 5 cluster, Medium Warehouse size
	  
21.3) What is concurrency 
		-Low concurrency → only a few users or queries running.
		-High concurrency → many users or applications running queries simultaneously.

		
		
		

		
		
		
