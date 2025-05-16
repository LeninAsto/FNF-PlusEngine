package backend;

import flixel.FlxG;
import sys.FileSystem;
import sys.io.File;
import states.MainMenuState;

class ModCompatibilityChecker {
    public static function checkModCompatibility(modName:String, onWarning:String->Void):Void {
        if (modName == "ModTemplate.zip" || modName == "readme.txt") return;

        var modsPath = "mods/";
        var modDataPath = modsPath + modName + "/data/compatibility.txt";
        if (FileSystem.exists(modDataPath)) {
            var lines = File.getContent(modDataPath).split("\n");
            if (lines.length >= 2) {
                var psychVersion = lines[0].trim();
                var plusVersion = lines[1].trim();

                if (compareVersions(MainMenuState.psychEngineVersion, psychVersion) < 0) {
                    onWarning('WARNING: Mod "$modName" requires Psych Engine version $psychVersion or higher!');
                }
                if (compareVersions(psychVersion, "0.6.3") <= 0) {
                    onWarning('WARNING: Mod "$modName" was made for Psych Engine 0.6.3. This mod may not be compatible with this engine!');
                }
                if (compareVersions(MainMenuState.plusEngineVersion, plusVersion) < 0) {
                    onWarning('WARNING: Mod "$modName" requires Plus Engine version $plusVersion or higher!');
                }
            }
        } else {
            onWarning('WARNING: Missing "compatibility.txt" file! There may be errors in the mod, or maybe not.');
        }
    }

    public static function compareVersions(a:String, b:String):Int {
        var aParts = a.split(".");
        var bParts = b.split(".");
        var len = Std.int(Math.max(aParts.length, bParts.length));
        for (i in 0...len) {
            var aNum = i < aParts.length ? Std.parseInt(aParts[i]) : 0;
            var bNum = i < bParts.length ? Std.parseInt(bParts[i]) : 0;
            if (aNum < bNum) return -1;
            if (aNum > bNum) return 1;
        }
        return 0;
    }
}