DBT (Data Buld Tool)
====================
🌟 What is dbt?
dbt = Data Build Tool
It’s a tool that helps transform raw data inside your data warehouse (like Snowflake, BigQuery, Redshift, Databricks).
Think of it as “SQL + version control + automation” for analytics teams.
Instead of writing messy SQL scripts here and there, dbt makes you organize them into models (SQL files) and runs them in the right order.

🏗️ How does dbt work?
You already have data loaded into your warehouse (from ETL/ELT tools like Fivetran, Airbyte, or Snowpipe).
dbt lets you write SQL SELECT statements that define how raw data should be transformed.
Example: cleaning columns, joining tables, aggregating sales, etc.
dbt compiles these SQL files into executable SQL and runs them on your warehouse.
The results are saved as tables or views in the warehouse.

my_dbt_project/
 ├── models/
 │   ├── staging/
 │   │   └── stg_orders.sql (Cleaning layer)
 │   └── marts/
 │       └── fct_sales.sql  (Tranformation layer)
 ├── dbt_project.yml
 └── ...



YML format
----------
We code in YML format in DBT
version: 2

models:
  - name: events
    description: This table contains clickstream events from the marketing website

    columns:
      - name: event_id
        description: This is a unique identifier for the event
        data_tests:
          - unique
          - not_null

      - name: user-id
        quote: true
        description: The user who performed the event
        data_tests:
          - not_null
		  

YML/YAML file usage (Mandatory/Optional/Required)
=================================================
Lets see whether YAML file is mandatory, optional, or not required for certain dbt features

🔹 1. profiles.yml
    Applies only to dbt Core (local installs) → required to store connection details.
    Not used in dbt Cloud (connections are managed in the UI).
    
 🔹 2. YAML files inside your dbt project

These are different from profiles.yml.
Inside a dbt project, YAML files (e.g., schema.yml) are used to declare metadata like sources, tests, descriptions, and documentation.

Feature-by-feature:
Feature	              Is YAML reqd?	    Why?
-------               -------------     ----
Sources	              ✅ Mandatory	    You must declare a source in a .yml file to use {{ source() }} in models.
Models	              ⚪ Optional	    Models themselves are just .sql files. But you use .yml to add tests, documentation, or group them.
Snapshots	          ✅ Mandatory      (but inside .sql not .yml) Snapshots need their own .sql files with config().But you can add descripns/tests in .yml
Seeds	              ⚪ Optional	    Seeds are just .csv files. A .yml can add tests/docs, but not required.
Macros	              ❌ Not required	Macros are .sql files in the macros/ directory. YAML plays no role.
Incremental models	  ⚪ Optional	    The incremental logic is in the model .sql file. YAML only if you want tests/docs.
Materializations	  ❌ Not required	Materializations are custom macros in macros/. YAML doesn’t apply.


Typical DBT flow in order
=========================

Sources + Seeds → Models (Staging) / Models (Incremental) / Snapshots (if history needed) → Marts

Sources 		→ Raw data from warehouse/external systems.  --Done (Tables from snowflake)
Seeds 			→ Static lookup/master data (CSV files).     --Done (csv files in DBT)
Staging 		→ Clean and standardize on sources + seeds.  --In Progress
Models 			→ Transform staging data into business logic.
Incremental Models → Special models that load only new/changed data.
Snapshots 		→ Capture history of slowly changing data (track changes over time).
Marts 			→ Final business-facing layer (facts & dimensions).
Macros 			→ Utility functions used across all steps.
Materializations → Define how each model is stored (table, view, incremental, etc.).


Creating Models, Test Models, Document Models, Schedule Job for models
======================================================================
Create a new Snowflake worksheet.
Load sample data into your Snowflake account.
Connect dbt to Snowflake.
Take a sample query and turn it into a model in your dbt project. A model in dbt is a select statement.
Add sources to your dbt project. Sources allow you to name and describe the raw data already loaded into Snowflake.
Add tests to your models.
Document your models.
Schedule a job to run.		  

