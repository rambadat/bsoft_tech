Snowpark API (Mainly DataFrame API)
===================================
--We are not sending snowflake data outside snowflake
--Instead, We can use Python/Java/Scala with snowpark API (having its own libraries) to query and process the data.

The Snowpark API provides an intuitive library for querying and processing data at scale in Snowflake. Using a library for any of three languages, you can build applications that process data in Snowflake without moving data to the system where your application code runs, and process at scale as part of the elastic and serverless Snowflake engine.

Snowflake currently provides Snowpark libraries for three languages: Java, Python, and Scala.

List of Snowpark API
--------------------
Snowpark Session
Snowpark APIs (DataFrame, Column, Row, Functions, Window, Grouping, Table Function, Table, Stored Procedure, User Defined Functions, Exceptions etc.)
Snowpark Pandas APIs



Data Frame Commands
===================
We have DataFrame in Pandas, Apache PySpark and Snowpark. All these are somewhat similar but the command and syntax differs slightly.
For snowpark DataFrame, we should be familier with our own syntaxes, commands etc when dealing with our DataFrame.
DataFrame can be build by three ways (Mainly there are two ways)
-DataFrame in SQL Way (DataFrame as a SQL query builder.)
-DataFrame as an API  (DataFrame in Snowpark is an object-oriented API for: Transformations (don’t execute immediately) / Actions (trigger execution))
-DataFrame in SQL Way and API way (hybrid) : Most programmers opt Hybrid)

Below is the query, we can express in sql way and also in DataFrame API way.
SELECT PRODUCT, SUM(SALES) AS TOTAL_SALES
        FROM SALES
        WHERE REGION = 'APAC'
        GROUP BY PRODUCT

DataFrame in SQL Way
-------------------------------------------------------
import snowflake.snowpark as snowpark

def main(session: snowpark.Session):

    query = """
        SELECT PRODUCT, SUM(SALES) AS TOTAL_SALES  --Agregation
        FROM SALES
        WHERE REGION = 'APAC' --Filteration
        GROUP BY PRODUCT      --Grouping
    """

    # Run the SQL inside Snowpark
    df = session.sql(query)

    # Show results
    df.show()   --Finally showing the results

    # Return df if running in Snowsight worksheet
    return df



DataFrame as an API Way
-------------------------------------------------------
from snowflake.snowpark.functions import col, sum

df = session.table("SALES")   --only selected table

df_transformed = (
    df.filter(col("REGION") == "APAC")     # WHERE REGION = 'APAC'    --filteratoin
      .group_by("PRODUCT")                 # GROUP BY PRODUCT         --Grouping
      .agg(sum(col("SALES")).alias("TOTAL_SALES"))   # SUM(SALES)     --Aggregation
)

df_transformed.show()  --Showing the result

Hybrid Way (SQL way + DataFrame API way)
----------------------------------------
This is exactly how most Snowpark developers work in real projects:
They mix
SQL (when it’s easier to express directly)
DataFrame API (when dynamic, programmatic control is needed).
This is what we call a hybrid way.

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


Concept
-------
SQL way → “Tell me the answer” (write whole query at once).
DataFrame API way → “Build the query step by step using functions & objects”.
Both end up as SQL executed in Snowflake, but the API is more Pythonic / programmatic, better for:
Dynamic queries
Conditional logic
Reusable functions
Integration with Python apps

A DataFrame is not just a query → it’s an object-oriented API to build queries step by step.
Transformations build the query, Actions run it.
It’s like working with a virtual table that you can manipulate with methods instead of raw SQL.
In Snowpark (and also Apache Spark), a DataFrame does not physically occupy storage.

🔹 How Snowpark DataFrames Work
	A Snowpark DataFrame is just a lazy query representation (a logical plan).
	It does not pull or store data in memory until you explicitly trigger an action like:
	.show()
	.collect()
	.to_pandas()
	.write.save_as_table()
	Until then, the DataFrame is only a set of instructions about how to fetch and transform the data.

