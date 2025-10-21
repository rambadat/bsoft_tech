Functions/Lambda,Map,Filter,Reduce Functions/Modular Programming/Azure Interaction
==================================================================================
Functions
=========
A function is a block of reusable code that performs a specific task.

def   → defines a function
greet → the function name
()    → parentheses (can include parameters)
:     → indicates the start of the function body

🧠 Basic Syntax
def function_name(parameters):
    # Function body
    return value

✅ Example 1 – A simple greeting function
def greet(name):
    return f"Hello, {name}!"

# Function call
print(greet("Prajeesh"))


🧾 Output:
Hello, Prajeesh!

-Parameters & Return Values
-Default Arguments
-Keyword Arguments
-Variable-Length Arguments
-Return Multiple Values
-Global vs Local Variables
-Docstrings and Type Hints


🧩 Function with Parameters & Return Values
-------------------------------------------
Functions can take inputs (parameters) and give outputs (return values).

def add_numbers(a, b):
    return a + b

result = add_numbers(5, 10)
print("Sum is:", result)


🧾 Output:
Sum is: 15

✅ Here, a and b are parameters, and the value passed during function call (5, 10) are arguments.


🧩 Default Arguments
--------------------
Default values are used when you don’t pass arguments.

def power(base, exponent=2):
    return base ** exponent

print(power(5))       # Uses default exponent = 2
print(power(5, 3))    # Override default


🧾 Output:
25
125

🧩 Keyword Arguments (Named Notation)
--------------------
You can pass arguments in any order using keywords.

def student_info(name, course, city):
    print(f"Name: {name}, Course: {course}, City: {city}")

student_info(course="Python", name="Prajeesh", city="Bangalore")


🧾 Output:
Name: Prajeesh, Course: Python, City: Bangalore


🧩 Variable-Length Arguments
----------------------------
When you don’t know how many arguments will be passed:

Use *args 	 → for variable positional arguments
Use **kwargs → for variable keyword arguments

def display_skills(name, *skills, **details):
    print("Name:", name)
    print("Skills:", skills)
    print("Details:", details)

display_skills("Prajeesh", "Python", "Snowflake", "DBT", location="Kerala", role="Data Engineer")


🧾 Output:
Name: Prajeesh
Skills: ('Python', 'Snowflake', 'DBT')
Details: {'location': 'Kerala', 'role': 'Data Engineer'}


| Feature       | `*args`                                                          | `**kwargs`                                               |
| ------------- | ---------------------------------------------------------------- | -------------------------------------------------------- |
| Collects      | Extra **positional arguments**                                   | Extra **keyword arguments**                              |
| Data Type     | Tuple                                                            | Dictionary                                               |
| Syntax        | Asterisk `*`                                                     | Double Asterisk `**`                                     |
| Example Usage | `("Python", "Snowflake", "DBT")`                                 | `{"location": "Kerala", "role": "Data Engineer"}`        |
| When to Use   | When you don’t know how many positional arguments will be passed | When you don’t know which named arguments will be passed |


🧩 Return Multiple Values
-------------------------
Functions can return multiple items (usually as a tuple).

def calc(a, b):
    return a + b, a - b, a * b

sum_, diff, prod = calc(10, 5)
print(sum_, diff, prod)


🧾 Output:
15 5 50


🧩 Global vs Local Variables
----------------------------
Local variables  → Exist only inside the function.
Global variables → Exist everywhere.

count = 100  # global

def increment():
    global count  --This means “Hey Python, I want to use the global variable named count — not create a new local one.”
    count += 1
    print("Inside function:", count)

increment()
print("Outside function:", count)


🧾 Output:
Inside function: 101
Outside function: 101

🧩 Docstrings and Type Hints
----------------------------
Python allows you to document and annotate functions clearly (Same what we do in top portion of unix shell script like comment)

def multiply(a, b):
    """
    Multiply two numbers and return the result.

    Args:
        a (int): First number
        b (int): Second number

    Returns:
        int: Product of the two numbers
    """
    return a * b


print(multiply(4, 5))


🧾 Output:
20


✅ Docstrings make your code readable, and type hints are super helpful for teams and IDEs.


🧩 Practical Example for Data Engineers
=======================================
Here’s a function that reads a CSV and counts records (simulated for now):

def read_csv_file(file_name):
    """Reads a CSV file and returns basic info."""
    print(f"Reading file: {file_name}")
    # Simulating record count
    record_count = 5000
    return {"file_name": file_name, "records": record_count}

info = read_csv_file("sales_data.csv")
print(info)


🧾 Output:
Reading file: sales_data.csv
{'file_name': 'sales_data.csv', 'records': 5000}


✅ Summary:

| Concept          | Example                                    |
| ---------------- | ------------------------------------------ |
| Simple function  | `def greet(name): return f"Hello, {name}"` |
| Default args     | `def power(a, b=2)`                        |
| *args / **kwargs | `def f(*args, **kwargs)`                   |
| Multiple returns | `return x, y, z`                           |
| Global variable  | `global var_name`                          |
| Docstring        | `"""This function..."""`                   |
| Type hint        | `def add(a: int, b: int) -> int`           |


Lambda, Map, Filter, and Reduce (Compact version of earlier traditional approach of using loops)
===============================
These are part of Python’s functional programming toolkit — i.e., they let you write compact and expressive data transformations without traditional loops.

