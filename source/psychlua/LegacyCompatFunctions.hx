#if LUA_ALLOWED
package psychlua;

class LegacyCompatFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua:State = funk.lua;

		Lua_helper.add_callback(lua, "getScore", function() {
			StructurePsychOld.warnLegacyLuaUsage('getScore()', "getProperty('songScore')");
			var game:PlayState = PlayState.instance;
			return game != null ? game.songScore : 0;
		});
		Lua_helper.add_callback(lua, "getMisses", function() {
			StructurePsychOld.warnLegacyLuaUsage('getMisses()', "getProperty('songMisses')");
			var game:PlayState = PlayState.instance;
			return game != null ? game.songMisses : 0;
		});
		Lua_helper.add_callback(lua, "getHits", function() {
			StructurePsychOld.warnLegacyLuaUsage('getHits()', "getProperty('songHits')");
			var game:PlayState = PlayState.instance;
			return game != null ? game.songHits : 0;
		});

		Lua_helper.add_callback(lua, "changePresence", function(details:String = 'In the Menus', ?state:String, ?smallImageKey:String, ?hasStartTimestamp:Bool = false, ?endTimestamp:Float = 0) {
			StructurePsychOld.warnLegacyLuaUsage('changePresence(...)', 'changeDiscordPresence(...)');
			#if DISCORD_ALLOWED
			DiscordClient.changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
			return true;
			#else
			return false;
			#end
		});

		Lua_helper.add_callback(lua, "getGlobalFromScript", function(luaFile:String, global:String) {
			StructurePsychOld.warnLegacyLuaUsage('getGlobalFromScript(luaFile, global)', 'callScript(...) or shared variables with setOnLuas/setOnScripts');
			var script:FunkinLua = findSiblingScript(funk, luaFile);
			if(script == null || script.lua == null || global == null) return null;

			Lua.getglobal(script.lua, global);
			var result:Dynamic = readSimpleLuaValue(script.lua, -1);
			Lua.pop(script.lua, 1);
			return result;
		});

		Lua_helper.add_callback(lua, "setGlobalFromScript", function(luaFile:String, global:String, value:Dynamic) {
			StructurePsychOld.warnLegacyLuaUsage('setGlobalFromScript(luaFile, global, value)', 'setOnLuas(...) or setOnScripts(...)');
			var script:FunkinLua = findSiblingScript(funk, luaFile);
			if(script == null || script.lua == null || global == null) return false;

			script.set(global, value);
			return true;
		});
	}

	static function findSiblingScript(funk:FunkinLua, luaFile:String):FunkinLua
	{
		if(luaFile == null || luaFile.length < 1) return null;

		var wanted:String = normalizeScriptPath(luaFile);
		if(!wanted.endsWith('.lua')) wanted += '.lua';

		for(script in getScripts(funk))
		{
			if(script == null || script.closed || script.lua == null) continue;

			var scriptPath:String = normalizeScriptPath(script.scriptName);
			if(scriptPath == wanted || scriptPath.endsWith('/' + wanted))
				return script;

			var slash:Int = scriptPath.lastIndexOf('/');
			var fileName:String = slash > -1 ? scriptPath.substring(slash + 1) : scriptPath;
			if(fileName == wanted)
				return script;
		}
		return null;
	}

	static function getScripts(funk:FunkinLua):Array<FunkinLua>
	{
		if(funk.context != null && funk.context.scriptList != null)
			return funk.context.scriptList;
		if(PlayState.instance != null)
			return PlayState.instance.luaArray;
		return [];
	}

	static function normalizeScriptPath(path:String):String
	{
		return path.replace('\\', '/');
	}

	static function readSimpleLuaValue(lua:State, index:Int):Dynamic
	{
		return switch(Lua.type(lua, index))
		{
			case Lua.LUA_TNUMBER: Lua.tonumber(lua, index);
			case Lua.LUA_TSTRING: Lua.tostring(lua, index);
			case Lua.LUA_TBOOLEAN: Lua.toboolean(lua, index);
			default: null;
		}
	}
}
#end
