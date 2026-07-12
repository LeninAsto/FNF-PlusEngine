@echo off
color 0a
cd ../..
echo BUILDING WINDOWS
haxelib run lime build windows -release
echo.
echo done - Windows build completed!
pause
pwd
