#!/bin/sh
# SETUP FOR MAC AND LINUX SYSTEMS!!!
# REMINDER THAT YOU NEED HAXE INSTALLED PRIOR TO USING THIS
# https://haxe.org/download
cd ..
echo Makking the main haxelib and setuping folder in same time..
mkdir ~/haxelib && haxelib setup ~/haxelib
echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib git hxcpp https://github.com/Psych-Plus-Team/hxcpp --quiet
haxelib git lime https://github.com/Psych-Plus-Team/lime --quiet
haxelib install openfl 9.4.1 --quiet
haxelib git flixel https://github.com/Psych-Plus-Team/flixel --quiet
haxelib install flixel-addons 3.3.2 --quiet
haxelib install flixel-ui 2.6.2 --quiet
haxelib install moonchart --quiet
haxelib install flixel-tools 1.5.1 --quiet
haxelib git hscript-iris https://github.com/Psych-Plus-Team/hscript-iris --quiet
haxelib install tjson 1.4.0 --quiet
haxelib git flxanimate https://github.com/Dot-Stuff/flxanimate 768740a56b26aa0c072720e0d1236b94afe68e3e --quiet
haxelib git linc_luajit https://github.com/Psych-Plus-Team/linc_luajit --quiet
haxelib install hxdiscord_rpc --quiet --skip-dependencies
haxelib install hxvlc 2.2.5 --quiet --skip-dependencies
haxelib git funkin.vis https://github.com/FunkinCrew/funkVis 22b1ce089dd924f15cdc4632397ef3504d464e90 --quiet --skip-dependencies
haxelib git grig.audio https://gitlab.com/haxe-grig/grig.audio.git cbf91e2180fd2e374924fe74844086aab7891666 --quiet
echo Finished!