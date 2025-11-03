File Handling
=============
File handling is one of the most essential and practically used parts of Python for data engineering — especially for reading logs, CSVs, JSONs, and handling file-based ETL operations.

Let’s dive deep — you’ll learn both input/output (I/O) and advanced file handling techniques.

🔹 1. Types of File Handling in Python

	| File Type            | Typical Module                        |
	| -------------------- | ------------------------------------- |
	| Text files (`.txt`)  | `open()`                              |
	| CSV files (`.csv`)   | `csv`, `pandas`                       |
	| JSON files (`.json`) | `json`                                |
	| Binary files         | `open(..., "rb")` / `open(..., "wb")` |
	| Excel files          | `openpyxl`, `pandas`                  |
	| Compressed files     | `zipfile`, `gzip`, `shutil`           |


🔹 2. Opening and Closing Files

	file = open("filename", "mode")

	| Mode   | Description                           |
	| ------ | ------------------------------------- |
	| `'r'`  | Read (default)                        |
	| `'w'`  | Write (overwrites file)               |
	| `'a'`  | Append (adds to end)                  |
	| `'r+'` | Read & Write                          |
	| `'x'`  | Create new file; error if file exists |
	| `'b'`  | Binary mode (e.g., `'rb'`, `'wb'`)    |


🔹 3. Reading a Text File

	# Read entire file
	with open("sample.txt", "r") as f:
		content = f.read()
		print(content)

	# Read line by line
	with open("sample.txt", "r") as f:
		for line in f:
			print(line.strip())

🔹 4. Writing to a File

	with open("output.txt", "w") as f:
		f.write("Hello, Prajeesh!\n")
		f.write("Welcome to file handling in Python.\n")

🔹 5. Appending to a File
	with open("output.txt", "a") as f:
		f.write("This line was appended later.\n")
		
🔹 6. Working with CSV Files

	import csv

	# Write CSV
	data = [["Name", "Role"], ["Prajeesh", "Data Engineer"], ["Ravi", "Analyst"]]
	with open("team.csv", "w", newline="") as f:
		writer = csv.writer(f)
		writer.writerows(data)

	# Read CSV
	with open("team.csv", "r") as f:
		reader = csv.reader(f)
		for row in reader:
			print(row)

🔹 7. Working with JSON Files
	import json

	# Write JSON
	data = {"name": "Prajeesh", "role": "Data Engineer", "skills": ["Python", "Snowflake"]}
	with open("user.json", "w") as f:
		json.dump(data, f, indent=4)

	# Read JSON
	with open("user.json", "r") as f:
		data_loaded = json.load(f)
		print(data_loaded)

🔹 Handling Errors During File Operations
	try:
		with open("missing.txt", "r") as f:
			data = f.read()
	except FileNotFoundError:
		print("❌ File not found!")
	except PermissionError:
		print("❌ Permission denied!")
	else:
		print("✅ File read successfully!")
	finally:
		print("📘 File operation completed.")
