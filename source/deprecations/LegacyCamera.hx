package deprecations;

import flixel.FlxCamera;
import openfl.filters.BitmapFilter;

class LegacyCamera
{
    public static function resolveMember(object:Dynamic, field:String, ?scriptOwner:String):Dynamic
    {
        if (field != 'setFilters' || !Std.isOfType(object, FlxCamera)) return null;
        var camera:FlxCamera = cast object;
        return function(filters:Null<Array<BitmapFilter>>):Void
        {
            HaxeLibDeprecations.warnMessage('flixel.FlxCamera.setFilters', 'setFilters is deprecated, use camera.filters instead', scriptOwner);
            camera.filters = filters;
        };
    }
}
