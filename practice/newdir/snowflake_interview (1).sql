Interview Preperation Foundation
================================
0.1) What is the contribution to the project
     -We are into ELT activities 
	 -Extraction & Loading Data into Snowflake (Bulk Load/snowpipe/snowpipe Streaming/Data Sharing & Stream (CDC operation within snowflake))
	 -CDC Tool Oracle Golden Gate (CDC captures redo logs)
	 -Applying Transfromations using DBT (Staging/Models/Marts), snowflake scripting, snowpark using python
1.1) How do we check which database, schema and role we are into 
1.2) Where we can get metadata of our created objects in snowflake
2.1) What is Storage integration
     -is a secure object 
	 -stores authentication credentials & configuration required to access external cloud storage (AWS S3/Azure Blob/GCP).
     -It acts as a bridge between Snowflake and external storage without exposing access keys/passwords directly to users
2.2) Parameters considered while creating Storage integration
	 type of stage|storage_provider|AZURE_TENANT_ID|ENABLED|STORAGE_ALLOWED_LOCATIONS
2.3) Steps to establish connection between snowflake and azure
     -create storage integration [type of stage|storage_provider|AZURE_TENANT_ID|ENABLED|STORAGE_ALLOWED_LOCATIONS]
	 -create file format [type|field delimiter|skip header|nullif|compression]
	 -create stage [Azure container url|storage integration|file format] [AccountAdmin role]
	 -Azure : Grant access to snowflake
	 -copy into table from @azure_stage1/ OR @azure_stage1/Covid_01012021.csv [file_format| on_error]  --This is Bulk Loading Multiple files/Single files
2.4) When to go for Azure SAS Token and When to go for Storage Integration
2.4) Can we load multiple files into single staging table from Azure? Yes
2.5) In one staging (azure_stage1), can we load data into multiple tables with different structures. The csv files are bank_transactions_20250726.csv,   
     bank_transactions_20250727.csv have same structure and customer_joined_20250726.csv, customer_joined_20250727.csv is having different structure
	 Yes, We can but with the help of PATTERN
	 FILE_FORMAT = (FORMAT_NAME = 'bank_txn_format')
     PATTERN = '.*bank_transactions_.*\.csv'
	 FILE_FORMAT = (FORMAT_NAME = 'customer_data_format')
	 PATTERN = '.*customer_joined_.*\.csv'
2.6) For different file formats like csv, json, parqut,  is it possible to use same stage ?
     Yes, ✅ you can use the same stage (like @azure_stage1) to store and load different file formats (CSV, JSON, PARQUET, etc.) in Snowflake.
2.7) Can i reload the file again even if it was already loaded into snowflake.
     Generally, snowflake will not reload the same file data. But if we want to do so, then FORCE=TRUE should be specified.
     COPY INTO bank_transactions
 	 FROM @azure_stage1/
	 FILE_FORMAT = (FORMAT_NAME = 'csv_format')
	 PATTERN = '.*bank_transactions_.*\.csv'
	 FORCE = TRUE
	 ON_ERROR = 'CONTINUE';	 
2.8) How to identify bad records while loading data into table. Pl capture bad records in error table
     CREATE OR REPLACE TABLE bank_txn_load_errors (
	  row_number INT,
	  error_column NUMBER,
	  error_message STRING,
	  raw_record STRING
	);

	INSERT INTO bank_txn_load_errors
	SELECT * FROM 
	  TABLE(
		VALIDATE(
		  TABLE_NAME => 'bank_transactions',
		  LOCATION => '@azure_stage1/bank_transactions_20250726.csv',
		  FILE_FORMAT => 'csv_format',
		  VALIDATION_MODE => 'RETURN_ERRORS'
		)
	  ); 
2.9)Create stored procedure to perform copy into operations and accordingly create a task and schedule it
	CREATE OR REPLACE PROCEDURE sp_load_bank_transactions()
	RETURNS STRING
	LANGUAGE SQL
	AS
	$$
	BEGIN
	  COPY INTO bank_transactions
	  FROM @azure_stage1
	  FILE_FORMAT = (FORMAT_NAME = 'csv_format')
	  PATTERN = '.*bank_transactions_.*\.csv'
	  ON_ERROR = 'CONTINUE';
	  RETURN 'COPY complete';
	END;
	$$;
	
	✅ PATTERN ensures only matching files are loaded.
	✅ ON_ERROR = 'CONTINUE' skips bad records but logs them.

	🔹 Create Task to Run Daily at 2 AM
	CREATE OR REPLACE TASK task_daily_load_bank_txns
	  WAREHOUSE = my_wh
	  SCHEDULE = 'USING CRON 0 2 * * * Asia/Kolkata'
	AS
	  CALL sp_load_bank_transactions();

	🔹 Start the Task
	ALTER TASK task_daily_load_bank_txns RESUME;
	
