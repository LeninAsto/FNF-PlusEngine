#!/bin/sh
set -eu

echo "Installing Plus Engine haxelibs..."
echo "This uses the normal/global haxelib repo."
mkdir -p ~/haxelib
haxelib setup ~/haxelib

###############################################################################
# Core build stack - required by the engine and every target.
###############################################################################
echo "[Core] hxcpp"
haxelib git hxcpp https://github.com/Psych-Plus-Team/hxcpp

echo "[Core] lime"
haxelib git lime https://github.com/Psych-Plus-Team/lime

echo "[Core] openfl 9.5.0"
haxelib install openfl 9.5.0 --quiet

###############################################################################
# HaxeFlixel stack - required by Plus/Psych and VSlice runtime.
###############################################################################
echo "[Flixel] flixel"
haxelib git flixel https://github.com/Psych-Plus-Team/flixel

echo "[Flixel] flixel-addons 3.3.2"
haxelib install flixel-addons 3.3.2 --quiet

echo "[Flixel] flixel-tools 1.5.1"
haxelib install flixel-tools 1.5.1 --quiet

echo "[Flixel] flixel-ui 2.6.2"
haxelib install flixel-ui 2.6.2 --quiet

###############################################################################
# Plus/Psych runtime - classic engine systems and classic mods.
# flxanimate is the Psych/Plus animation package: imports are flxanimate.*.
# Do not replace it with flixel-animate; VSlice uses a separate animate.* lib.
###############################################################################
echo "[Plus/Psych] hscript-iris"
haxelib git hscript-iris https://github.com/Psych-Plus-Team/hscript-iris

echo "[Plus/Psych] linc_luajit"
haxelib git linc_luajit https://github.com/Psych-Plus-Team/linc_luajit

echo "[Plus/Psych] flxanimate 4.0.0"
haxelib install flxanimate 4.0.0 --quiet

echo "[Plus/Psych] moonchart 0.5.0"
haxelib install moonchart 0.5.0 --quiet

echo "[Plus/Psych] tjson 1.4.0"
haxelib install tjson 1.4.0 --quiet

###############################################################################
# Optional desktop/media integrations.
###############################################################################
echo "[Optional] hxdiscord_rpc 1.3.0"
haxelib install hxdiscord_rpc 1.3.0 --quiet --skip-dependencies

echo "[Optional] hxvlc 2.2.6"
haxelib install hxvlc 2.2.6 --quiet --skip-dependencies

###############################################################################
# VSlice runtime / Polymod - needed when compiling with -D vslice or
# FEATURE_POLYMOD_MODS. These are required for source/funkin compatibility.
# polymod and flixel-animate intentionally use the Psych-Plus-Team forks.
# flixel-animate is the VSlice/Funkin animation package: imports are animate.*.
###############################################################################
echo "[VSlice] polymod fork"
haxelib git polymod https://github.com/Psych-Plus-Team/polymod master

echo "[VSlice] json2object"
haxelib git json2object https://github.com/FunkinCrew/json2object 59e0467c953d1f26e3cbf2a070f140e2d2e8457d

echo "[VSlice] jsonpatch 1.1.0"
haxelib install jsonpatch 1.1.0 --quiet

echo "[VSlice] jsonpath 1.1.0"
haxelib install jsonpath 1.1.0 --quiet

echo "[VSlice] thx.core git"
haxelib git thx.core https://github.com/fponticelli/thx.core 2bf2b992e06159510f595554e6b952e47922f128

echo "[VSlice] thx.semver git"
haxelib git thx.semver https://github.com/fponticelli/thx.semver bdb191fe7cf745c02a980749906dbf22719e200b

echo "[VSlice] flixel-animate fork"
haxelib git flixel-animate https://github.com/Psych-Plus-Team/flixel-animate main

echo "[VSlice] FlxPartialSound"
haxelib git FlxPartialSound https://github.com/FunkinCrew/FlxPartialSound.git 2f984e244f1544ca98c0e03b9b21ae570f07ac55

echo "[VSlice] hxjsonast"
haxelib git hxjsonast https://github.com/nadako/hxjsonast/ 20e72cc68c823496359775ac1f06500e67f189d5

echo "[VSlice/Base Game] funkin.vis"
haxelib git funkin.vis https://github.com/FunkinCrew/funkVis 22b1ce089dd924f15cdc4632397ef3504d464e90

echo "[VSlice/Base Game] grig.audio"
haxelib git grig.audio https://gitlab.com/haxe-grig/grig.audio.git cbf91e2180fd2e374924fe74844086aab7891666

echo "[Check libraries]"
haxelib list
###############################################################################
# Android-only VSlice/mobile helper. Install manually on Android machines:
# haxelib install extension-androidtools
###############################################################################

echo "Finished installing libraries!"