🧩 Lambda Functions (Anonymous Functions)
	A lambda function is a one-line, unnamed (anonymous) function.
	-Used for short, throwaway functions
	-Typically used with map(), filter(), and reduce()


	✅ Syntax:
	lambda arguments: expression

	🧠 Example 1: Simple lambda
	square = lambda x: x ** 2
	print(square(5))  --25

	🧠 Example 2: Multiple arguments
	add = lambda a, b: a + b
	print(add(10, 15)) --
	
	
	🧠 Example 3: Cleaning up the data (DataFrame Using Pandas library)
	import pandas as pd

	df = pd.DataFrame({
		"city": ["kochi", "Bangalore", "CHENNAI"],
		"population": [2.1, 12.3, 8.7]
	})
	
	df["city"] = df["city"].apply(lambda x: x.strip().title())
    print(df)
	
	        city  population
	0      Kochi         2.1
	1  Bangalore        12.3
	2    Chennai         8.7


	df["category"] = df["population"].apply(lambda x: "Metro" if x > 5 else "Non-Metro")
	print(df)

			city  population  category
	0      Kochi         2.1  Non-Metro
	1  Bangalore        12.3     Metro
	2    Chennai         8.7     Metro
	
	| Function      | Purpose                                                                                       | Example               | Output    |
	| ------------- | --------------------------------------------------------------------------------------------- | --------------------- | --------- |
	| **`strip()`** | Removes **extra spaces** from the beginning and end of a string.                              | `"  kochi  ".strip()` | `'kochi'` |
	| **`title()`** | Converts the **first letter of every word** to uppercase, and all other letters to lowercase. | `'kochi'.title()`     | `'Kochi'` |
	
	The apply() function is used to apply a function (built-in, user-defined, or lambda) to each element (or row/column) of a Pandas Series or DataFrame.

🧩 map() – Apply a Function to All Elements
	The map() function applies a given function to every element in an iterable (like a list).

	✅ Syntax:
	map(function, iterable)

	🧠 Example 1: Square every number
	nums = [1, 2, 3, 4, 5]
	squares = list(map(lambda x: x ** 2, nums))
	print(squares)   --[1, 4, 9, 16, 25]
	
	🧠 Example 2: Convert strings to uppercase
	names = ["prajeesh", "arun", "deepa"]
	upper_names = list(map(lambda x: x.upper(), names))
	print(upper_names)  --['PRAJEESH', 'ARUN', 'DEEPA']	
	

🧩 filter() – Select Items Matching a Condition
	The filter() function filters out elements that don’t satisfy a given condition.

	✅ Syntax:
	filter(function, iterable)

	🧠 Example 1: Filter even numbers
	nums = [10, 15, 20, 25, 30]
	evens = list(filter(lambda x: x % 2 == 0, nums))
	print(evens)  --[10, 20, 30]

	🧠 Example 2: Filter file names with .csv
	files = ["sales.csv", "data.json", "products.csv", "notes.txt"]
	csv_files = list(filter(lambda f: f.endswith(".csv"), files))
	print(csv_files) --['sales.csv', 'products.csv']

	✅ Perfect for data engineers processing file lists from Azure Blob or S3.	
	
	
🧩 reduce() – Combine All Elements into One
	The reduce() function applies a function cumulatively to elements of a list.
	It’s not built-in — you import it from the functools module.

	✅ Syntax:
	from functools import reduce
	reduce(function, iterable)

	🧠 Example 1: Sum all numbers
	from functools import reduce

	nums = [10, 20, 30, 40]
	total = reduce(lambda a, b: a + b, nums)
	print(total) --100

	🧠 Example 2: Find the largest number
	from functools import reduce

	nums = [5, 9, 3, 12, 7]
	largest = reduce(lambda a, b: a if a > b else b, nums)
	print(largest)  --12
	

	Summary
	-------
	lambda   : one-line, unnamed (anonymous) function typically used with map,filter and reduce
	map()	 : Applies a given function -> to every element in an iterable (like a list)
	filter() : Filters out elements that don’t satisfy a given condition
	reduce() : Combine (cumulatively) All Elements into One



🧩 Practical ETL Example – Filter and Transform File List
=========================================================
	from functools import reduce

	files = ["sales_2024.csv", "data.json", "products_2024.csv", "log.txt"]

	# Filter only CSV files
	csv_files = list(filter(lambda f: f.endswith(".csv"), files))    --using lambda and filter, list keyword here converts the filter object into a list
																	 --The filter() function goes through each element in the files list.
																	 --The lambda function returns True if the file name ends with .csv, otherwise False.
																	 --So, filter() will keep only those items that return True.

	# Remove extensions
	file_names = list(map(lambda f: f.replace(".csv", ""), csv_files))

	# Count total files
	file_count = reduce(lambda a, b: a + 1, csv_files, 0)

	print("CSV Files:", csv_files)
	print("Names:", file_names)
	print("Total Count:", file_count)


	🧾 Output:
	CSV Files: ['sales_2024.csv', 'products_2024.csv']
	Names: ['sales_2024', 'products_2024']
	Total Count: 2	
	
	
	
⚙️ Summary Table
| Concept    | Description                        | Example                         |
| ---------- | ---------------------------------- | ------------------------------- |
| `lambda`   | One-line anonymous function        | `lambda x: x*2`                 |
| `map()`    | Applies function to every element  | `map(lambda x: x+1, list)`      |
| `filter()` | Keeps elements meeting a condition | `filter(lambda x: x>0, list)`   |
| `reduce()` | Combines all elements into one     | `reduce(lambda a,b: a+b, list)` |

