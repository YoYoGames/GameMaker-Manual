@echo off
rem experimental build
if "%WORKSPACE%" == "" set WORKSPACE=%GITHUB_WORKSPACE%
if "%BUILD_NUMBER%" == "" set BUILD_NUMBER=999
if "%SOURCE_BUILD_NUMBER%" == "" set SOURCE_BUILD_NUMBER=%BUILD_NUMBER%
if "%SOURCE_MAJOR_VERSION%" == "" set SOURCE_MAJOR_VERSION=1
if "%SOURCE_MINOR_VERSION%" == "" set SOURCE_MINOR_VERSION=0
if "%JOB_NAME%" == "" set JOB_NAME=GMS2_Manual
set BUILDTYPE=release
set BUILDPLATFORM="Any CPU"
set BUILDCLEAN=1
set BUILDBETA=0
set S3_BUCKET=%S3_BUCKET%
set ZIP_FILE=%ZIP_FILE%
echo on

set basedir=%~dp0

:check_options
if "%1"=="release" ( 
	set BUILDTYPE=release
) else if "%1"=="debug" ( 
	set BUILDTYPE=debug
) else if "%1"=="noclean" ( 
	set BUILDCLEAN=0
) else if "%1"=="-beta" ( 
	set BUILDBETA=1
) else if "%1"=="-ES" ( 
	set BUILDES=1
)  else if "%1"=="-FR" ( 
	set BUILDFR=1
)  else if "%1"=="-DE" ( 
	set BUILDDE=1
)  else if "%1"=="-RU" ( 
	set BUILDRU=1
) else if "%1"=="-PT-BR" ( 
	set BUILDPT-BR=1
) else if "%1"=="-ZH" ( 
	set BUILDZH=1
) else if "%1"=="-IT" ( 
	set BUILDIT=1
) else if "%1"=="-JA" ( 
	set BUILDJA=1
) else if "%1"=="-PL" ( 
	set BUILDPL=1
) else "%1"=="-KO" ( 
	set BUILDKO=1
)


if "%DESTDIR%" == "" set DESTDIR=%GITHUB_WORKSPACE%\output

rem Pulling Adobe Zip from S3
aws s3 cp %S3_BUCKET%/%ZIP_FILE% %ZIP_FILE%
7z x %ZIP_FILE% -o"%basedir%"

rem Pulling RobohelpTool from S3
aws s3 cp %S3_BUCKET%/RoboHelpTool.exe RoboHelpTool.exe
copy "RoboHelpTool.exe" "%basedir%"

set roboHelpTool="%basedir%Adobe_RoboHelp_2022\RoboHelp.exe"
set helpTagsTool="%basedir%RoboHelpTool.exe"

rmdir "%DESTDIR%\RoboHelp" /s /q

if %BUILDBETA% == 1 (
	set robohelpPreset="GMS2 Manual Responsive HTML5 BETA"
) else if %BUILDES% == 1 (
	set robohelpPreset="GMS2 Manual Spanish"
) else if %BUILDFR% == 1 (
	set robohelpPreset="GMS2 Manual French"
) else if %BUILDDE% == 1 (
	robohelpPreset="GMS2 Manual German"
) else if %BUILDRU% == 1 (
	robohelpPreset="GMS2 Manual Russian"
) else if %BUILDPT-BR% == 1 (
	robohelpPreset="GMS2 Manual Portugese (Brazil)"
) else if %BUILDZH% == 1 (
	robohelpPreset="GMS2 Manual Chinese (Simplified)"
) else if %BUILDIT% == 1 (
	robohelpPreset="GMS2 Manual Italian"
) else if %BUILDJA% == 1 (
	robohelpPreset="GMS2 Manual Japanese"
) else if %BUILDPL% == 1 (
	robohelpPreset="GMS2 Manual Polish"
) else %BUILDKO% == 1 (
	robohelpPreset="GMS2 Manual Korean"
)

echo "%robohelpPreset%"

%roboHelpTool% --cl "%basedir%Manual\GMS2_Manual.rhpj" -o %robohelpPreset% -p "%DESTDIR%\RoboHelp" 

if not exist "%DESTDIR%\RoboHelp" (
	echo "RoboHelp Directory not found - RoboHelp Crashed?"
	exit /b 1
)

rem output help tags files
%helpTagsTool% -s="%basedir%Manual\contents" -o="%DESTDIR%\RoboHelp"

rem append css fix to layout.css
type "%basedir%SupportFiles\layout_fix_append.css" >> "%DESTDIR%\RoboHelp\template\Charcoal_Grey\layout.css"

@REM rem ************************************************** ZIP up the output
pushd %DESTDIR%\RoboHelp
7z a YoYoStudioRoboHelp.zip . -r
popd