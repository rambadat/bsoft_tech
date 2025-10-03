Determining the number of rows affected by DML commands
=======================================================
SQLROWCOUNT : Number of rows affected by the last DML statement.
SQLFOUND    : true if the last DML statement affected one or more rows.
SQLNOTFOUND : true if the last DML statement affected zero rows.

BEGIN
  LET sql_row_count_var INT := 0;
  LET sql_found_var BOOLEAN := NULL;
  LET sql_notfound_var BOOLEAN := NULL;
  IF ((SELECT MAX(value) FROM my_values) > 2) THEN
    UPDATE my_values SET value = 4 WHERE value < 3;
    sql_row_count_var := SQLROWCOUNT;
    sql_found_var := SQLFOUND;
    sql_notfound_var := SQLNOTFOUND;
  END IF;
  SELECT * from my_values;
  IF (sql_found_var = true) THEN
    RETURN 'Updated ' || sql_row_count_var || ' rows.';
  ELSEIF (sql_notfound_var = true) THEN
    RETURN 'No rows updated.';
  ELSE
    RETURN 'No DML statements executed.';
  END IF;
END;


CTE
===
A CTE (common table expression) is a named subquery defined in a WITH clause. You can think of the CTE as a temporary view for use in the statement that defines the CTE. The CTE defines the temporary view’s name, an optional list of column names, and a query expression (i.e. a SELECT statement). The result of the query expression is effectively a table. Each column of that table corresponds to a column in the (optional) list of column names.

WITH
    my_cte (cte_col_1, cte_col_2) AS (
        SELECT col_1, col_2
            FROM ...
    )
SELECT ... FROM my_cte;


WITH RECURSIVE managers 
      -- Column names for the "view"/CTE
      (employee_ID, manager_ID, employee_title, mgr_title) 
    AS
      -- Common Table Expression
      (

        -- Anchor Clause
        SELECT employee_ID, manager_ID, title AS employee_title, NULL AS mgr_title
          FROM employees
          WHERE title = 'President'

        UNION ALL

        -- Recursive Clause
        SELECT 
            employees.employee_ID, employees.manager_ID, employees.title, managers.employee_title AS mgr_title
          FROM employees JOIN managers 
            ON employees.manager_ID = managers.employee_ID
      )

  -- This is the "main select".
  SELECT employee_title AS Title, employee_ID, manager_ID, mgr_title
    FROM managers
    ORDER BY manager_id NULLS FIRST, employee_ID
  ;
+----------------------------+-------------+------------+----------------------------+
| TITLE                      | EMPLOYEE_ID | MANAGER_ID | MGR_TITLE                  |
|----------------------------+-------------+------------+----------------------------|
| President                  |           1 |       NULL | NULL                       |
| Vice President Engineering |          10 |          1 | President                  |
| Vice President HR          |          20 |          1 | President                  |
| Programmer                 |         100 |         10 | Vice President Engineering |
| QA Engineer                |         101 |         10 | Vice President Engineering |
| Health Insurance Analyst   |         200 |         20 | Vice President HR          |
+----------------------------+-------------+------------+----------------------------+

FUNCTIONS
=========
Scalar functions (Date, string, number Functions) : return one value per row --> 100 value /100 rows
Aggregate functions : return one value per group of rows 					 --> 1 value/100 rows
Window functions (Analytical functions)
Table functions
System functions
User-defined functions

Scalar functions
================
A scalar function is a function that returns one value per invocation; in most cases, you can think of this as returning one value per row. This contrasts with Aggregate functions, which return one value per group of rows.

[Conditional]
CASE
----
SELECT
    column1,
    CASE 
        WHEN column1 = 1 THEN 'one'
        WHEN column1 = 2 THEN 'two'
        WHEN column1 IS NULL THEN 'NULL'
        ELSE 'other'
    END AS result
FROM VALUES (1), (2), (NULL);

SELECT CASE COLLATE('m', 'upper')
    WHEN 'M' THEN TRUE
    ELSE FALSE
END;


WHERE timestamp_column BETWEEN '2025-04-30 00:00:00' AND '2025-04-31 00:00:00';
SELECT 'true' WHERE 1 BETWEEN 0 AND 10;

COALESCE : Returns the first non-NULL expression among its arguments, or NULL if all its arguments are NULL.
SELECT column1, column2, column3, coalesce(column1, column2, column3)
FROM (values
  (1,    2,    3   ),
  (null, 2,    3   ),
  (null, null, 3   ),
  (null, null, null),
  (1,    null, 3   ),
  (1,    null, null),
  (1,    2,    null)
) v;

