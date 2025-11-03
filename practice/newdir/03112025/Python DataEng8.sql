OS commands
===========
import os
import shutil

base_path = r"C:\Users\user\Desktop\snowflake\Python"
os.chdir(base_path)    #Move to target directory
print(f" Current Directory: {os.getcwd()}")

print("\n Listing all files and directories:")
for item in os.listdir(base_path): #List all files and directories
    print(" -", item)


new_folder = os.path.join(base_path, "newosfolder")
os.makedirs(new_folder, exist_ok=True)  #Create new directory named 'newosfolder'
print(f"\n Created Directory: {new_folder}")

os.chdir(new_folder)
for d in ["dir1", "dir2", "dir3"]:    #Move to newosfolder and create dir1, dir2, dir3
    os.makedirs(d, exist_ok=True)
print(f" Subdirectories created inside {new_folder}")


for d in ["dir2", "dir3"]:
    dir_path = os.path.join(new_folder, d)
    if os.path.exists(dir_path):
        shutil.rmtree(dir_path)    #Remove dir2 and dir3
        print(f"️  Deleted directory: {d}")

os.rename("dir1", "folder1")  #Rename dir1 to folder1
print("  Renamed 'dir1' to 'folder1'")


folder1_path = os.path.join(new_folder, "folder1")
os.chdir(folder1_path)
files = ["file1.txt", "file2.txt", "file3.txt"]
for file in files:
    with open(file, "w") as f:   #Create sample text files inside folder1
        f.write(f"This is {file}\nLine 2: Hello from Python!\nLine 3: End of file.\n")
    print(f" Created file: {file}")

if os.path.exists("file3.txt"):
    os.remove("file3.txt")   #Delete file3.txt
    print("️  Deleted file: file3.txt")

# Compress files and move archive to archive folder
archive_dir = r"C:\Users\user\Desktop\archive"
unarchive_dir = r"C:\Users\user\Desktop\unarchive"
os.makedirs(archive_dir, exist_ok=True)
os.makedirs(unarchive_dir, exist_ok=True)

temp_src = os.path.join(new_folder, "temp_files")   #Temporary source for archive
os.makedirs(temp_src, exist_ok=True)

for file in os.listdir(folder1_path):
    shutil.copy(os.path.join(folder1_path, file), temp_src)  #Copy files for archiving to temporary folder
print("Files copied to temporary folder for archiving.")

archive_name = os.path.join(archive_dir, "backup_files")
shutil.make_archive(archive_name, "zip", temp_src)   #Create archive
print(f"  Archive created: {archive_name}.zip")

shutil.move(f"{archive_name}.zip", archive_dir)   #Move archive (optional since created in archive_dir)
print(f" Moved archive to: {archive_dir}")

#Uncompress files from archive to unarchive
archive_path = os.path.join(archive_dir, "backup_files.zip")
shutil.unpack_archive(archive_path, unarchive_dir, "zip")
print(f" Uncompressed files to: {unarchive_dir}")

# Change file permissions
for file_name in ["file1.txt", "file2.txt"]:
    file_path = os.path.join(folder1_path, file_name)
    os.chmod(file_path, 0o644)  # rw-r--r--
    print(f" Changed file permissions for: {file_name}")

print("\n All tasks completed successfully!")
