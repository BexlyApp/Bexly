#!/usr/bin/env python3
import os
import re

# Define the directory to search
search_dir = r"d:\Projects\Bexly\lib"

# Pattern to find and replace
old_import = "bexly/core/database/pockaw_database"
new_import = "bexly/core/database/app_database"

# Counter
files_updated = 0

# Walk through all .dart files
for root, dirs, files in os.walk(search_dir):
    for file in files:
        if file.endswith(".dart"):
            filepath = os.path.join(root, file)

            # Read file content
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()

            # Check if file contains the old import
            if old_import in content:
                # Replace
                new_content = content.replace(old_import, new_import)

                # Write back
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)

                files_updated += 1
                print(f"Updated: {filepath}")

print(f"\nTotal files updated: {files_updated}")