✅ Key Takeaways for Data Engineers
lambda + map → quick transformations on lists/records
filter 		 → helps clean or select relevant data
reduce 		 → useful for aggregation (sum, max, concat, etc.)
They make your data processing pipelines more compact and efficient

Modular Programming
===================
Modular programming is the practice of dividing a program into independent, reusable pieces (modules).
-Each module handles a specific functionality
-Helps in code reuse, maintainability, and team collaboration

Example:
-blob_utils.py 			→ Functions for Azure Blob operations
-snowflake_utils.py 	→ Functions for Snowflake connections and queries
-main_etl.py	 		→ The main ETL logic that uses the above modules

🧩 Creating a Module
	Any Python file (.py) is a module.

	Step 1: Create a file math_utils.py
	# math_utils.py

	def add(a, b):
		return a + b

	def subtract(a, b):
		return a - b

	PI = 3.14159


🧩 Importing Modules
	Method 1: Import entire module
	import math_utils

	print(math_utils.add(5, 3))  --8
	print(math_utils.PI)         --3.14159
	

	Method 2: Import specific functions or variables
	from math_utils import add, PI

	print(add(10, 7))  --17
	print(PI)		   --3.14159


	Method 3: Import with alias
	import math_utils as mu

	print(mu.subtract(20, 5))	--15
	
	
🧩 Using __name__ == "__main__"
	Allows a module to be run as a script or imported without executing its main code

	# math_utils.py
	def multiply(a, b):
		return a * b

	if __name__ == "__main__":
		print("Testing multiply:", multiply(3, 4))

	When imported in another file, the test block won’t run
	

🧩 Understanding __name__ == "__main__"
	1) math_utils.py
	This is your reusable module — it defines reusable functions and constants:

	# math_utils.py
	def add(a, b):
		return a + b

	def subtract(a, b):
		return a - b

	def multiply(a, b):
		return a * b

	PI = 3.14159

	# This section only runs when this file is executed directly
	if __name__ == "__main__":                         # This block __name__=="__main__" is not that much important. This can be completely ignored or deleted
		print("Testing functions inside math_utils:")  # To be only used for Testing by calling this file directly at command prompt as
		print("Add:", add(10, 5))					   # python math_utils.py
		print("Subtract:", subtract(10, 5))
		print("Multiply:", multiply(10, 5))


	✅ If you run:
	python math_utils.py

	Output:
	Testing functions inside math_utils:
	Add: 15
	Subtract: 5
	Multiply: 50


	2) main_program.py
	Now, this is your driver script — it imports and uses functions from math_utils.py:

	# main_program.py
	# Option 1: import entire module
	import math_utils

	result1 = math_utils.add(20, 10)
	result2 = math_utils.subtract(50, 25)

	print("Addition result:", result1)
	print("Subtraction result:", result2)
	print("PI value:", math_utils.PI)

	# Option 2: import specific items
	from math_utils import multiply, PI

	print("Multiply result:", multiply(5, 6))
	print("PI value (again):", PI)

	✅ Run:
	python main_program.py

	Output :
	Addition result: 30
	Subtraction result: 25
	PI value: 3.14159
	Multiply result: 30
	PI value (again): 3.14159


| Concept                      | Meaning                                                                               | Example
| ---------------------------- | ------------------------------------------------------------------------------------- | -----------------------------------
| **Module**                   | A file (`.py`) that contains Python code (functions, variables, etc.)                 | `math_utils.py
| **Import**                   | To use functions/variables from another module                                        | `import math_utils
| **`__name__ == "__main__"`** | Ensures test code runs **only when the file is executed directly**, not when imported | Protects against accidental execution
| **Reusability**              | You can use the same module in multiple scripts                                       | For example, `data_cleaning_utils.py`



🧩 Practical Data Engineering Example
	Step 1: Create blob_utils.py
	# blob_utils.py

	def list_csv_files(files):
		"""Filter CSV files from list."""
		return [f for f in files if f.endswith(".csv")]   --it iterates each element in files list and filters csv only

	def count_files(files):
		"""Return the count of files."""
		return len(files)

	if __name__ == "__main__":
		files = ["sales.csv", "data.json", "inventory.csv"]
		print("CSV Files:", list_csv_files(files))
		print("Total files:", count_files(files))



	Step 2: Use it in main_etl.py
	# main_etl.py

	from blob_utils import list_csv_files, count_files

	files = ["sales_2025.csv", "returns_2025.csv", "products.json"]

	csv_files = list_csv_files(files)
	print("CSV files:", csv_files)
	print("Number of CSV files:", count_files(csv_files))


	🧾 Output:
	CSV files: ['sales_2025.csv', 'returns_2025.csv']
	Number of CSV files: 2
	
	✅ This shows how functions are reused across files — the essence of modular programming.
	

🧩 Organizing a Project Structure
	data_engineering_project/
	│
	├── blob_utils.py        # Functions for blob operations
	├── snowflake_utils.py   # Functions for Snowflake connectivity
	├── main_etl.py          # Main ETL script
	├── config.py            # Configuration (paths, credentials)
	└── requirements.txt     # Python dependencies

	Keeps your code clean, maintainable, and team-friendly
	Easy to scale and integrate into larger pipelines	
	
