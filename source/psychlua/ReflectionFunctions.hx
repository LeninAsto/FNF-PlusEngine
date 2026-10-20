package psychlua;

import Type.ValueType;
import haxe.Constraints;

import backend.ClassResolver;
import substates.GameOverSubstate;
import objects.StrumNote;

//
// Functions that use a high amount of Reflections, which are somewhat CPU intensive
// These functions are held together by duct tape
//

class ReflectionFunctions
{
	static final instanceStr:Dynamic = "##PSYCHLUA_STRINGTOOBJ";

	static function getLegacyPropertyTarget(objectName:String):Dynamic
	{
		if(objectName == null || objectName.trim().length == 0)
			return LuaUtils.getTargetInstance();
		return LuaUtils.getObjectDirectly(objectName);
	}

	static function isLegacyPropertyCall(objectName:String, propertyOrValue:Dynamic, thirdArgument:Dynamic):Bool
	{
		if(thirdArgument == null || !Std.isOfType(propertyOrValue, String))
			return false;
		if(objectName == null || objectName.trim().length == 0)
			return true;
		// The modern form uses a complete path in argument #1. The legacy form
		// passes an object tag first and a property path second.
		return objectName.indexOf('.') < 0 && getLegacyPropertyTarget(objectName) != null;
	}

	static function getPropertyFromTarget(target:Dynamic, property:String, allowMaps:Bool):Dynamic
	{
		if(target == null || property == null || property.length == 0)
			return target;
		var split:Array<String> = property.split('.');
		for(part in split)
		{
			if(target == null) return null;
			target = LuaUtils.getVarInArray(target, part, allowMaps);
		}
		return target;
	}

	static function setPropertyOnTarget(target:Dynamic, property:String, value:Dynamic, allowMaps:Bool):Dynamic
	{
		if(target == null || property == null || property.length == 0)
			return null;
		var split:Array<String> = property.split('.');
		for(i in 0...split.length - 1)
		{
			target = LuaUtils.getVarInArray(target, split[i], allowMaps);
			if(target == null) return null;
		}
		return LuaUtils.setVarInArray(target, split[split.length - 1], value, allowMaps);
	}

	static function resolveClass(className:String):Class<Dynamic>
	{
		return ClassResolver.resolveClass(className);
	}

