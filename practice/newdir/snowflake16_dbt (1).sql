Staging tables vs Dimension tables
==================================

🔹 Staging Models (stg_customers.sql, stg_suppliers.sql)
Clean, standardize, and rename raw source data.
Keep them as one-to-one representations of source tables (but cleaned).
They are usually not directly used by BI tools.
Naming convention: stg_*.

Example:
-Standardize phone numbers, trim spaces, make booleans consistent, filter bad rows.
-So your stg_customers.sql and stg_suppliers.sql are staging models, not final dimension tables.

🔹 Dimension Models (dim_customers.sql, dim_suppliers.sql)
Contain business logic and semantic meaning.
Create surrogate keys if needed, apply SCD Type 1/2 logic, and structure them for analytics.
Dimensions are consumed by fact tables (joins).
Fact tables foreign keys will be linked to dimension tables
Naming convention: dim_*.

Example:
-A dim_customers might add segmentation labels (e.g., Gold, Silver, Bronze customers based on loyalty score).

Conclusion
----------
stg_customers is a cleaned version of raw data (ETL prep step).
dim_customers is a business-facing table designed for analytics.

In dbt, we usually keep both:
stg_customers → cleans data.
dim_customers → applies business logic and serves marts.

packages.yml --created at root level because here we are going to use dbt_utils, also after that do (dbt deps) to install the dependency
------------
packages:
  - package: dbt-labs/dbt_utils
    version: 1.1.1  # (latest stable, check dbt Hub for updates)

models/marts/dim_customers.sql
------------------------------
{{ config(materialized='table') }}

with base as (
    select * from {{ ref('stg_customers') }}
),
-- apply business logic
transformed as (
    select
        customer_id,
        initcap(customer_name) as customer_name,   -- format names properly
        customer_type,
        region,
        signup_date,
        is_active,
        loyalty_score,
        -- segmentation logic
        case
            when loyalty_score >= 80 then 'Platinum'
            when loyalty_score between 50 and 79 then 'Gold'
            when loyalty_score between 30 and 49 then 'Silver'
            else 'Bronze'
        end as loyalty_segment,

        email,
        phone_number,
        -- surrogate key (optional for BI)
        {{ dbt_utils.generate_surrogate_key(['customer_id', 'customer_type']) }} as customer_sk
    from base
)
select * from transformed


models/marts/dim_suppliers.sql
------------------------------
{{ config(materialized='table') }}

with base as (
    select * from {{ ref('stg_suppliers') }}
),
-- apply business logic
transformed as (
    select
        supplier_id,
        initcap(supplier_name) as supplier_name, -- clean name formatting
        supplier_type,
        country,
        rating,
        onboard_date,
        is_preferred,
        -- categorize supplier rating
        case
            when rating >= 4.5 then 'Excellent'
            when rating between 3.5 and 4.49 then 'Good'
            when rating between 2.5 and 3.49 then 'Average'
            else 'Poor'
        end as rating_category,
        -- surrogate key
        {{ dbt_utils.generate_surrogate_key(['supplier_id', 'onboard_date']) }} as supplier_sk
    from base
)
select * from transformed


🔄 Workflow Recap
stg_customers → cleans raw customers.
dim_customers → adds segmentation, surrogate key, cleaned naming.
stg_suppliers → cleans raw suppliers.
dim_suppliers → adds rating category, surrogate key, cleaned naming.
👉 These dimension tables (dim_customers, dim_suppliers) are now analytics-ready and can be joined with fact tables (like fct_sales or fct_orders) in marts.


Fact Table
==========
A fact table stores measures (numeric values) of business processes. It contains all transactions.
Examples: sales_amount, quantity_sold, order_value, discount.
They always have foreign keys linking to dimension tables (like customers, suppliers, products, dates).

models/marts/fact_orders.sql
----------------------------
{{ config(materialized = 'table') }}