🧩 Key Takeaways	
| Concept                  | Description                                   |
| ------------------------ | --------------------------------------------- |
| Module                   | Any `.py` file with functions or classes      |
| Import                   | Bring module functionality into another file  |
| `__name__ == "__main__"` | Makes code reusable and testable              |
| Project structure        | Organize files for modular, maintainable code |
| Reuse                    | Functions in modules can be called anywhere   |

✅ By now, after Day 4, you should be able to:
-Write reusable functions
-Use lambda, map, filter, reduce for compact data transformation
-Organize your code into modules
-Build a mini ETL pipeline with modular structure


🧩 Write the code to fetch all the available files in azure blob storage into list or tuple
===========================================================================================
https://docs.azure.cn/en-us/storage/blobs/storage-quickstart-blobs-python?tabs=managed-identity%2Croles-azure-portal%2Csign-in-azure-cli

sample:
def upload_blob_file(self, blob_service_client: BlobServiceClient, container_name: str):
    
	container_client = blob_service_client.get_container_client(container=container_name)
	
    with open(file=os.path.join('filepath', 'filename'), mode="rb") as data:
        blob_client  = container_client.upload_blob(name="sample-blob.txt", data=data, overwrite=True)

✅ Final Design
We will build three clean functions:
| Function                 | Purpose                                                                      |
| ------------------------ | ---------------------------------------------------------------------------- |
| `list_csv_files()`       | List all CSVs in Azure Blob Storage and separate today’s and older files     |
| `archive_old_files()`    | Move old CSV files to `/archive/` folder                                     |
| `purge_archived_files()` | Verify and delete source files only after confirming the archive copy exists |

pip install azure-storage-blob  --install the required library

--Code begins
from azure.storage.blob import BlobServiceClient
from datetime import datetime, timezone

# === Configuration ===
CONNECTION_STRING = "<your_connection_string_here>"
CONTAINER_NAME 		= "<your_container_name_here>"
ARCHIVE_FOLDER 		= "archive/"  # Folder name within container


def list_csv_files(connection_string, container_name):
    """
    Lists all CSV files in the Azure Blob container and separates today's vs older files.
    """
    blob_service_client = BlobServiceClient.from_connection_string(connection_string)
    container_client 	= blob_service_client.get_container_client(container_name)

    today = datetime.now(timezone.utc).date()
    today_files = []
    old_files = []

    print(f"📅 Listing CSV files and separating by date ({today})...\n")

    for blob in container_client.list_blobs():
        if blob.name.endswith(".csv"):
            blob_date = blob.last_modified.date()
            if blob_date == today:
                today_files.append(blob.name)
            else:
                old_files.append(blob.name)

    print(f"✅ Found {len(today_files)} today's files and {len(old_files)} old files.\n")
    return today_files, old_files


def archive_old_files(connection_string, container_name, archive_folder, old_files):
    """
    Archives old CSV files by copying them to archive folder.
    """
    if not old_files:
        print("📦 No old files to archive.")
        return

    blob_service_client = BlobServiceClient.from_connection_string(connection_string)
    container_client = blob_service_client.get_container_client(container_name)

    for old_file in old_files:
        source_blob_url = f"https://{blob_service_client.account_name}.blob.core.windows.net/{container_name}/{old_file}"
        archive_blob_name = f"{archive_folder}{old_file.split('/')[-1]}"

        print(f"📤 Archiving: {old_file} → {archive_blob_name}")
        archive_blob_client = container_client.get_blob_client(archive_blob_name)
        copy_status = archive_blob_client.start_copy_from_url(source_blob_url)

        # Optional check: wait until copy completes (optional for large files)
        props = archive_blob_client.get_blob_properties()
        if props.copy.status != 'success':
            print(f"⚠️ Copy pending or failed for {old_file}, skipping deletion for now.")
        else:
            print(f"✅ Copy completed for {old_file}.")

    print("\n✅ Archiving process completed.\n")


def purge_archived_files(connection_string, container_name, archive_folder, old_files):
    """
    Deletes original files only if they exist in archive location.
    """
    if not old_files:
        print("🧹 No files to purge.")
        return

    blob_service_client = BlobServiceClient.from_connection_string(connection_string)
    container_client = blob_service_client.get_container_client(container_name)

    print("🧾 Checking archived files before purge...\n")

    for old_file in old_files:
        archive_blob_name = f"{archive_folder}{old_file.split('/')[-1]}"
        archive_blob_client = container_client.get_blob_client(archive_blob_name)

        if archive_blob_client.exists():
            print(f"🗑️ Purging: {old_file}")
            container_client.delete_blob(old_file)
        else:
            print(f"⚠️ Skipping purge for {old_file} — not found in archive.")

    print("\n✅ Purge process completed.\n")


if __name__ == "__main__":
    today_files, old_files = list_csv_files(CONNECTION_STRING, CONTAINER_NAME)
    archive_old_files(CONNECTION_STRING, CONTAINER_NAME, ARCHIVE_FOLDER, old_files)
    purge_archived_files(CONNECTION_STRING, CONTAINER_NAME, ARCHIVE_FOLDER, old_files)

    print(f"📊 Summary:")
    print(f"   Today's Files: {today_files}")
    print(f"   Archived & Purged: {old_files}")


🧾 Sample Output
📅 Listing CSV files and separating by date (2025-10-14)...

✅ Found 2 todays files and 3 old files.

📤 Archiving: sales_2025_10_13.csv → archive/sales_2025_10_13.csv
✅ Copy completed for sales_2025_10_13.csv
📤 Archiving: customers_2025_10_12.csv → archive/customers_2025_10_12.csv
✅ Copy completed for customers_2025_10_12.csv
✅ Archiving process completed.

