Query Tuning
============
Query Tuning in Snowflake means analyzing and optimizing SQL queries (and related warehouse usage) so that they:
-Run faster
-Use fewer compute credits (cost efficiency)
-Return accurate results with minimal resource wastage
Unlike traditional databases, Snowflake handles most automatic tuning (indexes, statistics, partitions, vacuuming, etc.), but bad SQL design can still cause slow queries or high costs.

🔹 When Should We Go for Query Tuning?
-------------------------------------
You usually tune queries when you see:
-Slow running queries → taking much longer than expected.
-High warehouse costs → queries consuming too many credits.
-Large scans → when query is scanning TBs of data unnecessarily.
-Concurrency issues → queries blocking or queuing due to resource overuse.
-Performance regression → queries used to run fast but became slower after data growth.

🔹 Key Query Tuning Techniques
------------------------------
1. Filter Early (Reduce Scans)
	Push filters (WHERE, LIMIT) as early as possible to avoid scanning unnecessary data.
	SELECT *   --Bad query
	FROM sales
	WHERE region = 'APAC';

	SELECT order_id, region, amount --Better query
	FROM sales
	WHERE region = 'APAC';

2. Use Clustering Keys (when needed)
	Snowflake automatically micro-partitions, but for large tables with frequent filter patterns, define a clustering key to improve pruning.

	ALTER TABLE sales 
	CLUSTER BY (region, order_date);

	This reduces scanned partitions and speeds up queries.

3. Avoid SELECT *
	Always project only the required columns.

4. Materialized Views
	Precompute expensive aggregations for faster access.

	CREATE MATERIALIZED VIEW mv_sales_summary AS
	SELECT region, SUM(amount) total_sales
	FROM sales
	GROUP BY region;

5. Use CTEs and Temp Tables Smartly
	Reuse subquery results via CTEs.
	For very large intermediate results, store them in a temporary table instead of recalculating.

6. Cache Results
	

7. Scale Appropriately
	Sometimes, tuning is not SQL-related but warehouse-related:
	Use larger warehouse for heavy queries.
	Use multi-cluster warehouse for high concurrency.

8. Query Profiling
	Use Query Profile in Snowsight to see execution details:
	% of time spent on scan, join, aggregation.
	Which step causes bottleneck.
	Whether partition pruning happened.

	SELECT * 
	FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
	WHERE query_id = 'your_query_id';
	
CLUSTER BY in Snowflake
=======================
Snowflake automatically organizes data into micro-partitions (~16 MB each).
But sometimes queries scan too many partitions because the data is spread randomly.
CLUSTER BY tells Snowflake how to physically organize rows inside micro-partitions so that filters (like WHERE region = 'APAC') can prune partitions efficiently.
It’s like indexing in traditional databases, but without manual index management.

CREATE TABLE sales (
    order_id      INT,
    region        STRING,
    order_date    DATE,
    amount        NUMBER
)
CLUSTER BY (region, order_date);


Or for an existing table:

ALTER TABLE sales 
CLUSTER BY (region, order_date);


🔹 When to Use
--------------
Go for CLUSTER BY when:
-The table is very large (billions of rows).
-Queries frequently filter on certain columns (e.g., region, date).
-You notice in Query Profile that partition pruning is not effective.

🔹 Example
Without CLUSTER BY --If region and order_date values are spread randomly, Snowflake may scan all partitions
------------------
SELECT SUM(amount)
FROM sales
WHERE region = 'APAC' 
  AND order_date BETWEEN '2024-01-01' AND '2024-12-31';
  
With CLUSTER BY (region, order_date)
------------------------------------
Now data is grouped by region and date → fewer partitions need scanning → query is faster & cheaper.

🔹 Things to Remember
CLUSTER BY is not mandatory → only use it if queries benefit.
Clustering adds maintenance overhead (requires reclustering as new data arrives).
Snowflake provides Automatic Clustering (extra cost) or you can manually recluster using:
ALTER TABLE sales RECLUSTER;

Best practice → cluster on low-cardinality columns (region, status) or date ranges, not on high-cardinality columns (like unique IDs).

✅ In short:
CLUSTER BY in Snowflake helps improve partition pruning by physically organizing large tables based on frequently filtered columns, speeding up queries and reducing cost.

Multi-Cluster Warehouse in Snowflake
====================================
A multi-cluster warehouse is a virtual warehouse that can automatically start and stop multiple clusters of compute resources to handle query load.
A single-cluster warehouse = one set of compute nodes.
A multi-cluster warehouse = multiple independent clusters (up to 10) behind the same logical warehouse.
👉 Think of it as auto-scaling compute horizontally to handle spikes in demand.


