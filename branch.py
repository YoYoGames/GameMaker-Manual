import os
import sys
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Define the path to the HEAD file
head_file_path = ".git/refs/remotes/origin/HEAD"

# Initialize the branch name variable
branch_name = ""

# Check if the HEAD file exists
if os.path.exists(head_file_path):
    # Read the content of the HEAD file
    logging.info(f"Reading content of HEAD file: {head_file_path}")
    with open(head_file_path, 'r') as head_file:
        head_content = head_file.read().strip()

        # Extract the branch name from the content
        if head_content.startswith("ref: "):
            branch_name = head_content.split("/")[-1].strip()
            logging.info(f"Extracted branch name: {branch_name}")
else:
    logging.error("HEAD file not found.")
    sys.exit(1)  # Exit with non-zero status if HEAD file is not found

# Write the branch name to the specified output file (if GITHUB_OUTPUT is set)
if branch_name:
    try:
        with open(branch_name, 'a') as env:
            env.write(f"branch_name={branch_name}\n")
        logging.info(f"Branch name '{branch_name}'")
    except Exception as e:
        logging.error(f"Failed to write branch name")
        logging.error(str(e))
else:
    logging.warning("GITHUB_OUTPUT environment variable not set. Branch name not written to output.")

# Optionally print the branch name for reference
print(f"Branch Name: {branch_name}")