Examples of dealing with staging raw data (Cleaning the data , Appying transformation, Applying filterations etc)
=================================================================================================================
Table : RAW.SALES.ORDERS
ID (int) | CUSTID (varchar) | ORDERDATE (string) | AMOUNT (int, cents) 
STATUS (varchar, values: 'Y','N','1','0','true','false') 
UPDATED_AT (timestamp) | COMMENTS (nullable) | SOURCE_SYSTEM (varchar)


--models/staging/stg_orders.sql
with source as (

    -- Select everything from raw table
    select *
    from RAW.SALES.ORDERS

),

deduplicated as (

    -- Remove duplicates: keep the latest record per order_id
    select *
    from source
    qualify row_number() over (
        partition by id
        order by updated_at desc
    ) = 1

),

renamed_and_cast as (

    select
        -- 1. Standardize column names & cast data types
        cast(id as varchar) as order_id,
        cast(custid as varchar) as customer_id,

        -- 2. Date format uniformity
        try_cast(orderdate as date) as order_date,

        -- 3. Numeric/decimal formatting (convert cents → dollars)
        cast(amount as number(12,2)) / 100 as order_amount_usd,

        -- 4. Normalize flags (Y/N, 1/0, true/false → boolean)
        case 
            when lower(status) in ('y','1','true') then true
            when lower(status) in ('n','0','false') then false
            else null
        end as is_active,

        -- 5. Handle nulls (default customer_id)
        coalesce(custid, 'UNKNOWN') as cleaned_customer_id,

        -- 6. Audit metadata
        source_system,
        updated_at,
        current_timestamp() as dbt_loaded_at

    from deduplicated

),

filtered as (

    -- 7. Remove bad data (invalid or test records)
    select *
    from renamed_and_cast
    where order_id is not null
      and order_amount_usd > 0

)

select * from filtered;

✅ What This Does
Column renaming & casting → id → order_id (varchar), custid → customer_id
Date format → orderdate safely cast into DATE
Decimal uniformity → amount in cents → order_amount_usd with number(12,2)
Deduplication → keep only the most recent row per order_id using QUALIFY
Null handling → missing custid replaced with "UNKNOWN"
Flag normalization → messy status column mapped into BOOLEAN (is_active)
Filtering → drop test/invalid rows (order_id is not null, amount > 0)
Audit tracking → add dbt_loaded_at for when the row was staged

Flow of Data : Raw Layer->Staging Layer->Transformation Layer->Consumption Layer
================================================================================
1) Raw Layer (Landing Zone)
This is not touched by dbt — raw data lands here from pipelines like Snowpipe, Fivetran, Airbyte, Informatica, etc.
Examples: RAW.SALES.ORDERS, RAW.CRM.CUSTOMERS
❌ No transformations, ❌ no renaming — just raw ingestion.

2) Staging Layer (stg_ models in dbt)
Goal: Clean & standardize raw data for consistent downstream use.
Activities dbt handles here:
Uniform naming conventions (snake_case, descriptive names).
Data type casting (TRY_CAST, decimals, booleans).
Deduplication (use QUALIFY ROW_NUMBER() or RANK).
Flag standardization (e.g., Y/N → boolean).
Date/time normalization (consistent DATE, TIMESTAMP_NTZ).
Basic filters (remove null IDs, invalid rows).
Add audit columns (dbt_loaded_at).

👉 These are implemented as SQL SELECT statements in dbt models.
dbt compiles them into Snowflake SQL, runs them, and materializes as views (default) or tables in the staging schema.

models/staging/stg_orders.sql
select
    cast(id as varchar) as order_id,
    try_cast(orderdate as date) as order_date,
    amount::number(12,2) / 100 as order_amount_usd,
    case when lower(status) in ('y','1','true') then true else false end as is_active,
    current_timestamp() as dbt_loaded_at
from RAW.SALES.ORDERS
where amount > 0

3) Intermediate / Transformation Layer
Goal: Apply business rules & joins across multiple staging models.

Here dbt handles:
Joins (orders + customers + products).
Derivations (calculate profit margin, lifetime value, order status).
Business logic standardization (e.g., how revenue is defined).
Data enrichment (lookup tables, reference data).