2.10)Steps to Schedule Task which calls Procedure to load data into snowflake table from stage (Bulk Load)
     -Create Stage (Storage Integration,File Fromat)
	 -Create Procedure
	 -Create Task and then Activate Task  (Similar to Autosys Job scheduler which trigger at specific Days and time)

2.11)Can we use the same stage for different file formats (Csv/Json/Txt/Parquet)
     Yes, you can use the same stage (internal or external), because a stage is just a pointer to a storage location (Snowflake-managed or S3/Azure/GCS).
     A stage itself does not lock to a single file format.
	 However, in practice, we often separate by folders or patterns to avoid mixing file formats accidentally.

You decide the file format at the time of COPY INTO (or by assigning a default file format when creating the stage).
	
3.1) How Snowpipe with AUTO_INGEST is different from Bulk Load
     -Bulk Load only required for fixed scheduler
	 -Snowpipe with Auto_Ingest acts instantly on file upload in Azure Blob
  	  CREATE OR REPLACE PIPE pipe_bank_transactions
	  AUTO_INGEST = TRUE
	  AS
	  COPY INTO bank_transactions_pipe
	  FROM @azure_stage_pipe
	  FILE_FORMAT = (FORMAT_NAME = 'csv_format')
	  PATTERN = '.*bank_transactions_.*\.csv';
4.1)Steps to create Notification Integration	  
    TYPE|NOTIFICATION_PROVIDER|ENABLED|AZURE_STORAGE_QUEUE_PRIMARY_URI|AZURE_TENANT_ID
4.2)Setting up snowpipe
    -Create Container (Resource Group-storage account)
	-Register Event Grid & Create Queue/Topic/Event [Queue : Receiver, Event : Sender]
	-Create Notification Integration (snowflake) & provide access to Storage Queue
	-Create Stage
	-Create Snowpipe with Auto Ingest (In Bulk Load, here we used to create Procedure and Task, Snowpipe will auto run based on file availability in azure)
4.3) Types of Stage
     -External Stage
	 -Internal Stage
	 -User Stage
	 -Table Stage
5.1) What is Stream 
     A bank has a transactions table where millions of records come in daily from multiple payment systems.
     Downstream, Finance needs a reconciliation fact table (fact_transactions) for reporting.
     Instead of reloading the whole source table every time (expensive + slow), they just want incremental inserts/updates/deletes.
5.2) What is snowpipe streaming
     Snowpipe Streaming is all about letting a source application (or CDC connector) push data directly into a Snowflake table through an API, instead of dropping files into cloud storage first.
