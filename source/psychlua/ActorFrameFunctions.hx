package psychlua;

#if LUA_ALLOWED
import backend.MusicBeatState;
import flixel.util.FlxColor;
import psychlua.backend.actorframe.ActorFrameBackend;
import psychlua.backend.actorframe.ActorFrameLuaPrelude;

class ActorFrameFunctions
{
	public static function implement(funk:FunkinLua):Void
	{
		var lua = funk.lua;

		Lua_helper.add_callback(lua, "_actorFrameCreate",
			function(kind:String, tag:String, ?parentTag:String = null, ?texture:String = null, ?text:String = null, ?camera:String = "hud",
					?width:Float = 1, ?height:Float = 1, ?color:String = "FFFFFF")
			{
				return ActorFrameBackend.createActor(kind, tag, parentTag, texture, text, camera, width, height, color);
			});

		Lua_helper.add_callback(lua, "_actorFrameDestroy", function(tag:String)
		{
			return ActorFrameBackend.destroyActorTree(tag);
		});

		Lua_helper.add_callback(lua, "_actorFrameSet", function(tag:String, property:String, value:Dynamic)
		{
			return ActorFrameBackend.setActorProperty(tag, property, value);
		});

		Lua_helper.add_callback(lua, "_actorFrameGet", function(tag:String, property:String)
		{
			return ActorFrameBackend.getActorProperty(tag, property);
		});

		Lua_helper.add_callback(lua, "_actorFrameSetColor", function(tag:String, r:Dynamic, ?g:Dynamic = null, ?b:Dynamic = null, ?a:Dynamic = null)
		{
			return ActorFrameBackend.setActorColor(tag, r, g, b, a);
		});

		Lua_helper.add_callback(lua, "_actorFrameTween",
			function(tag:String, property:String, value:Dynamic, ?duration:Float = 0, ?ease:String = "linear", ?delay:Float = 0)
			{
				return ActorFrameBackend.tweenActorProperty(tag, property, value, duration, ease, delay);
			});

		Lua_helper.add_callback(lua, "_actorFrameCancelTweens", function(tag:String, ?finish:Bool = false)
		{
			return ActorFrameBackend.cancelActorTweens(tag, finish);
		});

		Lua_helper.add_callback(lua, "_actorFrameSetShader", function(tag:String, shader:String)
		{
			return ActorFrameBackend.setActorShader(funk, tag, shader);
		});

		Lua_helper.add_callback(lua, "_actorFrameSetTarget", function(tag:String, targetTag:String)
		{
			return ActorFrameBackend.setActorProxyTarget(tag, targetTag);
		});

		Lua_helper.add_callback(lua, "_actorFrameCapture", function(tag:String)
		{
			return ActorFrameBackend.captureActorFrameTexture(tag);
		});

		Lua_helper.add_callback(lua, "_actorFrameExists", function(tag:String)
		{
			return ActorFrameBackend.getActorVariable(tag) != null || MusicBeatState.getVariables().exists(tag);
		});

		runLuaChunk(funk, ActorFrameLuaPrelude.prelude(), "ActorFrame prelude");
	}

	public static function installHooks(funk:FunkinLua):Void
	{
		runLuaChunk(funk, ActorFrameLuaPrelude.hookInstaller(), "ActorFrame hooks");
	}

	static function runLuaChunk(funk:FunkinLua, code:String, label:String):Bool
	{
		if (funk == null || funk.lua == null)
			return false;
		var result:Int = LuaL.dostring(funk.lua, code);
		if (result != 0)
		{
			var msg:String = Lua.tostring(funk.lua, -1);
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_actorframefunctions.value_failed_value', "{1} failed: {2}", [label, msg]), false, false, FlxColor.RED);
			Lua.pop(funk.lua, 1);
			return false;
		}
		return true;
	}
}
#end
