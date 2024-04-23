@echo off
setlocal enabledelayedexpansion

rem Read the content of .git/refs/remotes/origin/HEAD
set "git_head_file=.git\refs\remotes\origin\HEAD"

rem Check if the file exists
if exist "%git_head_file%" (
    rem Read the content of the file into a variable
    set /p "branch_name=" < "%git_head_file%"

    rem Extract the branch name after "refs/remotes/origin/"
    set "prefix=refs/remotes/origin/"
    set "branch_name=!branch_name:*%prefix%=!"

    rem Print the extracted branch name
    echo Branch Name: !branch_name!
) else (
    echo Error: .git/refs/remotes/origin/HEAD not found
    exit /b 1
)
