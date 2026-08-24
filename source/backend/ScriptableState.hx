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
		return true;

	public static function hasScript(name:String):Bool
		return name != null && name.length > 0 && scripting.ScriptRegistry.resolveClassFile('states.$name') != null;

	public static function tryCreate(name:String, ?fallback:FlxState, ?args:Array<Dynamic>):FlxState {
		if (!hasScript(name))
			return fallback;

		var created:Dynamic = scripting.ScriptRegistry.instantiate('states.$name', args);
		if (created != null && Std.isOfType(created, FlxState)) {
			trace('[ScriptableState] loaded states.$name');
			return cast created;
		}

		trace('[ScriptableState] states.$name did not create a FlxState.');
		return fallback;
	}

	public static function tryOverride(state:FlxState):Null<FlxState> {
		if (state == null)
			return null;

		var fullName:String = Type.getClassName(Type.getClass(state));
		if (fullName == null)
			return null;

		var parts:Array<String> = fullName.split('.');
		var name:String = parts[parts.length - 1];
		var created:FlxState = tryCreate(name, state);
		return created != state ? created : null;
	}
}
#end