🔹 Why We Need It
In high-concurrency situations (many users running queries at the same time), a single cluster may queue queries.
Multi-cluster warehouses add more clusters to process queries in parallel, reducing wait times.
When demand drops, extra clusters shut down automatically to save cost.

🔹 Key Features
-Scales Out (Concurrency)
	Adds clusters when too many queries are queued.
	Removes clusters when demand drops.
-Load Balancing
	Distributes queries evenly across clusters.
-Configurable Range
	You define a min and max number of clusters.
	Example: MIN_CLUSTER_COUNT = 1, MAX_CLUSTER_COUNT = 5 → Snowflake starts with 1 cluster, scales up to 5 when needed.

Create a Multi-Cluster Warehouse
--------------------------------
CREATE WAREHOUSE my_wh 
  WITH WAREHOUSE_SIZE = 'MEDIUM'
  WAREHOUSE_TYPE = 'STANDARD'
  MIN_CLUSTER_COUNT = 1
  MAX_CLUSTER_COUNT = 5
  SCALING_POLICY = 'ECONOMY';
  
Alter Existing Warehouse
------------------------
ALTER WAREHOUSE my_wh 
SET MIN_CLUSTER_COUNT = 2 
    MAX_CLUSTER_COUNT = 6;

🔹 Scaling Policies
1.ECONOMY (default)
	Adds clusters only when absolutely necessary.
	Removes clusters more aggressively to save cost.
2.STANDARD
	More responsive (scales up/down faster).
	Better for workloads needing low latency.

🔹 Example Use Cases
BI dashboards / Reporting → Many users hitting the same warehouse.
High-concurrency web applications → Thousands of small queries at once.
Mixed workloads → ETL + Ad-hoc queries together.


🔹 Important Notes
It does not make a single query run faster → It just allows more queries to run in parallel.
Extra clusters consume credits, but only while they’re running.
If your problem is a slow single query, use a larger warehouse size, not multi-cluster.

✅ In short:
Multi-Cluster Warehouse in Snowflake = Auto-scaling compute clusters to handle high concurrency workloads efficiently, without manual intervention.

Horizontal vs Vertical Scaling
==============================
🔹 Vertical Scaling (Scale Up)
-Means adding more power to a single machine/cluster.
-In Snowflake → increasing the warehouse size (e.g., SMALL → MEDIUM → LARGE → XLARGE).
-Each query gets more CPU, memory, and cache, so a single query can run faster.

👉 Analogy: Instead of 1 delivery van, you buy a bigger truck to carry more load at once.

Example in Snowflake
ALTER WAREHOUSE my_wh SET WAREHOUSE_SIZE = 'LARGE';
Before: 4 nodes (MEDIUM)
After: 16 nodes (LARGE)
Same warehouse, just more powerful.


🔹 Horizontal Scaling (Scale Out)
-Means adding more machines/clusters to handle workload in parallel.
-In Snowflake → enabling a multi-cluster warehouse (MIN_CLUSTER_COUNT, MAX_CLUSTER_COUNT).
-Does not speed up a single query, but allows more queries to run concurrently without queuing.

👉 Analogy: Instead of 1 big truck, you hire more vans to deliver in parallel.

Example in Snowflake
ALTER WAREHOUSE my_wh 
SET MIN_CLUSTER_COUNT = 1 
    MAX_CLUSTER_COUNT = 5;
Starts with 1 cluster.
Scales out to 5 clusters if many users run queries at the same time.
Queries are load-balanced across clusters.

🔹 Side-by-Side Comparison
Aspect				Vertical Scaling (Up)						Horizontal Scaling (Out)
-----------------------------------------------------------------------------------------------------
What				Bigger warehouse size						More clusters in same warehouse
Improves			Single query speed							Query concurrency (many users)
Use Case			Heavy ETL, complex joins, large scans		BI dashboards, reporting, many users
Cost impact			Higher credits per query					More credits if many clusters run
Snowflake Feature	WAREHOUSE_SIZE								MIN/MAX_CLUSTER_COUNT

✅ In short:
Vertical scaling = make one warehouse more powerful (faster queries).
Horizontal scaling = add more warehouses/clusters to handle more queries in parallel (higher concurrency).

High Concurrency
================
🔹 What It Means
Concurrency = the number of queries or workloads running at the same time on a warehouse.
-Low concurrency → only a few users or queries running.
-High concurrency → many users or applications running queries simultaneously.

👉 In simple terms:
If one person runs a query, that’s low concurrency.
If hundreds of analysts refresh dashboards at 9 AM, that’s high concurrency.

