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
		return true;

	public static function hasScript(name:String):Bool
		return name != null && name.length > 0 && scripting.ScriptRegistry.resolveClassFile('substates.$name') != null;

	public static function tryCreate(name:String, ?fallback:FlxSubState, ?args:Array<Dynamic>):FlxSubState {
		if (!hasScript(name))
			return fallback;

		var created:Dynamic = scripting.ScriptRegistry.instantiate('substates.$name', args);
		if (created != null && Std.isOfType(created, FlxSubState)) {
			trace('[ScriptableSubstate] loaded substates.$name');
			return cast created;
		}

		trace('[ScriptableSubstate] substates.$name did not create a FlxSubState.');
		return fallback;
	}
}
#end
