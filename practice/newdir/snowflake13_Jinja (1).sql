Jinja
=====
🔹 What is Jinja?
Jinja is a templating language written in Python.
It’s used in dbt to dynamically generate SQL code.
Instead of writing static SQL, Jinja lets you inject variables, apply logic (if/else, loops), and reuse code.

👉 You can think of Jinja as a “SQL code generator”.
When you run dbt, Jinja runs first → it fills in templates → produces pure SQL → sends it to Snowflake (or your warehouse).


🔹 What is Jinja?
Jinja is a templating language written in Python.
It’s used in dbt to dynamically generate SQL code.
Instead of writing static SQL, Jinja lets you inject variables, apply logic (if/else, loops), and reuse code.

👉 You can think of Jinja as a “SQL code generator”.
When you run dbt, Jinja runs first → it fills in templates → produces pure SQL → sends it to Snowflake (or your warehouse).

🔹 Examples of Jinja in dbt
1. Variable substitution
select * from {{ ref('stg_orders') }}

Here, {{ ref('stg_orders') }} is Jinja.
It tells dbt: “resolve this to the actual schema.table name of stg_orders”.

2. If/Else logic
select * from orders
{% if target.name == 'prod' %}
where order_date >= current_date - interval '90 days'
{% else %}
where order_date >= current_date - interval '7 days'
{% endif %}

👉 Different filters depending on environment.

3. Loops
{% for col in ['customer_id', 'order_id', 'product_id'] %}
    {{ col }},
{% endfor %}


👉 Expands into:
customer_id,
order_id,
product_id,

4. Macro usage
select {{ convert_to_date("order_date") }} as order_date
from {{ source('raw', 'orders') }}

🔹 How it works in dbt
You write SQL + Jinja.
dbt compiles → runs Jinja → generates raw SQL.
dbt executes that SQL on Snowflake (or BigQuery, Redshift, etc.).

✅ In short:
Jinja is the secret sauce in dbt that makes SQL dynamic, reusable, and environment-aware, instead of just static code.


Basic Programming Structures
============================
🔹 1. Variables
Used to inject dynamic values.
dbt exposes built-in variables (like target, this, var, etc.).

-- Example: using a variable defined in dbt_project.yml or CLI
select *  from {{ source('raw', var('orders_table')) }}

🔹 2. Expressions ({{ ... }})
{{ ... }} means evaluate this in Jinja and insert the result into SQL.

Most common in dbt (ref, source, var).
select * from {{ ref('stg_orders') }}

🔹 3. Control Structures ({% ... %})
(a) If / Else
{% if target.name == 'prod' %}
  where order_date >= current_date - interval '90 days'
{% else %}
  where order_date >= current_date - interval '7 days'
{% endif %}

👉 Great for environment-specific logic.

(b) For Loops
select
    {% for col in ['customer_id', 'order_id', 'product_id'] %}
        {{ col }}{% if not loop.last %},{% endif %}
    {% endfor %}
from raw.orders

👉 Expands into:
select
    customer_id,
    order_id,
    product_id
from raw.orders

🔹 4. Macros
Reusable logic wrapped in Jinja functions.

-- macros/convert_to_date.sql
{% macro convert_to_date(col_name) %}
    try_cast({{ col_name }} as date)
{% endmacro %}


Usage:
select {{ convert_to_date("order_date") }} as order_date
from {{ ref('stg_orders') }}

🔹 5. Filters (like in Python)
Modify variables inline.

-- uppercase filter
select '{{ "snowflake" | upper }}' as db_name


Output:
SNOWFLAKE

Common filters in dbt/Jinja:
upper, lower
default (set fallback values)
length (count items in a list)

🔹 6. Set Variables
You can define temporary variables inside SQL models.

{% set columns = ['customer_id', 'order_id', 'order_date'] %}
select
    {% for col in columns %}
        {{ col }}{% if not loop.last %},{% endif %}
    {% endfor %}
from {{ ref('stg_orders') }}

