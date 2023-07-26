@ECHO OFF
SetLocal EnableDelayedExpansion

rem directory
SET "PScommand="POWERSHELL Add-Type -AssemblyName System.Windows.Forms; $FolderBrowse = New-Object System.Windows.Forms.OpenFileDialog -Property @{ValidateNames = $false;CheckFileExists = $false;RestoreDirectory = $true;FileName = 'Selected Folder';};$null = $FolderBrowse.ShowDialog();$FolderName = Split-Path -Path $FolderBrowse.FileName;Write-Output $FolderName""
FOR /F "usebackq tokens=*" %%Q in (`%PScommand%`) DO (
    set destination=%%Q
)

rem echo Destination is %destination%

rem type of file
echo Choose which type of file you want to create.
echo =============
echo 1) Normal (default)
echo 2) GML Code keyword page
echo 3) GML Visual action page
set /p file_type=Type option (1/2/3): 
if "%file_type%"=="1" goto option_normal
if "%file_type%"=="2" goto option_code
if "%file_type%"=="3" goto option_visual

goto option_normal

:option_normal
set file_name=Template_Normal_Page
goto continue

:option_code
set /p keyword_type=Are you adding (1) Functions, (2) Constants or (3) Global Variables?  
if "%keyword_type%"=="1" set insert_keyword_before="    "abs","
if "%keyword_type%"=="2" set insert_keyword_before="    "ANSI_CHARSET","
if "%keyword_type%"=="3" set insert_keyword_before="    "argument_relative","

set file_name=Template_Code_Page
goto continue

:option_visual
set file_name=Template_Visual_Page
goto continue

:continue
set source_file=%~dp0%_page_generation\
set source_file=%source_file%%file_name%.htm
rem echo Will copy file %source_file% to %destination%

rem number of files
echo =============
echo =============
echo How many files do you want to create?
set /p number_of_files=Number of files: 

rem copy files 
set dest_file=%destination%\%file_name%.htm
set gml_js_file=%~dp0%contents\assets\scripts\gml.js
FOR /L %%X IN (1, 1, %number_of_files%) DO (
 rem copy file
 set new_name=!file_name!%%X
 echo Copying %file_name% to destination
 copy "%source_file%" "%destination%" /-y
 
 rem ask for title
 set /p custom_new_name="Enter name for file %%X (Optional): "
 if NOT "!custom_new_name!"=="" set new_name=!custom_new_name!
 
 rem insert titles
 echo Renaming it to !new_name!
 set old_title="<title>INSERT_TITLE</title>"
 set new_title="<title>!new_name!</title>"
 call "_page_generation\replace_text.bat" !old_title! !new_title! "%dest_file%">"%dest_file%.txt"
 
 rem insert keywords and tags
 echo Inserting metadata
 call "_page_generation\replace_text.bat" "Insert Keywords" !new_name! "%dest_file%.txt">"%dest_file%"
 call "_page_generation\replace_text.bat" "Insert Tags" !new_name! "%dest_file%">"%dest_file%.txt"
 call "_page_generation\replace_text.bat" "INSERT_INDEX" !new_name! "%dest_file%.txt">"%dest_file%"
 call "_page_generation\replace_text.bat" "INSERT_KEYWORDS" !new_name! "%dest_file%">"%dest_file%.txt"
 
 rem insert css and mainscript
 echo Inserting CSS and JS
 set path_css=assets/css/default.css
 set path_js=assets/scripts/main_script.js
 set path_css_old=!path_css!
 set path_js_old=!path_js!
 set path_prepend="../"
 
 set found_contents=0
 for %%a in ("%destination:\=" "%") do (
  if !found_contents!==1 set path_css=../!path_css! & set path_js=../!path_js!
  if %%a=="contents" set found_contents=1
 )
 
 call "_page_generation\replace_text.bat" !path_js_old! !path_js! "%dest_file%.txt">"%dest_file%"
 call "_page_generation\replace_text.bat" !path_css_old! !path_css! "%dest_file%">"%dest_file%.txt"
 
 rem remove other file
 del "%dest_file%"
 
 rem rename file
 rename "%dest_file%.txt" "!new_name!.htm"
 
 rem insert into gml.js
 set line_to_insert="    "!new_name!","
 if %file_type%==2 echo Inserting keyword into gml.js & call "_page_generation\insert_text.bat" %gml_js_file% %gml_js_file%.txt %insert_keyword_before% !line_to_insert! & del %gml_js_file% & rename %gml_js_file%.txt gml.js
 
)

echo Page(s) created
PAUSE
EXIT /B