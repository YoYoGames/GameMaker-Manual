@echo off
setlocal enabledelayedexpansion

echo "Checking current directory:"
echo %CD%

rem Get symbolic ref for remote origin/HEAD
for /f "delims=" %%A in ('git symbolic-ref refs/remotes/origin/HEAD 2^>nul') do (
    set "symbolic_ref=%%A"
)

rem Extract the branch name by removing the prefix "refs/remotes/origin/"
set "branch_name=!symbolic_ref:refs/remotes/origin/=!"

rem Print the extracted branch name
echo Branch Name: %branch_name%
