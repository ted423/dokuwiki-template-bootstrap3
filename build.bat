@echo off
rem =============================================================
rem  DokuWiki template packaging script (Windows)
rem
rem  Usage:  build.bat [version]
rem
rem  Produces: dist\<template>-<version>.zip
rem  The archive root folder is the template name taken from the
rem  "base" field of template.info.txt, so it can be unpacked
rem  straight into lib/tpl/ of a DokuWiki installation.
rem =============================================================
setlocal enabledelayedexpansion
cd /d "%~dp0"

set "DIST_DIR=dist"
set "TPL_NAME="
set "VERSION=%~1"

if not exist "template.info.txt" (
  echo [build] ERROR: template.info.txt not found in "%CD%"
  endlocal & exit /b 1
)

rem ---------- read template name / version from template.info.txt ----------
for /f "usebackq tokens=1,2 delims== " %%A in ("template.info.txt") do (
  if /i "%%A"=="base" set "TPL_NAME=%%B"
  if /i "%%A"=="build" if not defined VERSION set "VERSION=%%B"
)

if not defined TPL_NAME set "TPL_NAME=bootstrap3"
if not defined VERSION set "VERSION=unknown"
set "VERSION=%VERSION:/=-%"

set "ZIP_NAME=%TPL_NAME%-%VERSION%.zip"
set "ZIP_PATH=%CD%\%DIST_DIR%\%ZIP_NAME%"

echo [build] template : %TPL_NAME%
echo [build] version  : %VERSION%
echo [build] output   : %ZIP_PATH%

if not exist "%DIST_DIR%" mkdir "%DIST_DIR%"
if exist "%ZIP_PATH%" del /f /q "%ZIP_PATH%"

rem ---------- stage a clean copy of the template ----------
set "STAGE_ROOT=%TEMP%\dokuwiki-tpl-%RANDOM%%RANDOM%"
set "STAGE=%STAGE_ROOT%\%TPL_NAME%"
mkdir "%STAGE%" >nul 2>&1
if not exist "%STAGE%" (
  echo [build] ERROR: cannot create staging directory "%STAGE%"
  endlocal & exit /b 1
)

robocopy "." "%STAGE%" /E ^
  /XD "%CD%\.git" "%CD%\.github" "%CD%\.ai" "%CD%\.vscode" "%CD%\_test" "%CD%\%DIST_DIR%" ^
  /XF ".editorconfig" ".travis.yml" ".gitignore" "*.zip" "*.log" ".DS_Store" "Thumbs.db" ^
  /NFL /NDL /NJH /NJS /NP >nul
set "RC=%ERRORLEVEL%"
if %RC% GEQ 8 (
  echo [build] ERROR: robocopy failed with code %RC%
  goto :fail
)

rem ---------- compress ----------
set "ZIP_CMD="
where tar.exe >nul 2>&1 && set "ZIP_CMD=tar"

if "%ZIP_CMD%"=="tar" (
  tar --format=zip -cf "%ZIP_PATH%" -C "%STAGE_ROOT%" "%TPL_NAME%"
  if errorlevel 1 set "ZIP_CMD="
)

if not "%ZIP_CMD%"=="tar" (
  echo [build] tar.exe unavailable, falling back to PowerShell Compress-Archive
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Compress-Archive -Path '%STAGE%' -DestinationPath '%ZIP_PATH%' -Force"
  if errorlevel 1 (
    echo [build] ERROR: failed to create "%ZIP_PATH%"
    goto :fail
  )
)

if not exist "%ZIP_PATH%" (
  echo [build] ERROR: archive was not created
  goto :fail
)

rem ---------- report ----------
for %%F in ("%ZIP_PATH%") do set "ZIP_SIZE=%%~zF"
rmdir /s /q "%STAGE_ROOT%" >nul 2>&1

echo [build] OK  %ZIP_NAME% (%ZIP_SIZE% bytes)
echo [build] Install: unpack "%ZIP_NAME%" into lib/tpl/ of your DokuWiki
endlocal & exit /b 0

:fail
rmdir /s /q "%STAGE_ROOT%" >nul 2>&1
endlocal & exit /b 1