+---------+---------+---------+-------------------------------------+
| COLUMN1 | COLUMN2 | COLUMN3 | COALESCE(COLUMN1, COLUMN2, COLUMN3) |
|---------+---------+---------+-------------------------------------|
|       1 |       2 |       3 |                                   1 |
|    NULL |       2 |       3 |                                   2 |
|    NULL |    NULL |       3 |                                   3 |
|    NULL |    NULL |    NULL |                                NULL |
|       1 |    NULL |       3 |                                   1 |
|       1 |    NULL |    NULL |                                   1 |
|       1 |       2 |    NULL |                                   1 |
+---------+---------+---------+-------------------------------------+

Decode
------
SELECT column1, decode(column1, 
                       1, 'one', 
                       2, 'two', 
                       NULL, '-NULL-', 
                       'other'
                      ) AS decode_result
    FROM d;
+---------+---------------+
| COLUMN1 | DECODE_RESULT |
|---------+---------------|
|       1 | one           |
|       2 | two           |
|    NULL | -NULL-        |
|       4 | other         |
+---------+---------------+

GREATEST
--------
SELECT col_1,
       col_2,
       col_3,
       GREATEST(col_1, col_2, col_3) AS greatest
  FROM test_table_1_greatest
  ORDER BY col_1;
  
NULLIF : Returns NULL if expr1 is equal to expr2, otherwise returns expr1. Its data type should be same.
------
SELECT a, b, NULLIF(a,b) FROM i;
SELECT NULLIF(1,'A'), NVL(1,'1') FROM dual;
NULLIF internally does the implicit data type conversion

--------+--------+-------------+
   a    |   b    | nullif(a,b) |
--------+--------+-------------+
 0      | 0      | [NULL]      |
 0      | 1      | 0           |
 0      | [NULL] | 0           |
 1      | 0      | 1           |
 1      | 1      | [NULL]      |
 1      | [NULL] | 1           |
 [NULL] | 0      | [NULL]      |
 [NULL] | 1      | [NULL]      |
 [NULL] | [NULL] | [NULL]      |
--------+--------+-------------+

NVL : If expr1 is NULL, returns expr2, otherwise returns expr1.
NVL2 : Returns values depending on whether the first input is NULL:
		If expr1 is NOT NULL, then NVL2 returns expr2.
		If expr1 is NULL, then NVL2 returns expr3.  
		
		
[Conversion]
Cast
----
SELECT CAST(varchar_value AS NUMBER(5,2)) AS varchar_to_number1,
       SYSTEM$TYPEOF(varchar_to_number1) AS data_type
  FROM test_data_type_conversion;

TO_CHAR , TO_VARCHAR : Converts the input expression to a string. For NULL input, the output is NULL.  

[Numeric Data type]
TO_DECIMAL , TO_NUMBER , TO_NUMERIC

[Boolean Data Type]
TO_BOOLEAN

[Date and TIme]
TO_DATE, TO_TIME, TO_TIMESTAMP, 

[Semi Structered Data Type]
TO_ARRAY, TO_OBJECT, TO_VARIANT

[Geospatial Data Type]
TO_GEOGRAPHY

[Date and TIme]
LAST_DAY,PREVIOUS_DAY,NEXT_DAY, ADD_MONTHS,DATEADD, DATEDIFF, MONTHS_BETWEEN

[File]
GET_STAGE_LOCATION, GET_RELATIVE_PATH, GET_ABSOLUTE_PATH

[Numeric]
ABS, CEIL, FLOOR
TRUNC, TRUNCATE

[REGULAR EXPRESSION]
[SEMI STRUCTURES AND STRUCTURED DATA]
[STRING]
[TABLE]
[VECTOR]
[WINDOW]

Aggregate Functions
===================
Performs operation on group of rows

System functions
================
Snowflake provides the following types of system functions:
-Control functions that allow you to execute actions in the system (e.g. aborting a query).
-Information functions that return information about the system (e.g. calculating the clustering depth of a table).
-Information functions that return information about queries (e.g. information about EXPLAIN plans).

Table functions
===============
A table function returns a set of rows for each input row. The returned set can contain zero, one, or more rows. Each row can contain one or more columns

The following are appropriate scenarios as table functions:
-A function that accepts an account number and a date, and returns all charges billed to that account on that date. (More than one charge might have been billed on a particular date.)
-A function that accepts a user ID and returns the database roles assigned to that user. (A user might have multiple roles, including “sysadmin” and “useradmin”.)

-To list temperature of all Indian cities
SELECT city_name, temperature
    FROM TABLE(record_high_temperatures_for_date('2021-06-27'::DATE))
    ORDER BY city_name;
	
