--Creating Database/Schemas/Warehouse/Role
use role accountadmin;
create database db060725;
CREATE SCHEMA sch060725;

create warehouse wh060725
WITH WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 300
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

use warehouse wh060725;

create role developer060725;

GRANT USAGE ON WAREHOUSE wh060725 TO ROLE developer060725;
GRANT USAGE ON DATABASE db060725 TO ROLE developer060725;
GRANT USAGE ON SCHEMA sch060725 TO ROLE developer060725;
GRANT CREATE TABLE ON SCHEMA db060725.sch060725 TO ROLE developer060725;
GRANT SELECT ON ALL TABLES IN SCHEMA sch060725 TO ROLE developer060725;

--Using Database/Schemas/Warehouse/Role
use database db060725;
use WAREHOUSE wh060725;
use SCHEMA sch060725;
GRANT ROLE developer060725 TO USER RAMBADAT;  -- RAMBADAT is snowflake account user
use role developer060725;

select current_warehouse(),current_database(), current_schema(),current_user(),current_role() from dual;

GRANT ALL ON EMPLOYEE_DATA TO developer060725;  --Need to grant the privilege on table created to the <ROLE CREATED> as admin user
or
GRANT SELECT ON EMPLOYEE_DATA TO developer060725;

--Query the metadata for table
SELECT * FROM information_schema.columns
WHERE table_name = 'EMPLOYEE_DATA';


