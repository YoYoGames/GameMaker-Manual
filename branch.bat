@echo off
setlocal enabledelayedexpansion

rem Get symbolic ref for remote origin/HEAD
for /f "delims=" %%A in ('git symbolic-ref refs/remotes/origin/HEAD 2^>nul') do (
    set "symbolic_ref=%%A"
)

rem If symbolic_ref variable is set (i.e., command was successful)
if defined symbolic_ref (
    rem Extract the branch name by removing the prefix "refs/remotes/origin/"
    set "branch_name=!symbolic_ref:refs/remotes/origin/=!"
    
    rem Set the branch name as an environment variable
    set "BRANCH_NAME=!branch_name!"
) else (
    echo Error: Unable to retrieve symbolic ref for remote origin/HEAD
    exit /b 1
)