👉 These models may be materialized as tables (for performance) in a schema like ANALYTICS.INTERMEDIATE.
models/intermediate/int_orders_with_customers.sql
select
    o.order_id,
    o.order_date,
    o.order_amount_usd,
    c.customer_id,
    c.customer_name,
    c.country
from {{ ref('stg_orders') }} o
join {{ ref('stg_customers') }} c
  on o.customer_id = c.customer_id

4) Marts / Consumption Layer
Goal: Build analytics-ready tables for BI & reporting (Power BI, Tableau, Looker, etc.).
dbt handles:
Fact tables → transactional, aggregated (e.g., fct_sales).
Dimension tables → reference entities (e.g., dim_customers).
Aggregations (e.g., daily sales, revenue by product, churn rate).
Denormalization (flatten data for BI).
Performance optimizations (materialized as tables in Snowflake).

👉 These are in a schema like ANALYTICS.MARTS or ANALYTICS.CONSUMPTION.
models/marts/fct_sales.sql
select
    o.customer_id,
    c.customer_name,
    date_trunc('day', o.order_date) as order_day,
    sum(o.order_amount_usd) as total_sales
from {{ ref('stg_orders') }} o
join {{ ref('stg_customers') }} c
  on o.customer_id = c.customer_id
group by 1,2,3


5) dbt’s Special Powers in Cleaning/Transformation
Ref + DAG (Lineage)				: {{ ref('stg_orders') }} ensures correct dependency order.
Tests							: Built-in (e.g., unique, not_null) + custom data tests ensure data quality.
Macros							: Reusable SQL functions for consistent cleaning (e.g., cents_to_dollars).
Documentation & Lineage Graph	: Auto-generated from schema.yml + refs.
Materializations				: Choose whether staging = view, marts = table, snapshots = slowly changing dimensions.
CI/CD							: Run transformations + tests automatically on each commit.

RAW (no dbt) 
   ↓
STAGING (dbt: cleaning, type casting, standardization)
   ↓
INTERMEDIATE (dbt: joins, derivations, enrichment)
   ↓
MARTS / CONSUMPTION (dbt: facts, dimensions, aggregations → BI ready)

Handling Incremental Data
=========================
Incremental data handling is one of dbt’s most powerful features, especially in a Snowflake pipeline. 
Let’s walk through it step by step in the RAW → STAGING → INTERMEDIATE → MARTS cycle.

Instead of rebuilding the whole table every time (dbt run), dbt can only insert new/changed rows.
Controlled by materialization strategy → incremental.
Works perfectly in Snowflake since compute = $$, so smaller updates save time & cost.


{{ config(
    materialized = 'incremental',
    unique_key = 'order_id'
) }}

select
    id as order_id,
    customer_id,
    order_date::date as order_date,
    amount::number(12,2) / 100 as order_amount_usd,
    updated_at
from RAW.SALES.ORDERS

{% if is_incremental() %}
  -- Only bring in rows newer than the latest already loaded
  where updated_at > (select max(updated_at) from {{ this }})    --{{ this }} refers to target table which is a dbt model in our case
{% endif %}

Note : 
Target table : {{ this }} refers to target table which is a dbt model in our case
Source table : RAW.SALES.ORDERS


Breakdown:
materialized = 'incremental' → tells dbt to append/update instead of full rebuild.
unique_key = 'order_id' 	 → ensures existing rows with same key get updated (merge).
is_incremental() 			 → dbt macro that is true only during incremental runs (not first run).
{{ this }} 					 → refers to the target table (the one dbt is building).


RAW → STAGING (usually views/full refresh)
     ↓
INTERMEDIATE (sometimes incremental for heavy joins)
     ↓
MARTS / FACTS (incremental = MERGE, only new/changed data)
     ↓
SNAPSHOTS (slowly changing dimensions)


source
======
🔹 What is a Source in dbt?
In dbt, a source represents the raw tables that already exist in your data warehouse (e.g., in Snowflake).
These are usually tables or views not created by dbt → e.g., data loaded from external systems (via ETL tools, Fivetran, Snowpipe, etc.).
Declaring them as sources in dbt makes them:
Easily referenceable
Part of lineage graphs
Testable (you can apply not_null, unique, freshness tests directly on them)


models/staging/src_sources.yml:
version: 2

