Interview Preperation Foundation
================================
12.1) What is DBT
     -Tool to transform raw data inside your data warehouse
	 -Instead of writing messy SQL scripts here and there, dbt makes you organize them into models (SQL files) and runs them in the right order
	 -Dbt compiles these SQL files into executable SQL and runs them on your warehouse
	 -The results are saved as tables or views in the warehouse
	 -DBT Query Format -> select * from {{ source('rddp', 'orders') }}	
     -We code in YML format in DBT
		-profiles.yml  (Applies only to dbt Core)

		-package.yml
			packages:
			  - package: dbt-labs/dbt_utils
				version: 1.1.1  # (latest stable, check dbt Hub for updates)		

		-schema.yml

		-source.yml
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


		-seeds.yml
			version: 2
			seeds:
			  - name: business_units
				description: "Business units of RDDP company"
				columns:
				  - name: bu_id
					tests: [unique, not_null]
				  - name: bu_name
					tests: [unique, not_null]

			  - name: item_category
				description: "Categories under each business unit"
				columns:
				  - name: category_id
					tests: [unique, not_null]
				  - name: bu_id
					tests:
					  - relationships:
						  to: ref('business_units')
						  field: bu_id
						  
12.2) Is YML file required ?
		-Mandatory 	  : Sources,Snapshot
		-Optional  	  : Models, Seeds, Incremental Models
		-Not Required : Macros, Materializations
		
12.3) Typical DBT flow in order

		Sources + Seeds → Models (Staging) / Models (Incremental) / Snapshots (if history needed) → Marts
		source.yml + business_units.csv -> stg_customer.sql (Table)            -> dim_customers.sql
					 item_cateogory.csv	   stg_suppliers.sql (Table)  			  dim_suppliers.sql
										   stg_orders.sql  (Table Incr model)	  fact_orders.sql
										   ----------------------				  fact_sales.sql
										   customers_snapshot.sql				  pending_orders.sql
																				  sales_performance.sql
										   

		Sources 		→ Pointer to a Raw table (warehouse/external) systems.  --(Tables from snowflake). It might have landed in snowflake with snowpipe.
		Seeds 			→ Static lookup/master data (CSV files in DBT). Dbt can then load this CSV into our warehouse as a table. 
		Staging 		→ Initial cleaning and standardizing of data on sources + seeds.  --date format standardize, removing duplicates, rounding numerics
		------------------------------------------------------------------------------------------------
		Models 			→ Transform staging data into business logic. Default is View but can be configured as Table.
                      		 {{ config(materialized='table') }}
		Incremental Models → built once and then updated with only new or changed records. No Full Load required, Only Increamental Loads. 
		                     {{ config(materialized='incremental', unique_key='order_id', incremental_strategy='merge' ) }}
		Snapshots 		→ Capture history of slowly changing data (track changes over time). Ex. we can view past data along with present data.
							 {% snapshot customers_snapshot %}
							 {% endsnapshot %}
		------------------------------------------------------------------------------------------------
		Marts 			→ Final business-facing layer (facts & dimensions).
		------------------------------------------------------------------------------------------------
		
		Macros 			→ Utility functions used across all steps. [Reusable SQL codes/Materialization macros/Hooks/Custom logic]
		Materializations → Define how each model is stored (table, view, incremental, etc.).
						   Materialization tells dbt how to turn that SELECT query into a physical object in Snowflake

12.4) Flow of Data 
      
		Raw Layer->Staging Layer->Transformation Layer->Consumption Layer
		
		Raw Layer 		: Landing zone. Raw data lands here from snowpipe etc. This is not touched by DBT.
		Staging Layer 	: Clean & standardize raw data
		Transformation Layer  : Apply business rules & joins across multiple staging models
		Marts (Consump Layer) : Build analytics-ready tables for BI & reporting (Power BI, Tableau, Looker, etc.)
		
		RAW (no dbt) 
		   ↓
		STAGING (dbt: cleaning, type casting, standardization)
		   ↓
		INTERMEDIATE (dbt: joins, derivations, enrichment)
		   ↓
		MARTS / CONSUMPTION (dbt: facts, dimensions, aggregations → BI ready)
		
		
13.1) What is Jinja?
		Jinja is a templating language written in Python.
		It’s used in dbt to dynamically generate SQL code.
		Instead of writing static SQL, Jinja lets you inject variables, apply logic (if/else, loops), and reuse code.
	 
14.1) Snapshot strategies
		-Timestamp strategy 	→ Uses a column like updated_at.
		-Check strategy 		→ Compares all (or selected) columns for changes.
		
		When you run dbt snapshot:
		dbt compares source data with the existing snapshot table.
		If changes are found → it inserts a new version of the row with validity dates.

		dbt will compare current rows from the raw.customers table against what’s already stored in the snapshot.
		If any of the columns in check_cols change (home address, email, mobile no):
		dbt will close out the old record (dbt_valid_to gets filled).
		Insert a new version with updated values and a fresh dbt_valid_from.
		
14.2) Difference between dbt build and dbt run
        dbt run   : Builds models (SQL files under models/) into your target warehouse
		dbt build : Runs models + seeds + snapshots + tests in a single workflow.
		
		Order of execution
		------------------
		Seeds (dbt seed)
		Models (dbt run)
		Snapshots (dbt snapshot)
		Tests (dbt test)