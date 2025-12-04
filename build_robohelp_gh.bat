@echo on
setlocal enabledelayedexpansion
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
set BUILDBETA=%BUILDBETA%
set S3_BUCKET=%S3_BUCKET%
set ZIP_FILE=%ZIP_FILE%
set LANGUAGE=%LANGUAGE%


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

rem ── Run only in GameMaker-Manual ─────────────────────────────────────
if /i not "%GITHUB_REPOSITORY%"=="YoYoGames/GameMaker-Manual" (
    echo Skipping S3 upload — this is not the main GameMaker-Manual repo
    goto skip_s3_upload
)

rem ── Determine S3 path based on preset ────────────────────────────────
if /i "%robohelpPreset%"=="GMS2 Manual Responsive HTML5 BETA" (
    set "S3_PATH=%S3_BUCKET%/Beta"
    echo Branch is develop - Choose BETA
) else if /i "%robohelpPreset%"=="GMS2 Manual Responsive HTML5" (
    set "S3_PATH=%S3_BUCKET%/Green"
    echo Branch is Main - Choose Green
) else (
    set "S3_PATH=%S3_BUCKET%/LTS"
    echo Branch is neither develop nor main - Choose LTS
)

rem ── Temp directory for comparison ────────────────────────────────────
mkdir "temp_s3_compare" 2>nul

rem ── Download current files from S3 ───────────────────────────────────
for %%F in (helpdocs_keywords.json helpdocs_tags.json) do (
    echo Checking %%F...
    aws s3 cp "%S3_PATH%/%%F" "temp_s3_compare/%%F" >nul 2>&1

    if not exist "temp_s3_compare/%%F" (
        echo %%F missing on S3 → uploading
        aws s3 cp "%%F" "%S3_PATH%/%%F"
    ) else (
        fc /b "%%F" "temp_s3_compare/%%F" >nul 2>&1 || (
            echo %%F changed → uploading
            aws s3 cp "%%F" "%S3_PATH%/%%F"
        )
    )
)

rem Cleanup
rmdir /s /q temp_s3_compare 2>nul

:skip_s3_upload

rem ************************************************** ZIP up the output
7z a YoYoStudioRoboHelp.zip . -r

popd