sources:
  - name: raw                # Logical group name for sources
    database: analytics      # Snowflake DB
    schema: raw_data         # Schema where raw tables are
    tables:
      - name: orders
        description: "Raw orders data ingested from Shopify"
      - name: customers
        description: "Raw customers data ingested from CRM"

sql query
---------
select * from analytics.raw_data.orders

Equivalent DBT Query
--------------------
select * from {{ source('raw', 'orders') }}


Distinguish Staging vs Source
=============================
🔹 Source vs Staging in dbt

1️⃣ Source
---------
What it is  : A pointer (declaration) to a raw table that already exists in your warehouse.
Purpose		: Acts as the entry point for dbt models. It is not transformed, just declared.
Example	    : Raw table in Snowflake: analytics.raw_data.orders

dbt Declaration (YAML):
sources:
  - name: raw
    database: analytics
    schema: raw_data
    tables:
      - name: orders


Using in sql
------------
select * from {{ source('raw', 'orders') }}

2️⃣ Staging

What it is: A dbt model (SQL file) that references a source and applies initial cleaning + standardization.
Purpose: Make raw data analytics-friendly
Apply naming conventions (snake_case, consistent IDs)
Fix data types, date formats, null handling
Add calculated columns (e.g., order_date::date)

Example (stg_orders.sql):
with raw_orders as (
    select *
    from {{ source('raw', 'orders') }}
)

select
    try_cast(order_id as int) as order_id,
    upper(customer_name) as customer_name,
    to_date(order_date, 'YYYY-MM-DD') as order_date,
    total_amount::numeric(12,2) as order_amount
from raw_orders


🔹 Summary Table
Aspect			Source							Staging
Defined in		.yml file						.sql file (dbt model)
Data State		Raw, untransformed				Cleaned, standardized
Purpose			Entry point, lineage tracking	Initial cleaning + uniform structure
Examples		raw.orders, raw.customers		stg_orders.sql, stg_customers.sql
Transforms?		❌ No							✅ Yes (naming, types, nulls, formats)


Seeds
=====
🔹 What are Seeds in dbt?
A seed in dbt is just a CSV file that you place in your dbt project (inside the seeds/ directory).
dbt can then load that CSV into your warehouse as a table.
It’s useful for small, static datasets that don’t come from an external system.
Think of it as "lookup tables" or "reference data" that you keep under version control with your dbt project.

🔹 When to Use Seeds?
✅ Small dimension/lookup tables
✅ Reference mappings (country codes, status codes, product categories)
✅ Testing data for dev environments
✅ Default values for business logic

🔹 Example
1. Create a CSV file
In your dbt project, make a folder seeds/ and add a file called country_codes.csv:
country_code,country_name,continent
US,United States,North America
IN,India,Asia
FR,France,Europe


2. Define it in dbt_project.yml
seeds:
  my_project:       # your dbt project name
    country_codes:
      +schema: lookup    # seeds can be loaded into a specific schema
      +column_types:     # enforce data types in warehouse
        country_code: string
        country_name: string
        continent: string

3. Load it into Snowflake
dbt seed

dbt will:
Read the country_codes.csv
Create a table in Snowflake (e.g., LOOKUP.COUNTRY_CODES)
Insert the CSV rows into that table

4. Use it in Models
select o.order_id,
       o.customer_id,
       c.country_name,
       c.continent
from {{ ref('stg_orders') }} o
left join {{ ref('country_codes') }} c
  on o.country_code = c.country_code


🔹 Seeds vs Sources vs Models
Feature				Seeds						Sources	Models
Data origin			CSV file in dbt project		External tables in warehouse	SQL transformations
Size				Small (KB–MB)				Large (GB–TB)	Varies
Use case			Static reference data		Raw ingested data	Business logic, transformations
Managed by			dbt directly				External ingestion tools (Fivetran, Snowpipe, etc.)	dbt

Macros
======
A macro in dbt is like a function in programming.
It’s written in Jinja (a templating language), and lets you reuse SQL logic across models.
Instead of repeating the same SQL code in multiple models, you define it once as a macro and call it anywhere.

👉 Think of macros as "SQL functions + automation scripts" inside dbt.

