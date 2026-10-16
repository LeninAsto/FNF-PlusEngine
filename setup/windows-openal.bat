@echo off
setlocal

REM lime.ndll links OpenAL dynamically. Windows does not search the haxelib
REM NDLL directory for transitive DLL dependencies, so install the tracked
REM Lime runtime next to the active Neko executable.

set "HAXELIB_REPO="
for /f "usebackq delims=" %%I in (`haxelib config`) do if not defined HAXELIB_REPO set "HAXELIB_REPO=%%I"

if not defined HAXELIB_REPO (
	echo [OpenAL] ERROR: Could not determine the haxelib repository.
	exit /b 1
)

for %%I in ("%HAXELIB_REPO%\.") do set "HAXELIB_REPO=%%~fI"
set "LIME_OPENAL=%HAXELIB_REPO%\lime\git\dependencies\openal-soft\Win64\OpenAL32.dll"

if not exist "%LIME_OPENAL%" (
	echo [OpenAL] ERROR: Runtime not found at:
	echo %LIME_OPENAL%
	exit /b 1
)

set "NEKO_EXE="
for /f "delims=" %%I in ('where neko.exe 2^>nul') do if not defined NEKO_EXE set "NEKO_EXE=%%~fI"

if not defined NEKO_EXE (
	echo [OpenAL] ERROR: neko.exe was not found in PATH.
	exit /b 1
)

for %%I in ("%NEKO_EXE%") do set "NEKO_DIR=%%~dpI"
copy /y "%LIME_OPENAL%" "%NEKO_DIR%OpenAL32.dll" >nul

if errorlevel 1 (
	echo [OpenAL] ERROR: Could not install OpenAL32.dll next to:
	echo %NEKO_EXE%
	exit /b 1
)

echo [OpenAL] Installed runtime next to %NEKO_EXE%
exit /b 0
