Snowflake Project
=================
Daily source team will run generate_job (14:00 Hrs) in unix,autosys to generate csv/txt file 
Daily source team will run send_job (16:00 Hrs) in unix,autosys to transfer csv/txt/json/parquet file along with OK file to feed server. 
	-Azure container path is our feed server.
	-Azure URL = 'azure://prajstorage1.blob.core.windows.net/prajcontainer1'
	-From unix server, autosys job should upload file to Azure path
	  -Install azcopy on the Unix server
	  -Place below script on unix server
			#!/bin/bash
			# upload_to_azure.sh

			# Variables
			FILE_PATH="/u01/data/files/mydata.csv"
			AZURE_STORAGE_URL="https://<storage_account>.blob.core.windows.net/<container_name>/mydata.csv?<sas_token>"

			# Upload using AzCopy
			/opt/azcopy/azcopy copy "$FILE_PATH" "$AZURE_STORAGE_URL" --overwrite=true

			# Exit status
			if [ $? -eq 0 ]; then
			  echo "File uploaded successfully to Azure Blob."
			  exit 0
			else
			  echo "File upload failed!"
			  exit 1
			fi
	  -Autosys Jil Job creation
			insert_job: upload_csv_to_azure   
			job_type: c
			command: /u01/scripts/upload_to_azure.sh
			machine: unixserver01
			owner: appuser
			permission: gx,ge,wx,we,mx,me
			std_out_file: /u01/logs/upload_to_azure.out
			std_err_file: /u01/logs/upload_to_azure.err
			alarm_if_fail: 1
			start_times: "09:00"
			description: "Upload CSV file from Unix to Azure Blob container using AzCopy"

We need to load data file formats like csv, json, parquet. We will be using same stage in snowflake.
(Come up with different file formats and accordingly need to have each stage created).
CSV     --> stage_csv
JSON    --> stage_json
Parquet --> stage_parquet
Txt     --> stage_txt
In the same stage and same format, make use of pattern here as we might need to go with selective files for that file format.
Pl make a practice to capture bad records in error table during loading process.
Create stored procedure to perform COPY INTO operations and accordingly create a task and schedule it
Achieve the same with Snowpipe with AUTO_INGEST. You can go for any method --> Choose between Bulk Load with Task/Snowpipe with Auto_Ingest
The Task should first check for the arrival of txt and ok files
✅ For .txt file
LIST @my_ext_stage PATTERN='34597_GCCS_Facility_[0-9]{8}\\.txt';

✅ For .OK file
LIST @my_ext_stage PATTERN='34597_GCCS_Facility_[0-9]{8}\\.OK';
Also, Daily monitor logs for job status as success or failures

--Table setup
CREATE OR REPLACE TABLE job_master (
    jobid INT PRIMARY KEY,
    jobname STRING
);

INSERT INTO job_master (jobid, jobname) VALUES 
(13610, 'Recon Olympus vs GCCS');

CREATE OR REPLACE TABLE job_control (
    jobid INT,
    job_date DATE,
    status STRING,        -- PENDING, SUCCESS, FAILED
    start_time TIMESTAMP,
    end_time TIMESTAMP,
	retry_count INT DEFAULT,
    PRIMARY KEY (jobid, job_date)
);

