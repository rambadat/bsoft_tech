Error Handling and Logging
==========================
By the end of today, you’ll be able to:
Handle runtime errors gracefully using -> try / except / else / finally
Raise custom exceptions using raise
Create reusable custom exception classes
Implement structured logging (to console & file)
Combine both in a data-pipeline-style example


try:
except exceptname alias:  --named exception
except exceptname alias:  --named exception
except exceptname alias:  --named exception
except exception  alias:  --Other than named exception (All errors other than predefined excpetion mentioned)
else:   				  --The else: block is executed only if no exception occurs inside the try: block. It means successful execution.
finally:  --finally: defines a block of code that always executes, whether an exception occurred or not.
		  --It is usually used for cleanup actions — like closing files, releasing resources, disconnecting from databases, or deleting temporary files


PreDefined Exceptions
---------------------
Python has a large set of predefined (built-in) exceptions that cover most common error situations.
These are classes defined in Python’s standard library, and all of them inherit from the base class Exception.
| Exception                                 | Description                                                                            |
| ----------------------------------------- | -------------------------------------------------------------------------------------- |
| **`ZeroDivisionError`**                   | Raised when dividing by zero.                                                          |
| **`TypeError`**                           | Raised when an operation or function is applied to an object of an inappropriate type. |
| **`ValueError`**                          | Raised when a function receives an argument of the right type but inappropriate value. |
| **`NameError`**                           | Raised when a variable is not defined.                                                 |
| **`IndexError`**                          | Raised when list index is out of range.                                                |
| **`KeyError`**                            | Raised when a dictionary key is not found.                                             |
| **`FileNotFoundError`**                   | Raised when trying to open a file that does not exist.                                 |
| **`IOError`**                             | Raised when an input/output operation fails (reading/writing files).                   |
| **`AttributeError`**                      | Raised when an invalid attribute reference is made.                                    |
| **`ImportError` / `ModuleNotFoundError`** | Raised when importing a module that doesn’t exist.                                     |
| **`RuntimeError`**                        | Raised when an error doesn’t fit into any other category.                              |
| **`MemoryError`**                         | Raised when an operation runs out of memory.                                           |
| **`OverflowError`**                       | Raised when a numeric operation exceeds the limit for a data type.                     |
| **`AssertionError`**                      | Raised when an `assert` statement fails.                                               |
| **`StopIteration`**                       | Raised by `next()` when no more items are available in an iterator.                    |
| **`EOFError`**                            | Raised when `input()` hits an end-of-file condition (no input).                        |
| **`OSError`**                             | Raised for operating system–related errors (e.g., file or path issues).                |




🧠 1. Error Handling Basics
   ------------------------
	🔹 Example: Try / Except / Else / Finally
	def divide(a, b):
		try:
			result = a / b
		except ZeroDivisionError as e:
			print("❌ Cannot divide by zero:", e)
		except TypeError as e:
			print("❌ Invalid type:", e)
		else:
			print("✅ Division successful! Result:", result)
		finally:
			print("📘 Division function executed.\n")

	divide(10, 2)
	divide(10, 0)
	divide(10, 'five')

	Output:
	✅ Division successful! Result: 5.0
	📘 Division function executed.

	❌ Cannot divide by zero: division by zero
	📘 Division function executed.

	❌ Invalid type: unsupported operand type(s) for /: 'int' and 'str'
	📘 Division function executed.


🧠 2. Raising Exceptions
   ---------------------
	If a condition violates business logic, you can raise your own exceptions:
	
	def validate_sales_amount(amount):
		if amount < 0:
			raise ValueError(f"Invalid sales amount: {amount}")
		return True

	try:
		validate_sales_amount(-100)
	except ValueError as e:
		print("❗ Business rule violated:", e)


