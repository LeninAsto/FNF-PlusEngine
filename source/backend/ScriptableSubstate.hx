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
		return Mods.launchedMod != null && Mods.launchedMod.length > 0 && scripting.ScriptedStates.hasSubstate(name, scripting.ScriptedStates.ResolveScope.LAUNCHED);

	public static function tryCreate(name:String, ?fallback:FlxSubState, ?args:Array<Dynamic>):FlxSubState {
		if (Mods.launchedMod == null || Mods.launchedMod.length < 1)
			return fallback;

		var substate:MusicBeatSubstate = scripting.ScriptedStates.loadSubstate(name, args, scripting.ScriptedStates.ResolveScope.LAUNCHED);
		return substate != null ? substate : fallback;
	}
}
#end