🔹 Storage vs Memory
	Storage in Snowflake: Data is always stored in Snowflake tables (on cloud storage, compressed into micro-partitions).
	Memory in Snowpark: When you run .collect() or .to_pandas(), results are brought into the Python client memory (your Snowpark session).
	No duplication: The DataFrame itself does not create new storage unless you persist it by writing into a table (via .write.save_as_table() or create_or_replace_view()).


# Create a DataFrame from the data in the "sample_product_data" table.
df_table = session.table("sample_product_data")

# Create a DataFrame with one column named a from specified values.
df1 = session.create_dataframe([1001, 1002, 1003, 1004]).to_df("empid")
df1.show()
# To return the DataFrame as a table in a Python worksheet use return instead of show()
# return df1
----------
|"Empid" |
----------
|1001    |
|1002    |
|1003    |
|1004    |
----------

# Create a DataFrame with 4 columns, "a", "b", "c" and "d".
df2 = session.create_dataframe([[1, 2, 3, 4]], schema=["a", "b", "c", "d"])
df2.show()
# To return the DataFrame as a table in a Python worksheet use return instead of show()
# return df2
-------------------------
|"A"  |"B"  |"C"  |"D"  |
-------------------------
|1    |2    |3    |4    |
-------------------------

# Create a DataFrame and specify a schema
from snowflake.snowpark.types import IntegerType, StringType, StructType, StructField
schema = StructType([StructField("a", IntegerType()), StructField("b", StringType())])
df4 = session.create_dataframe([[1, "snow"], [3, "flake"]], schema)
df4.show()
# To return the DataFrame as a table in a Python worksheet use return instead of show()
# return df4

---------------
|"A"  |"B"    |
---------------
|1    |snow   |
|3    |flake  |
---------------

# Create a DataFrame from a range
# The DataFrame contains rows with values 1, 3, 5, 7, and 9 respectively.
df_range = session.range(1, 10, 2).to_df("a")
df_range.show()
# To return the DataFrame as a table in a Python worksheet use return instead of show()
# return df_range
-------
|"A"  |
-------
|1    |
|3    |
|5    |
|7    |
|9    |
-------

from snowflake.snowpark.types import StructType, StructField, StringType, IntegerType
# Create DataFrames from data in a stage.
df_json = session.read.json("@my_stage2/data1.json")
df_catalog = session.read.schema(StructType([StructField("name", StringType()), StructField("age", IntegerType())])).csv("@stage/some_dir")

-----
In Snowpark, a DataFrame is immutable (just like in Spark or Pandas).
👉 That means you cannot directly update/insert/delete rows inside a DataFrame.
Instead:
You create a new DataFrame with the transformation applied.
If you want permanent changes in a Snowflake table, you use .write.save_as_table() or session.sql("INSERT/UPDATE/DELETE...").

Creating DataFrame
==================
import snowflake.snowpark as snowpark
from snowflake.snowpark.functions import col

def main (session: snowpark.Session): 
    session.use_role("developer060725")
    session.use_warehouse("wh060725")
    session.use_database("db060725")
    session.use_schema("sch060725")

    # Example DataFrame logic
    df_emp = session.create_dataframe([1001, 1002, 1003, 1004]).to_df("empid")
    df_emp.show()
    df_emp.

    df_empnew = session.create_dataframe([2221, 2222]).to_df("empidnew")
    df_empnew.show()
	
Inserting/Updating/Deleting data in DataFrame
=============================================	
import snowflake.snowpark as snowpark
from snowflake.snowpark.functions import col,when

def main (session: snowpark.Session): 
    session.use_role("developer060725")
    session.use_warehouse("wh060725")
    session.use_database("db060725")
    session.use_schema("sch060725")

    # Example DataFrame logic
    df = session.create_dataframe([(1001, "John"), (1002, "Alice"), (1003, "Bob")]).to_df("empid", "name")
    df.show()

    new_rows = session.create_dataframe([(1004, "David")]).to_df("empid", "name")

    df_inserted = df.union(new_rows)
    df_inserted.show()

    df_updated = df.with_column(
    "name",
    when(col("name") == "Bob", "Robert").otherwise(col("name"))
    )

    df_updated.show()
 
    return df_updated


