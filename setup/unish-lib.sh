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

echo "[Core - 3D] away3d"
haxelib git away3d https://github.com/openfl/away3d.git

###############################################################################
# HaxeFlixel stack - required by Plus/Psych.
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
###############################################################################
echo "[Plus/Psych] hscript-iris"
haxelib git hscript-iris https://github.com/Psych-Plus-Team/hscript-iris

echo "[Plus/Psych] hxscript"
haxelib git hxscript https://github.com/Psych-Plus-Team/hxscript.git

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
# Lightweight audio visualization used by Plus/Psych UI helpers.
###############################################################################
echo "[Audio Viz] funkin.vis"
haxelib git funkin.vis https://github.com/FunkinCrew/funkVis 22b1ce089dd924f15cdc4632397ef3504d464e90

echo "[Audio Viz] grig.audio"
haxelib git grig.audio https://gitlab.com/haxe-grig/grig.audio.git cbf91e2180fd2e374924fe74844086aab7891666

echo "[Check libraries]"
haxelib list

echo "Finished installing libraries!"