with base as (
    select
        o.order_id,
        o.customer_id,
        o.order_date,
        o.order_status,
        o.payment_method,
        current_timestamp() as record_loaded_at
    from {{ ref('stg_orders') }} o
)
select * from base


models/marts/fact_sales.sql
---------------------------
{{ config(materialized='incremental', unique_key='sale_id', on_schema_change='sync') }}

with src as (
    select
        sale_id,
        order_id,
        item_id,
        /* If you also have customer_id / supplier_id on sales, include them here as FKs (no joins) */
        -- customer_id,
        -- supplier_id,
        /* Casts for numeric stability */
        cast(quantity   as number(12,2)) as quantity,
        cast(unit_price as number(12,2)) as unit_price,
        /* Measures */
        round(quantity * unit_price, 2)                   as gross_amount,
        cast(coalesce(tax_amount, 0) as number(12,2))     as tax_amount,
        round(quantity * unit_price, 2) + coalesce(tax_amount, 0) as net_amount,
        /* Descriptive fields */
        sale_date,
        channel,
        promo_code
        /* If your table has it, keep an updated timestamp to support tighter incr. filtering */
        -- , updated_timestamp
    from {{ source('rddp_raw', 'sales') }}
)
select * from src
{% if is_incremental() %}
  /*
    Optional incremental filter to avoid scanning the full source:
    - If you have updated_timestamp on sales, prefer that.
    - Otherwise, use a rolling window on sale_date (e.g., last 90 days).
  */
  where sale_date >= (
    select coalesce(dateadd(day, -90, max(sale_date)), '1900-01-01') from {{ this }}
  )
  -- If you have updated_timestamp, replace the above with:
  -- where updated_timestamp > (select coalesce(max(updated_timestamp), '1900-01-01') from {{ this }})
{% endif %}




Marts/Dimension/Facts/Dashboard Queries build using Dimension and Facts
=======================================================================

Raw tables---->Staging tables---->Mart (Dimension/Fact) tables----->Dashboard Marts---->Tableau/PowerBI Visualization

Marts/Dimension/Facts
---------------------
Dimension tables (dim_*) and Fact tables (fct_*) themselves are marts.
They live inside the Marts layer of dbt.
Example: dim_customer, dim_supplier, fct_sales.

Dashboard Reports
-----------------
When you query facts and dimensions together, you are just using the marts (building dashboards, reports, KPIs, etc.).
Example: joining fct_sales with dim_customer to see sales by region → this is analytics/BI usage, not a new mart.

So:
✅ Marts = curated dimension + fact tables stored in your warehouse.
❌ A query itself is not a mart — it’s just leveraging marts.

Think of it this way:
Staging models (stg_) → clean raw data.
Intermediate models (int_) → apply business logic, prepare joins.
Marts (dim_ & fct_) → the final “presentation layer” → fact and dimension tables.
Dashboards/queries → sit outside dbt in BI tools (Power BI, Tableau, Looker, etc.), and they consume marts.

⚡ Example in our case:
dim_customer, dim_supplier → Dimension marts.
fct_sales (with last 13 months, top/bottom products) → Fact marts.
Power BI → will join dim_customer + fct_sales to show “Sales by Customer Segment”.

models/marts/sales_performance.sql --Dashboard Reports. Now, Dashboards can visualize this data in their own format. They can do slicing/dicing on this data
----------------------------------
{{ config(materialized = 'table') }}

with last_13_months as (
    select
        date_trunc('month', sale_date) as month,
        sum(quantity * unit_price) as total_sales,
        sum(quantity) as total_quantity
    from {{ ref('fact_sales') }}
    where sale_date >= dateadd(month, -13, current_date)
    group by 1
),
high_low_months as (
    select
        month,
        total_sales,
        rank() over (order by total_sales desc) as sales_rank_desc,
        rank() over (order by total_sales asc) as sales_rank_asc
    from last_13_months
),
item_sales as (
    select
        s.item_id,
        sum(s.quantity) as total_quantity,
        sum(s.quantity * s.unit_price) as total_sales
    from {{ ref('fact_sales') }} s
    where s.sale_date >= dateadd(month, -13, current_date)
    group by s.item_id
),
high_low_items as (
    select
        item_id,
        total_quantity,
        total_sales,
        rank() over (order by total_quantity desc) as qty_rank_desc,
        rank() over (order by total_quantity asc) as qty_rank_asc
    from item_sales
)
-- Final result
select
    'monthly_sales' as metric_type,
    cast(month as date) as metric_date,
    total_sales,
    total_quantity,
    null as item_id
