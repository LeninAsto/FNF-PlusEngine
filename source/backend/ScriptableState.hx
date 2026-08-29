package backend;

import flixel.FlxState;

#if HSCRIPT_ALLOWED
class ScriptableState extends MusicBeatState {
	public var stateName(default, null):String;

	public function new(?name:String) {
		stateName = name != null ? name : 'ScriptableState';
		super(false, stateName);
	}

	public static inline function overridesEnabled():Bool
		return false;

	public static function hasScript(name:String):Bool
		return false;

	public static function tryCreate(name:String, ?fallback:FlxState, ?args:Array<Dynamic>):FlxState {
		return fallback;
	}

	public static function tryOverride(state:FlxState):Null<FlxState> {
		return null;
	}
}
#end