Steps to perform general operations on DataFrame
================================================
Filtering, Sorting, Joins,Grouping, Aggregations, Transformations, Window Functions, CTEs,Actions, UDF, SP etc.

1) Establishing Snowpark Session connection
	from snowflake.snowpark import Session, Row
	from snowflake.snowpark.functions import col, upper, avg, sum, when, rank, row_number
	from snowflake.snowpark.window import Window

	connection_parameters = {                           --dictionary (dict) object in Python i.e. key:value pairs
		"account": "<your_account>",
		"user": "<your_username>",
		"password": "<your_password>",
		"role": "<your_role>",
		"warehouse": "<your_warehouse>",
		"database": "<your_database>",
		"schema": "<your_schema>"
	}

	session = Session.builder.configs(connection_parameters).create()  --Use this dictionary of values (connection_parameters) to configure my session.

2) Create Initial DataFrames
	# Department DataFrame
	dept_data = [
		Row(deptno=10, dname="ACCOUNTING", loc="NEW YORK"),
		Row(deptno=20, dname="RESEARCH", loc="DALLAS"),
		Row(deptno=30, dname="SALES", loc="CHICAGO"),
		Row(deptno=40, dname="OPERATIONS", loc="BOSTON")
	]
	dept_df = session.create_dataframe(dept_data)

	# Employee DataFrame
	emp_data = [
		Row(empno=1, ename="John", job="Manager", sal=5000, deptno=10),
		Row(empno=2, ename="Jane", job="Analyst", sal=4000, deptno=20),
		Row(empno=3, ename="Jake", job="Clerk", sal=3000, deptno=30),
		Row(empno=4, ename="Jill", job="Salesman", sal=3500, deptno=30),
		Row(empno=5, ename="Jeff", job="Manager", sal=6000, deptno=40)
	]
	emp_df = session.create_dataframe(emp_data)

3) Insert/Update/Delete Operations
	# Insert
	new_row = session.create_dataframe([Row(empno=6, ename="Jess", job="Clerk", sal=2800, deptno=20)])
	emp_df = emp_df.union(new_row)

	# Update
	emp_df = emp_df.with_column(
		"sal",
		when(col("deptno") == 30, col("sal") + 500).otherwise(col("sal"))
	)

	# Delete
	emp_df = emp_df.filter(col("deptno") != 10)
	
4) Filtering & Sorting
	high_paid = emp_df.filter(col("sal") > 3500)
	sorted_df = emp_df.sort(col("sal").desc())

5) Join DataFrames
	joined_df = emp_df.join(dept_df, "deptno").select(
		emp_df["empno"], emp_df["ename"], emp_df["sal"], dept_df["dname"], dept_df["loc"]
	)

6) Grouping and Aggregation
	grouped_df = emp_df.group_by("deptno").agg(
		avg("sal").alias("avg_sal"),
		sum("sal").alias("total_sal")
	)

7) Transformations
	transformed_df = emp_df.with_column("ename", upper(col("ename")))
	transformed_df = transformed_df.with_column("bonus", col("sal") * 0.10)

8) Window Functions
	# Rank employees by salary within each department
	window_spec = Window.partition_by("deptno").order_by(col("sal").desc())

	ranked_df = emp_df.with_column("rank", rank().over(window_spec))

	# Row number for each employee in department
	rownum_df = emp_df.with_column("row_num", row_number().over(window_spec))
	