🧠 3. Custom Exception Classes
   ---------------------------
	Custom exceptions make debugging easier in data pipelines.

	class BlobConnectionError(Exception):
		"""Raised when Azure Blob connection fails."""
		pass

	try:
		raise BlobConnectionError("Failed to connect to Azure Blob Storage")
	except BlobConnectionError as e:
		print("⚠️ Custom Error:", e)


🧠 4. Logging in Python
   --------------------
	🔹 Setup logging (to file + console)
	import logging

	# Configure logging
	logging.basicConfig(
		level=logging.INFO,
		format='%(asctime)s | %(levelname)s | %(message)s',
		handlers=[
			logging.FileHandler("data_pipeline.log"),
			logging.StreamHandler()
		]
	)

	# Example usage
	logging.info("Pipeline started")
	logging.warning("File missing header row")
	logging.error("Database connection failed")
	logging.critical("System crash detected")


	🗂 Log file generated → data_pipeline.log
	2025-10-14 10:22:13 | INFO    | Pipeline started
	2025-10-14 10:22:14 | WARNING | File missing header row
	2025-10-14 10:22:15 | ERROR   | Database connection failed


🧠 5. Combine Error Handling + Logging
   -----------------------------------
	Here’s how both come together in a data-pipeline context:
	import logging
	from azure.storage.blob import BlobServiceClient

	logging.basicConfig(
		filename='azure_pipeline.log',
		level=logging.INFO,
		format='%(asctime)s - %(levelname)s - %(message)s'
	)

	def connect_to_blob(connection_string):
		try:
			blob_service_client = BlobServiceClient.from_connection_string(connection_string)
			logging.info("Connected successfully to Azure Blob Storage.")
			return blob_service_client
		except Exception as e:
			logging.error(f"Failed to connect to Azure Blob: {e}")
			raise  # re-raise for pipeline to stop

	def list_blobs(container_client):
		try:
			blobs = [b.name for b in container_client.list_blobs()]
			logging.info(f"Found {len(blobs)} blobs.")
			return blobs
		except Exception as e:
			logging.error(f"Error listing blobs: {e}")
			return []

	# Example run
	try:
		client = connect_to_blob("invalid_connection_string")
		container_client = client.get_container_client("sales-data")
		list_blobs(container_client)
	except Exception as e:
		logging.critical(f"Pipeline failed: {e}")


🧠 6. Best Practices for Data Engineers
	| Practice                    | Description                                                                  |
	| --------------------------- | ---------------------------------------------------------------------------- |
	| ✅ Catch Specific Exceptions | Handle `FileNotFoundError`, `KeyError`, `ValueError` individually            |
	| 🚫 Avoid Bare `except:`     | Always log or re-raise errors                                                |
	| 💡 Use `finally`            | For cleanup (close connections, delete temp files)                           |
	| 🧰 Custom Exceptions        | Define meaningful errors for ETL (e.g., `DataValidationError`)               |
	| 🧾 Central Logging          | Use one logger for all pipeline components                                   |
	| 📊 Log Levels               | INFO (normal), WARNING (suspicious), ERROR (failure), CRITICAL (system down) |


✅ Selective/Generic Error Handling (Also includes File Logging-operation_log.txt)
===================================
except ZeroDivErr as e:
except TypeError  as e:
except Exception  as e:

import datetime   --Code starts from here (Above is just sample points)