Window function
===============
Window functions are aggregate functions that can operate on a subset of rows within the set of input rows.	

A window function is an analytic SQL function that operates on a group of related rows known as a partition. A partition is usually a logical group of rows along some familiar dimension, such as product category, location, time period, or business unit. Function results are computed over each partition, with respect to an implicit or explicit window frame. 

Window Frame is a fixed or variable set of rows relative to the current row. The current row is a single input row for which the function result is currently being computed. Function results are calculated row by row within each partition, and each row in the window frame takes its turn as the current row.

Window Function --> acts on each Partition (Covid data parition applied citywise)
Window Frame    --> each row in the window frame takes its turn as the current row

The OVER clause consists of three main components:
--A PARTITION BY clause
--An ORDER BY clause
--A window frame specification  (most Important)

For an aggregate function, the input is a group of rows, and the output is one row.
For a window function, the input is each row within a partition, and the output is one row per input row.

SELECT menu_category, menu_price_usd, menu_cogs_usd,
    AVG(menu_cogs_usd) OVER(PARTITION BY menu_category ORDER BY menu_price_usd ROWS BETWEEN CURRENT ROW and 2 FOLLOWING) avg_cogs
  FROM menu_items
  ORDER BY menu_category, menu_price_usd
  LIMIT 15;
  
--Running Total  (Cumulative)
SELECT menu_category, menu_price_usd,
    SUM(menu_price_usd)
      OVER(PARTITION BY menu_category ORDER BY menu_price_usd
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) sum_price
  FROM menu_items
  WHERE menu_category IN('Beverage','Dessert','Snack')
  ORDER BY menu_category, menu_price_usd;

+---------------+----------------+-----------+
| MENU_CATEGORY | MENU_PRICE_USD | SUM_PRICE |
|---------------+----------------+-----------|
| Beverage      |           2.00 |      2.00 |
| Beverage      |           3.00 |      8.00 |
| Beverage      |           3.00 |      8.00 |
| Beverage      |           3.50 |     11.50 |
| Dessert       |           3.00 |      3.00 |
| Dessert       |           4.00 |      7.00 |
| Dessert       |           5.00 |     12.00 |
| Dessert       |           6.00 |     24.00 |
| Dessert       |           6.00 |     24.00 |
| Dessert       |           7.00 |     31.00 |
| Snack         |           6.00 |     12.00 |
| Snack         |           6.00 |     12.00 |
| Snack         |           7.00 |     19.00 |
| Snack         |           9.00 |     28.00 |
| Snack         |          11.00 |     39.00 |
+---------------+----------------+-----------+

Window frames for cumulative and sliding calculations
--Cumulative in general is always unbounded.
--Cumulative when bounded is considered as sliding/moving.


-----
CREATE TABLE store_sales_2 (
    day INTEGER,
    sales_today INTEGER
    );
+-------------------------------------------+
| status                                    |
|-------------------------------------------|
| Table STORE_SALES_2 successfully created. |
+-------------------------------------------+
INSERT INTO store_sales_2 (day, sales_today) VALUES
    (1, 10),
    (2, 14),
    (3,  6),
    (4,  6),
    (5, 14),
    (6, 16),
    (7, 18);
+-------------------------+
| number of rows inserted |
|-------------------------|
|                       7 |
+-------------------------+

SELECT day, 
       sales_today, 
       RANK()
           OVER (ORDER BY sales_today DESC) AS Rank,
       SUM(sales_today)
           OVER (ORDER BY day
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
               AS "SALES SO FAR THIS WEEK",
       SUM(sales_today)
           OVER ()
               AS total_sales,
       AVG(sales_today)
           OVER (ORDER BY day ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
               AS "3-DAY MOVING AVERAGE"
    FROM store_sales_2
    ORDER BY day;
+-----+-------------+------+------------------------+-------------+----------------------+
| DAY | SALES_TODAY | RANK | SALES SO FAR THIS WEEK | TOTAL_SALES | 3-DAY MOVING AVERAGE |
|-----+-------------+------+------------------------+-------------+----------------------|
|   1 |          10 |    5 |                     10 |          84 |               10.000 |
|   2 |          14 |    3 |                     24 |          84 |               12.000 |
|   3 |           6 |    6 |                     30 |          84 |               10.000 |
|   4 |           6 |    6 |                     36 |          84 |                8.666 |
|   5 |          14 |    3 |                     50 |          84 |                8.666 |
|   6 |          16 |    2 |                     66 |          84 |               12.000 |
|   7 |          18 |    1 |                     84 |          84 |               16.000 |
+-----+-------------+------+------------------------+-------------+----------------------+