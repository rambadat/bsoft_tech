Retail Project
==============
We are a company RDDP dealing in below business (Business Units : Electronics/Food Products/Clothing/Furniture)
Item Categories (sample)
Electronics → LED TV, UHD TV, QLED TV, Refrigerator, Air Cooler, Laptops
Food Products → Masala, Spices
Clothing → Jeans, Formal Shirts, Casual Shirts, Formal Pants, Casual Pants
Furniture → Bed Cot, Sofa, Dining Table, Mattress


Seeds + Sources → Models (Staging Full Data Load) → Models (Incremental Data Load) → Snapshots (if history needed) → Marts


Setup Snowflake objects (Role/Database/Schema/Warehouse/Grants/Tables)
----------------------------------------------------------------------
USE ROLE developer060725;
USE WAREHOUSE wh060725;
USE DATABASE db060725;
USE SCHEMA sch060725;  --Normal schema to work
CREATE SCHEMA db060725.dbt_schema;  --This schema will create objects through dbt

GRANT USAGE ON DATABASE db060725 TO ROLE developer060725;
GRANT USAGE ON SCHEMA db060725.dbt_schema TO ROLE developer060725;
GRANT CREATE TABLE, CREATE VIEW, CREATE STAGE, CREATE FILE FORMAT ON SCHEMA db060725.dbt_schema TO ROLE developer060725;
GRANT USAGE, OPERATE ON WAREHOUSE wh060725 TO ROLE developer060725;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA db060725.dbt_schema TO ROLE developer060725;
GRANT ALL PRIVILEGES ON FUTURE VIEWS IN SCHEMA db060725.dbt_schema TO ROLE developer060725;

Sources + Seeds
---------------
--Below 3 are our seeds and dbt is creating tables in dbt_schema based on seed file
--so below 3 tables not required in schema sch060725
--business_units.csv
bu_id,bu_name,description
BU01,Electronics,Electronics items such as TVs, Refrigerators, Laptops
BU02,Food Products,Various food brands like spices and masalas
BU03,Clothing,Apparel for men and women
BU04,Furniture,Furniture for home and office

--item_category.csv
category_id,bu_id,category_name,description
C01,BU01,LED TV,Light Emitting Diode Televisions
C02,BU01,UHD TV,Ultra HD Televisions
C03,BU01,QLED TV,Quantum Dot Televisions
C04,BU01,Refrigerator,Home Refrigerators
C05,BU01,Air Cooler,Air Cooling Devices

--item_master.csv
item_id,category_id,item_name,brand,unit_price,is_active
I001,C01,Sony LED 42-inch,Sony,45000,TRUE
I002,C01,Samsung LED 50-inch,Samsung,55000,TRUE
I003,C02,Samsung UHD 55-inch,Samsung,65000,TRUE
I004,C03,Sony QLED 65-inch,Sony,120000,TRUE
I005,C04,LG Double Door Refrigerator,LG,30000,TRUE
I006,C05,Symphony Air Cooler,Symphony,12000,TRUE


CREATE TABLE db060725.sch060725.customers (
    customer_id STRING PRIMARY KEY,
    customer_name STRING,
    customer_type STRING,  -- e.g., 'Retail', 'Wholesale'
    region STRING,
    signup_date DATE,
    is_active BOOLEAN,
    loyalty_score NUMBER(5,2), -- segmentation
    email STRING,
    phone_number STRING,
	updated_timestamp TIMESTAMP_TZ
);

CREATE TABLE db060725.sch060725.suppliers (
    supplier_id STRING PRIMARY KEY,
    supplier_name STRING,
    supplier_type STRING,   -- e.g., 'Manufacturer', 'Distributor'
    country STRING,
    rating NUMBER(3,1),
    onboard_date DATE,
    is_preferred BOOLEAN
);

CREATE TABLE db060725.sch060725.orders (
    order_id STRING PRIMARY KEY,
    customer_id STRING REFERENCES customers(customer_id),
    order_date DATE,
    order_status STRING,  -- 'Pending', 'Shipped', 'Cancelled'
    payment_method STRING,
    total_amount NUMBER(10,2),
    discount_applied BOOLEAN,
    shipping_region STRING,
    supplier_id STRING REFERENCES suppliers(supplier_id),
	updated_timestamp TIMESTAMP_TZ
);