def divide_and_subtract(a, b):
    log_file = "operation_log.txt"

    # Helper function to write logs
    def write_log(message):
        with open(log_file, "a") as f:
            timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            f.write(f"[{timestamp}] {message}\n")

    # --- Division Block ---
    try:
        result_div = a / b
    except ZeroDivisionError as e:
        msg = f"❌ Division error: Cannot divide by zero: {e}"
        print(msg)
        write_log(msg)
        result_div = None
    except TypeError as e:
        msg = f"❌ Division error: Invalid type: {e}"
        print(msg)
        write_log(msg)
        result_div = None
    except Exception as e:  # Generic error handling
        msg = f"⚠️ Division error: Unexpected error occurred: {e}"
        print(msg)
        write_log(msg)
        result_div = None
    else:
        msg = f"✅ Division successful! Result: {result_div}"
        print(msg)
        write_log(msg)

    # --- Subtraction Block ---
    try:
        result_sub = a - b
    except TypeError as e:
        msg = f"❌ Subtraction error: Invalid type: {e}"
        print(msg)
        write_log(msg)
        result_sub = None
    except Exception as e:  # Generic fallback
        msg = f"⚠️ Subtraction error: Unexpected error occurred: {e}"
        print(msg)
        write_log(msg)
        result_sub = None
    else:
        msg = f"✅ Subtraction successful! Result: {result_sub}"
        print(msg)
        write_log(msg)

    # --- Finally Block ---
    msg = "📘 Function execution completed.\n"
    print(msg)
    write_log(msg)

    return result_div, result_sub

Custom Exceptions
=================
Here is the custom_exceptions.py file — now with a logging system that automatically records errors (and timestamps) to a file like error.log
This version is production-grade, perfect for your Snowflake / Azure / AWS pipelines, ETL scripts, or any automation work.

"""
custom_exceptions.py
--------------------
Reusable custom exception classes for data engineering, ETL, and cloud automation.

✅ Features:
- Custom exceptions for input, file, database, and cloud errors.
- Centralized logging for consistent debugging.
- Ready for use in production data pipelines.
"""

import logging
from datetime import datetime
import os

# LOGGING CONFIGURATION
LOG_DIR = "logs"
os.makedirs(LOG_DIR, exist_ok=True)
LOG_FILE = os.path.join(LOG_DIR, "error.log")

logging.basicConfig(
    filename=LOG_FILE,
    level=logging.ERROR,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)

# CUSTOM EXCEPTION CLASSES

class InvalidInputError(Exception):
    """Raised when the input provided to a function or process is invalid."""
    def __init__(self, message="Invalid input provided"):
        super().__init__(message)


class FileProcessingError(Exception):
    """Raised when file operations (read/write/upload/download) fail."""
    def __init__(self, file_name=None, message="File processing error occurred"):
        self.file_name = file_name
        self.message = message
        super().__init__(f"{message}: {file_name}" if file_name else message)


class DataValidationError(Exception):
    """Raised when data fails to meet validation rules."""
    def __init__(self, message="Data validation failed", record_id=None):
        self.message = message
        self.record_id = record_id
        super().__init__(f"{message} (Record ID: {record_id})" if record_id else message)


class DatabaseConnectionError(Exception):
    """Raised when database connection fails."""
    def __init__(self, db_name=None, message="Database connection failed"):
        self.db_name = db_name
        self.message = message
        super().__init__(f"{message}: {db_name}" if db_name else message)


class CloudStorageError(Exception):
    """Raised when an error occurs in Azure Blob, AWS S3, or GCP Storage."""
    def __init__(self, provider=None, message="Cloud storage operation failed"):
        self.provider = provider
        self.message = message
        super().__init__(f"[{provider}] {message}" if provider else message)


class ConfigurationError(Exception):
    """Raised when configuration or environment setup is invalid."""
    def __init__(self, message="Invalid or missing configuration"):
        super().__init__(message)


class OperationTimeoutError(Exception):
    """Raised when an operation takes longer than expected."""
    def __init__(self, operation=None, message="Operation timed out"):
        self.operation = operation
        super().__init__(f"{message}: {operation}" if operation else message)


# CENTRALIZED LOGGING FUNCTION
def log_exception(e):
    """Utility to log exceptions in a consistent format."""
    error_message = f"{datetime.now()} | {type(e).__name__}: {e}"
    print(f"❌ {error_message}")          # Console print
    logging.error(f"{type(e).__name__}: {e}")  # Write to log file


✅ Example Usage
You can import this file anywhere in your project and handle all errors in one place.

from custom_exceptions import (
    FileProcessingError,
    DataValidationError,
    log_exception
)

