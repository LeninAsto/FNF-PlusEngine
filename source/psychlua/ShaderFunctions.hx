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
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.initluashader_platform_unsupported_for_runtime_shaders', "initLuaShader: Platform unsupported for Runtime Shaders!"), false, false, FlxColor.RED);
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
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.makeluashader_shader_value_failed_or_is_missing', "makeLuaShader: Shader {1} failed or is missing!", [shader]), false, false, FlxColor.RED);
				return false;
			}

			MusicBeatState.getVariables().set(tag, runtimeShader);
			if(funk.context != null && funk.context.variables != null)
				funk.context.variables.set(tag, runtimeShader);
			return true;
			#else
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.makeluashader_platform_unsupported_for_runtime_shaders', "makeLuaShader: Platform unsupported for Runtime Shaders!"), false, false, FlxColor.RED);
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
					FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.setspriteshader_shader_value_failed_to_compile_and_was_removed', "setSpriteShader: Shader {1} failed to compile and was removed.", [shader]), false, false, FlxColor.RED);
					return false;
				}

				leObj.shader = runtimeShader;
				return true;
			}
			#else
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.setspriteshader_platform_unsupported_for_runtime_shaders', "setSpriteShader: Platform unsupported for Runtime Shaders!"), false, false, FlxColor.RED);
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
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.setcamerashader_shader_value_failed_or_is_missing', "setCameraShader: Shader {1} failed or is missing!", [shader]), false, false, FlxColor.RED);
				return false;
			}

			removeCameraShaderFilter(camera, shader);
			var filters:Array<openfl.filters.BitmapFilter> = camera.filters != null ? camera.filters.copy() : [];
			filters.push(new openfl.filters.ShaderFilter(runtimeShader));
			camera.filters = filters;
			camera.filtersEnabled = true;
			return true;
			#else
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.setcamerashader_platform_unsupported_for_runtime_shaders', "setCameraShader: Platform unsupported for Runtime Shaders!"), false, false, FlxColor.RED);
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
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.removecamerashader_platform_unsupported_for_runtime_shaders', "removeCameraShader: Platform unsupported for Runtime Shaders!"), false, false, FlxColor.RED);
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
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.getshaderbool_shader_is_not_flxruntimeshader', "getShaderBool: Shader is not FlxRuntimeShader!"), false, false, FlxColor.RED);
				return null;
			}
			return shader.getBool(prop);
			#else
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.getshaderbool_platform_unsupported_for_runtime_shaders', "getShaderBool: Platform unsupported for Runtime Shaders!"), false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderBoolArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.getshaderboolarray_shader_is_not_flxruntimeshader', "getShaderBoolArray: Shader is not FlxRuntimeShader!"), false, false, FlxColor.RED);
				return null;
			}
			return shader.getBoolArray(prop);
			#else
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.getshaderboolarray_platform_unsupported_for_runtime_shaders', "getShaderBoolArray: Platform unsupported for Runtime Shaders!"), false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderInt", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.getshaderint_shader_is_not_flxruntimeshader', "getShaderInt: Shader is not FlxRuntimeShader!"), false, false, FlxColor.RED);
				return null;
			}
			return shader.getInt(prop);
			#else
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.getshaderint_platform_unsupported_for_runtime_shaders', "getShaderInt: Platform unsupported for Runtime Shaders!"), false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderIntArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.getshaderintarray_shader_is_not_flxruntimeshader', "getShaderIntArray: Shader is not FlxRuntimeShader!"), false, false, FlxColor.RED);
				return null;
			}
			return shader.getIntArray(prop);
			#else
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.getshaderintarray_platform_unsupported_for_runtime_shaders', "getShaderIntArray: Platform unsupported for Runtime Shaders!"), false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderFloat", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.getshaderfloat_shader_is_not_flxruntimeshader', "getShaderFloat: Shader is not FlxRuntimeShader!"), false, false, FlxColor.RED);
				return null;
			}
			return shader.getFloat(prop);
			#else
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.getshaderfloat_platform_unsupported_for_runtime_shaders', "getShaderFloat: Platform unsupported for Runtime Shaders!"), false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderFloatArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.getshaderfloatarray_shader_is_not_flxruntimeshader', "getShaderFloatArray: Shader is not FlxRuntimeShader!"), false, false, FlxColor.RED);
				return null;
			}
			return shader.getFloatArray(prop);
			#else
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.getshaderfloatarray_platform_unsupported_for_runtime_shaders', "getShaderFloatArray: Platform unsupported for Runtime Shaders!"), false, false, FlxColor.RED);
			return null;
			#end
		});


		Lua_helper.add_callback(lua, "setShaderBool", function(obj:String, prop:String, value:Bool) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.setshaderbool_shader_is_not_flxruntimeshader', "setShaderBool: Shader is not FlxRuntimeShader!"), false, false, FlxColor.RED);
				return false;
			}
			shader.setBool(prop, value);
			return true;
			#else
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.setshaderbool_platform_unsupported_for_runtime_shaders', "setShaderBool: Platform unsupported for Runtime Shaders!"), false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderBoolArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.setshaderboolarray_shader_is_not_flxruntimeshader', "setShaderBoolArray: Shader is not FlxRuntimeShader!"), false, false, FlxColor.RED);
				return false;
			}
			shader.setBoolArray(prop, values);
			return true;
			#else
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.setshaderboolarray_platform_unsupported_for_runtime_shaders', "setShaderBoolArray: Platform unsupported for Runtime Shaders!"), false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderInt", function(obj:String, prop:String, value:Int) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.setshaderint_shader_is_not_flxruntimeshader', "setShaderInt: Shader is not FlxRuntimeShader!"), false, false, FlxColor.RED);
				return false;
			}
			shader.setInt(prop, value);
			return true;
			#else
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.setshaderint_platform_unsupported_for_runtime_shaders', "setShaderInt: Platform unsupported for Runtime Shaders!"), false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderIntArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.setshaderintarray_shader_is_not_flxruntimeshader', "setShaderIntArray: Shader is not FlxRuntimeShader!"), false, false, FlxColor.RED);
				return false;
			}
			shader.setIntArray(prop, values);
			return true;
			#else
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.setshaderintarray_platform_unsupported_for_runtime_shaders', "setShaderIntArray: Platform unsupported for Runtime Shaders!"), false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderFloat", function(obj:String, prop:String, value:Float) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.setshaderfloat_shader_is_not_flxruntimeshader', "setShaderFloat: Shader is not FlxRuntimeShader!"), false, false, FlxColor.RED);
				return false;
			}
			shader.setFloat(prop, value);
			return true;
			#else
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.setshaderfloat_platform_unsupported_for_runtime_shaders', "setShaderFloat: Platform unsupported for Runtime Shaders!"), false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderFloatArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.setshaderfloatarray_shader_is_not_flxruntimeshader', "setShaderFloatArray: Shader is not FlxRuntimeShader!"), false, false, FlxColor.RED);
				return false;
			}

			shader.setFloatArray(prop, values);
			return true;
			#else
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.setshaderfloatarray_platform_unsupported_for_runtime_shaders', "setShaderFloatArray: Platform unsupported for Runtime Shaders!"), false, false, FlxColor.RED);
			return true;
			#end
		});

		Lua_helper.add_callback(lua, "setShaderSampler2D", function(obj:String, prop:String, bitmapdataPath:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.setshadersampler2d_shader_is_not_flxruntimeshader', "setShaderSampler2D: Shader is not FlxRuntimeShader!"), false, false, FlxColor.RED);
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
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.setshadersampler2d_platform_unsupported_for_runtime_shaders', "setShaderSampler2D: Platform unsupported for Runtime Shaders!"), false, false, FlxColor.RED);
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
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.error_on_getting_shader_object_value_not_found', "Error on getting shader: Object {1} not found", [obj]), false, false, FlxColor.RED);
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
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.shader_value_failed_before_skipping_it_for_this_session', "Shader {1} failed before, skipping it for this session.", [shader]), false, false, FlxColor.RED);
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
		FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_shaderfunctions.runtime_shaders_need_mods_allowed_to_load_value', "Runtime shaders need MODS_ALLOWED to load {1}.", [shader]), false, false, FlxColor.RED);
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
