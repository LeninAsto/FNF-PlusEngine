@echo off
color 0A
title Installing Haxe Libraries

cd /d "%~dp0.."

echo Installing libraries...
echo This may take a few moments.
echo.

:: Core
echo [1/15] hxcpp
haxelib git hxcpp https://github.com/Psych-Plus-Team/hxcpp --quiet

echo [2/15] lime
haxelib git lime https://github.com/Psych-Plus-Team/lime.git --quiet    

echo [3/15] openfl
haxelib install openfl 9.5.0 --quiet

:: HaxeFlixel
echo [4/15] flixel
haxelib git flixel https://github.com/Psych-Plus-Team/flixel --quiet

echo [5/15] flixel-addons
haxelib install flixel-addons 3.3.2 --quiet

echo [6/15] flixel-tools
haxelib install flixel-tools 1.5.1 --quiet

:: Engine
echo [7/15] hscript-iris
haxelib git hscript-iris https://github.com/Psych-Plus-Team/hscript-iris.git --quiet

echo [8/15] moonchart
haxelib install moonchart 0.5.1 --quiet

echo [9/15] tjson
haxelib install tjson 1.4.0 --quiet

echo [10/15] flxanimate
haxelib git flxanimate https://github.com/Dot-Stuff/flxanimate 768740a56b26aa0c072720e0d1236b94afe68e3e --quiet

echo [11/15] linc_luajit
haxelib git linc_luajit https://github.com/Psych-Plus-Team/linc_luajit.git --quiet

echo [12/15] hxdiscord_rpc
haxelib install hxdiscord_rpc --quiet --skip-dependencies

echo [13/15] hxvlc
haxelib install hxvlc 2.2.6 --quiet --skip-dependencies

echo [14/15] funkin.vis
haxelib git funkin.vis https://github.com/FunkinCrew/funkVis 22b1ce089dd924f15cdc4632397ef3504d464e90 --quiet

echo [15/15] grig.audio
haxelib git grig.audio https://gitlab.com/haxe-grig/grig.audio.git cbf91e2180fd2e374924fe74844086aab7891666 --quiet

echo.
echo Finished installing libraries!
pause