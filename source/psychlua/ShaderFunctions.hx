package psychlua;

import backend.ClientPrefs;
import backend.GLCapabilities;
import backend.Native;

#if (!flash && sys)
import flixel.addons.display.FlxRuntimeShader;
#end

class ShaderFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua = funk.lua;
		// Read-only GPU capability API. Mods can select a modern effect or a safe fallback.
		funk.addLocalCallback("getOpenGLVersion", () -> Native.getOpenGLVersion());
		funk.addLocalCallback("getOpenGLTier", () -> GLCapabilities.tierLabel());
		funk.addLocalCallback("isOpenGLES", function() {
			GLCapabilities.init();
			return GLCapabilities.isES;
		});
		funk.addLocalCallback("getOpenGLMaxTextureSize", function() {
			GLCapabilities.init();
			return GLCapabilities.maxTextureSize;
		});
		funk.addLocalCallback("supportsOpenGLFeature", (feature:String) -> GLCapabilities.supports(feature));

		// shader shit
		funk.addLocalCallback("initLuaShader", function(name:String) {
			if(!ClientPrefs.data.shaders) return false;

			#if (!flash && MODS_ALLOWED && sys)
			return funk.initLuaShader(name);
			#else
			FunkinLua.luaTrace("initLuaShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});
		
		funk.addLocalCallback("makeLuaShader", function(tag:String, shader:String) {
			if(!ClientPrefs.data.shaders) return false;

			#if (!flash && sys)
			tag = tag.replace('.', '');
			var runtimeShader:FlxRuntimeShader = resolveRuntimeShader(funk, shader);
			if(runtimeShader == null)
			{
				FunkinLua.luaTrace('makeLuaShader: Shader $shader failed or is missing!', false, false, FlxColor.RED);
				return false;
			}

			MusicBeatState.getVariables().set(tag, runtimeShader);
			if(funk.context != null && funk.context.variables != null)
				funk.context.variables.set(tag, runtimeShader);
			return true;
			#else
			FunkinLua.luaTrace("makeLuaShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});

		funk.addLocalCallback("setSpriteShader", function(obj:String, shader:String) {
			if(!ClientPrefs.data.shaders) return false;

			#if (!flash && sys)
			var split:Array<String> = obj.split('.');
			var leObj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}

			if(leObj != null) {
				var runtimeShader:FlxRuntimeShader = null;
				runtimeShader = resolveRuntimeShader(funk, shader, function(error:Dynamic)
				{
					if(leObj != null)
						leObj.shader = null;
				});

				if(runtimeShader == null)
				{
					leObj.shader = null;
					FunkinLua.luaTrace('setSpriteShader: Shader $shader failed to compile and was removed.', false, false, FlxColor.RED);
					return false;
				}

				leObj.shader = runtimeShader;
				return true;
			}
			#else
			FunkinLua.luaTrace("setSpriteShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});

		funk.addLocalCallback("setCameraShader", function(cameraName:String, shader:String) {
			if(!ClientPrefs.data.shaders) return false;

			#if (!flash && sys)
			var camera:FlxCamera = LuaUtils.cameraFromString(cameraName);
			if(camera == null)
				return false;

			var runtimeShader:FlxRuntimeShader = resolveRuntimeShader(funk, shader, function(error:Dynamic)
			{
				removeCameraShaderFilter(camera, shader);
			});
			if(runtimeShader == null)
			{
				FunkinLua.luaTrace('setCameraShader: Shader $shader failed or is missing!', false, false, FlxColor.RED);
				return false;
			}

			removeCameraShaderFilter(camera, shader);
			var filters:Array<openfl.filters.BitmapFilter> = camera.filters != null ? camera.filters.copy() : [];
			filters.push(new openfl.filters.ShaderFilter(runtimeShader));
			camera.filters = filters;
			camera.filtersEnabled = true;
			return true;
			#else
			FunkinLua.luaTrace("setCameraShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});

		Lua_helper.add_callback(lua, "removeCameraShader", function(cameraName:String, ?shader:String = null) {
			#if (!flash && sys)
			var camera:FlxCamera = LuaUtils.cameraFromString(cameraName);
			if(camera == null)
				return false;
			return removeCameraShaderFilter(camera, shader);
			#else
			FunkinLua.luaTrace("removeCameraShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});

		Lua_helper.add_callback(lua, "removeSpriteShader", function(obj:String) {
			var split:Array<String> = obj.split('.');
			var leObj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}

			if(leObj != null) {
				leObj.shader = null;
				return true;
			}
			return false;
		});


		Lua_helper.add_callback(lua, "getShaderBool", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderBool: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getBool(prop);
			#else
			FunkinLua.luaTrace("getShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderBoolArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderBoolArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getBoolArray(prop);
			#else
			FunkinLua.luaTrace("getShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderInt", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderInt: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getInt(prop);
			#else
			FunkinLua.luaTrace("getShaderInt: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderIntArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderIntArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getIntArray(prop);
			#else
			FunkinLua.luaTrace("getShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderFloat", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderFloat: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getFloat(prop);
			#else
			FunkinLua.luaTrace("getShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderFloatArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderFloatArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getFloatArray(prop);
			#else
			FunkinLua.luaTrace("getShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});


		Lua_helper.add_callback(lua, "setShaderBool", function(obj:String, prop:String, value:Bool) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderBool: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setBool(prop, value);
			return true;
			#else
			FunkinLua.luaTrace("setShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderBoolArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderBoolArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setBoolArray(prop, values);
			return true;
			#else
			FunkinLua.luaTrace("setShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderInt", function(obj:String, prop:String, value:Int) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderInt: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setInt(prop, value);
			return true;
			#else
			FunkinLua.luaTrace("setShaderInt: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderIntArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderIntArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setIntArray(prop, values);
			return true;
			#else
			FunkinLua.luaTrace("setShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderFloat", function(obj:String, prop:String, value:Float) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderFloat: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setFloat(prop, value);
			return true;
			#else
			FunkinLua.luaTrace("setShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderFloatArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderFloatArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}

			shader.setFloatArray(prop, values);
			return true;
			#else
			FunkinLua.luaTrace("setShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return true;
			#end
		});

		Lua_helper.add_callback(lua, "setShaderSampler2D", function(obj:String, prop:String, bitmapdataPath:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderSampler2D: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}

			// trace('bitmapdatapath: $bitmapdataPath');
			var value = Paths.image(bitmapdataPath);
			if(value != null && value.bitmap != null)
			{
				// trace('Found bitmapdata. Width: ${value.bitmap.width} Height: ${value.bitmap.height}');
				shader.setSampler2D(prop, value.bitmap);
				return true;
			}
			return false;
			#else
			FunkinLua.luaTrace("setShaderSampler2D: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
	}
	
	#if (!flash && MODS_ALLOWED && sys)
	public static function getShader(obj:String):FlxRuntimeShader
	{
		var split:Array<String> = obj.split('.');
		var target:Dynamic = null;
		if(split.length > 1) target = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
		else target = LuaUtils.getObjectDirectly(split[0]);

		if(target == null)
		{
			FunkinLua.luaTrace('Error on getting shader: Object $obj not found', false, false, FlxColor.RED);
			return null;
		}

		if(Std.isOfType(target, FlxRuntimeShader))
			return cast target;

		var shaderValue:Dynamic = Reflect.getProperty(target, 'shader');
		if(shaderValue != null && Std.isOfType(shaderValue, FlxRuntimeShader))
			return cast shaderValue;

		return null;
	}
	#end

	#if (!flash && sys)
	static function resolveRuntimeShader(funk:FunkinLua, shader:String, ?onError:Dynamic):FlxRuntimeShader
	{
		var existing:Dynamic = LuaUtils.getObjectDirectly(shader);
		if(existing != null && Std.isOfType(existing, FlxRuntimeShader))
			return cast existing;

		#if MODS_ALLOWED
		if(shaders.ErrorHandledShader.isBroken(shader))
		{
			FunkinLua.luaTrace('Shader $shader failed before, skipping it for this session.', false, false, FlxColor.RED);
			return null;
		}

		if(!funk.runtimeShaders.exists(shader) && !funk.initLuaShader(shader))
			return null;

		var arr:Array<String> = funk.runtimeShaders.get(shader);
		var runtimeShader:shaders.ErrorHandledShader.ErrorHandledRuntimeShader = new shaders.ErrorHandledShader.ErrorHandledRuntimeShader(shader, arr[0], arr[1]);
		if(onError != null)
			runtimeShader.onError = onError;

		if(runtimeShader.failed || shaders.ErrorHandledShader.isBroken(shader))
			return null;

		return runtimeShader;
		#else
		FunkinLua.luaTrace('Runtime shaders need MODS_ALLOWED to load $shader.', false, false, FlxColor.RED);
		return null;
		#end
	}

	static function removeCameraShaderFilter(camera:FlxCamera, ?shader:String = null):Bool
	{
		if(camera == null || camera.filters == null)
			return false;

		if(shader == null || shader.length == 0)
		{
			camera.filters = [];
			return true;
		}

		var target:Dynamic = LuaUtils.getObjectDirectly(shader);
		var removed:Bool = false;
		var filters:Array<openfl.filters.BitmapFilter> = [];
		for(filter in camera.filters)
		{
			var keep:Bool = true;
			if(Std.isOfType(filter, openfl.filters.ShaderFilter))
			{
				var shaderFilter:openfl.filters.ShaderFilter = cast filter;
				var filterShader:Dynamic = shaderFilter.shader;
				if(filterShader == target)
					keep = false;
				else if(Std.isOfType(filterShader, shaders.ErrorHandledShader.ErrorHandledRuntimeShader))
				{
					var runtime:shaders.ErrorHandledShader.ErrorHandledRuntimeShader = cast filterShader;
					keep = runtime.shaderName != shader;
				}
			}

			if(keep)
				filters.push(filter);
			else
				removed = true;
		}

		camera.filters = filters;
		return removed;
	}
	#end
}
