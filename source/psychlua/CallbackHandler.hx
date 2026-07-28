#if LUA_ALLOWED
package psychlua;

class CallbackHandler
{
	public static inline function call(l:State, fname:String):Int
	{
		try
		{
			//trace('calling $fname');
			var cbf:Dynamic = Lua_helper.callbacks.get(fname);

			//Local functions have the lowest priority
			//This is to prevent a "for" loop being called in every single operation,
			//so that it only loops on reserved/special functions
			if(cbf == null) 
			{
				//trace('checking last script');
				var last:FunkinLua = FunkinLua.lastCalledScript;
				if(last == null || last.lua != l)
				{
					var script:FunkinLua = FunkinLua.getScriptFromState(l);
					if(script != null)
						cbf = script.callbacks.get(fname);
				}
				else cbf = last.callbacks.get(fname);
			}
			
			if(cbf == null) return 0;

			var nparams:Int = Lua.gettop(l);
			var args:Array<Dynamic> = [];

			if ((fname == 'changeControls' || fname == 'applyGameplayControls') && nparams > 0) {
				args[0] = readGameplayControlsTable(l, 1);
			} else {
				for (i in 0...nparams) {
					args[i] = Convert.fromLua(l, i + 1);
				}
			}

			var ret:Dynamic = null;
			/* return the number of results */

			ret = Reflect.callMethod(null,cbf,args);

			if(ret != null){
				Convert.toLua(l, ret);
				return 1;
			}
		}
		catch(e:Dynamic)
		{
			if(Lua_helper.sendErrorsToLua)
			{
				var errorText:String = Std.isOfType(e, haxe.Exception) ? cast(e, haxe.Exception).details() : Std.string(e);
				LuaL.error(l, 'CALLBACK ERROR! $errorText');
				return 0;
			}
			throw e;
		}
		return 0;
	}

	static function readGameplayControlsTable(l:State, idx:Int):Dynamic
	{
		if (Lua.type(l, idx) != Lua.LUA_TTABLE)
			return null;

		final result:Dynamic = {};
		readGameplayControlField(l, idx, result, 'left');
		readGameplayControlField(l, idx, result, 'down');
		readGameplayControlField(l, idx, result, 'up');
		readGameplayControlField(l, idx, result, 'right');
		readGameplayControlField(l, idx, result, 'note_left');
		readGameplayControlField(l, idx, result, 'note_down');
		readGameplayControlField(l, idx, result, 'note_up');
		readGameplayControlField(l, idx, result, 'note_right');
		return result;
	}

	static function readGameplayControlField(l:State, tableIndex:Int, result:Dynamic, fieldName:String):Void
	{
		Lua.getfield(l, tableIndex, fieldName);
		if (Lua.type(l, -1) != Lua.LUA_TNIL) {
			final values = readLuaStringList(l, -1);
			if (values != null)
				Reflect.setField(result, fieldName, values);
		}
		Lua.pop(l, 1);
	}

	static function readLuaStringList(l:State, idx:Int):Null<Array<String>>
	{
		switch (Lua.type(l, idx)) {
			case Lua.LUA_TSTRING | Lua.LUA_TNUMBER:
				return [luaValueToString(l, idx)];
			case Lua.LUA_TTABLE:
				final values:Array<String> = [];
				for (i in 1...9) {
					Lua.rawgeti(l, idx, i);
					final valueType = Lua.type(l, -1);
					if (valueType == Lua.LUA_TNIL) {
						Lua.pop(l, 1);
						break;
					}
					if (valueType == Lua.LUA_TSTRING || valueType == Lua.LUA_TNUMBER)
						values.push(luaValueToString(l, -1));
					Lua.pop(l, 1);
				}
				return values;
		}
		return null;
	}

	static function luaValueToString(l:State, idx:Int):String
	{
		return cast(Lua.tostring(l, idx), String);
	}
}
#end