CREATE OR REPLACE TABLE job_summary_log (
    jobid INT,
    jobname STRING,
    job_date DATE,
    status STRING,
    retry_count INT,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    duration_minutes INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE OR REPLACE PROCEDURE check_and_load_facility_file(jobid INT)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.8'
PACKAGES = ('snowflake-snowpark-python', 'requests')
HANDLER = 'run'
AS
$$
from datetime import datetime
import requests

def run(session, jobid: int) -> str:
    today = datetime.now().date()

    # Get job name from job_master
    job_info = session.sql(f"""
        SELECT jobname FROM job_master WHERE jobid = {jobid}
    """).collect()

    if not job_info:
        return f"Jobid {jobid} not found in job_master."

    jobname = job_info[0]["JOBNAME"]

    # Check control table
    ctrl = session.sql(f"""
        SELECT status, start_time, retry_count
        FROM job_control
        WHERE jobid = {jobid} AND job_date = '{today}'
    """).collect()

    if ctrl and ctrl[0]["STATUS"] in ("SUCCESS","FAILED"):
        return f"Job {jobid} ({jobname}) already finished. Skipping."

    # If not started, initialize
    if not ctrl:
        session.sql(f"""
            INSERT INTO job_control (jobid, job_date, status, start_time, retry_count)
            VALUES ({jobid}, '{today}', 'PENDING', CURRENT_TIMESTAMP, 0)
        """).collect()
        retry_count = 0
    else:
        retry_count = ctrl[0]["RETRY_COUNT"]

    stage_name = "@my_ext_stage"

    # Check for TXT & OK files
    txt_files = session.sql(f"""
        LIST {stage_name} PATTERN='34597_GCCS_Facility_[0-9]{{8}}\\.txt'
    """).collect()

    ok_files = session.sql(f"""
        LIST {stage_name} PATTERN='34597_GCCS_Facility_[0-9]{{8}}\\.OK'
    """).collect()

    if txt_files and ok_files:
        # Perform COPY INTO
        session.sql(f"""
            COPY INTO my_table 
            FROM {stage_name}
            PATTERN='34597_GCCS_Facility_[0-9]{{8}}\\.txt'
            FILE_FORMAT=(TYPE=CSV FIELD_OPTIONALLY_ENCLOSED_BY='"')
        """').collect()  --Single quotes added, Pl remove it

        session.sql(f"""
            UPDATE job_control
            SET status='SUCCESS', end_time=CURRENT_TIMESTAMP
            WHERE jobid={jobid} AND job_date='{today}'
        """).collect()

        # Insert into summary log
        session.sql(f"""
            INSERT INTO job_summary_log (jobid, jobname, job_date, status, retry_count, start_time, end_time, duration_minutes)
            SELECT jobid, '{jobname}', job_date, status, retry_count, start_time, end_time,
                   DATEDIFF('minute', start_time, end_time)
            FROM job_control
            WHERE jobid={jobid} AND job_date='{today}'
        """).collect()

        return f"Files found and loaded successfully for job {jobid} ({jobname})."

    else:
        # Increment retry count
        retry_count += 1
        session.sql(f"""
            UPDATE job_control
            SET retry_count = {retry_count}
            WHERE jobid={jobid} AND job_date='{today}'
        """).collect()

        if retry_count >= 6:  # After 6 retries (~1 hour)
            session.sql(f"""
                UPDATE job_control
                SET status='FAILED', end_time=CURRENT_TIMESTAMP
                WHERE jobid={jobid} AND job_date='{today}'
            """).collect()

            # Insert into summary log
            session.sql(f"""
                INSERT INTO job_summary_log (jobid, jobname, job_date, status, retry_count, start_time, end_time, duration_minutes)
                SELECT jobid, '{jobname}', job_date, status, retry_count, start_time, end_time,
                       DATEDIFF('minute', start_time, end_time)
                FROM job_control
                WHERE jobid={jobid} AND job_date='{today}'
            """).collect()

            # Trigger email notification
            email_api_url = "https://<your_azure_function_url>/sendEmail"
            payload = {
                "to": ["Citi_Team_Project_DL@citi.com"],
                "cc": ["prajeesh.balan@citi.com"],
                "subject": f"Snowflake Load Alert - Job {jobid} ({jobname}) FAILED",
                "body": f"The expected TXT/OK files for job {jobid} ({jobname}) "
                        f"were not found after 6 retries (1 hour). Load failed."
            }
            requests.post(email_api_url, json=payload)

            return f"Files missing after 6 retries. Job {jobid} ({jobname}) marked FAILED and email sent."
        else:
            return f"Files not yet available for job {jobid} ({jobname}). Retry {retry_count}/6."
$$;


CREATE OR REPLACE TASK facility_file_check_task
  WAREHOUSE = my_wh
  SCHEDULE = '15 MINUTE'
AS
CALL check_and_load_facility_file(13610);

✅ Flow
First run: inserts job_control with retry_count = 0.
Each run:
If file found → load → SUCCESS → stop.
If file missing → retry_count++.
After 6 retries → mark FAILED + send email.

Monitoring all jobs
-------------------
CREATE OR REPLACE VIEW job_monitoring_vw AS
SELECT 
    j.jobid,
    j.jobname,
    c.job_date,
    c.status,
    c.retry_count,
    c.start_time,
    c.end_time,
    DATEDIFF('minute', c.start_time, NVL(c.end_time, CURRENT_TIMESTAMP)) AS duration_minutes
FROM job_master j
LEFT JOIN job_control c 
    ON j.jobid = c.jobid
   AND c.job_date = CURRENT_DATE;

SELECT * FROM job_monitoring_vw ORDER BY jobid, start_time;

| JOBID | JOBNAME                | JOB_DATE   | STATUS  | RETRY_COUNT | START_TIME          | END_TIME            | DURATION_MINUTES |
| ----- | ---------------------- | ---------- | ------- | ----------- | ------------------- | ------------------- | ---------------- |
| 13610 | Recon Olympus vs GCCS  | 2025-09-25 | SUCCESS | 2           | 2025-09-25 09:00:00 | 2025-09-25 09:20:00 | 20               |
| 14001 | Daily Position Extract | 2025-09-25 | FAILED  | 6           | 2025-09-25 08:00:00 | 2025-09-25 09:00:00 | 60               |

--Querying the Historical Log
SELECT * FROM job_summary_log
WHERE job_date = CURRENT_DATE
ORDER BY jobid, start_time;

SELECT 
    jobid,
    jobname,
    COUNT(*) AS total_runs,
    SUM(CASE WHEN status='SUCCESS' THEN 1 ELSE 0 END) AS success_count,
    SUM(CASE WHEN status='FAILED' THEN 1 ELSE 0 END) AS fail_count,
    ROUND(SUM(CASE WHEN status='SUCCESS' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS success_rate_pct
FROM job_summary_log
WHERE job_date >= DATEADD(month, -1, CURRENT_DATE)  --Monthly success rate
GROUP BY jobid, jobname;

✅ Now you have:
job_master = static metadata (jobid, jobname).
job_control = live tracking for today.
job_summary_log = historical log (auditable + reporting).

Lets have a table TBL_GCCS_Facility_AllData which will have the data of each day.
Like this, over a period of time, we will ahve weeks, months and yearwise data in long run.
Pl create a stream 
CREATE OR REPLACE STREAM STRM_GCCS_ALL 
ON TABLE TBL_GCCS_Facility_AllData 
APPEND_ONLY = FALSE; 

CREATE OR REPLACE TASK TASK_MERGE_2021
  WAREHOUSE = my_wh
  SCHEDULE = '5 MINUTE'
AS
MERGE INTO TBL_GCCS_Facility_2021 AS TARGET
USING (
    SELECT *
    FROM STRM_GCCS_ALL
    WHERE YEAR = 2021
) AS SOURCE
ON TARGET.FACILITY_ID = SOURCE.FACILITY_ID 
   AND TARGET.LEGAL_UNIT_CODE = SOURCE.LEGAL_UNIT_CODE
   AND TARGET.STIFF_SEQ_NO = SOURCE.STIFF_SEQ_NO  -- add more keys as needed
WHEN MATCHED AND METADATA$ACTION = 'DELETE' THEN DELETE
WHEN MATCHED AND METADATA$ACTION = 'UPDATE' THEN 
    UPDATE SET
      TARGET.AVAILABLE_AMOUNT = SOURCE.AVAILABLE_AMOUNT,
      TARGET.RECEIVABLE_AMOUNT = SOURCE.RECEIVABLE_AMOUNT
WHEN NOT MATCHED THEN
    INSERT (FACILITY_ID, LEGAL_UNIT_CODE, STIFF_SEQ_NO, YEAR, AVAILABLE_AMOUNT, RECEIVABLE_AMOUNT)
    VALUES (SOURCE.FACILITY_ID, SOURCE.LEGAL_UNIT_CODE, SOURCE.STIFF_SEQ_NO,SOURCE.YEAR);