🧾 Checking archived files before purge...

🗑️ Purging: sales_2025_10_13.csv
🗑️ Purging: customers_2025_10_12.csv
✅ Purge process completed.

📊 Summary:
   Todays Files: ['sales_2025_10_14.csv', 'inventory_2025_10_14.csv']
   Archived & Purged: ['sales_2025_10_13.csv', 'customers_2025_10_12.csv']



🧩 Mini Data Pipeline Project: File Processing & Summary
=========================================================
Scenario:
You have a folder with files from Azure Blob (simulated as a list). You need to:
1.Filter only CSV files
2.Extract base names (remove .csv)
3.Count the files
4.Generate a summary report
5.Organize everything into modules for reuse

Step 1: Project Structure
	mini_pipeline/
	│
	├── blob_utils.py        # Functions to handle file operations
	├── report_utils.py      # Functions to generate summary
	├── main_pipeline.py     # Main pipeline script
	└── config.py            # Optional: store config variables

Step 2: Module – blob_utils.py
	# blob_utils.py

	def filter_csv_files(files):
		"""Return list of CSV files."""
		return list(filter(lambda f: f.endswith(".csv"), files))

	def extract_base_names(files):
		"""Remove .csv extension from filenames."""
		return list(map(lambda f: f.replace(".csv", ""), files))

	def count_files(files):
		"""Return the number of files."""
		return len(files)

	# Test block
	if __name__ == "__main__":
		test_files = ["sales.csv", "data.json", "inventory.csv"]
		print("CSV Files:", filter_csv_files(test_files))
		print("Base Names:", extract_base_names(filter_csv_files(test_files)))
		print("Count:", count_files(test_files))


Step 3: Module – report_utils.py
	# report_utils.py

	from functools import reduce

	def generate_summary(file_list):
		"""Generate summary string for list of files."""
		count = len(file_list)
		all_files = reduce(lambda a, b: a + ", " + b, file_list) if file_list else "No files"
		return f"Total Files: {count}\nFiles: {all_files}"

	# Test block
	if __name__ == "__main__":
		files = ["sales", "inventory"]
		print(generate_summary(files))

Step 4: Main Pipeline – main_pipeline.py
	# main_pipeline.py

	from blob_utils import filter_csv_files, extract_base_names, count_files
	from report_utils import generate_summary

	# Simulated Azure Blob files
	files = [
		"sales_2025.csv",
		"returns_2025.csv",
		"products.json",
		"logfile.txt",
		"inventory_2025.csv"
	]

	# Step 1: Filter CSV files
	csv_files = filter_csv_files(files)

	# Step 2: Extract base names
	base_names = extract_base_names(csv_files)

	# Step 3: Count CSV files
	file_count = count_files(csv_files)

	# Step 4: Generate summary report
	report = generate_summary(base_names)

	# Step 5: Display report
	print(report)


🧾 Expected Output:
Total Files: 3
Files: sales_2025, returns_2025, inventory_2025


✅ What This Mini Pipeline Demonstrates
| Concept                         | Example in Project                                                |
| ------------------------------- | ----------------------------------------------------------------- |
| **Functions**                   | `filter_csv_files()`, `extract_base_names()`, `count_files()`     |
| **Lambda, map, filter, reduce** | `filter()`, `map()`, `reduce()`                                   |
| **Modular Programming**         | Separate `.py` files, imported in `main_pipeline.py`              |
| **Reusable Code**               | Any new file list can be processed without changing the functions |
| **Docstrings & Type Hints**     | Documented functions for clarity                                  |


This is essentially a realistic mini-ETL workflow:
-Input → Transformation → Aggregation → Summary/Report
-Fully modular and reusable


❄️ Full Azure-to-Snowflake Mini Data Pipeline Project  
=====================================================
📊 Workflow Overview
| Step | Task                                | Tool                 |
| ---- | ----------------------------------- | -------------------- |
| 1    | List & classify CSVs (today vs old) | Azure SDK            |
| 2    | Load todays CSVs into Snowflake     | Snowpark / COPY INTO |
| 3    | Archive old files to `/archive/`    | Azure SDK            |
| 4    | Purge verified files                | Azure SDK            |
| 5    | Log all activity & summary          | Python `logging`     |

***Azure Blob → Snowflake → Archive → Purge → Log***

from azure.storage.blob import BlobServiceClient
from snowflake.snowpark import Session
from datetime import datetime, timezone
import logging

# === CONFIGURATION ===
CONNECTION_STRING = "<your_azure_connection_string>"
CONTAINER_NAME = "<your_container_name>"
ARCHIVE_FOLDER = "archive/"
SNOWFLAKE_CONFIG = {
    "account": "<your_account>",
    "user": "<your_user>",
    "password": "<your_password>",
    "warehouse": "<your_warehouse>",
    "database": "<your_database>",
    "schema": "<your_schema>",
    "role": "<your_role>",
}
STAGE_NAME = "@azure_stage"   # External Stage already created in Snowflake
TABLE_NAME = "stg_sales_data"  # Snowflake target table

LOG_FILE = "pipeline_log.txt"
logging.basicConfig(filename=LOG_FILE, level=logging.INFO,
                    format="%(asctime)s - %(levelname)s - %(message)s")


