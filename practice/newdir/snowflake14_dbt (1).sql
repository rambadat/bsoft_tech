Incremental Models
==================
🔹 Definition
An incremental model in dbt is a table that is built once and then updated with only new or changed records instead of being rebuilt from scratch every time.

👉 Without incremental: dbt drops and recreates the whole table on every run.
👉 With incremental: dbt only processes new data, saving huge compute costs in Snowflake.


✅ Example dbt Incremental Model with updated_timestamp
{{ config(materialized = 'incremental', unique_key = 'order_id') }}

select
    order_id,
    customer_id,
    order_date,
    total_amount,
    updated_timestamp
from {{ source('raw', 'orders') }}
{% if is_incremental() %}
  -- Only get rows updated after the max timestamp already loaded
  where updated_timestamp > (
      select max(updated_timestamp) from {{ this }}
  )
{% endif %}

🔹 What Happens Here:
First Run → fact_orders is created with all rows.
Next Run  → Only rows with updated_timestamp greater than the latest in target are pulled.

dbt generates a MERGE so:
If order_id already exists → it’s updated with new values.
If new order_id → it’s inserted.

✅ This way, you’re safe against late-arriving data, updates, corrections, and cancellations.


Materialization
===============
🔹 What is Materialization in dbt?

Materialization = the strategy dbt uses to build a model in the database.

In dbt, every model (.sql file) is just a SELECT query.
Materialization tells dbt how to turn that SELECT query into a physical object in Snowflake (or any warehouse).

👉 Think of it like:
“Should dbt make this query into a table?”
“Should it be a view?”
“Should it be updated incrementally?”



Types of Materializations in dbt
--------------------------------
1. View (default)
dbt creates a view from your query.
Lightweight, always up-to-date with source data.
But can be slow for large datasets, because every query recomputes.

{{ config(materialized='view') }}


2. Table
dbt runs your query and stores the results as a physical table.
Faster for querying large data.
But must be rebuilt every time you dbt run.

{{ config(materialized='table') }}

3. Incremental
dbt creates a table, but only loads new/updated data on subsequent runs.
Uses strategies like append or merge.
Perfect for fact tables / event logs.

{{ config(
    materialized='incremental',
    unique_key='order_id',
    incremental_strategy='merge'
) }}

4. Ephemeral
Not created in the database.
Acts like a CTE (Common Table Expression) that gets injected into downstream models.
Great for small transformation steps you don’t want stored as a table/view.

{{ config(materialized='ephemeral') }}


Example of Materialized as View
-------------------------------
📌 The Model: stg_orders.sql
{{ config(materialized='view') }}

select
    order_id,
    customer_id,
    order_date
from {{ source('raw', 'orders') }}


🔹 What dbt does behind the scenes
During compilation
dbt sees materialized='view'.
It prepares a create or replace view statement in Snowflake.

Generated SQL in Snowflake
create or replace view DEV_DB.STAGING.stg_orders as (

    select
        order_id,
        customer_id,
        order_date
    from DEV_DB.RAW.orders

);


After creation
stg_orders is not storing any data itself.
Instead, it always queries the underlying RAW.orders table whenever you run a query against it.

Snapshot
========
🔹 What is a Snapshot in dbt?
A snapshot in dbt is a way to capture and preserve the state of a table over time.
Normally, if a source table is updated (e.g., customer address changes), the old value is lost.
With a snapshot, dbt will store the changes, so you can see what the data looked like yesterday, last week, last month, etc.

Snapshot Strategies
-------------------
Timestamp strategy 	→ Uses a column like updated_at.
Check strategy 		→ Compares all (or selected) columns for changes.

👉 In other words: dbt snapshots = slowly changing dimension (SCD Type 2) out-of-the-box.


🔹 Example Use Case

Imagine you have a customers table in Snowflake:

customer_id	name		address		updated_at
101			John Doe	NY, USA		2025-08-01 12:00:00
102			Jane Roe	LA, USA		2025-08-05 14:30:00

Now John moves from NY to Boston → the source table is updated:

customer_id		name		address			updated_at
101				John Doe	Boston, USA		2025-08-18 09:00:00