🔹 Why do we need Macros?
✅ Avoid repetitive SQL code
✅ Apply transformations consistently
✅ Simplify maintenance (change in one place → applied everywhere)
✅ Add logic & automation (loops, if-else, dynamic table names, etc.)


🔹 Types of Macros
1) Reusable SQL snippets 	: e.g., a standard way to clean emails, standardize date formats.
2) Materialization macros 	: Define how dbt builds models (table, view, incremental).
3) Hooks & operations 		: Run SQL before/after models (like auditing, permissions).
4) Custom logic with Jinja : Loops, if/else, dynamic schema or table names.


1. Reusable SQL Snippet Macros
------------------------------
These are the most common type — basically "functions for SQL logic."
They prevent copy-paste SQL.

✅ Use case: casting, trimming, cleaning data.

Example: macros/convert_to_date.sql
{% macro convert_to_date(column_name) %}
    try_cast({{ column_name }} as date)
{% endmacro %}

Usage in a model:
select {{ convert_to_date("order_date") }} as order_date
from {{ source("raw", "orders") }};

2. Materialization Macros
-------------------------
Materializations define how dbt builds a model in the warehouse:
as a view
as a table
as an incremental table (append/update)

👉 These are defined in dbt itself, but you can override or create custom ones.

Example: a custom "snapshot-like" materialization:
{% materialization my_incremental, adapter='snowflake' %}
  {# logic for building incremental model #}
{% endmaterialization %}


Usage in schema.yml or model config:
materialized: my_incremental

3. Hooks and Operations Macros
------------------------------
Hooks = macros that run before or after a model/table is built.
Operations = macros you can run manually with dbt run-operation.

✅ Use cases:
Granting permissions
Logging / audit inserts
Running maintenance commands

Example: Post-hook to grant select permission:
models:
  my_model:
    post-hook:
      - "{{ grant_select('role_analyst') }}"


Macro definition:
{% macro grant_select(role) %}
    grant select on {{ this }} to role {{ role }}
{% endmacro %}

4. Environment / Config Macros
------------------------------
Macros that help with dynamic configs (schema, database, naming conventions).
✅ Use case: Switching schema automatically between dev and prod.

Example:
{% macro schema_for_env() %}
    {% if target.name == 'prod' %}
        analytics
    {% else %}
        analytics_dev
    {% endif %}
{% endmacro %}


Usage in model:
select * from {{ schema_for_env() }}.orders

5. Loop / Conditional Logic Macros
----------------------------------
Macros can contain loops and if/else to generate SQL dynamically.

✅ Use case: Automatically create select statements for many columns.

Example:
{% macro select_columns_with_prefix(columns, prefix) %}
    {% for col in columns %}
        {{ prefix }}.{{ col }}{% if not loop.last %}, {% endif %}
    {% endfor %}
{% endmacro %}


Usage:
select {{ select_columns_with_prefix(['id', 'name', 'email'], 'c') }}
from {{ source("raw", "customers") }} as c;

Expands to:
select c.id, c.name, c.email from raw.customers as c;

6. Testing Macros
-----------------
Custom tests are just macros that return rows failing the condition.

✅ Use case: Ensure data quality.

Example: Test no null emails:
{% test not_null_email(model, column_name) %}
    select * from {{ model }}
    where {{ column_name }} is null
{% endtest %}


Usage in schema.yml:
tests:
  - not_null_email:
      column_name: email
	  
🔹 Quick Comparison
Type					Purpose	Example
Reusable SQL			Clean/reuse SQL	convert_to_date
Materialization			Define build type	incremental, snapshot
Hooks/Operations		Pre/post tasks	grant_select, logging
Env/Config				Dynamic configs	schema_for_env
Loop/Conditional		Auto-generate SQL	select_columns_with_prefix
Testing					Data quality checks	not_null_email	  

Topics to be covered
====================
Models,Source,Staging,Seeds,Macros,Incremental Models,Materialization,Snapshot,Jinja
Build above objects in DBT, DBT Test, DBT RUN
Integrate DBT with CI/CD (Jenkins/DBT Cloud/Airflow),Monitor DBT runs, setup alerts for failures,YML Testing / Production Deployment