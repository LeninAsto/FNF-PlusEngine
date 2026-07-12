package shaders;

import openfl.filters.ColorMatrixFilter;
import openfl.filters.BitmapFilter;
import flixel.FlxG;
import backend.ClientPrefs;

class ColorblindFilter {
    private static final COLOR_MATRICES:Map<String, Array<Float>> = [
        'None' => [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0],
        'Protanopia' => [0.567, 0.433, 0.0, 0.558, 0.442, 0.0, 0.0, 0.242, 0.758],
        'Protanomaly' => [0.817, 0.183, 0.0, 0.333, 0.667, 0.0, 0.0, 0.125, 0.875],
        'Deuteranopia' => [0.625, 0.375, 0.0, 0.7, 0.3, 0.0, 0.0, 0.3, 0.7],
        'Deuteranomaly' => [0.8, 0.2, 0.0, 0.258, 0.742, 0.0, 0.0, 0.142, 0.858],
        'Tritanopia' => [0.95, 0.05, 0.0, 0.0, 0.433, 0.567, 0.0, 0.475, 0.525],
        'Tritanomaly' => [0.967, 0.033, 0.0, 0.0, 0.733, 0.267, 0.0, 0.183, 0.817],
        'Achromatopsia' => [0.299, 0.587, 0.114, 0.299, 0.587, 0.114, 0.299, 0.587, 0.114],
        'Achromatomaly' => [0.618, 0.320, 0.062, 0.163, 0.775, 0.062, 0.163, 0.320, 0.516]
    ];
    
    private static var currentFilter:ColorMatrixFilter = null;
    private static var currentMode:String = "None";

    public static function apply(mode:String = "None", ?targetFilters:Array<BitmapFilter>):Array<BitmapFilter> {
        if (mode == null) mode = "None";

        if (mode == currentMode && currentFilter != null) {
            if (targetFilters != null) {
                targetFilters.push(currentFilter);
                return targetFilters;
            }
        }

        var matrix3x3:Array<Float> = COLOR_MATRICES.exists(mode) 
            ? COLOR_MATRICES[mode] 
            : COLOR_MATRICES["None"];

        var matrix4x5:Array<Float> = [
            matrix3x3[0], matrix3x3[1], matrix3x3[2], 0, 0,
            matrix3x3[3], matrix3x3[4], matrix3x3[5], 0, 0,
            matrix3x3[6], matrix3x3[7], matrix3x3[8], 0, 0,
            0, 0, 0, 1, 0
        ];

        if (currentFilter == null) {
            currentFilter = new ColorMatrixFilter(matrix4x5);
        } else {
            currentFilter.matrix = matrix4x5;
        }
        
        currentMode = mode;

        if (targetFilters != null) {
            targetFilters.push(currentFilter);
            return targetFilters;
        } else {
            var filters:Array<BitmapFilter> = [currentFilter];
            FlxG.game.filtersEnabled = true;
            FlxG.game.setFilters(filters);
            return filters;
        }
    }

    public static function remove():Void {
        FlxG.game.filtersEnabled = false;
        FlxG.game.setFilters([]);
    }

    public static function UpdateColors(?input:Array<BitmapFilter>):Void {
        var mode:String = "None";
        try {
            mode = ClientPrefs.data.colorblindMode;
        } catch (e:Dynamic) {
            mode = "None";
        }
        
        apply(mode, input);
    }

    public static function isModeActive(mode:String):Bool {
        return currentMode == mode;
    }

    public static function getAvailableModes():Array<String> {
        return [
            "None",
            "Protanopia",
            "Protanomaly",
            "Deuteranopia",
            "Deuteranomaly",
            "Tritanopia",
            "Tritanomaly",
            "Achromatopsia",
            "Achromatomaly"
        ];
    }
}