def process_file(file_path):
    if not file_path.endswith(".csv"):
        raise FileProcessingError(file_path, "Only CSV files are supported")

    # Simulating another kind of error
    if "invalid" in file_path:
        raise DataValidationError("Corrupted data found", record_id=1234)

    print(f"Processing file: {file_path}")

try:
    process_file("invalid_data.json")
except (FileProcessingError, DataValidationError) as e:
    log_exception(e)
except Exception as e:
    log_exception(e)


Output on Console
❌ 2025-10-17 11:36:52.678920 | FileProcessingError: Only CSV files are supported: invalid_data.json
Output in log file (logs/error.log)
2025-10-17 11:36:52 | ERROR | root | FileProcessingError: Only CSV files are supported: invalid_data.json


🚀Production-Grade ETL Pipeline with Centralized Logging
========================================================
🎯 Goal
Build a complete ETL simulation that:
Handles errors with retry and custom exceptions
Uses a centralized, rotating log system
Outputs structured JSON logs for easy parsing (e.g., by Splunk, ELK, Datadog)
Provides clear success/failure visibility

🧠 Key Concepts Introduced Today
| Concept                                | Description                                       |
| -------------------------------------- | ------------------------------------------------- |
| `logging.handlers.RotatingFileHandler` | Automatically rotates logs to prevent large files |
| JSON Logging                           | Logs stored in machine-readable JSON format       |
| Retry Decorator                        | Retries transient failures (like network issues)  |
| Custom Exception Classes               | Clearly identify ETL error types                  |
| Modular ETL Functions                  | `extract`, `transform`, `load`, `main` separated  |

📘 Code: etl_production_logger.py
import os
import time
import json
import random
import logging
from logging.handlers import RotatingFileHandler

# ------------------------------------------------------------
# 1️⃣ Centralized JSON Logging Setup
# ------------------------------------------------------------
class JSONFormatter(logging.Formatter):
    """Custom JSON log formatter for structured logging."""
    def format(self, record):
        log_record = {
            "timestamp": self.formatTime(record, self.datefmt),
            "level": record.levelname,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno
        }
        return json.dumps(log_record)

# Configure rotating log handler
log_handler = RotatingFileHandler(
    "etl_pipeline.jsonlog", maxBytes=2000000, backupCount=3, encoding="utf-8"
)
log_handler.setFormatter(JSONFormatter())

# Configure root logger
logging.basicConfig(
    level=logging.INFO,
    handlers=[log_handler, logging.StreamHandler()]
)
logger = logging.getLogger(__name__)

# ------------------------------------------------------------
# 2️⃣ Custom Exception Classes
# ------------------------------------------------------------
class FileReadError(Exception):
    """Raised when a file cannot be read."""
    pass

class DataValidationError(Exception):
    """Raised when transformation fails validation."""
    pass

class LoadError(Exception):
    """Raised when data fails to load."""
    pass

# ------------------------------------------------------------
# 3️⃣ Retry Decorator (for transient failures)
# ------------------------------------------------------------
def retry(max_attempts=3, delay=2):
    """Retry decorator for unstable operations."""
    def decorator(func):
        def wrapper(*args, **kwargs):
            for attempt in range(1, max_attempts + 1):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    logger.warning(f"Attempt {attempt}/{max_attempts} failed: {e}")
                    if attempt == max_attempts:
                        logger.critical(f"All attempts failed for {func.__name__}")
                        raise
                    time.sleep(delay)
        return wrapper
    return decorator

# ------------------------------------------------------------
# 4️⃣ ETL Steps (Extract, Transform, Load)
# ------------------------------------------------------------
@retry(max_attempts=3)
def extract_files(data_dir):
    """Simulates file extraction from local or Azure Blob folder."""
    try:
        if not os.path.exists(data_dir):
            raise FileNotFoundError(f"Source directory not found: {data_dir}")

        files = os.listdir(data_dir)
        if not files:
            raise FileReadError("No files available for processing")

        logger.info(f"Found {len(files)} files for extraction.")
        return files
    except Exception as e:
        logger.error(f"Extraction failed: {e}")
        raise FileReadError(e)

