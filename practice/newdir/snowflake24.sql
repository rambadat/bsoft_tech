Raw Access Policy (selective rows fetch)
=================
A Row Access Policy is a security rule that restricts which rows of a table or view a user can see, based on their role, user identity, or other conditions.
It ensures row-level security (RLS) — i.e., two users querying the same table can see different sets of rows depending on who they are.

💡 Simple Definition
A Row Access Policy is a condition (usually written as a Boolean expression) attached to a table or view that filters data automatically for users, based on whom they are or what role they have.

🧠 Conceptual Example
Suppose you have a SALES table:
| REGION | SALES_REP | AMOUNT |
| ------ | --------- | ------ |
| East   | Alice     | 2000   |
| West   | Bob       | 1500   |
| North  | Carol     | 1800   |

Now:
Alice should see only East region
Bob → only West
Carol → only North
✅ Instead of creating three separate views, you can attach a Row Access Policy that enforces this rule automatically.


CREATE OR REPLACE ROW ACCESS POLICY region_policy
AS (region STRING) RETURNS BOOLEAN ->
  CASE
    WHEN CURRENT_ROLE() IN ('EAST_SALES_ROLE') AND region = 'East' THEN TRUE
    WHEN CURRENT_ROLE() IN ('WEST_SALES_ROLE') AND region = 'West' THEN TRUE
    WHEN CURRENT_ROLE() IN ('NORTH_SALES_ROLE') AND region = 'North' THEN TRUE
    ELSE FALSE
  END;
  
ALTER TABLE sales
ADD ROW ACCESS POLICY region_policy
ON (region);

SELECT * FROM sales;

Snowflake automatically applies the policy — meaning:
The query engine filters rows based on the condition in the policy.
The user only sees rows allowed by their role.
✅ No manual filtering or WHERE clause needed!


🧰 Important System Functions Used
| Function                        | Description                               |
| ------------------------------- | ----------------------------------------- |
| `CURRENT_ROLE()`                | Returns role executing the query          |
| `CURRENT_USER()`                | Returns username                          |
| `CURRENT_ACCOUNT()`             | Returns Snowflake account ID              |
| `CURRENT_REGION()`              | Returns current Snowflake region          |
| `IS_ROLE_IN_SESSION(role_name)` | Checks if a role is active in the session |

You can use these functions inside Row Access Policy logic.


🛡️ Example: Row Policy Using Username
CREATE OR REPLACE ROW ACCESS POLICY sales_user_policy
AS (sales_rep STRING) RETURNS BOOLEAN ->
  sales_rep = CURRENT_USER();

ALTER TABLE sales
ADD ROW ACCESS POLICY sales_user_policy
ON (sales_rep);

Now:
-Alice sees only rows where sales_rep = 'ALICE'
-Bob sees only rows where sales_rep = 'BOB'

🔍 View Policy Details
SHOW ROW ACCESS POLICIES;
OR
DESC TABLE sales;

🔄 Replace or Drop Policy
ALTER TABLE sales DROP ROW ACCESS POLICY region_policy;
DROP ROW ACCESS POLICY region_policy;


🧱 Row Access Policy + Column Masking
Often, organizations combine both:
-Row Access Policy → restrict which rows are visible
-Masking Policy → hide or obfuscate sensitive columns

CREATE MASKING POLICY mask_salary
AS (val NUMBER) RETURNS NUMBER ->
  CASE
    WHEN CURRENT_ROLE() IN ('HR_ROLE') THEN val
    ELSE NULL
  END;

CREATE ROW ACCESS POLICY region_row_policy
AS (region STRING) RETURNS BOOLEAN ->
  region = 'East';


ALTER TABLE employees
  ADD MASKING POLICY mask_salary ON salary,
  ADD ROW ACCESS POLICY region_row_policy ON (region);


🧮 Use Cases
| Use Case                     | Example                                            |
| ---------------------------- | -------------------------------------------------- |
| Regional data separation     | Show only data for the user’s assigned region      |
| Departmental security        | HR can see all employees; managers only their team |
| Multi-tenant SaaS            | Each customer (tenant) sees only their own data    |
| Regulatory compliance        | Restrict access to PII data by jurisdiction        |
| Sensitive data collaboration | Filter records based on data sharing rules         |


⚙️ Integration with Other Snowflake Features
| Feature                | Description                                    |
| ---------------------- | ---------------------------------------------- |
| **Dynamic Tables**     | Policy is applied automatically during refresh |
| **Materialized Views** | Policy propagates to dependent views           |
| **Secure Views**       | Combine with RLS for extra isolation           |
| **Data Sharing**       | Shared data retains row-level restrictions     |