🔹 Why It Matters in Snowflake
A single-cluster warehouse has limited compute slots.
If too many queries run at once, new queries get queued (wait until resources free up).
High concurrency → long wait times.

🔹 Example Scenario
Imagine:
-You have a SMALL warehouse with 8 users.
-At 9 AM, 200 BI dashboard queries hit Snowflake.

Without scaling:
-Some queries run, others queue and users wait.

With multi-cluster warehouse (horizontal scaling):
-Snowflake spins up additional clusters (say 5 clusters).
-Queries are distributed across clusters.
-All 200 queries run in parallel with minimal waiting.

🔹 High Concurrency Workloads Examples
1.BI Tools / Dashboards (Tableau, Power BI, Looker) → many concurrent queries.
2.Shared Warehouses → multiple teams running queries at the same time.
3.APIs & Applications → hundreds/thousands of small queries hitting Snowflake concurrently.
4.Peak Usage Windows → 9 AM report refresh, month-end financial closing, etc.

✅ In short:
High concurrency = many queries running at the same time.
If the warehouse can’t handle it, queries queue. Multi-cluster warehouses (horizontal scaling) are Snowflake’s solution.

❄️ Resolving High Concurrency in Snowflake
==========================================
🔹 1. Use Multi-Cluster Warehouses (Horizontal Scaling)
Define warehouses with MIN_CLUSTER_COUNT and MAX_CLUSTER_COUNT.
Snowflake automatically starts more clusters when many queries are queued.

ALTER WAREHOUSE finance_wh 
SET MIN_CLUSTER_COUNT = 1 
    MAX_CLUSTER_COUNT = 5 
    SCALING_POLICY = 'STANDARD';

👉 Good for BI/reporting workloads (e.g., many analysts refreshing dashboards).

🔹 2. Vertical Scaling for Heavy Queries
If individual ETL or month-end jobs are too slow, scale up warehouse size instead of clusters.

ALTER WAREHOUSE etl_wh SET WAREHOUSE_SIZE = 'XLARGE';

👉 Larger warehouse = faster query execution = less time blocking resources.


🔹 3. Workload Isolation with Multiple Warehouses
Don’t dump everything on a single warehouse.
Create separate warehouses for:
-ETL/Batch jobs (etl_wh)
-Ad-hoc queries (adhoc_wh)
-BI/Reporting (reporting_wh)

👉 This prevents ad-hoc or long-running queries from blocking critical jobs.


🔹 4. Query Optimization (Reduce Pressure)
-Avoid SELECT *, filter early.
-Use clustering keys for pruning on large fact tables.
-Create materialized views for expensive month-end aggregates.
-Partition large ETL loads into smaller batches instead of one giant query.

👉 Each optimized query frees up slots for others.

🔹 5. Result Caching & Data Sharing
Encourage teams to leverage query result cache for repeated queries.
Share read-only data copies instead of letting each team hit the same large tables with duplicate queries.

🔹 6. Resource Monitors (Cost & Load Control)
Set credit limits on warehouses to prevent runaway workloads.

CREATE RESOURCE MONITOR monthend_monitor 
WITH CREDIT_QUOTA = 500 
TRIGGERS ON 90 PERCENT DO NOTIFY
         ON 100 PERCENT DO SUSPEND;

👉 This avoids overspending during peak windows.


🔹 7. Query Scheduling & Orchestration
Use Snowflake Tasks, Airflow, or DBT Cloud to stagger heavy jobs.
Avoid “everyone’s month-end jobs at 11:55 PM.”
Spread batch jobs in time windows (e.g., finance jobs at 6 AM, sales at 7 AM).

🔹 8. Concurrency Monitoring & Alerts
Use WAREHOUSE_LOAD_HISTORY and QUERY_HISTORY to track queueing.

SELECT * 
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
WHERE WAREHOUSE_NAME = 'finance_wh'
ORDER BY START_TIME DESC;

👉 This shows when your warehouse was overloaded → helps in capacity planning.

✅ Practical Strategy for Multi-Member Teams
Define separate warehouses for ETL, BI, Ad-hoc.
Enable multi-cluster scaling for BI/reporting warehouses.
Scale up ETL warehouses for heavy jobs (then auto-suspend).
Schedule jobs smartly → stagger peak workloads.
Optimize queries & leverage caching/materialized views.
Monitor & tune → regularly check warehouse load and adjust scaling policies.

👉 In short:
Concurrency issues = mix of scaling + workload isolation + query tuning + scheduling.
Snowflake gives flexibility with multi-cluster + multiple warehouses → your team just needs to assign the right workload to the right warehouse.