from last_13_months
union all
select
    'highest_sales_month' as metric_type,
    cast(month as date) as metric_date,
    total_sales,
    null as total_quantity,
    null as item_id
from high_low_months
where sales_rank_desc = 1
union all
select
    'lowest_sales_month' as metric_type,
    cast(month as date) as metric_date,
    total_sales,
    null as total_quantity,
    null as item_id
from high_low_months
where sales_rank_asc = 1
union all
select
    'highest_ordered_item' as metric_type,
    null as metric_date,
    total_sales,
    total_quantity,
    item_id
from high_low_items
where qty_rank_desc = 1
union all
select
    'lowest_ordered_item' as metric_type,
    null as metric_date,
    total_sales,
    total_quantity,
    item_id
from high_low_items
where qty_rank_asc = 1

models/marts/pending_orders.sql --Dashboard Reports. Now, Dashboards can visualize this data in their own format. They can do slicing/dicing on this data
-------------------------------
{{ config(materialized = 'table') }}

select
    fo.order_id,
    fo.customer_id,
    fo.order_date,
    case
        when fo.order_status = 'Pending' then 'Pending (Status)'
        when s.order_id is null then 'Pending (No Sale)'
    end as pending_reason
from {{ ref('fact_orders') }} fo
left join {{ ref('fact_sales') }} s
    on fo.order_id = s.order_id
where fo.order_status = 'Pending'
   or s.order_id is null


Star Schema
===========

A star schema is a type of data warehouse schema where a central fact table is connected to multiple dimension tables in a way that looks like a star.
The fact table sits at the center and stores quantitative data (measures/metrics) such as sales amount, quantity, revenue, etc.
The dimension tables surround it and store descriptive attributes (context) like customer details, product information, supplier, time/date, or region.

📌 The structure looks like a star:
Fact = center
Dimensions = points of the star

Key Characteristics of Star Schema
----------------------------------
1) Central Fact Table
	-Contains numeric, measurable data (e.g., sales_amount, quantity_sold).
	-Stores foreign keys referencing dimensions.

2) Dimension Tables
	-Contain descriptive attributes (e.g., product_name, customer_region).
	-Usually denormalized (fewer joins, faster queries).

3) Simple Queries
	-Easy to understand and optimized for OLAP (analytical queries).


                     +------------------+
                     |  dim_customer    |
                     |------------------|
                     | customer_id (PK) |
                     | customer_name    |
                     | customer_type    |
                     | region           |
                     | loyalty_score    |
                     +------------------+

                     +------------------+
                     |  dim_supplier    |
                     |------------------|
                     | supplier_id (PK) |
                     | supplier_name    |
                     | supplier_type    |
                     | country          |
                     | rating           |
                     +------------------+

                     +------------------+
                     |  dim_product     |
                     |------------------|
                     | product_id (PK)  |
                     | product_name     |
                     | category         |
                     | price            |
                     +------------------+

+------------------+       +------------------+       +------------------+
|  dim_date        |       |   fct_sales      |       |  dim_region      |
|------------------|       |------------------|       |------------------|
| date_id (PK)     |<----->| order_date (FK)  |       | region_id (PK)   |
| full_date        |       | order_id (PK)    |       | region_name      |
| month            |       | customer_id (FK) |       | country          |
| year             |       | supplier_id (FK) |       +------------------+
+------------------+       | product_id (FK)  |
                           | quantity_sold    |
                           | sales_amount     |
                           | updated_timestamp|
                           +------------------+