	public static function implement(funk:FunkinLua)
	{
		var lua:State = funk.lua;
		Lua_helper.add_callback(lua, "getProperty", function(variable:String, ?allowMapsOrProperty:Dynamic = false) {
			// Compatibility with engines/mods using getProperty(object, property).
			if(Std.isOfType(allowMapsOrProperty, String))
				return getPropertyFromTarget(getLegacyPropertyTarget(variable), cast allowMapsOrProperty, false);

			var allowMaps:Bool = allowMapsOrProperty == true;
			var split:Array<String> = variable.split('.');
			if(split.length > 1)
				return LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split, true, allowMaps), split[split.length-1], allowMaps);
			return LuaUtils.getVarInArray(LuaUtils.getTargetInstance(), variable, allowMaps);
		});
		Lua_helper.add_callback(lua, "setProperty", function(variable:String, value:Dynamic, ?thirdArgument:Dynamic = null, ?allowInstances:Bool = false) {
			// Compatibility with setProperty(object, property, value), used by a
			// number of older Psych/Kade-derived mods.
			if(isLegacyPropertyCall(variable, value, thirdArgument))
			{
				var parsedValue:Dynamic = allowInstances ? parseInstances(thirdArgument) : thirdArgument;
				return setPropertyOnTarget(getLegacyPropertyTarget(variable), cast value, parsedValue, false);
			}

			var allowMaps:Bool = thirdArgument == true;
			var split:Array<String> = variable.split('.');
			if(split.length > 1) {
				LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split, true, allowMaps), split[split.length-1], allowInstances ? parseInstances(value) : value, allowMaps);
				return value;
			}
			LuaUtils.setVarInArray(LuaUtils.getTargetInstance(), variable, allowInstances ? parseInstances(value) : value, allowMaps);
			return value;
		});
		Lua_helper.add_callback(lua, "getPropertyFromClass", function(classVar:String, variable:String, ?allowMaps:Bool = false) {
			var myClass:Dynamic = resolveClass(classVar);
			if(myClass == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_reflectionfunctions.getpropertyfromclass_class_value_not_found', "getPropertyFromClass: Class {1} not found", [classVar]), false, false, FlxColor.RED);
				return null;
			}
			variable = ClassResolver.resolveClientPrefsDataProperty(classVar, variable);

			var split:Array<String> = variable.split('.');
			if(split.length > 1) {
				var obj:Dynamic = LuaUtils.getVarInArray(myClass, split[0], allowMaps);
				for (i in 1...split.length-1)
					obj = LuaUtils.getVarInArray(obj, split[i], allowMaps);

				return LuaUtils.getVarInArray(obj, split[split.length-1], allowMaps);
			}
			return LuaUtils.getVarInArray(myClass, variable, allowMaps);
		});
		Lua_helper.add_callback(lua, "setPropertyFromClass", function(classVar:String, variable:String, value:Dynamic, ?allowMaps:Bool = false, ?allowInstances:Bool = false) {
			var myClass:Dynamic = resolveClass(classVar);
			if(myClass == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_reflectionfunctions.setpropertyfromclass_class_value_not_found', "setPropertyFromClass: Class {1} not found", [classVar]), false, false, FlxColor.RED);
				return null;
			}
			variable = ClassResolver.resolveClientPrefsDataProperty(classVar, variable);

			var split:Array<String> = variable.split('.');
			if(split.length > 1) {
				var obj:Dynamic = LuaUtils.getVarInArray(myClass, split[0], allowMaps);
				for (i in 1...split.length-1)
					obj = LuaUtils.getVarInArray(obj, split[i], allowMaps);

				LuaUtils.setVarInArray(obj, split[split.length-1], allowInstances ? parseInstances(value) : value, allowMaps);
				return value;
			}
			LuaUtils.setVarInArray(myClass, variable, allowInstances ? parseInstances(value) : value, allowMaps);
			return value;
		});
		Lua_helper.add_callback(lua, "getPropertyFromGroup", function(group:String, index:Int, variable:Dynamic, ?allowMaps:Bool = false):Dynamic {
			var split:Array<String> = group.split('.');
			var realObject:Dynamic = null;
			if(split.length > 1)
				realObject = LuaUtils.getPropertyLoop(split, false, allowMaps);
			else
				realObject = Reflect.getProperty(LuaUtils.getTargetInstance(), group);

			var groupOrArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), group);
			if(groupOrArray != null)
			{
				switch(Type.typeof(groupOrArray))
				{
					case TClass(Array): //Is Array
						var leArray:Dynamic = realObject[index];
						if(leArray != null) {
							var result:Dynamic = null;
							if(Type.typeof(variable) == ValueType.TInt)
								result = leArray[variable];
							else
								result = LuaUtils.getGroupStuff(leArray, variable, allowMaps);
							return result;
						}
						FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_reflectionfunctions.getpropertyfromgroup_missing_object', "getPropertyFromGroup: Object #{1} from group: {2} doesn't exist!", [index, group]), false, false, FlxColor.RED);

					default: //Is Group
						var member:Dynamic = realObject.members[index];
						#if (MODCHART_ALLOWED && LUA_ALLOWED)
						// When the modchart manager is active, expose rendered strum x/y so Lua scripts
						// using getPropertyFromGroup('playerStrums'...) can track the real visual position.
						if (member != null && Std.isOfType(member, StrumNote) && Std.isOfType(variable, String))
						{
							var propName:String = cast variable;
							if (propName == 'x' || propName == 'y')
							{
								var renderedPoint = ModchartFunctions.getRenderedStrumPosition(cast member);
								if (renderedPoint != null)
									return propName == 'x' ? renderedPoint.x : renderedPoint.y;
							}
						}
						#end

						var result:Dynamic = LuaUtils.getGroupStuff(member, variable, allowMaps);
						return result;
				}
			}
			FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_reflectionfunctions.getpropertyfromgroup_missing_group', "getPropertyFromGroup: Group/Array {1} doesn't exist!", [group]), false, false, FlxColor.RED);
			return null;
		});
		Lua_helper.add_callback(lua, "setPropertyFromGroup", function(group:String, index:Int, variable:Dynamic, value:Dynamic, ?allowMaps:Bool = false, ?allowInstances:Bool = false) {
			var split:Array<String> = group.split('.');
			var realObject:Dynamic = null;
			if(split.length > 1)
				realObject = LuaUtils.getPropertyLoop(split, false, allowMaps);
			else
				realObject = Reflect.getProperty(LuaUtils.getTargetInstance(), group);

			if(realObject != null)
			{
				switch(Type.typeof(realObject))
				{
					case TClass(Array): //Is Array
						var leArray:Dynamic = realObject[index];
						if(leArray != null)
						{
							if(Type.typeof(variable) == ValueType.TInt)
							{
								leArray[variable] = allowInstances ? parseInstances(value) : value;
								return value;
							}
							LuaUtils.setGroupStuff(leArray, variable, allowInstances ? parseInstances(value) : value, allowMaps);
						}

					default: //Is Group
						LuaUtils.setGroupStuff(realObject.members[index], variable, allowInstances ? parseInstances(value) : value, allowMaps);
				}
			}
			else FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_reflectionfunctions.setpropertyfromgroup_missing_group', "setPropertyFromGroup: Group/Array {1} doesn't exist!", [group]), false, false, FlxColor.RED);
			return value;
		});
		Lua_helper.add_callback(lua, "addToGroup", function(group:String, tag:String, ?index:Int = -1) {
			var obj:FlxSprite = LuaUtils.getObjectDirectly(tag);
			if(obj == null || obj.destroy == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_reflectionfunctions.addtogroup_object_value_is_not_valid', "addToGroup: Object {1} is not valid!", [tag]), false, false, FlxColor.RED);
				return;
			}

			var groupOrArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), group);
			if(groupOrArray == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_reflectionfunctions.addtogroup_group_array_value_is_not_valid', "addToGroup: Group/Array {1} is not valid!", [group]), false, false, FlxColor.RED);
				return;
			}

			if(index < 0)
			{
				switch(Type.typeof(groupOrArray))
				{
					case TClass(Array): //Is Array
						groupOrArray.push(obj);

					default: //Is Group
						groupOrArray.add(obj);
				}
			}
			else groupOrArray.insert(index, obj);
		});
		Lua_helper.add_callback(lua, "removeFromGroup", function(group:String, ?index:Int = -1, ?dontDestroyOrTag:Dynamic = false, ?destroy:Bool = true) {
			var obj:FlxSprite = null;
			var shouldDestroy:Bool = destroy;
			var tag:String = null;
			if (Std.isOfType(dontDestroyOrTag, Bool))
				shouldDestroy = !cast(dontDestroyOrTag, Bool);
			else if (dontDestroyOrTag != null)
				tag = Std.string(dontDestroyOrTag);

			if(tag != null)
			{
				obj = LuaUtils.getObjectDirectly(tag);
				if(obj == null || obj.destroy == null)
				{
					FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_reflectionfunctions.removefromgroup_object_value_is_not_valid', "removeFromGroup: Object {1} is not valid!", [tag]), false, false, FlxColor.RED);
					return;
				}
			}

			var groupOrArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), group);
			if(groupOrArray == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_reflectionfunctions.removefromgroup_group_array_value_is_not_valid', "removeFromGroup: Group/Array {1} is not valid!", [group]), false, false, FlxColor.RED);
				return;
			}

			switch(Type.typeof(groupOrArray))
			{
				case TClass(Array): //Is Array
					if(obj != null)
					{
						groupOrArray.remove(obj);
						if(shouldDestroy) obj.destroy();
					}
					else
					{
						obj = groupOrArray[index];
						groupOrArray.remove(obj);
						if(shouldDestroy && obj != null && obj.destroy != null) obj.destroy();
					}

				default: //Is Group
					if(obj == null) obj = groupOrArray.members[index];
					groupOrArray.remove(obj, true);
					if(shouldDestroy && obj != null) obj.destroy();
			}
		});

		Lua_helper.add_callback(lua, "callMethod", function(funcToRun:String, ?args:Array<Dynamic>) {
			var parent:Dynamic = PlayState.instance;
			var split:Array<String> = funcToRun.split('.');
			var varParent:Dynamic = MusicBeatState.getVariables().get(split[0].trim());
			if (varParent != null) {
				split.shift();
				funcToRun = split.join('.').trim();
				parent = varParent;
			}

			if(funcToRun.length > 0) {
				return callMethodFromObject(parent, funcToRun, parseInstances(args));
			}
			return Reflect.callMethod(null, parent, parseInstances(args));
		});
		Lua_helper.add_callback(lua, "callMethodFromClass", function(className:String, funcToRun:String, ?args:Array<Dynamic>) {
			return callMethodFromObject(resolveClass(className), funcToRun, parseInstances(args));
		});

		Lua_helper.add_callback(lua, "createInstance", function(variableToSave:String, className:String, ?args:Array<Dynamic>) {
			if (!Std.isOfType(args, Array)) args = [];
			variableToSave = variableToSave.trim().replace('.', '');
			if(MusicBeatState.getVariables().get(variableToSave) == null)
			{
				if(args == null) args = [];
				var myType:Dynamic = resolveClass(className);

				if(myType == null)
				{
					FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_reflectionfunctions.createinstance_class_value_not_found', "createInstance: Class {1} not found", [className]), false, false, FlxColor.RED);
					return false;
				}

				var obj:Dynamic = Type.createInstance(myType, parseInstances(args));
				if(obj != null)
					MusicBeatState.getVariables().set(variableToSave, obj);
				else
					FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_reflectionfunctions.createinstance_create_failed', "createInstance: Failed to create {1}, arguments are possibly wrong.", [variableToSave]), false, false, FlxColor.RED);

				return (obj != null);
			}
			else FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_reflectionfunctions.createinstance_variable_in_use', "createInstance: Variable {1} is already being used and cannot be replaced!", [variableToSave]), false, false, FlxColor.RED);
			return false;
		});
		Lua_helper.add_callback(lua, "addInstance", function(objectName:String, ?inFront:Bool = false) {
			var savedObj:Dynamic = MusicBeatState.getVariables().get(objectName);
			if(savedObj != null)
			{
				var obj:Dynamic = savedObj;
				if (inFront)
					LuaUtils.getTargetInstance().add(obj);
				else
				{
					if(!PlayState.instance.isDead)
						PlayState.instance.insert(PlayState.instance.members.indexOf(LuaUtils.getLowestCharacterGroup()), obj);
					else
						GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), obj);
				}
			}
			else FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.psychlua_reflectionfunctions.addinstance_can_t_add_what_doesn_t_exist_value', "addInstance: Can't add what doesn't exist~ ({1})", [objectName]), false, false, FlxColor.RED);
		});
		Lua_helper.add_callback(lua, "instanceArg", function(instanceName:String, ?className:String = null) {
			var retStr:String ='$instanceStr::$instanceName';
			if(className != null) retStr += '::$className';
			return retStr;
		});
	}

	static function parseInstanceArray(arg:Array<Dynamic>) {
		var newArray:Array<Dynamic> = [];
		for (val in arg)
			newArray.push(parseInstances(val));
		return newArray;
	}
	public static function parseInstances(arg:Dynamic):Dynamic {
		if (arg == null) return null;

		if (Std.isOfType(arg, Array)) {
			return parseInstanceArray(arg);
		} else {
			return parseSingleInstance(arg);
		}
	}
	public static function parseSingleInstance(arg:Dynamic)
	{
		var argStr:String = cast arg;
		if(argStr != null && argStr.length > instanceStr.length)
		{
			var index:Int = argStr.indexOf('::');
			if(index > -1)
			{
				argStr = argStr.substring(index+2);
				//trace('Op1: $argStr');
				var lastIndex:Int = argStr.lastIndexOf('::');

				var split:Array<String> = (lastIndex > -1) ? argStr.substring(0, lastIndex).split('.') : argStr.split('.');
				arg = (lastIndex > -1) ? resolveClass(argStr.substring(lastIndex+2)) : PlayState.instance;
				for (j in 0...split.length)
				{
					//trace('Op2: ${Type.getClass(args[i])}, ${split[j]}');
					arg = LuaUtils.getVarInArray(arg, split[j].trim());
					//trace('Op3: ${args[i] != null ? Type.getClass(args[i]) : null}');
				}
			}
		}
		return arg;
	}

	static function callMethodFromObject(classObj:Dynamic, funcStr:String, args:Array<Dynamic>)
	{
		var split:Array<String> = funcStr.split('.');
		var funcToRun:Function = null;
		var obj:Dynamic = classObj;
		//trace('start: ' + obj);
		if(obj == null)
		{
			return null;
		}

		for (i in 0...split.length)
		{
			obj = LuaUtils.getVarInArray(obj, split[i].trim());
			//trace(obj, split[i]);
		}

		funcToRun = cast obj;
		//trace('end: $obj');
		return funcToRun != null ? Reflect.callMethod(obj, funcToRun, args) : null;
	}
}