🔹 7. Comments
Jinja also supports inline comments.
{# This is a Jinja comment, wont appear in compiled SQL #}

🔹 Summary Table
Jinja Structure		Syntax										Use in dbt
Expression			{{ ... }}									Inject values, refs, vars
If/Else				{% if ... %} ... {% endif %}				Environment conditions
For Loop			{% for ... %} ... {% endfor %}				Dynamic column/table generation
Macro				{% macro name(args) %} ... {% endmacro %}	Reusable SQL logic
Filters				`{{ 										var	upper }}`			
Set					{% set x = ... %}							Store list/vars inside model
Comment				{# ... #}									Hide notes from compiled SQL

✅ These 7 structures cover 95% of Jinja you’ll use in dbt.
The rest are advanced (nested macros, custom filters, etc.), but not needed early on.

Advanced Jinja Structures in dbt
================================
1. Nested Control Structures
You can nest if inside for, or for inside if.

{% for col in ['id','amount','status'] %}
    {% if col == 'amount' %}
        round({{ col }}, 2) as {{ col }}
    {% else %}
        {{ col }}
    {% endif %}{% if not loop.last %},{% endif %}
{% endfor %}

👉 Dynamically applies rounding only to numeric fields.


2. Loop Helpers (loop object)
Inside a for loop, Jinja exposes a loop object:
loop.index → 1-based index
loop.index0 → 0-based index
loop.first → true if first iteration
loop.last → true if last iteration

{% for col in ['id','amount','status'] %}
    {{ col }}{% if not loop.last %},{% endif %}
{% endfor %}

👉 Avoids trailing commas.


3. Call Blocks (Higher-Order Macros)
You can pass a block of code into a macro.

-- Macro definition
{% macro wrap_in_case(col) %}
    case 
        {% call(col_name) col() %}
        {% endcall %}
    end
{% endmacro %}


Usage:
select
    {{ wrap_in_case() }}
        when {{ col_name }} is null then 'UNKNOWN'
        else {{ col_name }}
    {% endwrap_in_case %}
from my_table

👉 Allows flexible, reusable condition wrapping.


4. Custom Filters
You can define your own filters using macros.

-- macros/filters.sql
{% macro add_prefix(val, prefix='col_') %}
    {{ '"' ~ prefix ~ val ~ '"' }}
{% endmacro %}


Usage:
select {{ add_prefix("customer_id") }}


5. Dictionary / Key-Value Iteration
Jinja supports dictionaries (dicts in Python terms).

{% set column_map = {'id':'int', 'amount':'decimal(10,2)', 'status':'varchar'} %}

{% for col, dtype in column_map.items() %}
    cast({{ col }} as {{ dtype }}) as {{ col }}{% if not loop.last %},{% endif %}
{% endfor %}

👉 Dynamically applies correct datatypes.


6. Include & Import
Break large macros into multiple files.

{% import 'macros/helpers.sql' as helpers %}

select {{ helpers.safe_cast('amount', 'number') }}

👉 Helps with large dbt projects (modularization).


7. Do Statement (Non-Rendering Code)
Run Python/Jinja logic without outputting into SQL.

{% set my_list = [] %}
{% for i in range(5) %}
    {% do my_list.append("col_" ~ i) %}
{% endfor %}

-- Debug
{{ my_list }}

👉 Useful for building lists/dictionaries programmatically.


8. Recursive Loops
You can loop recursively over nested structures.

{% set nested = {'a': {'b': {'c': 'd'}}} %}

{% for key, value in nested.items() recursive %}
    {{ key }}
    {% if value is mapping %}
        {{ loop(value.items()) }}
    {% else %}
        {{ value }}
    {% endif %}
{% endfor %}

👉 Rare in dbt, but useful for nested JSON field handling.


9. Whitespace Control
You can trim spaces around Jinja tags:

select
    {%- for col in ['id','name','amount'] -%}
        {{ col }}
        {%- if not loop.last %},{% endif %}
    {%- endfor -%}
from my_table

👉 Generates clean SQL without unwanted line breaks/whitespace.


10. Jinja Tests (Boolean checks)
Jinja provides tests like is, in, defined, none.

{% if my_var is defined %}
   select '{{ my_var }}' as value
{% endif %}

👉 Helps avoid errors if a variable is missing.


🔹 Summary Table
Advanced Jinja Feature		Use Case in dbt
Nested If/For				Dynamic SQL with conditional formatting
Loop helpers				Avoid trailing commas, index tracking
Call blocks					Pass reusable SQL snippets into macros
Custom filters				Create your own transformation filters
Dict iteration				Map columns → datatypes dynamically
Include/Import				Modularize macros across files
Do statement				Modify variables/lists without rendering
Recursive loops				Handle nested JSON-like structures
Whitespace control			Generate neat, compact SQL
Jinja tests					Defensive coding with variable checks


Jinja Cheat Sheet
=================
🔹 1. Variables & Expressions
{{ variable }}                  -- insert a variable
{{ "hello"|upper }}             -- apply filters
{{ 10 + 5 }}                    -- inline expressions


🔹 2. Control Structures
If / Else
{% if status == 'active' %}
  where status = 'active'
{% elif status == 'pending' %}
  where status = 'pending'
{% else %}
  where status is null
{% endif %}

For Loops
{% for col in ['id', 'name', 'amount'] %}
  {{ col }}{% if not loop.last %}, {% endif %}
{% endfor %}

👉 loop helpers:
loop.index → 1-based index
loop.index0 → 0-based index
loop.first, loop.last → boolean flags


🔹 3. Whitespace Control
{%- for col in cols -%}   -- trims whitespace
{{ col }}
{%- endfor -%}


🔹 4. Macros (Reusable Functions)
Defining a Macro
{% macro clean_text(col) %}
    trim(lower({{ col }}))
{% endmacro %}

Calling a Macro
select {{ clean_text('customer_name') }} from {{ ref('raw_customers') }}

🔹 5. ref and source
from {{ ref('stg_orders') }}          -- points to another model
from {{ source('raw', 'orders') }}    -- points to a source table

🔹 6. Do Statement
{% set cols = [] %}
{% for col in ['a','b','c'] %}
  {% do cols.append(col ~ '_clean') %}
{% endfor %}
-- cols = ['a_clean', 'b_clean', 'c_clean']


🔹 7. Call Blocks
{% macro with_condition(col) %}
    case when {{ caller() }} is not null then {{ col }} else 'UNKNOWN' end
{% endmacro %}

{% call with_condition('status') %}
    {{ col }}
{% endcall %}


🔹 8. Filters
{{ "Prajeesh" | upper }}      -- "PRAJEESH"
{{ "2025-08-18" | replace("-", "/") }}
{{ [1,2,3] | join(",") }}     -- "1,2,3"

Common Filters: upper, lower, title, trim, replace, default, join, length.


🔹 9. Jinja Tests
{% if value is none %}        -- check for null
{% if myvar is defined %}     -- check if variable exists
{% if 5 is divisibleby 2 %}   -- custom test
{% if 'a' in ['a','b','c'] %} -- membership

🔹 10. Advanced Structures
Dictionaries
{% set col_map = {'id':'int', 'amount':'decimal'} %}
{% for col, dtype in col_map.items() %}
  try_cast({{ col }} as {{ dtype }}) as {{ col }},
{% endfor %}

Nested Loops
{% for schema in schemas %}
  {% for table in schema.tables %}
    {{ schema.name }}.{{ table }}
  {% endfor %}
{% endfor %}


🔹 11. Environment-aware Logic
{% if target.name == 'prod' %}
  where order_date >= current_date - interval '90 days'
{% else %}
  where order_date >= current_date - interval '7 days'
{% endif %}


🔹 12. Combination with SQL
👉 Jinja compiles first, then dbt runs the SQL.

select
    {% for col in ['id','amount'] %}
        coalesce({{ col }}, 0) as {{ col }}
        {% if not loop.last %},{% endif %}
    {% endfor %}
from {{ ref('stg_orders') }}


Compiles to:
select
    coalesce(id, 0) as id,
    coalesce(amount, 0) as amount
from my_project.staging.stg_orders

