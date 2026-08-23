package backend;

import flixel.FlxState;

#if HSCRIPT_ALLOWED
import psychlua.ScriptRegistry;
import psychlua.ScriptedClass.IScriptSuperProxyProvider;
import psychlua.ScriptedClass.ScriptClassHandler;
import psychlua.ScriptedClass.ScriptTemplateBase;
import psychlua.ScriptedNativeFactory;

/**
 * Psych/Megumin-style class-backed state host.
 *
 * A state override lives at scripts/classes/states/<Name>.hx (or classes/states/<Name>.hx)
 * and should declare `package states; class <Name> extends MusicBeatState`.
 */
class ScriptableState extends MusicBeatState implements IScriptSuperProxyProvider
{
	public var stateName(default, null):String;
	var scriptInstance:ScriptTemplateBase;
	var superProxy:Dynamic;

	public function new(?name:String, ?fallback:FlxState, ?args:Array<Dynamic>)
	{
		stateName = name != null ? name : 'ScriptableState';
		super(false, stateName);
		buildScriptInstance(args != null ? args : []);
	}

	public static inline function overridesEnabled():Bool
		return true;

	public static function hasScript(name:String):Bool
		return name != null && name.length > 0 && ScriptRegistry.resolveClassFile('states.$name') != null;

	public static function tryCreate(name:String, ?fallback:FlxState, ?args:Array<Dynamic>):FlxState
	{
		if (!hasScript(name))
			return fallback;

		var state:ScriptableState = new ScriptableState(name, fallback, args);
		return state.scriptInstance != null ? state : fallback;
	}

	public static function tryOverride(state:FlxState):Null<ScriptableState>
	{
		if (state == null)
			return null;

		var fullName:String = Type.getClassName(Type.getClass(state));
		if (fullName == null)
			return null;

		var parts:Array<String> = fullName.split('.');
		var name:String = parts[parts.length - 1];
		var created:FlxState = tryCreate(name, state);
		return Std.isOfType(created, ScriptableState) ? cast created : null;
	}

	function buildScriptInstance(args:Array<Dynamic>):Void
	{
		var handler:ScriptClassHandler = ScriptRegistry.resolveClass('states.$stateName');
		if (handler == null)
			return;

		scriptInstance = ScriptedNativeFactory.buildOn(handler, this, args);
		if (scriptInstance == null)
			trace('[ScriptableState] $stateName did not create a ScriptTemplateBase instance.');
		else
			trace('[ScriptableState] loaded states.$stateName');
	}

	public function getScriptSuperProxy():Dynamic
	{
		if (superProxy == null)
		{
			var methods:Map<String, Dynamic> = [];
			methods.set('create', nativeSuperCreate);
			methods.set('update', nativeSuperUpdate);
			methods.set('stepHit', nativeSuperStepHit);
			methods.set('beatHit', nativeSuperBeatHit);
			methods.set('sectionHit', nativeSuperSectionHit);
			methods.set('destroy', nativeSuperDestroy);
			superProxy = ScriptedNativeFactory.makeSuperFunction(this, nativeSuperNew, methods);
		}
		return superProxy;
	}

	function nativeSuperNew(args:Array<Dynamic>):Dynamic
		return this;

	function nativeSuperCreate():Void
		super.create();

	function nativeSuperUpdate(elapsed:Float):Void
		super.update(elapsed);

	function nativeSuperStepHit():Void
		super.stepHit();

	function nativeSuperBeatHit():Void
		super.beatHit();

	function nativeSuperSectionHit():Void
		super.sectionHit();

	function nativeSuperDestroy():Void
		super.destroy();

	override function create():Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'create'))
			ScriptedNativeFactory.call(scriptInstance, 'create');
		else
			super.create();
	}

	override function update(elapsed:Float):Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'update'))
			ScriptedNativeFactory.call(scriptInstance, 'update', [elapsed]);
		else
			super.update(elapsed);
	}

	override public function stepHit():Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'stepHit'))
			ScriptedNativeFactory.call(scriptInstance, 'stepHit');
		else
			super.stepHit();
	}

	override public function beatHit():Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'beatHit'))
			ScriptedNativeFactory.call(scriptInstance, 'beatHit');
		else
			super.beatHit();
	}

	override public function sectionHit():Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'sectionHit'))
			ScriptedNativeFactory.call(scriptInstance, 'sectionHit');
		else
			super.sectionHit();
	}

	override function destroy():Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'destroy'))
			ScriptedNativeFactory.call(scriptInstance, 'destroy');
		else
			super.destroy();
		scriptInstance = null;
		superProxy = null;
	}
}
#end
