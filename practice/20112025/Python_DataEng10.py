File Handling and OS projects
=============================
Yes, Please Pl create log file by writing sample python code. Initially, Pl create log file with the name basic_checks.log and write few logs and then also append further lines. Each line of log file should start with date and time at the beginning of the line. The sample python code should check for the existence of directory (feed), existence of files(customer.csv, supplier.csv, order.csv), do basic operations like compression and once compressed remove the original files from original location and put the compressed file in archive location. Also purge the compressed files older than 7 days from archive location.Pl create functions in a module and import module in our python script. Also take care of exception handling.

C:\Users\user\Desktop\snowflake\Python\
│
├── file_utils.py              ← module with reusable functions
├── main_script.py             ← main driver script
└── basic_checks.log           ← log file (auto-created)


🧩 file_utils.py → the module
-----------------------------
import os
import shutil
import logging
from datetime import datetime, timedelta

# Setup logging
def setup_logger():
    log_file = "basic_checks.log"
    logging.basicConfig(
        filename=log_file,
        level=logging.INFO,
        format="%(asctime)s - %(levelname)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S"
    )
    return logging.getLogger()

logger = setup_logger()


# Check for directory existence
def check_directory_exists(dir_path):
    if os.path.exists(dir_path) and os.path.isdir(dir_path):
        logger.info(f"Directory exists: {dir_path}")
        return True
    else:
        logger.error(f"Directory not found: {dir_path}")
        return False



# Check if required files exist
def check_files_exist(dir_path, files_list):
    all_exist = True
    for file in files_list:
        file_path = os.path.join(dir_path, file)
        if os.path.exists(file_path):
            logger.info(f"File exists: {file_path}")
        else:
            logger.error(f"File missing: {file_path}")
            all_exist = False
    return all_exist


# Compress and archive files
def compress_and_archive(src_dir, archive_dir, files_list):
    os.makedirs(archive_dir, exist_ok=True)
    
    for file in files_list:
        src_file = os.path.join(src_dir, file)
        if os.path.exists(src_file):
            zip_base_name = os.path.splitext(file)[0]
            zip_path = os.path.join(archive_dir, zip_base_name)
            
            try:
                shutil.make_archive(zip_path, 'zip', src_dir, file)
                logger.info(f"Compressed and archived: {file}")
                os.remove(src_file)
                logger.info(f"Removed original file after compression: {file}")
            except Exception as e:
                logger.error(f"Error compressing {file}: {e}")
        else:
            logger.warning(f"File not found for compression: {file}")


# Purge old files (older than 7 days)
def purge_old_archives(archive_dir, days=7):
    now = datetime.now()
    threshold = now - timedelta(days=days)
    
    for file in os.listdir(archive_dir):
        file_path = os.path.join(archive_dir, file)
        if os.path.isfile(file_path):
            modified_time = datetime.fromtimestamp(os.path.getmtime(file_path))
            if modified_time < threshold:
                try:
                    os.remove(file_path)
                    logger.info(f"Purged old archive: {file}")
                except Exception as e:
                    logger.error(f"Error purging file {file}: {e}")



🚀 main_script.py → the main driver script
-------------------------------------------
import os
from file_utils import (
    check_directory_exists,
    check_files_exist,
    compress_and_archive,
    purge_old_archives,
    logger
)

# Define directories and file names
base_path = r"C:\Users\user\Desktop\snowflake\Python"
feed_dir = os.path.join(base_path, "feed")
archive_dir = os.path.join(base_path, "archive")

files_to_check = ["customer.csv", "supplier.csv", "order.csv"]

# Workflow execution with logging
try:
    logger.info("---- Starting File Check Process ----")

    if check_directory_exists(feed_dir):
        if check_files_exist(feed_dir, files_to_check):
            logger.info("All files exist. Proceeding to compression...")
            compress_and_archive(feed_dir, archive_dir, files_to_check)
        else:
            logger.warning("Some files are missing in feed directory.")
    
    purge_old_archives(archive_dir, days=7)

    logger.info("---- Process Completed Successfully ----")

except Exception as e:
    logger.error(f"Unexpected error: {e}")


🧾 Example Log Output (basic_checks.log)
----------------------------------------
2025-10-17 07:55:12 - INFO - ---- Starting File Check Process ----
2025-10-17 07:55:12 - INFO - Directory exists: C:\Users\user\Desktop\snowflake\Python\feed
2025-10-17 07:55:12 - INFO - File exists: ...\customer.csv
2025-10-17 07:55:12 - INFO - File exists: ...\supplier.csv
2025-10-17 07:55:12 - INFO - File exists: ...\order.csv
2025-10-17 07:55:12 - INFO - Compressed and archived: customer.csv
2025-10-17 07:55:12 - INFO - Removed original file after compression: customer.csv
2025-10-17 07:55:12 - INFO - Purged old archive: old_order.zip
2025-10-17 07:55:12 - INFO - ---- Process Completed Successfully ----
