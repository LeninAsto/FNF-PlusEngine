package scripting;

#if HSCRIPT_ALLOWED
import flixel.FlxG;
import flixel.util.FlxColor;

class ScriptError {
	public static function show(text:String, ?color:FlxColor):Void {
		var finalColor:FlxColor = color == null ? FlxColor.WHITE : color;
		if (states.PlayState.instance != null)
			states.PlayState.instance.addTextToDebug(text, finalColor);
		else
			FlxG.log.warn(text);
		trace(text);
	}

	public static function warn(origin:String, text:String):Void
		show('WARNING: $origin: $text', FlxColor.YELLOW);

	public static function error(origin:String, text:String):Void
		show('ERROR: $origin: $text', FlxColor.RED);
}
#end
