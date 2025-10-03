Exception
=========
Within the EXCEPTION clause, use a WHEN clause to handle an exception by name. You can handle exceptions that you declare as well as built-in exceptions. Currently, Snowflake provides the following built-in exceptions:

-STATEMENT_ERROR: This exception indicates an error while executing a statement. For example, if you attempt to drop a table that does not exist, this exception is raised.
-EXPRESSION_ERROR: This exception indicates an error related to an expression. For example, if you create an expression that evaluates to a VARCHAR, and you attempt to assign the value of the expression to a FLOAT, this error is raised.

CREATE OR REPLACE TABLE test_error_log(
  error_type VARCHAR,
  error_code VARCHAR,
  error_message VARCHAR,
  error_state VARCHAR,
  error_timestamp TIMESTAMP);


DECLARE
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


SQL Joins
=========
Inner join
Outer join (LEFT OUTER JOIN, RIGHT OUTER JOIN, FULL OUTER JOIN)
Cross join
Natural join

SET Operators
=============
INTERSECT
MINUS , EXCEPT
UNION [ { DISTINCT | ALL } ] [ BY NAME ]

--UNION BY NAME (Good Feature)
-Columns with the same identifiers are matched and combined. Matching of unquoted identifiers is case-insensitive, and matching of quoted identifiers is case-sensitive.
-The inputs aren’t required to have the same number of columns. If a column exists in one input but not the other, it is filled with NULL values in the combined result set for each row where it’s missing.
-The order of columns in the combined result set is determined by the order of unique columns from left to right, as they are first encountered.

SELECT * FROM union_demo_column_order1
UNION BY NAME
SELECT * FROM union_demo_column_order2
ORDER BY a;

SELECT * FROM union_demo_column_order1
UNION ALL BY NAME
SELECT * FROM union_demo_column_order2
ORDER BY a;

SELECT office_name, postal_code FROM sales_office_postal_example
UNION BY NAME
SELECT customer, postal_code FROM customer_postal_example
ORDER BY postal_code;

+-------------+-------------+-----------+
| OFFICE_NAME | POSTAL_CODE | CUSTOMER  |
|-------------+-------------+-----------|
| sales1      | 94061       | NULL      |
| NULL        | 94061       | customer2 |
| NULL        | 94066       | customer1 |
| sales2      | 94070       | NULL      |
| sales4      | 98005       | NULL      |
| NULL        | 98005       | customer4 |
| sales3      | 98116       | NULL      |
| NULL        | 98444       | customer3 |
+-------------+-------------+-----------+

The output shows that columns with different identifiers aren’t combined and that rows have NULL values for columns that are in one table but not the other. The postal_code column is in both tables, so there are no NULL values in the output for the postal_code column.

SELECT office_name AS office_or_customer, postal_code FROM sales_office_postal_example
UNION BY NAME
SELECT customer AS office_or_customer, postal_code FROM customer_postal_example
ORDER BY postal_code;

+--------------------+-------------+
| OFFICE_OR_CUSTOMER | POSTAL_CODE |
|--------------------+-------------|
| sales1             | 94061       |
| customer2          | 94061       |
| customer1          | 94066       |
| sales2             | 94070       |
| sales4             | 98005       |
| customer4          | 98005       |
| sales3             | 98116       |
| customer3          | 98444       |
+--------------------+-------------+

--Use the UNION operator and cast mismatched data types
CREATE OR REPLACE TABLE union_test1 (v VARCHAR);
CREATE OR REPLACE TABLE union_test2 (i INTEGER);

INSERT INTO union_test1 (v) VALUES ('Smith, Jane');
INSERT INTO union_test2 (i) VALUES (42);

SELECT v::VARCHAR FROM union_test1
UNION
SELECT i::VARCHAR FROM union_test2;

Dynamic sql
===========
The following techniques are available for constructing SQL statements dynamically at runtime:
-TO_QUERY function - This function takes a SQL string with optional parameters as input.
 You can use the TO_QUERY function in the code for stored procedures and applications that construct SQL statements dynamically. This table function takes a SQL string as input. Optionally, the SQL string can contain parameters, and you can specify the arguments to pass to the parameters as bind variables.

CREATE OR REPLACE PROCEDURE get_num_results_tq(query VARCHAR)
RETURNS TABLE ()
LANGUAGE SQL
AS
DECLARE
  res RESULTSET DEFAULT (SELECT COUNT(*) FROM TABLE(TO_QUERY(:query)));
BEGIN
  RETURN TABLE(res);
END;

CALL get_num_results_tq('SELECT 1');


-Dynamic SQL (Execute Immediate) - Code in a stored procedure or application takes input and constructs a dynamic SQL statement using this input. 
CREATE OR REPLACE PROCEDURE get_num_results(query VARCHAR)
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


DECLARE
  rs RESULTSET;
  query VARCHAR DEFAULT 'SELECT * FROM invoices WHERE price > ? AND price < ?';
  minimum_price NUMBER(12,2) DEFAULT 20.00;
  maximum_price NUMBER(12,2) DEFAULT 30.00;
BEGIN
  rs := (EXECUTE IMMEDIATE :query USING (minimum_price, maximum_price));
  RETURN TABLE(rs);
END;

----------------
Pending function
----------------
Scalar functions (Date, string, number Functions) : return one value per row
Aggregate functions : return one value per group of rows
Window functions (Analytical functions)
Table functions
System functions
User-defined functions

Scalar functions
----------------
A scalar function is a function that returns one value per invocation; in most cases, you can think of this as returning one value per row. This contrasts with Aggregate functions, which return one value per group of rows.

CASE
SELECT
    column1,
    CASE 
        WHEN column1 = 1 THEN 'one'
        WHEN column1 = 2 THEN 'two'
        WHEN column1 IS NULL THEN 'NULL'
        ELSE 'other'
    END AS result
FROM VALUES (1), (2), (NULL);


--------
Pending
--------
Window Functions
Transactions : BEGIN TRANSACTION, COMMIT , ROLLBACK , SHOW TRANSACTIONS , DESCRIBE TRANSACTION
All type of loops and conditions




	