9) CTEs (Common Table Expressions)
	cte_query = """
	WITH high_salary AS (
		SELECT * FROM EMPLOYEE_TABLE WHERE SAL > 4000
	),
	joined AS (
		SELECT h.ENAME, h.SAL, d.DNAME
		FROM high_salary h
		JOIN DEPARTMENT_TABLE d ON h.DEPTNO = d.DEPTNO
	)
	SELECT * FROM joined ORDER BY SAL DESC
	"""

	cte_result = session.sql(cte_query).collect()

10) Actions
	transformed_df.show()
	result = transformed_df.collect()

11) Save Final DataFrame
	transformed_df.write.save_as_table("final_employee_data", mode="overwrite")

12) User-Defined Functions (UDFs)
	from snowflake.snowpark.functions import udf

	@udf
	def double_salary(sal: int) -> int:

		return sal * 2

	df = df.with_column("double_sal", double_salary(col("sal")))

13) Stored Procedures
	from snowflake.snowpark import StoredProcedure

	def my_proc(session: Session) -> str:
		df = session.table("my_table").filter(col("status") == "active")
		df.write.save_as_table("active_table", mode="overwrite")
		return "Done"

	StoredProcedure.register(my_proc, session, name="proc_active_filter", replace=True)


Snowpark SQL vs DataFrame API Cheat Sheet
=========================================
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

🧠 Tips for Switching Styles (sometimes use sql, sometime use DataFrame API, sometimes use mixture of both)
===========================================================================================================
Use SQL for complex joins, CTEs, and legacy logic.
Use DataFrame API for chaining, transformations, and ML workflows.
Use Hybrid when you want SQL for staging and Python for logic.

DataFrame Transformations Methods (Most Frequently Used)
========================================================
--rows are changed or impacted 
--Data volume can be reduced eg by Grouping, filter, Data rows remains same eg upper, lower, case, decode etc
--Data volume can increase eg cartesan product
👉 Filtering & Selecting
select() 			→ choose specific columns.
filter() / where() 	→ apply row conditions.
with_column() 		→ add or replace a column.
drop() 				→ remove a column.
alias() 			→ rename column(s).

👉 Aggregation
group_by() 			→ group rows by column(s).
agg() 				→ apply aggregate functions (sum, count, avg, etc.).
distinct() 			→ remove duplicates.
drop_duplicates() 	→ same as above, more explicit.

👉 Joins & Set Operations
join() 				→ join with another DataFrame.
union() 			→ combine two DataFrames (same schema).
union_all() 		→ same as union, allows duplicates.

👉 Sorting & Ordering
order_by() / sort() → sort rows.
limit() 			→ restrict number of rows.

👉 Null & Conditional Handling
fillna() 			→ replace nulls.
dropna() 			→ drop null rows.
when()/case_when() 	→ conditional column creation.

✅ Summary (Top 10 you’ll use most):
select(), filter(), with_column(), drop(),
group_by(), agg(),
join(), union(),
order_by(), limit()


DataFrame Actions Methods (Most Frequently Used)
================================================
--No rows are changed or impacted. Only rows are displayed.
👉 Viewing / Collecting Data
show() 				→ quick preview of rows (like SELECT * LIMIT N).
collect() 			→ pull all results into Python as Row objects.
first() 			→ get the first row.
count() 			→ row count.
to_pandas() 		→ convert results into a Pandas DataFrame (very common for data analysis/ML).

👉 Writing / Persisting Data
write.save_as_table("table") 				→ save DataFrame as a table.
write.mode("append").save_as_table("table") → append results to table.
create_or_replace_table("table") 			→ overwrite table with new results.
create_or_replace_view("view") 				→ store results as a view.

👉 Debugging / Schema
explain() 			→ see generated SQL query/execution plan.
schema 				→ inspect schema.
columns 			→ list column names.

✅ Summary (Top 10 you’ll use 90% of the time):
show(), collect(), first(), count(), to_pandas(),
write.save_as_table(), write.mode("append").save_as_table(),
create_or_replace_table(), create_or_replace_view(), explain()

Mixing Python codes and DataFrame codes together 
================================================
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
