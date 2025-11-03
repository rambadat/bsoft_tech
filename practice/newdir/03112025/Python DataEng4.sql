File Handling
=============
Let’s now go through File Handling in Python, which is a core skill for Data Engineers.
This is where you learn how to read, write, and process files — a daily task in ETL pipelines and data workflows.

File Modes in Python
| Mode   | Description                                |
| `'r'`  | Read (default)                             |
| `'w'`  | Write (overwrites file if exists)          |
| `'a'`  | Append                                     |
| `'r+'` | Read + Write                               |
| `'b'`  | Binary mode (used with images, PDFs, etc.) |


📘1. Text Files
	 ----------
	# Writing to a text file
	with open("example.txt", "w") as file:
		file.write("Hello Prajeesh!\n")
		file.write("Welcome to Day 6 - File Handling.\n")

	# Reading the text file
	with open("example.txt", "r") as file:
		content = file.read()

	print("File Content:\n", content)


	Output:
	File Content:
	Hello Prajeesh!
	Welcome to Day 6 - File Handling.


🧱2. CSV Files
	 ---------
	CSV (Comma-Separated Values) is a very common file format for data pipelines.

	-Example: Write CSV
	import csv
	data = [
		["Name", "Department", "Salary"],
		["Prajeesh", "Data Engineering", 80000],
		["Subodh", "DevOps", 75000],
		["Dhananjay", "Fullstack", 75000],
		["Debasis", "Data Scientist", 75000],
		["Ram", "Artificial Intelligence", 75000]
	]


	with open("employees.csv", "w", newline="") as file:
		writer = csv.writer(file)
		writer.writerows(data)


	-Example: Read CSV
	import csv

	with open("employees.csv", "r") as file:
		reader = csv.reader(file)
		for row in reader:
			print(row)

	Output:
	['Name', 'Department', 'Salary']
	['Prajeesh', 'Data Engineering', '80000']
	['Ankit', 'DevOps', '75000']


🧮3. JSON Files
	 ----------
	JSON (JavaScript Object Notation) is widely used for configuration, APIs, and metadata.

	-Example: Write JSON
	import json

	employee_data = {
		"name": "Prajeesh",
		"role": "Data Engineer",
		"skills": ["Python", "Snowflake", "Azure"],
		"experience": 4
	}

	with open("employee.json", "w") as file:
		json.dump(employee_data, file, indent=4)


	-Example: Read JSON
	import json

	with open("employee.json", "r") as file:
		data = json.load(file)

	print(data)
	print("Employee name:", data["name"])


	Output:
	{'name': 'Prajeesh', 'role': 'Data Engineer', 'skills': ['Python', 'Snowflake', 'Azure'], 'experience': 4}
	Employee name: Prajeesh



⚙️4. Using Context Managers (with open)
	 ----------------------------------
	with open() automatically closes the file after use — it’s the safest and most recommended way.

	try:
		with open("example.txt", "r") as file:
			data = file.read()
			print(data)
	except FileNotFoundError:
		print("File not found. Please check the filename.")
	


Error Handling in File Operations
=================================
Common exceptions:
FileNotFoundError 	→ file doesn’t exist
PermissionError 	→ no permission
IOError 			→ read/write issues

Example:
try:
	with open("non_existing.txt", "r") as file:
		content = file.read()
except FileNotFoundError:
	print("Error: File not found.")
except PermissionError:
	print("Error: You do not have permission to read this file.")
else:
	print("File read successfully!")
finally:
	print("File operation completed.")


Output:
Error: File not found.
File operation completed.	



🧠 Quick Summary
| Concept         | Module   | Key Function                   |
| --------------- | -------- | ------------------------------ |
| Text Files      | Built-in | `open()`, `read()`, `write()`  |
| CSV Files       | `csv`    | `csv.reader()`, `csv.writer()` |
| JSON Files      | `json`   | `json.load()`, `json.dump()`   |
| Context Manager | Built-in | `with open()`                  |
| Error Handling  | Built-in | `try-except-finally`           |
