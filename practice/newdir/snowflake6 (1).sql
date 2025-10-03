https://docs.snowflake.com/en/developer-guide/snowflake-scripting/blocks

use WAREHOUSE wh060725;
use role developer060725;
use database db060725;
use SCHEMA sch060725;
use role accountadmin;
GRANT CREATE PROCEDURE ON SCHEMA db060725.sch060725 TO ROLE developer060725;
GRANT CREATE SEQUENCE ON SCHEMA db060725.sch060725 TO ROLE developer060725;
use role developer060725;
------------------
describe table employees;
select * from information_schema.procedures;
select * from information_schema.functions;
select * from information_schema.tables;
select * from information_schema.sequences;
------------------
DECLARE
  my_var VARCHAR;
BEGIN
  my_var := 'Snowflake';
  RETURN my_var;
END;
------------------
drop table message_logs;
drop procedure test_loops();
drop sequence message_logs_seq;

GRANT CREATE SEQUENCE ON SCHEMA db060725.sch060725 TO ROLE developer060725;
GRANT CREATE PROCEDURE ON SCHEMA db060725.sch060725 TO ROLE developer060725;
GRANT CREATE FUNCTION ON SCHEMA db060725.sch060725 TO ROLE developer060725;
CREATE OR REPLACE SEQUENCE message_logs_seq START WITH 1 INCREMENT BY 1;

create or replace table message_logs
(
  sno number,
  sno_identity number identity(1,1) not null,
  proc_name varchar2(100),
  message_text varchar2(1000),
  log_date datetime default CURRENT_TIMESTAMP
  );


IDENTITY(1,1) means:
1 → Start value: The first inserted row gets a value of 1.
1 → Increment: Each new row increases the value by 1.
------------------
CREATE OR REPLACE PROCEDURE test_loops()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE 
    counter  INT;
    counter1 INT;
BEGIN
   counter := 0;
   
   FOR i IN 1 TO 5 LOOP
      counter := counter + i;
   END LOOP;

   insert into message_logs(sno,proc_name,message_text)
   values (message_logs_seq.NEXTVAL,'test_loops','A simple message');

   RETURN 'Procedure Executed';
END;
$$


call test_loops();  --independently running

--running in within block (mostly useful to handle multiple statements)
BEGIN
call test_loops();
END;
-------------------
drop FUNCTION multiply(int,int);

CREATE OR REPLACE FUNCTION multiply(x1 int, x2 int)
RETURNS int
LANGUAGE SQL
AS
$$
   x1*x2
$$
-------------------
--This is something like overloading
drop FUNCTION addition(int,int);
drop FUNCTION addition(int,int,int);

CREATE OR REPLACE FUNCTION addition(x1 int, x2 int)
RETURNS int
LANGUAGE SQL
AS
$$
   x1+x2
$$

CREATE OR REPLACE FUNCTION addition(x1 int, x2 int, x3 int)
RETURNS int
LANGUAGE SQL
AS
$$
   x1+x2+x3
$$
------------------
CREATE OR REPLACE FUNCTION get_employee_fullname(emp_id INT)
RETURNS STRING
LANGUAGE SQL
AS
$$

      SELECT first_name || ' ' || last_name
      FROM employees
      WHERE empid = emp_id

$$;

------------
Functions (UDTF :User Defined Tabular Function)
-----------------------------------------------
create or replace table orders (
    product_id varchar, 
    quantity_sold numeric(11, 2)
    );

insert into orders (product_id, quantity_sold) values 
    ('compostable bags', 2000),
    ('re-usable cups',  1000);
	
create or replace function orders_for_product(PROD_ID varchar)
    returns table (Product_ID varchar, Quantity_Sold numeric(11, 2))
    as
    $$
        select product_ID, quantity_sold 
            from orders 
            where product_ID = PROD_ID
    $$
    ;

select product_id, quantity_sold from table(orders_for_product('compostable bags'))
order by product_id;

--------------------------------------------------------------
create or replace table countries (country_code char(2), country_name varchar);
insert into countries (country_code, country_name) values 
    ('FR', 'FRANCE'),
    ('US', 'UNITED STATES'),
    ('ES', 'SPAIN');

create or replace table user_addresses (user_ID integer, country_code char(2));
insert into user_addresses (user_id, country_code) values 
    (100, 'ES'),
    (123, 'FR'),
    (123, 'US');
	
CREATE OR REPLACE FUNCTION get_countries_for_user ( id number )
  RETURNS TABLE (country_code char, country_name varchar)
  AS 'select distinct c.country_code, c.country_name
      from user_addresses a, countries c
      where a.user_id = id
      and c.country_code = a.country_code';

select *
    from table(get_countries_for_user(123)) cc
    where cc.country_code in ('US','FR','CA')
    order by country_code;
-----------------------------------------------------------------
create or replace table favorite_years as
    select 2016 year
    UNION ALL
    select 2017
    UNION ALL
    select 2018
    UNION ALL
    select 2019;

 create or replace table colors as
    select 2017 year, 'red' color, true favorite
    UNION ALL
    select 2017 year, 'orange' color, true favorite
    UNION ALL
    select 2017 year, 'green' color, false favorite
    UNION ALL
    select 2018 year, 'blue' color, true favorite
    UNION ALL
    select 2018 year, 'violet' color, true favorite
    UNION ALL
    select 2018 year, 'brown' color, false favorite;

create or replace table fashion as
    select 2017 year, 'red' fashion_color
    UNION ALL
    select 2018 year, 'black' fashion_color
    UNION ALL
    select 2019 year, 'orange' fashion_color;

