#if LUA_ALLOWED
package psychlua;

import backend.MusicBeatState;
import flixel.FlxState;
import openfl.utils.Assets as OpenFlAssets;

#if sys
import sys.FileSystem;
#end

class LuaState extends MusicBeatState
{
	public static var instance:LuaState;

	public var stateName:String;
	public var luaArray:Array<FunkinLua> = [];
	var _fallbackState:FlxState;
	var _created:Bool = false;

	public function new(name:String, ?fallbackState:FlxState)
	{
		super();
		stateName = name;
		_fallbackState = fallbackState;
	}

	public static function findScript(name:String):Null<String>
	{
		var rel:String = 'scripts/states/$name.lua';

		#if sys
		#if MODS_ALLOWED
		var modded:String = Paths.modFolders(rel);
		if(FileSystem.exists(modded)) return modded;
		#end

		var shared:String = Paths.getSharedPath(rel);
		if(FileSystem.exists(shared)) return shared;
		#end

		var assetPath:String = Paths.getSharedPath(rel);
		if(OpenFlAssets.exists(assetPath)) return assetPath;
		return null;
	}

	public static function findPreset():Null<String>
	{
		var rel:String = 'scripts/states/_preset.lua';
		#if sys
		#if MODS_ALLOWED
		var modded:String = Paths.modFolders(rel);
		if(FileSystem.exists(modded)) return modded;
		#end
		var shared:String = Paths.getSharedPath(rel);
		if(FileSystem.exists(shared)) return shared;
		#end
		var assetPath:String = Paths.getSharedPath(rel);
		return OpenFlAssets.exists(assetPath) ? assetPath : null;
	}

	public static inline function hasScript(name:String):Bool
		return findScript(name) != null;

	override function create():Void
	{
		instance = this;
		super.create();

		var path:String = findScript(stateName);
		if(path == null)
		{
			if(_fallbackState != null)
				MusicBeatState.switchState(_fallbackState);
			return;
		}

		loadLua(findPreset(), false);
		loadLua(path, false);

		callOnLuas('onCreatePre', []);
		callOnLuas('onCreate', []);
		callOnLuas('onCreatePost', []);
		_created = true;
	}

	function makeContext(scriptPath:String):LuaHostContext
		return new LuaHostContext(LuaHostKind.STATE, stateName, this, this, variables, luaArray);

	function loadLua(path:String, autoCreate:Bool = false):Void
	{
		if(path == null) return;
		try
		{
			new FunkinLua(path, makeContext(path), autoCreate);
		}
		catch(e:Dynamic)
		{
			FunkinLua.luaTrace('[LuaState:$stateName] Failed to load $path: $e', true, false, FlxColor.RED);
		}
	}

	override function update(elapsed:Float):Void
	{
		if(LuaUtils.isStop(callOnLuas('onUpdate', [elapsed]))) return;
		super.update(elapsed);
		callOnLuas('onUpdatePost', [elapsed]);
	}

	override public function stepHit():Void
	{
		callOnLuas('onStepHit', [curStep]);
		super.stepHit();
	}

	override public function beatHit():Void
	{
		callOnLuas('onBeatHit', [curBeat]);
		super.beatHit();
	}

	override public function sectionHit():Void
	{
		callOnLuas('onSectionHit', [curSection]);
		super.sectionHit();
	}

	override function destroy():Void
	{
		callOnLuas('onDestroy', []);
		for(script in luaArray.copy())
			if(script != null) script.stop();
		luaArray = [];
		if(instance == this) instance = null;
		super.destroy();
	}

	public function setOnLuas(varName:String, arg:Dynamic, ?exclusions:Array<String> = null):Void
	{
		if(exclusions == null) exclusions = [];
		for(script in luaArray)
			if(script != null && !exclusions.contains(script.scriptName))
				script.set(varName, arg);
	}

	public function callOnLuas(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false,
			?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null):Dynamic
	{
		if(args == null) args = [];
		if(excludeScripts == null) excludeScripts = [];
		if(excludeValues == null) excludeValues = [];

		var ret:Dynamic = LuaUtils.Function_Continue;
		for(script in luaArray)
		{
			if(script == null || excludeScripts.contains(script.scriptName)) continue;
			var value:Dynamic = script.call(funcName, args);
			if(excludeValues.contains(value)) continue;
			if(value != null && value != LuaUtils.Function_Continue)
			{
				ret = value;
				if(!ignoreStops && LuaUtils.isStop(value)) return value;
			}
		}
		return ret;
	}
}
#end