# 🔹 Function 1: List todays and old CSV files
-----------------------------------------------
def list_csv_files(connection_string, container_name):
    blob_service_client = BlobServiceClient.from_connection_string(connection_string)
    container_client = blob_service_client.get_container_client(container_name)

    today = datetime.now(timezone.utc).date()
    today_files, old_files = [], []

    print(f"\n📅 Scanning container '{container_name}' for CSV files...\n")

    for blob in container_client.list_blobs():
        if blob.name.endswith(".csv"):
            blob_date = blob.last_modified.date()
            if blob_date == today:
                today_files.append(blob.name)
            else:
                old_files.append(blob.name)

    print(f"✅ Found {len(today_files)} today's files and {len(old_files)} old files.\n")
    logging.info(f"Today's Files: {today_files}")
    logging.info(f"Old Files: {old_files}")
    return today_files, old_files


# 🔹 Function 2: Load todays files into Snowflake
--------------------------------------------------
def load_to_snowflake(snowflake_config, stage_name, table_name, today_files):
    if not today_files:
        print("📂 No todays files to load into Snowflake.")
        logging.info("No today's files to load.")
        return

    print("❄️ Connecting to Snowflake and loading data...\n")
    session = Session.builder.configs(snowflake_config).create()

    for file in today_files:
        copy_query = f"""
        COPY INTO {table_name}
        FROM {stage_name}/{file}
        FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY='"' SKIP_HEADER=1)
        ON_ERROR = 'CONTINUE';
        """
'        print(f"📥 Loading file: {file}")
        session.sql(copy_query).collect()
        logging.info(f"Loaded {file} into Snowflake table {table_name}")

    print("\n✅ Snowflake load completed.\n")
    session.close()


# 🔹 Function 3: Archive old CSVs
---------------------------------
def archive_old_files(connection_string, container_name, archive_folder, old_files):
    if not old_files:
        print("📦 No old files to archive.\n")
        return

    blob_service_client = BlobServiceClient.from_connection_string(connection_string)
    container_client = blob_service_client.get_container_client(container_name)

    print("🚀 Archiving old files...\n")

    for old_file in old_files:
        source_blob_url = f"https://{blob_service_client.account_name}.blob.core.windows.net/{container_name}/{old_file}"
        archive_blob_name = f"{archive_folder}{old_file.split('/')[-1]}"
        archive_blob_client = container_client.get_blob_client(archive_blob_name)
        archive_blob_client.start_copy_from_url(source_blob_url)

        props = archive_blob_client.get_blob_properties()
        if props.copy.status == "success":
            print(f"✅ Archived: {old_file}")
            logging.info(f"Archived {old_file}")
        else:
            print(f"⚠️ Archive failed for: {old_file}")
            logging.warning(f"Archive failed for {old_file}")

    print("\n✅ Archiving process completed.\n")



# 🔹 Function 4: Purge old files after archive verification
-----------------------------------------------------------
def purge_archived_files(connection_string, container_name, archive_folder, old_files):
    if not old_files:
        print("🧹 No files to purge.\n")
        return

    blob_service_client = BlobServiceClient.from_connection_string(connection_string)
    container_client = blob_service_client.get_container_client(container_name)

    print("🧾 Validating and purging archived files...\n")

    for old_file in old_files:
        archive_blob_name = f"{archive_folder}{old_file.split('/')[-1]}"
        archive_blob_client = container_client.get_blob_client(archive_blob_name)

        if archive_blob_client.exists():
            container_client.delete_blob(old_file)
            print(f"🗑️ Purged: {old_file}")
            logging.info(f"Purged {old_file}")
        else:
            print(f"⚠️ Skipping purge — archive missing for {old_file}")
            logging.warning(f"Skipped purge for {old_file}")

    print("\n✅ Purge process completed.\n")



# 🔹 Function 5: Generate pipeline summary
------------------------------------------
def generate_summary(today_files, old_files):
    print("📊 --- PIPELINE SUMMARY ---")
    print(f"Date: {datetime.now().date()}")
    print(f"Todays Files: {today_files if today_files else 'None'}")
    print(f"Archived & Purged: {old_files if old_files else 'None'}")
    print("--------------------------------------\n")

    logging.info(f"SUMMARY - Today's Files: {today_files}")
    logging.info(f"SUMMARY - Archived & Purged: {old_files}")



# 🚀 MAIN PIPELINE
---------------------
if __name__ == "__main__":
    print("🔧 Starting Azure → Snowflake Mini Data Pipeline...\n")

    today_files, old_files = list_csv_files(CONNECTION_STRING, CONTAINER_NAME)
    load_to_snowflake(SNOWFLAKE_CONFIG, STAGE_NAME, TABLE_NAME, today_files)
    archive_old_files(CONNECTION_STRING, CONTAINER_NAME, ARCHIVE_FOLDER, old_files)
    purge_archived_files(CONNECTION_STRING, CONTAINER_NAME, ARCHIVE_FOLDER, old_files)
    generate_summary(today_files, old_files)

    print("🎯 Pipeline execution completed successfully!")




🚀 Project: Azure Blob File Processing & Summary (ETL Simulation)
=================================================================
🎯 Objective

We’ll build a modular pipeline that:
-Connects to Azure Blob Storage
-Lists all files in a container
-Filters CSV, JSON, and Parquet files
-Generates a categorized summary report
-Uses functions + modular programming

