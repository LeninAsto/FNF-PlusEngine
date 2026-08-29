package backend;

import flixel.FlxSubState;

#if HSCRIPT_ALLOWED
class ScriptableSubstate extends MusicBeatSubstate {
	public var substateName(default, null):String;

	public function new(?name:String) {
		substateName = name != null ? name : 'ScriptableSubstate';
		super();
	}

	public static inline function overridesEnabled():Bool
		return false;

	public static function hasScript(name:String):Bool
		return false;

	public static function tryCreate(name:String, ?fallback:FlxSubState, ?args:Array<Dynamic>):FlxSubState {
		return fallback;
	}
}
#end
