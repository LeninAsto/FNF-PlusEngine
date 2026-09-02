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
		return Mods.launchedMod != null && Mods.launchedMod.length > 0 && scripting.ScriptedStates.hasState(name, scripting.ScriptedStates.ResolveScope.LAUNCHED);

	public static function tryCreate(name:String, ?fallback:FlxState, ?args:Array<Dynamic>):FlxState {
		if (Mods.launchedMod == null || Mods.launchedMod.length < 1)
			return fallback;

		var state:MusicBeatState = scripting.ScriptedStates.loadState(name, args, scripting.ScriptedStates.ResolveScope.LAUNCHED);
		return state != null ? state : fallback;
	}

	public static function tryOverride(state:FlxState):Null<FlxState> {
		return null;
	}
}
#end