Tech Stack: Azure Blob Storage • Snowflake • Snowpark Python
✅ Enhancements included
Uses Azure SDK for blob operations
Separates logic into functions:
list_files() 	→ fetch all files & split into today’s vs others
archive_files() → move files from raw → archive folder
purge_files() 	→ delete already archived files from raw
Integrated with Snowflake External Stage + Storage Integration + File Format
Adds logging, error handling, and config centralization


🧠 Project Structure
azure_snowflake_pipeline/
│
├── config.json
├── pipeline.py
├── setup.sql
└── requirements.txt


📘 config.json
{
  "azure": {
    "connection_string": "DefaultEndpointsProtocol=https;AccountName=yourstorageaccount;AccountKey=yourkey;EndpointSuffix=core.windows.net",
    "container_name": "sales-data",
    "raw_folder": "raw/",
    "archive_folder": "archive/"
  },
  "snowflake": {
    "account": "your_account_identifier",
    "user": "your_user",
    "password": "your_password",
    "role": "DEVELOPER_ROLE",
    "warehouse": "COMPUTE_WH",
    "database": "SALES_DB",
    "schema": "STAGING",
    "stage": "azure_stage_sales",
    "file_format": "sales_csv_format",
    "target_table": "stg_sales_data"
  }
}

📦 pipeline.py
import os
import datetime
import logging
import json
from azure.storage.blob import BlobServiceClient
import snowflake.snowpark as snowpark
from snowflake.snowpark.functions import col