def transform_data(file_name):
    """Simulates data transformation step with random failures."""
    try:
        # Randomly simulate bad data
        if random.choice([True, False]):
            raise DataValidationError(f"Invalid data detected in {file_name}")

        transformed_data = {
            "file": file_name,
            "records_processed": random.randint(50, 500),
            "status": "SUCCESS"
        }
        logger.info(f"Transformed file successfully: {file_name}")
        return transformed_data
    except DataValidationError as e:
        logger.warning(f"Data validation failed for {file_name}: {e}")
        return {"file": file_name, "records_processed": 0, "status": "FAILED"}

@retry(max_attempts=2)
def load_data(transformed_records):
    """Simulates loading data into Snowflake or Data Warehouse."""
    try:
        success_count = sum(1 for rec in transformed_records if rec["status"] == "SUCCESS")
        if success_count == 0:
            raise LoadError("No valid transformed data available for load")

        logger.info(f"Loaded {success_count} files successfully into Snowflake.")
    except Exception as e:
        logger.error(f"Load step failed: {e}")
        raise LoadError(e)

# ------------------------------------------------------------
# 5️⃣ Main Pipeline Controller
# ------------------------------------------------------------
def run_pipeline():
    """Main orchestration logic for the ETL job."""
    data_dir = "sample_data"

    logger.info("🚀 ETL Pipeline started.")
    try:
        # Step 1: Extract
        files = extract_files(data_dir)

        # Step 2: Transform
        transformed = [transform_data(f) for f in files]

        # Step 3: Load
        load_data(transformed)

        logger.info("🎯 ETL Pipeline completed successfully!")
    except Exception as e:
        logger.critical(f"💥 Pipeline failed: {e}")
    finally:
        logger.info("📘 ETL job finished.\n")

# ------------------------------------------------------------
# 6️⃣ Entry Point
# ------------------------------------------------------------
if __name__ == "__main__":
    run_pipeline()


🧾 Example Log Output (etl_pipeline.jsonlog)
Each log entry is JSON formatted, making it searchable & machine-readable.
{"timestamp": "2025-10-14 21:50:10", "level": "INFO", "message": "🚀 ETL Pipeline started.", "module": "etl_production_logger", "function": "run_pipeline", "line": 113}
{"timestamp": "2025-10-14 21:50:10", "level": "INFO", "message": "Found 4 files for extraction.", "module": "etl_production_logger", "function": "extract_files", "line": 62}
{"timestamp": "2025-10-14 21:50:10", "level": "WARNING", "message": "Data validation failed for sales_2025_10_12.csv: Invalid data detected in sales_2025_10_12.csv", "module": "etl_production_logger", "function": "transform_data", "line": 78}
{"timestamp": "2025-10-14 21:50:10", "level": "INFO", "message": "Loaded 3 files successfully into Snowflake.", "module": "etl_production_logger", "function": "load_data", "line": 95}
{"timestamp": "2025-10-14 21:50:10", "level": "INFO", "message": "🎯 ETL Pipeline completed successfully!", "module": "etl_production_logger", "function": "run_pipeline", "line": 119}


⚙️ Setup Instructions
Create a folder:
sample_data/
├── sales_2025_10_13.csv
├── sales_2025_10_14.csv
├── report.csv
└── test_data.csv

Run the pipeline:
python etl_production_logger.py

Check:
Console output
etl_pipeline.jsonlog (rotates after ~2MB)

💡 Real-World Usage
| Environment     | Integration                                        |
| --------------- | -------------------------------------------------- |
| Azure           | Push logs to Application Insights                  |
| AWS             | Send logs to CloudWatch                            |
| GCP             | Export logs to Stackdriver                         |
| Snowflake Tasks | Wrap `run_pipeline()` in a task for scheduled runs |