CREATE TABLE db060725.sch060725.sales (
    sale_id STRING PRIMARY KEY,
    order_id STRING REFERENCES orders(order_id),
    item_id STRING,       -- REFERENCES item_master(item_id),
    quantity NUMBER,
    unit_price NUMBER(10,2),
    sale_date DATE,
    channel STRING,      -- 'Online', 'In-store'
    promo_code STRING,
    tax_amount NUMBER(10,2)
);

models/staging/source.yml
-------------------------
version: 2

sources:
  - name: rddp_raw
    database: db060725
    schema: sch060725
    tables:
      - name: customers
      - name: suppliers
      - name: orders
      - name: sales

models/staging/stg_customer.sql (Full Load)
-------------------------------------------
{{ config(materialized='table') }}

with source as (
    select * 
    from {{ source('rddp_raw', 'customers') }}
),
renamed as (
    select
        customer_id,
        trim(upper(customer_name))       as customer_name,   -- clean spaces + upper case
        lower(customer_type)             as customer_type,   -- normalize
        initcap(region)                  as region,          -- proper case for region
        signup_date,
        is_active,
        coalesce(loyalty_score, 0)       as loyalty_score,   -- replace nulls with 0
        lower(email)                     as email,           -- lowercase email
        regexp_replace(phone_number, '[^0-9]', '') as phone_number -- keep only digits
    from source
    where is_active = true               -- filter only active customers
)
select * from renamed

models/staging/stg_supplier.sql (Full Load)
-------------------------------------------
with source as (
    select * 
    from {{ source('rddp_raw', 'suppliers') }}
),
deduplicated as (
    select 
        supplier_id,
        trim(initcap(supplier_name)) as supplier_name,   -- clean names
        initcap(supplier_type) as supplier_type,         -- normalize type
        upper(country) as country,                       -- standardize country
        coalesce(rating, 0.0) as rating,                 -- handle null ratings
        onboard_date,
        {{ date_trunc_month('onboard_date') }} onboard_month,  -- usage of macro
        is_preferred,
        row_number() over (
            partition by supplier_id 
            order by onboard_date desc
        ) as row_num
    from source
),
final as (
    select
        supplier_id,
        supplier_name,
        supplier_type,
        country,
        rating,
        onboard_date,
        onboard_month,
        is_preferred
    from deduplicated
    where row_num = 1
)
select * from final

	  
models/staging/stg_orders.sql (Incremental Load)
------------------------------------------------
{{ config(materialized='incremental', unique_key='order_id', incremental_strategy='merge' ) }}

with source as (

    select * 
    from {{ source('rddp_raw', 'orders') }}

),
final AS (
    SELECT
        order_id,
        customer_id,
        order_date,
        UPPER(order_status) AS order_status,              -- normalize case
        INITCAP(payment_method) AS payment_method,        -- proper case
        COALESCE(total_amount, 0) AS total_amount,        -- handle null
        discount_applied,
        INITCAP(shipping_region) AS shipping_region,      -- normalize region
        supplier_id,
        updated_timestamp
    FROM source
    {% if is_incremental() %}
        WHERE updated_timestamp > (SELECT MAX(updated_timestamp) FROM {{ this }})
    {% endif %}
)
SELECT * FROM final;

snapshots/customers_snapshots.sql (Historical data)
---------------------------------------------------
{% snapshot customers_snapshot %}

--check strategy applied for email and phone_number
{{
    config(
        target_schema='dbt_schema',    
        unique_key='customer_id',       
        strategy='check',               
        check_cols=['email', 'phone_number'] 
    )
}}

select
    customer_id,
    email,
    phone_number,
    updated_timestamp
from {{ source('rddp_raw', 'customers') }}

{% endsnapshot %}

macros/date_trunc_month.sql
---------------------------
{% macro date_trunc_month(column_name) %}
    DATE_TRUNC('MONTH', {{ column_name }})
{% endmacro %}