🧾 In short
| Aspect              | Row Access Policy                                |
| ------------------- | ------------------------------------------------ |
| **Purpose**         | Row-level security                               |
| **Scope**           | Filters rows per user/role                       |
| **Created on**      | Tables or views                                  |
| **Expression type** | Boolean logic                                    |
| **Typical use**     | Multi-tenant, regional or role-based data access |
| **Related feature** | Masking policy (for columns)                     |


Aggregation Policy (only aggregated query will be successfully executed)
==================
An Aggregation Policy is a schema-level object in Snowflake that lets a data provider control what kind of queries can access data in a table or view — specifically, it forces consumers to aggregate data rather than allowing them to see individual records. 

In other words, if a table has an aggregation policy, queries against it are “aggregation-constrained”:
-The query must use an aggregation function (e.g. SUM, AVG, COUNT, etc.) or be grouped via GROUP BY.
-Each group generated must have at least a minimum number of rows (or entities, in some variants) defined by the aggregation policy. 
-If some groups don’t meet the minimum size, those are combined into a “remainder group” whose key is set to NULL. 

These policies help protect individual privacy by preventing data consumers from querying and extracting fine-grained individual record information


🔍 Key Components & Behavior
Here are important aspects of how aggregation policies work:
| Component                           | Description                                                                                                         |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| **Minimum group size**              | The smallest number of rows (or entities) that each group must have. 
|									  |	If a group has fewer, it is merged into a “remainder” group.
| **Entity-level privacy (optional)** | You can define an *entity key* (one or more columns identifying an entity, e.g., `user_id`, `email`). 
|									  | With entity-level privacy, the minimum size is enforced over unique entity values, not just rows.
|									  | This prevents privacy leaks when one entity has many rows. 
| **Allowed functions**               | Only certain aggregation functions are permitted. Also, the query must use `GROUP BY` (or scalar aggregation). 
|									  | Other constructs (like window functions) are restricted.
| **Remainder group logic**           | Groups not meeting minimum size threshold are merged into a remainder group, with the GROUP BY key set to NULL.
| **Policy constraints**              | There are limitations: e.g. external tables can’t have aggregation policies; 
|									  | wont work with certain SQL constructs like `ROLLUP`, `CUBE`, `GROUPING SETS`, etc.


⚙️ How to Create / Use Them
Here’s the general workflow:

1.Create an Aggregation Policy
CREATE AGGREGATION POLICY my_agg_policy
  AS () RETURNS AGGREGATION_CONSTRAINT -> AGGREGATION_CONSTRAINT(MIN_GROUP_SIZE => 5);

Or a conditional policy, e.g., allow unrestricted access for admin roles but impose aggregation for others:
CREATE AGGREGATION POLICY my_agg_policy
  AS () RETURNS AGGREGATION_CONSTRAINT ->
    CASE
      WHEN CURRENT_ROLE() = 'ADMIN' THEN NO_AGGREGATION_CONSTRAINT()
      ELSE AGGREGATION_CONSTRAINT(MIN_GROUP_SIZE => 5)
    END;


2.Attach the policy to a table or view
ALTER TABLE my_table
  SET AGGREGATION POLICY my_agg_policy;


3.Querying restrictions apply — Any query on my_table must satisfy the policy: group size, aggregation functions, etc. If conditions aren’t met, groups are merged or results are constrained.

4.Monitoring & management — You can view all aggregation policies via SNOWFLAKE.ACCOUNT_USAGE.AGGREGATION_POLICIES; see which tables/views have them; detach them if needed.



🛠️ When and Why Use Aggregation Policies
Here are scenarios and motivations for using aggregation policies:
-Data privacy / compliance: When sharing data with external entities (partners, customers), but you want to ensure no single record is exposed.
-Data clean rooms: Aggregation policies help enforce minimum group thresholds to avoid re-identification.
-Sensitive data exposure: Even internally, there may be regulatory or business reasons to avoid exposing individual-level data, while still enabling aggregate reporting.
-Sharing live data: Providers who share datasets want to protect identifiable info by forcing aggregated queries.

✅ Summary
Aggregation Policies = governance feature for controlling granularity of query results
Forces grouping & minimum group-size thresholds
Helps protect individual privacy
Works with entities (if entity keys defined)
Applied at table or view level