Without a snapshot  → You lose the fact that John was in NY before.
With a snapshot 	→ dbt preserves both versions.

Example: Snapshot with Timestamp strategy
-----------------------------------------
🔹 How to Create a Snapshot in dbt
Create a file: snapshots/customers_snapshot.sql

{% snapshot customers_snapshot %}

{{ config(
    target_schema='snapshots',
    unique_key='customer_id',
    strategy='timestamp',
    updated_at='updated_at'
) }}

select
    customer_id,
    name,
    address,
    updated_at
from {{ source('raw', 'customers') }}

{% endsnapshot %}


🔹 How It Works
unique_key='customer_id' → Identifies a unique row.
strategy='timestamp' → dbt looks at updated_at column to decide if a row changed.
When you run dbt snapshot:
dbt compares source data with the existing snapshot table.
If changes are found → it inserts a new version of the row with validity dates.

🔹 Resulting Snapshot Table
customer_id		name		address			dbt_valid_from			dbt_valid_to
101				John Doe	NY, USA			2025-08-01 12:00:00		2025-08-18 09:00:00
101				John Doe	Boston, USA		2025-08-18 09:00:00		NULL
102				Jane Roe	LA, USA			2025-08-05 14:30:00		NULL

dbt_valid_from → when this version became valid.
dbt_valid_to → when this version was replaced (NULL = current).


Example: Snapshot with Check Strategy
-------------------------------------
Create a snapshot file:
snapshots/customers_snapshot.sql

{% snapshot customers_snapshot %}
{{ config(
    target_schema='snapshots',          -- schema where snapshot will be stored
    unique_key='customer_id',           -- primary identifier
    strategy='check',                   -- check strategy
    check_cols=['home_address', 'email_address', 'mobile_no']  -- track changes in these columns
) }}

select
    customer_id,
    name,
    home_address,
    email_address,
    mobile_no,
    updated_at
from {{ source('raw', 'customers') }}

{% endsnapshot %}


🔹 How It Works
dbt will compare current rows from the raw.customers table against what’s already stored in the snapshot.
If any of the columns in check_cols change (home address, email, mobile no):
dbt will close out the old record (dbt_valid_to gets filled).
Insert a new version with updated values and a fresh dbt_valid_from.

🔹 Example Run
First snapshot run (initial state):
customer_id		name		home_address	email_address	mobile_no	dbt_valid_from			dbt_valid_to
101				John Doe	NY, USA			john@abc.com 	1234567890	2025-08-01 10:00:00		NULL
102				Jane Roe	LA, USA			jane@xyz.com	9876543210	2025-08-01 10:00:00		NULL

Later John changes his email address:
customer_id		name		home_address	email_address		mobile_no
101				John Doe	NY, USA			john.doe@abc.com	1234567890

Snapshot after second run:
customer_id		name		home_address	email_address		mobile_no	dbt_valid_from			dbt_valid_to
101				John Doe	NY, USA			john@abc.com		1234567890	2025-08-01 10:00:00		2025-08-18 09:15:00
101				John Doe	NY, USA			john.doe@abc.com	1234567890	2025-08-18 09:15:00		NULL
102				Jane Roe	LA, USA			jane@xyz.com		9876543210	2025-08-01 10:00:00		NULL

✅ This way, you have a full history of customer attributes, and you can always query “what was John’s email last month?”

Difference between dbt build and dbt run
========================================
🔹 dbt run
Purpose: Builds models (SQL files under models/) into your target warehouse.
Scope: Only runs models — does not handle tests or snapshots.
Command: dbt run

Example:
If you add or change a model (stg_orders.sql), dbt run will compile the SQL and create/update the table/view in your target schema.

🔹 dbt build
Purpose: A newer, all-in-one command introduced in dbt v1.0+.
Scope: Runs models + seeds + snapshots + tests in a single workflow.
Command: dbt build

Order of execution (per resource):
---------------------------------
Seeds (dbt seed)
Models (dbt run)
Snapshots (dbt snapshot)
Tests (dbt test)

Example:
If you run dbt build, it will:
Load your CSV seed files into Snowflake
Run your transformations (run)
Apply snapshots if any
Run tests on the final objects