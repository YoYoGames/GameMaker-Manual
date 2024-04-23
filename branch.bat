@echo off
setlocal enabledelayedexpansion

rem Read the content of .git/refs/remotes/origin/HEAD using type
for /f "delims=" %%A in ('type .git\refs\remotes\origin\HEAD 2^>nul') do (
    set "branch_ref=%%A"
)

rem Extract the branch name after "refs/remotes/origin/"
set "prefix=refs/remotes/origin/"
set "branch_name=!branch_ref:*%prefix%=!"

rem Print the extracted branch name
echo Branch Name: !branch_name!
