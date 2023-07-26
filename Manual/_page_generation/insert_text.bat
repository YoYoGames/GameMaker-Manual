@echo off
set inputfile=%1
set outputfile=%2
set texttofind=%3
set texttoprepend=%~4

set inserted=0
>"%outputfile%" (
    for /f "usebackq delims="  %%a in ("%inputfile%") do (
          if %inserted%==0 if "%%~a"==%texttofind% echo(%texttoprepend% & set inserted=1
           echo(%%a
    )
)