5.3) Can we take base table of oracle or some other database and create stream in snowflake ?
5.4) Can oracle golden gate load data directly from oracle table to Azure Blob as csv file : Yes
5.5) Can oracle golden gate load data directly from oracle table to Snowflake table : Yes with Snowpipe Streaming API
6.1) Create table with identity column and current_timestamp as default datetime
6.2) Procedure format (Note : RESULTSET and RETURN TABLE widely used)
		CREATE OR REPLACE PROCEDURE sample_proc()
		RETURNS STRING
		LANGUAGE SQL
		AS
		$$
		DECLARE 
		  ..
		BEGIN
           ...
		   RETURN 'Procedure Executed';
		END;
		$$

		CREATE OR REPLACE PROCEDURE get_emp_fullname()  --Procedure with Execute Immediate and Exception
		RETURNS STRING
		LANGUAGE SQL
		AS
		$$
		DECLARE
			v_fullname STRING;
		BEGIN
			-- Step 1: Insert a test employee
			INSERT INTO employees VALUES (1005,'Umang','Kumar');

			-- Step 2: Get full name of empid = 1004
			SELECT first_name || ' ' || last_name
			  INTO v_fullname
			  FROM employees
			 WHERE empid = 1004;

			-- Step 3: Insert into message_logs using dynamic SQL
			EXECUTE IMMEDIATE
				'INSERT INTO message_logs (message_text)
				 VALUES (''' || v_fullname || ''')';

			RETURN 'Procedure Completed';
		EXCEPTION
		WHEN OTHER THEN
					-- Log the error
					LET err_msg STRING DEFAULT ERROR_MESSAGE();
					LET err_state STRING DEFAULT ERROR_STATE();
					LET err_stack STRING DEFAULT ERROR_STACK_TRACE();
					RETURN 'Error occurred: ' || err_msg || 
						   ' | State: ' || err_state ||
						   ' | Stack: ' || err_stack;

		END;
		$$;
		
		DECLARE  		--Creating procedure using Resuiltset
		  v_emp_resultset   RESULTSET;
		  v_collist         VARCHAR;
		  v_select          VARCHAR;
		BEGIN
		  v_collist := 'empid,first_name,last_name';
		  v_select := 'SELECT ' || v_collist || ' FROM employees';
		  v_emp_resultset := (EXECUTE IMMEDIATE :v_select);
		  RETURN TABLE(v_emp_resultset);
		END;		
		
		CREATE OR REPLACE PROCEDURE get_transformed_employees_res()  --Procedure using cursor, execute immediate, return table
		RETURNS TABLE(empid NUMBER, first_name VARCHAR, last_name VARCHAR)
		LANGUAGE SQL
		AS
		$$
		DECLARE
			v_empid     NUMBER;
			v_firstname STRING;
			v_lastname  STRING;

			c1 CURSOR FOR SELECT empid, first_name, last_name FROM employees;
			c2 CURSOR FOR SELECT empid, first_name, last_name FROM transformed_emps;
		BEGIN
			-- Clear the table first (since it's temporary, this may not be needed)
			TRUNCATE TABLE transformed_emps;

		   FOR rec IN c1 DO
				v_empid := rec.empid;
				v_firstname := UPPER(rec.first_name); -- transformation
				v_lastname := UPPER(rec.last_name);   -- transformation

				-- Insert with transformation
				EXECUTE IMMEDIATE
				  'INSERT INTO transformed_emps (empid, first_name, last_name) VALUES (' 
				  || v_empid || ', ''' || v_firstname || ''', ''' || v_lastname || ''')';
		   END FOR;

		   OPEN c2;
		   RETURN TABLE(RESULTSET_FROM_CURSOR(c2));

		END;
		$$;

		call get_transformed_employees_res();

		CREATE OR REPLACE PROCEDURE sales_total_out_sp_demo(  --procedure with out parameter
			id INT,
			quarter VARCHAR(20),
			total_sales OUT NUMBER(38,0))
		  RETURNS STRING
		  LANGUAGE SQL
		AS
		$$
		BEGIN
		  SELECT SUM(amount) INTO total_sales FROM quarterly_sales
			WHERE empid = :id AND
				  quarter = :quarter;
		  RETURN 'Done';
		END;
		$$;

		CREATE OR REPLACE PROCEDURE emp_quarter_calling_sp_demo(  --Procedure calling other Procedure
			id INT,
			quarter VARCHAR(20))
		  RETURNS STRING
		  LANGUAGE SQL
		AS
		BEGIN
		  LET x NUMBER(38,0);
		  CALL sales_total_out_sp_demo(:id, :quarter, :x);
		  RETURN 'Total sales for employee ' || id || ' in quarter ' || quarter || ': ' || x;
		END;

		CALL emp_quarter_calling_sp_demo(1, '2023_Q1');		
		

		CREATE OR REPLACE PROCEDURE get_allemps()    --Procedure to return resultset as Table
		RETURNS TABLE (empid NUMBER, first_name VARCHAR, last_name VARCHAR)
		LANGUAGE SQL
		AS
		DECLARE
		  res RESULTSET DEFAULT (SELECT empid,first_name,last_name FROM employees ORDER BY empid DESC LIMIT 10);
		BEGIN
		  RETURN TABLE(res);
		END;

		call get_allemps();		
		
		DECLARE                             --Procedure to handle multiple Exceptions
		  my_exception EXCEPTION (-20002, 'Raised MY_EXCEPTION.');
		BEGIN
		  LET counter := 0;
		  LET should_raise_exception := false;
		  SELECT 10 / 0;
		  IF (should_raise_exception) THEN
			RAISE my_exception;
		  END IF;
		  counter := counter + 1;
		  RETURN counter;
		EXCEPTION
		  WHEN STATEMENT_ERROR THEN
			INSERT INTO test_error_log VALUES(
			  'STATEMENT_ERROR', :sqlcode, :sqlerrm, :sqlstate, CURRENT_TIMESTAMP());
			RETURN OBJECT_CONSTRUCT('Error type', 'STATEMENT_ERROR',
									'SQLCODE', sqlcode,
									'SQLERRM', sqlerrm,
									'SQLSTATE', sqlstate);
		  WHEN my_exception THEN
			INSERT INTO test_error_log VALUES(
			  'MY_EXCEPTION', :sqlcode, :sqlerrm, :sqlstate, CURRENT_TIMESTAMP());
			RETURN OBJECT_CONSTRUCT('Error type', 'MY_EXCEPTION',
									'SQLCODE', sqlcode,
									'SQLERRM', sqlerrm,
									'SQLSTATE', sqlstate);
		  WHEN OTHER THEN
			INSERT INTO test_error_log VALUES(
			  'OTHER', :sqlcode, :sqlerrm, :sqlstate, CURRENT_TIMESTAMP());
			RETURN OBJECT_CONSTRUCT('Error type', 'Other error',
									'SQLCODE', sqlcode,
									'SQLERRM', sqlerrm,
									'SQLSTATE', sqlstate);
		END;
		
		DECLARE                        --Procedure to handle multiple Exceptions with sqlstate
		  v_emp_name STRING;
		BEGIN
			-- Example SELECT INTO (may raise P0002 or P0003)
			SELECT first_name INTO v_emp_name
			FROM employees
			WHERE emp_id = 9999;

			-- Example division (may raise 22012)
			LET v_divide_result FLOAT := 100 / 0;

			-- Example insert (may raise 23505 or 23502)
			INSERT INTO employees(emp_id, first_name, last_name)
			VALUES (1, NULL, 'Smith');  -- NULL in NOT NULL col => 23502

			RETURN 'Employee found: ' || v_emp_name;

		EXCEPTION
			WHEN OTHER THEN
				CASE SQLSTATE
					WHEN 'P0002' THEN  -- Query returned no rows
						RETURN 'No employee found (SQLSTATE P0002)';
					WHEN 'P0003' THEN  -- Query returned too many rows
						RETURN 'Multiple employees found (SQLSTATE P0003)';
					WHEN '22012' THEN  -- Division by zero
						RETURN 'Division by zero error (SQLSTATE 22012)';
					WHEN '23505' THEN  -- Unique constraint violation
						RETURN 'Duplicate value violates unique constraint (SQLSTATE 23505)';
					WHEN '23502' THEN  -- NOT NULL constraint violation
						RETURN 'NULL value in a NOT NULL column (SQLSTATE 23502)';
					ELSE
						RETURN 'Unhandled error: ' || SQLSTATE || ' - ' || ERROR_MESSAGE();
				END CASE;
		END;

6.3) Executing procedure individually and within a block
		call sample_proc();  --independently running

		--running in within block (mostly useful to handle multiple statements)
		BEGIN
		call sample_proc();
		END;
		
6.4) Resultset vs RETURN TABLE  (Most Widely used 100% used)
     RESULTSET    : Using resultset we are returning the results back to caller 
	 RETURN TABLE : While in case of RETURN TABLE, the results are not returned to caller but instead the results acts as a rows of the table which we can 
	                further be used in sql queries joins
					
6.4) Function format which returns int/string/table
		CREATE OR REPLACE FUNCTION addition(x1 int, x2 int)
		RETURNS int  --return int
		LANGUAGE SQL
		AS
		$$
		   x1+x2
		$$	 
		
		CREATE OR REPLACE FUNCTION get_employee_fullname(emp_id INT)
		RETURNS STRING
		LANGUAGE SQL
		AS
		$$

			  SELECT first_name || ' ' || last_name
			  FROM employees
			  WHERE empid = emp_id

		$$;		
		
		create or replace function orders_for_product(PROD_ID varchar)     --Tabular Function
		returns table (Product_ID varchar, Quantity_Sold numeric(11, 2))
		as
		$$
			select product_ID, quantity_sold 
				from orders 
				where product_ID = PROD_ID
		$$;		
		
		--Syntax to select from function (not procedure) as a table 
		--Used where we create Func with return as table
		--select col1,col2 from table(func_name( param1,...)) 
		--order by col1
		select product_id, quantity_sold from table(orders_for_product('compostable bags'))
		order by product_id;
		
6.5) How to drop function with same name (overloading)
        --Pl provide data type accordingly
		drop FUNCTION addition(int,int);
		drop FUNCTION addition(int,int,int);


7.1) SQL Joins & Set Operators
		SQL Joins
		---------
		Inner join
		Outer join (LEFT OUTER JOIN, RIGHT OUTER JOIN, FULL OUTER JOIN)
		Cross join
		Natural join

		SET Operators
		-------------
		INTERSECT
		MINUS , EXCEPT
		UNION [ { DISTINCT | ALL } ] [ BY NAME ]
		
7.2)  Dynamic Sql 
		CREATE OR REPLACE PROCEDURE get_num_results_tq(query VARCHAR)   --Dynamic sql to execute query
		RETURNS TABLE ()
		LANGUAGE SQL
		AS
		DECLARE
		  res RESULTSET DEFAULT (SELECT COUNT(*) FROM TABLE(TO_QUERY(:query)));
		BEGIN
		  RETURN TABLE(res);
		END;

		CALL get_num_results_tq('SELECT 1');

        --[Widely used]
		CREATE OR REPLACE PROCEDURE get_num_results(query VARCHAR)  --Dynamic sql to execute query and return integer
		RETURNS INTEGER
		LANGUAGE SQL
		AS
		DECLARE
		  row_count INTEGER DEFAULT 0;
		  stmt VARCHAR DEFAULT 'SELECT COUNT(*) FROM (' || query || ')';
		  res RESULTSET DEFAULT (EXECUTE IMMEDIATE :stmt);
		  cur CURSOR FOR res;
		BEGIN
		  OPEN cur;
		  FETCH cur INTO row_count;
		  RETURN row_count;
		END;

        --[Widely used]
		DECLARE                                  ----Dynamic sql to execute query by accepting input values
		  rs RESULTSET;
		  query VARCHAR DEFAULT 'SELECT * FROM invoices WHERE price > ? AND price < ?';
		  minimum_price NUMBER(12,2) DEFAULT 20.00;
		  maximum_price NUMBER(12,2) DEFAULT 30.00;
		BEGIN
		  rs := (EXECUTE IMMEDIATE :query USING (minimum_price, maximum_price));
		  RETURN TABLE(rs);
		END;

7.2) Scaler functions vs Aggregate functions
		 Scaler functions    : Returns one value per row              [case/coalesce/decode/cast]
		 Aggregate functions : Returns one values per group of rows   [sum/avg]

8.1) Determining the number of rows affected by DML commands
		SQLROWCOUNT : Number of rows affected by the last DML statement.
		SQLFOUND    : true if the last DML statement affected one or more rows.
		SQLNOTFOUND : true if the last DML statement affected zero rows.
		

8.2) What is CTE ?
		A CTE (common table expression) is a named subquery defined in a WITH clause. 
		You can think of the CTE as a temporary view for use in the statement. 
		The CTE defines 
		    -temporary view name
			-optional list of column names
			-query expression (i.e. a SELECT statement)
			-The result of the query expression is effectively a table
			-Each column of that table corresponds to a column

		WITH
			my_cte (cte_col_1, cte_col_2) AS (
				SELECT col_1, col_2
					FROM ...
			)
		SELECT ... FROM my_cte;

8.3) Table Functions  [Most widely used]
		-A Table function returns a set of rows for each input row. 
		-The returned set can contain zero, one, or more rows. 
		-Each row can contain one or more columns
		-Example : A function that accepts an account number and a date, and returns all charges billed to that account on that date.
		-Example : A function that accepts a user ID and returns the database roles assigned to that user.
		
8.4) Difference between Table functions vs. procedures with RETURN TABLE
		Table Function   (Required when we need results in query)
		--------------
		A user-defined table function (UDTF) in Snowflake returns a set of rows (like a table).
		You can use it directly in the FROM clause of SQL, just like a table or view.
		Designed for set-based operations.
		👉 Output behaves like a real table — you can join, filter, aggregate, etc.

		CREATE OR REPLACE FUNCTION split_words(input STRING)
		RETURNS TABLE(word STRING)
		LANGUAGE SQL
		AS
		$$
		  SELECT TRIM(value) AS word
		  FROM TABLE(SPLIT_TO_TABLE(input, ' '))
		$$;
		
		Procedure with RETURN TABLE (like Ref Cursor)
		---------------------------
		A stored procedure or scripting function can also return a TABLE(...).
		But here, it’s meant for procedural logic: you can do loops, conditional logic, dynamic SQL, and finally return a set of rows.
		Unlike UDTFs, procedures are usually called with CALL and don’t plug into a query’s FROM clause.

		CREATE OR REPLACE PROCEDURE get_emps()
		RETURNS TABLE(emp_id INT, emp_name STRING)
		LANGUAGE SQL
		AS
		$$
		DECLARE v_dept STRING;
		BEGIN
			v_dept := 'SALES';
			RETURN TABLE(
				SELECT emp_id, first_name FROM employees WHERE department = v_dept
			);
		END;
		$$;

		-- Usage
		CALL get_emps();
		


8.4) Window Functions
        -Window functions are aggregate functions that can operate on a subset of rows within the set of input rows.	
		-A Window function is an analytic SQL function that operates on a group of related rows known as a partition (category/loc/time period/business unit) -Function results are computed over each partition based on Window Frame

		-Window Function --> acts on each Partition (Covid data parition applied citywise)
		-Window Frame    --> each row in the window frame takes its turn as the current row

		The OVER clause consists of three main components:
			-A PARTITION BY clause
			-An ORDER BY clause
			-A window frame specification  (most Important)

		--Running Total  (Cumulative)
		SELECT menu_category, menu_price_usd,
			SUM(menu_price_usd)
			  OVER(PARTITION BY menu_category ORDER BY menu_price_usd
			  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) sum_price
		  FROM menu_items
		  WHERE menu_category IN('Beverage','Dessert','Snack')
		  ORDER BY menu_category, menu_price_usd;

9.1) What is Snowpark API
		-We are not sending snowflake data outside snowflake
		-Instead, We can use Python/Java/Scala with snowpark API (having its own libraries) to query and process the data
		-The Snowpark API provides an library for querying and processing data 
		-Using a library for any of three languages, you can build applications that process data in Snowflake without moving data to the system where your 
		 application code runs.

9.2) List of Snowpark API
		-Snowpark Session
		-Snowpark APIs (DataFrame, Column, Row, Functions, Window, Grouping, Table Function, Table, Stored Procedure, User Defined Functions, Exceptions etc.)
		-Snowpark Pandas APIs

9.3) Data Frame
		DataFrame can be build by three ways (Mainly there are two ways)
		-DataFrame in SQL Way (DataFrame as a SQL query builder.)
		-DataFrame as an API  (DataFrame in Snowpark is an object-oriented API for: Transformations (don’t execute immediately) / Actions (trigger execution))
		-DataFrame in SQL Way and API way (hybrid) : Most programmers opt Hybrid)
		
9.4) Pl express below query using DataFrame with sql and DataFrame with API
		SELECT PRODUCT, SUM(SALES) AS TOTAL_SALES
		FROM SALES
		WHERE REGION = 'APAC'
		GROUP BY PRODUCT
		
		DataFrame in SQL Way (Creating DataFrame using sql query)
		---------------------------------------------------------
		import snowflake.snowpark as snowpark

		def main(session: snowpark.Session):

			query = """
				SELECT PRODUCT, SUM(SALES) AS TOTAL_SALES  --Agregation
				FROM SALES
				WHERE REGION = 'APAC' --Filteration
				GROUP BY PRODUCT      --Grouping
			"""

			# Run the SQL inside Snowpark
			df = session.sql(query) --Creating DataFrame using sql query

			# Show results
			df.show()   --Finally showing the results

			# Return df if running in Snowsight worksheet
			return df



		DataFrame as an API Way (Using DF methods, we do data processing)
		-----------------------------------------------------------------
		from snowflake.snowpark.functions import col, sum

		df = session.table("SALES")   --only selected table

		df_transformed = (
			df.filter(col("REGION") == "APAC")     # WHERE REGION = 'APAC'    --filteratoin
			  .group_by("PRODUCT")                 # GROUP BY PRODUCT         --Grouping
			  .agg(sum(col("SALES")).alias("TOTAL_SALES"))   # SUM(SALES)     --Aggregation
		)

		df_transformed.show()  --Showing the result

		Hybrid Way (SQL way + DataFrame API way)
		---------------------------------------

		This is exactly how most Snowpark developers work in real projects:
		They mix
		-SQL (when it’s easier to express directly)
		-DataFrame API (when dynamic, programmatic control is needed).


		# Write base query in SQL
		df_sql = session.sql("""
			SELECT PRODUCT, REGION, SALES    --No Grouping, No Aggregation, Only Filteration
			FROM SALES
			WHERE REGION = 'APAC'
		""")

		from snowflake.snowpark.functions import col, sum

		df_api = (
			df_sql.group_by("PRODUCT")									--Grouping
				  .agg(sum(col("SALES")).alias("TOTAL_SALES"))			--Aggregation
				  .with_column("SALES_WITH_TAX", col("TOTAL_SALES") * 1.1)  # add new column
		)

		df_api.show()     # triggers SQL execution		

9.5) Behaviour of Data Frame
		-In Snowpark, a DataFrame is immutable (just like in Spark or Pandas).
		👉 That means you cannot directly update/insert/delete rows inside a DataFrame.
		Instead:
		You create a new DataFrame with the transformation applied.
		If you want permanent changes in a Snowflake table, you use .write.save_as_table() or session.sql("INSERT/UPDATE/DELETE...").
		
9.6) While creating dataframe, if we use .write.save_as_table() 
     What happens ? Does this gets stored as a table in snowflake ?
	 
		-Creates a table in Snowflake
			A permanent table named MY_TABLE is created in the current database and schema.
			If the table already exists, you may get an error unless you specify mode="overwrite".
		-Writes the DataFrame data into the table
			All rows of the DataFrame are persisted in Snowflake storage.
			This is different from a temporary DataFrame, which only exists in session memory.	 
		-Table type
			By default, permanent table.
			Options exist for temporary or transient tables:
			df.write.save_as_table("MY_TEMP_TABLE", mode="overwrite", table_type="TEMPORARY")
		-Schema inference
			Snowpark infers the table columns from the DataFrame schema.
			Data types are mapped automatically to Snowflake types (STRING, NUMBER, DATE, etc.).
		
		✅ Summary
		.write.save_as_table() persists the DataFrame as a Snowflake table.
		After this, the table is fully queryable via Snowflake SQL:
		SELECT * FROM MY_TABLE;
        You can also apply DML, joins, etc. on this table like any normal Snowflake table.
		
9.6) DataFrame Creation/Transformations on DF-Insert,Update,Delete/Actions on DF

		Creating DataFrame and Display DF rows
		--------------------------------------
		import snowflake.snowpark as snowpark
		from snowflake.snowpark.functions import col

		def main (session: snowpark.Session): 
			session.use_role("developer060725")
			session.use_warehouse("wh060725")
			session.use_database("db060725")
			session.use_schema("sch060725")

			# Example DataFrame logic
			df_emp = session.create_dataframe([1001, 1002, 1003, 1004]).to_df("empid")  --Create DF1
			df_emp.show()																--Show DF1 rows

			df_empnew = session.create_dataframe([2221, 2222]).to_df("empidnew")        --Create DF2
			df_empnew.show()															--Show DF2 rows

9.7) Distinguish DataFrame-Sql vs DataFrame-API
		SQL way 			→ “Tell me the answer” (write whole query at once).
		DataFrame API way 	→ “Build the query step by step using functions & objects”.
		Both end up as SQL executed in Snowflake, but the API is more Pythonic / programmatic, better for:
			-Dynamic queries
			-Conditional logic
			-Reusable functions
			-Integration with Python apps
		We can go Hybrid way i.e. mixture of SQL and API
		
		A DataFrame is not just a query → it’s an object-oriented API to build queries step by step.
		Transformations build the query, Actions run it.
		It’s like working with a virtual table that you can manipulate with methods instead of raw SQL.
		In Snowpark (and also Apache Spark), a DataFrame does not physically occupy storage.		
		
9.8) How Snowpark DataFrames Work
		A Snowpark DataFrame is just a lazy query representation (a logical plan).
		It does not pull or store data in memory until you explicitly trigger an action like:
			.show()
			.collect()
			.to_pandas()
			.write.save_as_table()
		Until then, the DataFrame is only a set of instructions about how to fetch and transform the data.		
		In Snowpark, a DataFrame is immutable (just like in Spark or Pandas).
		👉 That means you cannot directly update/insert/delete rows inside a DataFrame.
		Instead: You create a new DataFrame with the transformation applied.		
		If you want permanent changes in a Snowflake table, you use .write.save_as_table() or session.sql("INSERT/UPDATE/DELETE...").		
		
9.9) Creating DataFrame
		-df_table = session.table("sample_product_data")  --create DF from the data in the sample_product_data table
		-df1 = session.create_dataframe([1001, 1002, 1003, 1004]).to_df("empid")  --create DF with one column as empid
		-df2 = session.create_dataframe([[1, 2, 3, 4]], schema=["a", "b", "c", "d"])  --create DF with 4 columns
		-from snowflake.snowpark.types import IntegerType, StringType, StructType, StructField   --create DF and specify a schema
		 schema = StructType([StructField("a", IntegerType()), StructField("b", StringType())])
		 df4 = session.create_dataframe([[1, "snow"], [3, "flake"]], schema)
		-df_range = session.range(1, 10, 2).to_df("a")   --create DF from a range
		-df_json = session.read.json("@my_stage2/data1.json")   --create DF from data in stage
		 df_catalog = session.read.schema(StructType([StructField("name", StringType()), StructField("age", IntegerType())])).csv("@stage/some_dir")
		-query = """SELECT PRODUCT, SUM(SALES) AS TOTAL_SALES   --create DF from sql query. In query itself we have filteration and aggregation
				    FROM SALES
				    WHERE REGION = 'APAC' --Filteration
				    GROUP BY PRODUCT      --Grouping
			     """
		 df = session.sql(query) --Creating DataFrame using sql query
		 
9.10) Operations performed using DataFrame
		-Connect Snowpark Session   [ Session.builder.configs(connection_parameters).create() ]
		-Create Initial DataFrames
		-Transformations & Actions
		-Insert/Update/Delete Operations
		-Filtering & Sorting
		-Join DataFrames
		-Grouping and Aggregation
		-Window Functions
		-CTE
		-Stored Procedures
		-User-Defined Functions
		-Save Final DataFrame

9.11) Operations performed using DF-SQL vs DF-API
	🧩 Operation		🗣️ SQL Style (session.sql)									🐍 DataFrame Style (session.table)
	Select all			SELECT * FROM employees										session.table("employees")
	Filter rows			SELECT * FROM employees WHERE salary > 5000					df.filter(col("salary") > 5000)
	Sort rows			ORDER BY salary DESC										df.sort(col("salary").desc())
	Select columns		SELECT name, salary FROM employees							df.select("name", "salary")
	Rename column		SELECT salary AS base_salary FROM employees					df.with_column_renamed("salary", "base_salary")
	Add new column		SELECT salary, salary * 0.1 AS bonus FROM employees			df.with_column("bonus", col("salary") * 0.1)
	Group & aggregate	SELECT deptno, AVG(salary) FROM employees GROUP BY deptno	df.group_by("deptno").agg(avg("salary"))
	Join tables			SELECT * FROM emp e JOIN dept d ON e.deptno = d.deptno		emp_df.join(dept_df, "deptno")
	Limit rows			SELECT * FROM employees LIMIT 10							df.limit(10)
	Create table		CREATE OR REPLACE TABLE new_table AS SELECT ...				df.write.save_as_table("new_table", mode="overwrite")
	Window function		RANK() OVER (PARTITION BY deptno ORDER BY salary DESC)		rank().over(Window.partition_by("deptno").order_by(col("salary").desc()))
	CTE 				WITH high_paid AS (...) SELECT * FROM high_paid				Use session.sql() only — not supported in DataFrame API
	
9.12) DataFrame Methods
										┌───────────────────────┐
										│   DataFrame Methods   │
										└───────────────────────┘
													│
					┌─────────────┬───────────────┬───────────────┬───────────────┬───────────────┐
					│            		 │               │               │               │               │
				Select &     		Filtering /       Sorting &      Aggregation /     Joining        Set Operations
				Projection     		Row Selection     Ordering       Grouping
					│             		│               │               │               │               │
				 ┌──┼──┐      		┌───┼───┐       ┌───┼───┐       ┌───┼───┐       ┌───┼───┐       ┌───┼───┐
				select()      		filter()        sort()         group_by()      join()           union()
				select_expr() 		where()         order_by()     agg()           cross_join()     union_all()
				with_column() 		limit()                        count()         alias()          intersect()
				drop()        		sample()                       sum()                            except_()
				alias()       		head()                         avg()
				columns()           		                       min()
																   max()

					┌─────────────┬───────────────┬───────────────┐
					│             │               │               │
				Window       Data Output /     Others / Utilities
				Functions       Actions
					│             │               │
				┌──┼──┐       ┌───┼───┐       ┌───┼───┐
				over()        collect()      count()
				row_number()  show()         distinct()
				rank()        write.save_as_table() describe()
				dense_rank()  write.mode()    is_empty()
				lead()        to_pandas()
				lag()


9.12) Mixing Python codes and DataFrame codes together 

	import snowflake.snowpark as snowpark
	from snowflake.snowpark.functions import col, when

	def main(session: snowpark.Session):

		session.use_role("developer060725")
		session.use_warehouse("wh060725")
		session.use_database("db060725")
		session.use_schema("sch060725")

		# Create initial DataFrame
		df = session.create_dataframe([
			(1001, "John", "APAC", 500),
			(1002, "Alice", "EU", 300),
			(1003, "Bob", "APAC", 700),
			(1004, "David", "US", 200)
		]).to_df("empid", "name", "region", "sales")

		# Count rows
		row_count = df.count()

		# ✅ Use Python IF logic to decide which Snowpark transformation to apply
		if row_count <= 3:
			print("Few rows, let's filter only APAC region")
			df_transformed = df.filter(col("region") == "APAC")
		else:
			print("More rows, let's update sales figures")
			df_transformed = df.with_column(
				"sales",
				when(col("region") == "APAC", col("sales") * 1.1)  # give APAC 10% boost
				.otherwise(col("sales"))
			)

		# ✅ Use Python loop to apply multiple filters dynamically
		regions = ["APAC", "EU"]
		for r in regions:
			print(f"Showing rows for region: {r}")
			df.filter(col("region") == r).show()

		# Final result
		df_transformed.show()

		return df_transformed
		
		Notes
		row_count = df.count() → triggers query, returns an integer.
		Python if/else chooses which transformation to apply.
		Python for loop iterates over a list of regions and executes .filter() on DataFrame.
		Final transformed DataFrame is returned.