# ------------------------------------------------------------
# 1️⃣ Logging Setup
# ------------------------------------------------------------
logging.basicConfig(
    filename='pipeline_log.txt',
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# ------------------------------------------------------------
# 2️⃣ Load Configuration
# ------------------------------------------------------------
with open("config.json") as cfg:
    CONFIG = json.load(cfg)

AZURE_CFG = CONFIG["azure"]
SNOW_CFG = CONFIG["snowflake"]

# ------------------------------------------------------------
# 3️⃣ Azure Connection Setup
# ------------------------------------------------------------
blob_service_client = BlobServiceClient.from_connection_string(AZURE_CFG["connection_string"])
container_client = blob_service_client.get_container_client(AZURE_CFG["container_name"])

# ------------------------------------------------------------
# 4️⃣ List files & classify by date
# ------------------------------------------------------------
def list_files():
    """List all blobs and separate today's CSVs from older ones."""
    all_files = []
    today_files = []
    other_files = []

    today_str = datetime.datetime.now().strftime("%Y_%m_%d")

    for blob in container_client.list_blobs(name_starts_with=AZURE_CFG["raw_folder"]):
        if blob.name.endswith(".csv"):
            all_files.append(blob.name)
            if today_str in blob.name:
                today_files.append(blob.name)
            else:
                other_files.append(blob.name)

    logging.info(f"Total files: {len(all_files)}, Today's: {len(today_files)}, Others: {len(other_files)}")
    return all_files, today_files, other_files

# ------------------------------------------------------------
# 5️⃣ Archive files
# ------------------------------------------------------------
def archive_files(file_list):
    """Move files from raw → archive folder."""
    for file_path in file_list:
        file_name = os.path.basename(file_path)
        source_blob = container_client.get_blob_client(file_path)
        dest_blob_name = f"{AZURE_CFG['archive_folder']}{file_name}"
        dest_blob = container_client.get_blob_client(dest_blob_name)

        # Copy → then delete from raw
        dest_blob.start_copy_from_url(source_blob.url)
        container_client.delete_blob(file_path)

        logging.info(f"Archived: {file_name}")

# ------------------------------------------------------------
# 6️⃣ Purge files
# ------------------------------------------------------------
def purge_files():
    """Purge files from raw folder that exist in archive."""
    archived_files = {os.path.basename(b.name) for b in container_client.list_blobs(name_starts_with=AZURE_CFG["archive_folder"])}
    for blob in container_client.list_blobs(name_starts_with=AZURE_CFG["raw_folder"]):
        if os.path.basename(blob.name) in archived_files:
            container_client.delete_blob(blob.name)
            logging.info(f"Purged from raw: {blob.name}")

# ------------------------------------------------------------
# 7️⃣ Snowflake Connection
# ------------------------------------------------------------
def create_snowflake_session():
    """Establish Snowflake session."""
    connection_parameters = {
        "account": SNOW_CFG["account"],
        "user": SNOW_CFG["user"],
        "password": SNOW_CFG["password"],
        "role": SNOW_CFG["role"],
        "warehouse": SNOW_CFG["warehouse"],
        "database": SNOW_CFG["database"],
        "schema": SNOW_CFG["schema"]
    }
    session = snowpark.Session.builder.configs(connection_parameters).create()
    return session

# ------------------------------------------------------------
# 8️⃣ Load todays CSVs into Snowflake
# ------------------------------------------------------------
def load_into_snowflake(session, files):
    """COPY INTO table from stage (only today's CSVs)."""
    for file_path in files:
        file_name = os.path.basename(file_path)
        sql = f"""
        COPY INTO {SNOW_CFG['target_table']}
        FROM @{SNOW_CFG['stage']}/{file_name}
        FILE_FORMAT = (FORMAT_NAME = {SNOW_CFG['file_format']})
        ON_ERROR = 'CONTINUE';
        """
        session.sql(sql).collect()
        logging.info(f"Loaded {file_name} into Snowflake")

# ------------------------------------------------------------
# 9️⃣ Generate summary report
# ------------------------------------------------------------
def generate_summary(session):
    """Example: simple aggregation report."""
    df = session.table(SNOW_CFG["target_table"])
    summary = df.group_by(col("REGION")).agg({"SALES_AMOUNT": "sum"})
    summary.show()
    logging.info("Generated summary successfully")

# ------------------------------------------------------------
# 🔟 Main Pipeline Flow
# ------------------------------------------------------------
def main():
    logging.info("Pipeline started")

    all_files, today_files, other_files = list_files()

    if not today_files:
        logging.warning("No today's files found. Exiting.")
        return

    archive_files(other_files)  # Move older files to archive

    session = create_snowflake_session()
    load_into_snowflake(session, today_files)
    generate_summary(session)

    purge_files()  # Clean up raw directory after successful processing

    logging.info("Pipeline completed successfully")

# ------------------------------------------------------------
if __name__ == "__main__":
    main()



📦 requirements.txt
azure-storage-blob==12.20.0
snowflake-snowpark-python==1.15.0

✅ End-to-End Flow
| Step | Stage        | Description                                          |
| ---- | ------------ | ---------------------------------------------------- |
| 1️⃣  | Azure → List | Fetch all `.csv` in raw folder                       |
| 2️⃣  | Split        | Identify today's files and others                    |
| 3️⃣  | Archive      | Move older files to `/archive`                       |
| 4️⃣  | Load         | Copy today's files into Snowflake via external stage |
| 5️⃣  | Summary      | Generate aggregation in Snowflake                    |
| 6️⃣  | Purge        | Delete successfully archived files from raw          |
| 7️⃣  | Log          | Detailed pipeline log for debugging                  |


📄 File: setup.sql
Below is the setup.sql file that creates all the required objects in Snowflake —
including storage integration, file format, stage, and target table — perfectly aligned with your pipeline.py.

-- ==========================================================
-- 🧱 1️⃣ CREATE STORAGE INTEGRATION (for Azure Blob Storage)
-- ==========================================================
CREATE OR REPLACE STORAGE INTEGRATION AZURE_SALES_INT
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = AZURE
  ENABLED = TRUE
  AZURE_TENANT_ID = '<your-tenant-id>'
  STORAGE_ALLOWED_LOCATIONS = ('azure://yourstorageaccount.blob.core.windows.net/sales-data');

-- View integration details
DESC INTEGRATION AZURE_SALES_INT;

-- ==========================================================
-- 📁 2️⃣ CREATE DATABASE, SCHEMA, AND ROLE SETUP
-- ==========================================================
CREATE OR REPLACE ROLE DEVELOPER_ROLE;
GRANT ROLE DEVELOPER_ROLE TO USER <your_username>;

CREATE OR REPLACE DATABASE SALES_DB;
CREATE OR REPLACE SCHEMA SALES_DB.STAGING;
USE SCHEMA SALES_DB.STAGING;

-- ==========================================================
-- 🧾 3️⃣ CREATE FILE FORMAT FOR CSV FILES
-- ==========================================================
CREATE OR REPLACE FILE FORMAT SALES_CSV_FORMAT
  TYPE = CSV
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  NULL_IF = ('NULL', 'null')
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  EMPTY_FIELD_AS_NULL = TRUE
  TRIM_SPACE = TRUE
  COMPRESSION = AUTO;

-- ==========================================================
-- 🗂️ 4️⃣ CREATE EXTERNAL STAGE USING STORAGE INTEGRATION
-- ==========================================================
CREATE OR REPLACE STAGE AZURE_STAGE_SALES
  URL = 'azure://yourstorageaccount.blob.core.windows.net/sales-data/raw'
  STORAGE_INTEGRATION = AZURE_SALES_INT
  FILE_FORMAT = SALES_CSV_FORMAT;

-- List files to verify connectivity
LIST @AZURE_STAGE_SALES;

-- ==========================================================
-- 🧩 5️⃣ CREATE TARGET TABLE IN SNOWFLAKE
-- ==========================================================
CREATE OR REPLACE TABLE STG_SALES_DATA (
    ORDER_ID       STRING,
    PRODUCT_ID     STRING,
    CUSTOMER_ID    STRING,
    REGION         STRING,
    SALES_AMOUNT   FLOAT,
    SALES_DATE     DATE
);

-- ==========================================================
-- 📥 6️⃣ COPY COMMAND TEMPLATE (used by Python script)
-- ==========================================================
-- Example manual load:
-- COPY INTO STG_SALES_DATA
-- FROM @AZURE_STAGE_SALES/sales_2025_10_14.csv
-- FILE_FORMAT = (FORMAT_NAME = SALES_CSV_FORMAT)
-- ON_ERROR = 'CONTINUE';

-- ==========================================================
-- 📊 7️⃣ EXAMPLE VALIDATION QUERY
-- ==========================================================
SELECT REGION, SUM(SALES_AMOUNT) AS TOTAL_SALES
FROM STG_SALES_DATA
GROUP BY REGION
ORDER BY TOTAL_SALES DESC;

-- ==========================================================
-- ✅ Setup complete!
-- ==========================================================


💡 How to Deploy
In Snowflake:
Open a worksheet.
Run the contents of setup.sql (replace <your-tenant-id> and yourstorageaccount).
Verify stage connectivity with:
LIST @AZURE_STAGE_SALES;


In Python (local or Databricks environment):
Run:
pip install -r requirements.txt
python pipeline.py


Result:
The pipeline lists Azure files.
Processes only today’s CSVs.
Archives old files.
Loads data into Snowflake.
Generates a regional sales summary.
Purges successfully archived files.




