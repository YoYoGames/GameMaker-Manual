@echo off
setlocal enabledelayedexpansion

echo "Checking current directory:"
echo %CD%

rem Get symbolic ref for remote origin/HEAD
for /f "delims=" %%A in ('git symbolic-ref refs/remotes/origin/HEAD 2^>nul') do (
    set "symbolic_ref=%%A"
)

rem Print symbolic ref for debugging
echo "Symbolic ref:"
echo !symbolic_ref!