fct_sales is the fact table (center of the star).
dim_customer, dim_supplier, dim_product, dim_date, and dim_region are dimension tables.

Relationships:
fct_sales.customer_id → dim_customer.customer_id
fct_sales.supplier_id → dim_supplier.supplier_id
fct_sales.product_id  → dim_product.product_id
fct_sales.order_date  → dim_date.date_id
dim_customer.region   → dim_region.region_id (optional if region is split out).


Example
If we build a Sales Star Schema:
Fact Table: fct_sales → stores order_id, date_id, product_id, customer_id, quantity, sales_amount.
Dimension Tables:
dim_customer → customer attributes
dim_product  → product attributes
dim_date     → calendar attributes
dim_supplier → supplier details

So if you ask: “What were the total sales of Product A in the last 13 months by region?”,
The numbers come from fact table (sales_amount)
The descriptive breakdown (product, time, region) comes from dimension tables.

👉 In short:
Star schema = Fact table (metrics) + Dimension tables (context) arranged in a star-like structure.

Our Example
-----------
--Raw
select count(1) from db060725.sch060725.customers;
select count(1) from db060725.sch060725.suppliers;
select count(1) from db060725.sch060725.orders;
select count(1) from db060725.sch060725.sales;
csv files
--Staging
select * from dbt_schema.stg_orders;
select * from dbt_schema.stg_suppliers;
select * from dbt_schema.stg_customers;
--Mart (Dimension/Fact)
select * from dbt_schema.dim_customers;
select * from dbt_schema.dim_suppliers;
select * from dbt_schema.fact_sales;
select * from dbt_schema.fact_orders;
--Mart (Dashboard Reports)
select * from dbt_schema.sales_performance;
select * from dbt_schema.pending_orders;

Who should build complex business queries like last 13 months sales performance which involves big volume of data processing. Is it Snowflake or Tableau ?
==========================================================================================================================================================
🔹 Where should the heavy lifting happen?

1. Snowflake (dbt + SQL)
Strengths:
Designed for massive data volumes (billions of rows).
Query optimization, clustering, partition pruning, scaling warehouses.
Can pre-aggregate, filter, and transform data before BI tools see it.
Better performance and cost control: you run a query once, materialize it into a table/view, and BI tools just read it.
Best use: Complex joins, aggregations, SCD handling, fact-dimension modeling, last-13-month calculations, top-N analysis.

2. Tableau

Strengths:
Excellent visualization & interactivity.
Can issue SQL directly to Snowflake via live connection.
Works well with smaller datasets after initial aggregation in Snowflake.

Limitations:
Not a data warehouse. It does not optimize queries like Snowflake does.
If Tableau users directly query raw fact tables (e.g., billions of sales rows), performance will degrade.
You’ll likely see slow dashboards and higher Snowflake costs because each Tableau interaction = a new SQL query.

🔹 Recommended Best Practice

👉 Always push the heavy lifting to Snowflake via dbt.
Build marts in dbt (e.g., sales_performance, pending_orders) so Tableau only consumes query-ready tables/views.
Tableau then acts as a thin visualization layer, not a query engine.
This ensures:
Performance: Queries are optimized in Snowflake.
Consistency: All teams see the same business logic (defined in dbt, not duplicated in Tableau workbooks).
Cost efficiency: Tableau queries hit pre-aggregated marts, not raw data.

🔹 Real-world approach
Good: Tableau builds queries directly on fact/dim tables.
Better: dbt creates marts → Tableau connects to marts.
Best: dbt creates marts + summary tables (pre-aggregated KPIs) → Tableau reads those → dashboards are lightning fast.

✅ Conclusion:
Tableau can query Snowflake directly, but it should not handle complex/large queries. Let Snowflake (via dbt) do the heavy lifting. Tableau should focus only on visualization and simple filtering.