import os

# Define the path to the HEAD file
head_file_path = ".git/refs/remotes/origin/HEAD"

# Initialize the branch name variable
branch_name = ""

# Check if the HEAD file exists
if os.path.exists(head_file_path):
    # Read the content of the HEAD file
    with open(head_file_path, 'r') as head_file:
        head_content = head_file.read().strip()

        # Extract the branch name from the content
        if head_content.startswith("ref: refs/remotes/origin/"):
            branch_name = head_content.replace("ref: refs/remotes/origin/", "")

# Append the branch name as a GitHub Actions variable to the specified output file
if branch_name:
    with open(os.getenv('GITHUB_OUTPUT'), 'a') as env:
        env.write(f"branch_name={branch_name}\n")
