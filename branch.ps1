# Define the path to the HEAD file
$headFilePath = ".git\refs\remotes\origin\HEAD"

# Initialize the branch name variable
$branchName = ""

# Check if the HEAD file exists
if (Test-Path $headFilePath -PathType Leaf) {
    # Read the content of the HEAD file
    $branchName = Get-Content $headFilePath -Raw

    # Extract the branch name from the content
    $branchName = $branchName -replace '^ref: refs/remotes/origin/', ''
}

# Output the branch name as an output variable
Write-Output "$branchName"
