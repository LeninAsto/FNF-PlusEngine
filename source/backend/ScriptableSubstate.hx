package backend;

import flixel.FlxSubState;

#if HSCRIPT_ALLOWED
import psychlua.ScriptRegistry;
import psychlua.ScriptedClass.IScriptSuperProxyProvider;
import psychlua.ScriptedClass.ScriptClassHandler;
import psychlua.ScriptedClass.ScriptTemplateBase;
import psychlua.ScriptedNativeFactory;

/**
 * Psych/Megumin-style class-backed substate host.
 *
 * A substate override lives at scripts/classes/substates/<Name>.hx
 * (or classes/substates/<Name>.hx) and should extend MusicBeatSubstate.
 */
class ScriptableSubstate extends MusicBeatSubstate implements IScriptSuperProxyProvider
{
	public var substateName(default, null):String;
	var scriptInstance:ScriptTemplateBase;
	var superProxy:Dynamic;

	public function new(?name:String, ?fallback:FlxSubState, ?args:Array<Dynamic>)
	{
		substateName = name != null ? name : 'ScriptableSubstate';
		super();
		buildScriptInstance(args != null ? args : []);
	}

	public static inline function overridesEnabled():Bool
		return true;

	public static function hasScript(name:String):Bool
		return name != null && name.length > 0 && ScriptRegistry.resolveClassFile('substates.$name') != null;

	public static function tryCreate(name:String, ?fallback:FlxSubState, ?args:Array<Dynamic>):FlxSubState
	{
		if (!hasScript(name))
			return fallback;

		var substate:ScriptableSubstate = new ScriptableSubstate(name, fallback, args);
		return substate.scriptInstance != null ? substate : fallback;
	}

	function buildScriptInstance(args:Array<Dynamic>):Void
	{
		var handler:ScriptClassHandler = ScriptRegistry.resolveClass('substates.$substateName');
		if (handler == null)
			return;

		scriptInstance = ScriptedNativeFactory.buildOn(handler, this, args);
		if (scriptInstance == null)
			trace('[ScriptableSubstate] $substateName did not create a ScriptTemplateBase instance.');
		else
			trace('[ScriptableSubstate] loaded substates.$substateName');
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
			methods.set('close', nativeSuperClose);
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

	function nativeSuperClose():Void
		super.close();

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

	override function close():Void
	{
		if (ScriptedNativeFactory.has(scriptInstance, 'close'))
			ScriptedNativeFactory.call(scriptInstance, 'close');
		else
			super.close();
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
