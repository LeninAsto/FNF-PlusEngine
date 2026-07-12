@echo off
color 0a
cd ../..
echo BUILDING ANDROID 
haxelib run lime build android -release 
echo.
echo done - Android build completed!
pause
pwd