create or replace function favorite_colors(the_year int)
    returns table(color string) as
    'select color from colors where year=the_year and favorite=true';
-----------------------------------------------------
CREATE OR REPLACE PROCEDURE get_emp_fullname()
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
--------------------------
--Creating procedure using Resuiltset
DECLARE
  v_empset     RESULTSET;
  v_collist    VARCHAR;
  v_select     VARCHAR;
BEGIN
  v_collist := 'empid,first_name,last_name';
  v_select := 'SELECT ' || v_collist || ' FROM employees';
  v_empset := (EXECUTE IMMEDIATE :v_select);
  RETURN TABLE(v_empset);
END;
--------------------------
CREATE OR REPLACE PROCEDURE get_transformed_employees()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    v_empid     INT;
    v_firstname STRING;
    v_lastname  STRING;

    c1 CURSOR FOR SELECT empid, first_name, last_name FROM employees;
BEGIN
    -- Clear the table first (since it's temporary, this may not be needed)
    DELETE FROM transformed_emps;

   FOR rec IN c1 DO
		v_empid := rec.empid;
		v_firstname := UPPER(rec.first_name); -- transformation
		v_lastname := UPPER(rec.last_name);   -- transformation

		-- Insert with transformation
	    EXECUTE IMMEDIATE
		  'INSERT INTO transformed_emps (empid, first_name, last_name) VALUES (' 
		  || v_empid || ', ''' || v_firstname || ''', ''' || v_lastname || ''')';
   END FOR;
    
    RETURN 'COMPLETED';
END;
$$;

call get_transformed_employees_new();
select * from transformed_emps;
--------------------------
CREATE OR REPLACE PROCEDURE get_transformed_employees_res()
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

--Above,we are doing transformation and inserting transformed data into table and then trying to get the resultset data within the same procedure.
--Alternatively, we can create new procedure to get the resultset as below 

SELECT * FROM TABLE(get_transformed_employees_resquery());

CREATE OR REPLACE PROCEDURE get_transformed_employees_resquery()
RETURNS TABLE(empid NUMBER, first_name VARCHAR, last_name VARCHAR)
LANGUAGE SQL
AS
$$
DECLARE
    c2 CURSOR FOR SELECT empid, first_name, last_name FROM transformed_emps;
BEGIN
   OPEN c2;
   RETURN TABLE(RESULTSET_FROM_CURSOR(c2));
END;
$$;
---------------------------
--Procedure with in and out parameters
CREATE OR REPLACE TABLE quarterly_sales(
  empid INT,
  amount INT,
  quarter TEXT)
  AS SELECT * FROM VALUES
    (1, 10000, '2023_Q1'),
    (1, 400, '2023_Q1'),
    (2, 4500, '2023_Q1'),
    (2, 35000, '2023_Q1'),
    (1, 5000, '2023_Q2'),
    (1, 3000, '2023_Q2'),
    (2, 200, '2023_Q2'),
    (2, 90500, '2023_Q2'),
    (1, 6000, '2023_Q3'),
    (1, 5000, '2023_Q3'),
    (2, 2500, '2023_Q3'),
    (2, 9500, '2023_Q3'),
    (3, 2700, '2023_Q3'),
    (1, 8000, '2023_Q4'),
    (1, 10000, '2023_Q4'),
    (2, 800, '2023_Q4'),
    (2, 4500, '2023_Q4'),
    (3, 2700, '2023_Q4'),
    (3, 16000, '2023_Q4'),
    (3, 10200, '2023_Q4');

select sum(amount) from quarterly_sales
where empid=1 and quarter='2023_Q1';

CREATE OR REPLACE PROCEDURE sales_total_out_sp_demo(
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
$$
;


CREATE OR REPLACE PROCEDURE emp_quarter_calling_sp_demo(
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
---------------------------
--Procedure to return resultset as Table
CREATE OR REPLACE PROCEDURE get_allemps()
RETURNS TABLE (empid NUMBER, first_name VARCHAR, last_name VARCHAR)
LANGUAGE SQL
AS
DECLARE
  res RESULTSET DEFAULT (SELECT empid,first_name,last_name FROM employees ORDER BY empid DESC LIMIT 10);
BEGIN
  RETURN TABLE(res);
END;

call get_allemps();

---------------------------
CREATE OR REPLACE PROCEDURE auto_event_logging_sp(
  table_name VARCHAR,
  dept_val INTEGER,
  deptnew_val INTEGER)
RETURNS TABLE()
LANGUAGE SQL
AS
$$
BEGIN
  UPDATE IDENTIFIER(:table_name)
    SET department_id = :deptnew_val
    WHERE department_id = :dept_val;
  LET res RESULTSET := (SELECT * FROM IDENTIFIER(:table_name) ORDER BY empid);
  RETURN TABLE(res);
EXCEPTION
  WHEN statement_error THEN
    res := (SELECT :sqlcode sql_code, :sqlerrm error_message, :sqlstate sql_state);
    RETURN TABLE(res);
END;
$$

ALTER PROCEDURE AUTO_EVENT_LOGGING_SP(VARCHAR, INTEGER, INTEGER) SET LOG_LEVEL = 'INFO';

ALTER PROCEDURE auto_event_logging_sp(VARCHAR, INTEGER, INTEGER)
SET AUTO_EVENT_LOGGING = 'LOGGING';

ALTER PROCEDURE auto_event_logging_sp(VARCHAR, INTEGER, INTEGER)
SET AUTO_EVENT_LOGGING = 'ALL';

CALL auto_event_logging_sp('employees', 30, 40);