Example of how an Aggregation Policy works in Snowflake
-------------------------------------------------------
🧱 Step 1️⃣: Create a Demo Table
CREATE OR REPLACE TABLE sales_data (
    region STRING,
    customer_id STRING,
    amount NUMBER
);

INSERT INTO sales_data VALUES
('East', 'C001', 200),
('East', 'C002', 250),
('East', 'C003', 300),
('West', 'C004', 100),
('West', 'C005', 150),
('West', 'C006', 175),
('North', 'C007', 400),
('North', 'C008', 425),
('North', 'C009', 450);


🧩 Step 2️⃣: Create an Aggregation Policy
We’ll create a policy that enforces a minimum group size of 3 —
meaning, no query can return a group smaller than 3 rows.

CREATE OR REPLACE AGGREGATION POLICY sales_agg_policy
AS () RETURNS AGGREGATION_CONSTRAINT ->
    AGGREGATION_CONSTRAINT(MIN_GROUP_SIZE => 3);

✅ This means:
Any query on this table must aggregate (e.g., SUM, AVG, COUNT)
Each group must have at least 3 rows

🧱 Step 3️⃣: Attach the Policy to the Table
ALTER TABLE sales_data
SET AGGREGATION POLICY sales_agg_policy;

🧪 Step 4️⃣: Try Queries and See the Behavior
	❌ Case 1: Non-aggregated query
	SELECT * FROM sales_data;
	➡️ Result: ❌ Error
	Snowflake blocks it:
	Aggregation policy on 'SALES_DATA' requires aggregation in queries.
	
	✅ Case 2: Aggregated query that meets policy
	SELECT region, COUNT(*) AS num_customers, SUM(amount) AS total_sales
	FROM sales_data
	GROUP BY region;


	➡️ Result: ✅ Works fine — each region has 3 rows, meeting the minimum size.

	| REGION | NUM_CUSTOMERS | TOTAL_SALES |
	| ------ | ------------- | ----------- |
	| East   | 3             | 750         |
	| West   | 3             | 425         |	
	| North  | 3             | 1275        |
	
	⚠️ Case 3: Aggregated query with small groups
	Let’s say someone tries:
	SELECT region, customer_id, SUM(amount)
	FROM sales_data
	GROUP BY region, customer_id;

	➡️ Result: ❗ Snowflake will enforce the policy.

	If any (region, customer_id) group has fewer than 3 rows, it will merge them into a remainder group with NULL keys, like:

	REGION	CUSTOMER_ID	SUM(AMOUNT)
	NULL	NULL	3300

	The remainder group ensures no small group leaks individual-level data.	
	

🧮 Step 5️⃣: Add Entity-Level Privacy (Optional)
We can strengthen privacy by defining entity-level enforcement (e.g., based on customer_id).

CREATE OR REPLACE AGGREGATION POLICY sales_entity_policy
AS (customer_id STRING)
RETURNS AGGREGATION_CONSTRAINT ->
  AGGREGATION_CONSTRAINT(
    MIN_GROUP_SIZE => 3,
    ENTITY_KEY => (customer_id)
  );


Apply it:
ALTER TABLE sales_data
SET AGGREGATION POLICY sales_entity_policy;


Now, Snowflake ensures:
Each group must contain at least 3 distinct customer_id values
Even if one customer has multiple rows, they count as one entity


🧾 Step 6️⃣: Check Applied Policy
SHOW AGGREGATION POLICIES;
Or:
DESC TABLE sales_data;

You’ll see:
+----------------------+----------------------+
| property             | value                |
+----------------------+----------------------+
| aggregation_policy   | SALES_ENTITY_POLICY  |
+----------------------+----------------------+

🧰 Step 7️⃣: Remove Policy (if needed)
ALTER TABLE sales_data
UNSET AGGREGATION POLICY;

🧭 Summary
| Concept             | Description                                 |
| ------------------- | ------------------------------------------- |
| **Purpose**         | Enforces aggregation-based privacy controls |
| **Where used**      | Data sharing, clean rooms, analytics        |
| **Forces**          | Aggregation functions or GROUP BY           |
| **Min group size**  | Protects from identifying small groups      |
| **Entity key**      | Ensures privacy based on distinct entities  |
| **Remainder group** | Combines too-small groups under `NULL` key  |
	
	
🏁 In short
🔒 Aggregation Policy = A privacy guardrail that forces queries to be aggregated and prevents revealing small or individual-level data — essential for data sharing, marketplace datasets, and clean room collaborations.
