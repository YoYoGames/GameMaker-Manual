import os
import logging

# Configure logging
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
        if head_content.startswith("ref: refs/remotes/origin/"):
            branch_name = head_content.replace("ref: refs/remotes/origin/", "")
            logging.info(f"Extracted branch name: {branch_name}")

# Append the branch name as a GitHub Actions variable to the specified output file
if branch_name:
    github_output_file = os.getenv('GITHUB_OUTPUT')
    logging.info(f"Appending branch name '{branch_name}' to output file: {github_output_file}")

    with open(github_output_file, 'a') as env
