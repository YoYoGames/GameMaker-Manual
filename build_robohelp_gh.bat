@echo on
setlocal enabledelayedexpansion
rem experimental build
if "%WORKSPACE%" == "" set WORKSPACE="D:\GameMaker-Manual"
if "%BUILD_NUMBER%" == "" set BUILD_NUMBER=999
if "%SOURCE_BUILD_NUMBER%" == "" set SOURCE_BUILD_NUMBER=%BUILD_NUMBER%
if "%SOURCE_MAJOR_VERSION%" == "" set SOURCE_MAJOR_VERSION=1
if "%SOURCE_MINOR_VERSION%" == "" set SOURCE_MINOR_VERSION=0
if "%JOB_NAME%" == "" set JOB_NAME=GMS2_Manual
set BUILDTYPE=release
set BUILDPLATFORM="Any CPU"
set BUILDCLEAN=1
set BUILDBETA=1
set S3_BUCKET="s3://manual-json-files/"
set ZIP_FILE="Adobe_RoboHelp_2022.0.0.331.zip"
set LANGUAGE=EN


set basedir=%~dp0

:check_options
if %LANGUAGE%==EN (
    if "%BUILDBETA%"=="1" (
        set robohelpPreset="GMS2 Manual Responsive HTML5 BETA"
    ) else (
        set robohelpPreset="GMS2 Manual Responsive HTML5"
    )
	goto finish_options
) else if %LANGUAGE%==ES ( 
	set robohelpPreset="GMS2 Manual Spanish"
	goto finish_options
) else if %LANGUAGE%==FR ( 
	set robohelpPreset="GMS2 Manual French"
	goto finish_options
) else if %LANGUAGE%==DE ( 
	set robohelpPreset="GMS2 Manual German"
	goto finish_options
) else if %LANGUAGE%==RU ( 
	set robohelpPreset="GMS2 Manual Russian"
	goto finish_options
) else if %LANGUAGE%==PT-BR ( 
	set robohelpPreset="GMS2 Manual Portuguese (Brazil)"
	goto finish_options
) else if %LANGUAGE%==ZH ( 
	set robohelpPreset="GMS2 Manual Chinese (Simplified)"
	goto finish_options
) else if %LANGUAGE%==IT ( 
	set robohelpPreset="GMS2 Manual Italian"
	goto finish_options
) else if %LANGUAGE%==JA ( 
	set robohelpPreset="GMS2 Manual Japanese"
	goto finish_options
) else if %LANGUAGE%==PL ( 
	set robohelpPreset="GMS2 Manual Polish"
	goto finish_options
) else if %LANGUAGE%==KO ( 
	set robohelpPreset="GMS2 Manual Korean"
	goto finish_options
)else ( 
	set DESTDIR=%1
	goto finish_options
)

shift
goto check_options

:finish_options

if "%DESTDIR%" == "" set DESTDIR=%GITHUB_WORKSPACE%\output

rem Pulling Adobe Zip from S3
aws s3 cp %S3_BUCKET%/%ZIP_FILE% %ZIP_FILE%
7z x %ZIP_FILE% -o"%basedir%"

rem Pulling RobohelpTool from S3
aws s3 cp %S3_BUCKET%/RoboHelpTool.exe RoboHelpTool.exe
copy "RoboHelpTool.exe" "%basedir%"

set roboHelpTool="%basedir%Adobe_RoboHelp_2022\RoboHelp.exe"
set helpTagsTool="%basedir%RoboHelpTool.exe"

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

pushd %DESTDIR%\RoboHelp

rem Determine S3 path based on preset
if /i %robohelpPreset%=="GMS2 Manual Responsive HTML5 BETA" (
    echo Branch is develop - Choose BETA
    set S3_PATH=s3://manual-json-files/Beta
) else if /i %robohelpPreset%=="GMS2 Manual Responsive HTML5" (
    echo Branch is Main - Choose Green
    set S3_PATH=s3://manual-json-files/Green
) else (
    echo Branch is not develop or main - Choose LTS
    set S3_PATH=s3://manual-json-files/LTS
)

rem Create temp directory for comparison
mkdir temp_s3_compare 2>nul

rem Download existing files from S3 for comparison (ignore errors if files don't exist)
echo Downloading existing files from S3 for comparison...
aws s3 cp %S3_PATH%/helpdocs_keywords.json temp_s3_compare\helpdocs_keywords.json 2>nul
aws s3 cp %S3_PATH%/helpdocs_tags.json temp_s3_compare\helpdocs_tags.json 2>nul

rem Check and upload helpdocs_keywords.json if modified
set UPLOAD_KEYWORDS=0
if not exist temp_s3_compare\helpdocs_keywords.json (
    echo helpdocs_keywords.json does not exist in S3 - will upload
    set UPLOAD_KEYWORDS=1
) else (
    fc /b helpdocs_keywords.json temp_s3_compare\helpdocs_keywords.json >nul 2>&1
    if errorlevel 1 (
        echo helpdocs_keywords.json has been modified - will upload
        set UPLOAD_KEYWORDS=1
    ) else (
        echo helpdocs_keywords.json is unchanged - skipping upload
    )
)

if %UPLOAD_KEYWORDS%==1 (
    aws s3 cp helpdocs_keywords.json %S3_PATH%/helpdocs_keywords.json
)

rem Check and upload helpdocs_tags.json if modified
set UPLOAD_TAGS=0
if not exist temp_s3_compare\helpdocs_tags.json (
    echo helpdocs_tags.json does not exist in S3 - will upload
    set UPLOAD_TAGS=1
) else (
    fc /b helpdocs_tags.json temp_s3_compare\helpdocs_tags.json >nul 2>&1
    if errorlevel 1 (
        echo helpdocs_tags.json has been modified - will upload
        set UPLOAD_TAGS=1
    ) else (
        echo helpdocs_tags.json is unchanged - skipping upload
    )
)

if %UPLOAD_TAGS%==1 (
    aws s3 cp helpdocs_tags.json %S3_PATH%/helpdocs_tags.json
)

rem Cleanup temp directory
rmdir /s /q temp_s3_compare 2>nul

@REM rem ************************************************** ZIP up the output
7z a YoYoStudioRoboHelp.zip . -r
popd
