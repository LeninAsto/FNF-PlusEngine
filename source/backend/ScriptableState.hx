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
		return hasLaunchedMod() && scripting.ScriptedStates.hasState(name, scripting.ScriptedStates.ResolveScope.PRIORITY);

	public static function tryCreate(name:String, ?fallback:FlxState, ?args:Array<Dynamic>):FlxState {
		if (!hasLaunchedMod())
			return fallback;
		var state:MusicBeatState = scripting.ScriptedStates.loadState(name, args, scripting.ScriptedStates.ResolveScope.PRIORITY);
		if (state == null && hasScript(name))
			scripting.ScriptError.warn('ScriptableState', 'Scripted state "$name" exists but could not be created; using hardcoded fallback.');
		return state != null ? state : fallback;
	}

	public static function tryCreateLazy(name:String, fallback:Void->FlxState, ?args:Array<Dynamic>):FlxState {
		if (!hasLaunchedMod())
			return fallback != null ? fallback() : null;
		var state:MusicBeatState = scripting.ScriptedStates.loadState(name, args, scripting.ScriptedStates.ResolveScope.PRIORITY);
		if (state == null && hasScript(name))
			scripting.ScriptError.warn('ScriptableState', 'Scripted state "$name" exists but could not be created; using hardcoded fallback.');
		return state != null ? state : (fallback != null ? fallback() : null);
	}

	public static function tryCreateFromFallback(fallback:FlxState):FlxState {
		if (fallback == null)
			return fallback;
		if (!hasLaunchedMod())
			return fallback;

		if (Std.isOfType(fallback, MusicBeatState)) {
			var musicState:MusicBeatState = cast fallback;
			if (musicState.isScriptedState)
				return fallback;
		}

		var cls:Class<Dynamic> = Type.getClass(fallback);
		if (cls == null)
			return fallback;

		var fullName:String = Type.getClassName(cls);
		if (fullName == null || fullName.length < 1)
			return fallback;

		var parts:Array<String> = fullName.split('.');
		var stateName:String = parts[parts.length - 1];
		var state:MusicBeatState = scripting.ScriptedStates.loadState(stateName, [], scripting.ScriptedStates.ResolveScope.PRIORITY);
		return state != null ? state : fallback;
	}

	public static function tryOverride(state:FlxState):Null<FlxState> {
		return null;
	}

	static inline function hasLaunchedMod():Bool
		return Mods.launchedMod != null && Mods.launchedMod.length > 0;
}
#end
