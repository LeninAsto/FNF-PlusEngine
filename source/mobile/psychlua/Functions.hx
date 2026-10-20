package mobile.psychlua;

import psychlua.backend.CustomSubstate;
#if LUA_ALLOWED
import lime.ui.Haptic;
import psychlua.backend.FunkinLua;
import psychlua.backend.LuaUtils;
import mobile.backend.TouchUtil;
#if android
import mobile.backend.PsychJNI;
#end

/**
 * ...
 * @author: Karim Akra and Homura Akemi (HomuHomu833)
 */
class MobileFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua:State = funk.lua;
		Lua_helper.add_callback(lua, 'mobileC', Controls.instance.mobileC);

		Lua_helper.add_callback(lua, 'mobileControlsMode', getMobileControlsAsString());

		Lua_helper.add_callback(lua, "extraButtonPressed", (button:String) ->
		{
			button = button.toLowerCase();
			if (MusicBeatState.getState().mobileControls != null)
			{
				switch (button)
				{
					case 'second':
						return MusicBeatState.getState().mobileControls.buttonExtra2.pressed;
					default:
						return MusicBeatState.getState().mobileControls.buttonExtra.pressed;
				}
			}
			return false;
		});

		Lua_helper.add_callback(lua, "extraButtonJustPressed", (button:String) ->
		{
			button = button.toLowerCase();
			if (MusicBeatState.getState().mobileControls != null)
			{
				switch (button)
				{
					case 'second':
						return MusicBeatState.getState().mobileControls.buttonExtra2.justPressed;
					default:
						return MusicBeatState.getState().mobileControls.buttonExtra.justPressed;
				}
			}
			return false;
		});

		Lua_helper.add_callback(lua, "extraButtonJustReleased", (button:String) ->
		{
			button = button.toLowerCase();
			if (MusicBeatState.getState().mobileControls != null)
			{
				switch (button)
				{
					case 'second':
						return MusicBeatState.getState().mobileControls.buttonExtra2.justReleased;
					default:
						return MusicBeatState.getState().mobileControls.buttonExtra.justReleased;
				}
			}
			return false;
		});

		Lua_helper.add_callback(lua, "extraButtonReleased", (button:String) ->
		{
			button = button.toLowerCase();
			if (MusicBeatState.getState().mobileControls != null)
			{
				switch (button)
				{
					case 'second':
						return MusicBeatState.getState().mobileControls.buttonExtra2.released;
					default:
						return MusicBeatState.getState().mobileControls.buttonExtra.released;
				}
			}
			return false;
		});

		Lua_helper.add_callback(lua, "vibrate", (?duration:Int, ?period:Int) ->
		{
			if (duration == null)
				return FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.mobile_psychlua_functions.vibrate_no_duration_specified', "vibrate: No duration specified."));
			else if (period == null)
				period = 0;
			return Haptic.vibrate(period, duration);
		});

		Lua_helper.add_callback(lua, "addTouchPad", (DPadMode:String, ActionMode:String, ?addToCustomSubstate:Bool = false, ?posAtCustomSubstate:Int = -1) ->
		{
			PlayState.instance.makeLuaTouchPad(DPadMode, ActionMode);
			if (addToCustomSubstate)
			{
				if (PlayState.instance.luaTouchPad != null || !PlayState.instance.members.contains(PlayState.instance.luaTouchPad))
					CustomSubstate.insertLuaTpad(posAtCustomSubstate);
			}
			else
				PlayState.instance.addLuaTouchPad();
		});

		Lua_helper.add_callback(lua, "removeTouchPad", () ->
		{
			PlayState.instance.removeLuaTouchPad();
		});

		Lua_helper.add_callback(lua, "addTouchPadCamera", () ->
		{
			if (PlayState.instance.luaTouchPad == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.mobile_psychlua_functions.addtouchpadcamera_touch_pad_does_not_exist', "addTouchPadCamera: Touch Pad does not exist."));
				return;
			}
			PlayState.instance.addLuaTouchPadCamera();
		});

		Lua_helper.add_callback(lua, "touchPadJustPressed", function(button:Dynamic):Bool
		{
			if (PlayState.instance.luaTouchPad == null)
			{
				return false;
			}
			return PlayState.instance.luaTouchPadJustPressed(button);
		});

		Lua_helper.add_callback(lua, "touchPadPressed", function(button:Dynamic):Bool
		{
			if (PlayState.instance.luaTouchPad == null)
			{
				return false;
			}
			return PlayState.instance.luaTouchPadPressed(button);
		});

		Lua_helper.add_callback(lua, "touchPadJustReleased", function(button:Dynamic):Bool
		{
			if (PlayState.instance.luaTouchPad == null)
			{
				return false;
			}
			return PlayState.instance.luaTouchPadJustReleased(button);
		});

		Lua_helper.add_callback(lua, "touchPadReleased", function(button:Dynamic):Bool
		{
			if (PlayState.instance.luaTouchPad == null)
			{
				return false;
			}
			return PlayState.instance.luaTouchPadReleased(button);
		});

		Lua_helper.add_callback(lua, "touchJustPressed", TouchUtil.justPressed);
		Lua_helper.add_callback(lua, "touchPressed", TouchUtil.pressed);
		Lua_helper.add_callback(lua, "touchJustReleased", TouchUtil.justReleased);
		Lua_helper.add_callback(lua, "touchReleased", TouchUtil.released);
		Lua_helper.add_callback(lua, "touchPressedObject", function(object:String, ?camera:String):Bool
		{
			var obj = PlayState.instance.getLuaObject(object);
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if (obj == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.mobile_psychlua_functions.touchpressedobject_value_does_not_exist', "touchPressedObject: {1} does not exist.", [object]));
				return false;
			}
			return TouchUtil.overlaps(obj, cam) && TouchUtil.pressed;
		});

		Lua_helper.add_callback(lua, "touchJustPressedObject", function(object:String, ?camera:String):Bool
		{
			var obj = PlayState.instance.getLuaObject(object);
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if (obj == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.mobile_psychlua_functions.touchjustpressedobject_missing_object', "touchJustPressedObject: {1} does not exist.", [object]));
				return false;
			}
			return TouchUtil.overlaps(obj, cam) && TouchUtil.justPressed;
		});

		Lua_helper.add_callback(lua, "touchJustReleasedObject", function(object:String, ?camera:String):Bool
		{
			var obj = PlayState.instance.getLuaObject(object);
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if (obj == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.mobile_psychlua_functions.touchjustreleasedobject_missing_object', "touchJustReleasedObject: {1} does not exist.", [object]));
				return false;
			}
			return TouchUtil.overlaps(obj, cam) && TouchUtil.justReleased;
		});

		Lua_helper.add_callback(lua, "touchReleasedObject", function(object:String, ?camera:String):Bool
		{
			var obj = PlayState.instance.getLuaObject(object);
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if (obj == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.mobile_psychlua_functions.touchreleasedobject_value_does_not_exist', "touchReleasedObject: {1} does not exist.", [object]));
				return false;
			}
			return TouchUtil.overlaps(obj, cam) && TouchUtil.released;
		});

		Lua_helper.add_callback(lua, "touchPressedObjectComplex", function(object:String, ?camera:String):Bool
		{
			var obj = PlayState.instance.getLuaObject(object);
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if (obj == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.mobile_psychlua_functions.touchpressedobjectcomplex_missing_object', "touchPressedObjectComplex: {1} does not exist.", [object]));
				return false;
			}
			return TouchUtil.overlapsComplex(obj, cam) && TouchUtil.pressed;
		});

		Lua_helper.add_callback(lua, "touchJustPressedObjectComplex", function(object:String, ?camera:String):Bool
		{
			var obj = PlayState.instance.getLuaObject(object);
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if (obj == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.mobile_psychlua_functions.touchjustpressedobjectcomplex_missing_object', "touchJustPressedObjectComplex: {1} does not exist.", [object]));
				return false;
			}
			return TouchUtil.overlapsComplex(obj, cam) && TouchUtil.justPressed;
		});

		Lua_helper.add_callback(lua, "touchJustReleasedObjectComplex", function(object:String, ?camera:String):Bool
		{
			var obj = PlayState.instance.getLuaObject(object);
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if (obj == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.mobile_psychlua_functions.touchjustreleasedobjectcomplex_missing_object', "touchJustReleasedObjectComplex: {1} does not exist.", [object]));
				return false;
			}
			return TouchUtil.overlapsComplex(obj, cam) && TouchUtil.justReleased;
		});

		Lua_helper.add_callback(lua, "touchReleasedObjectComplex", function(object:String, ?camera:String):Bool
		{
			var obj = PlayState.instance.getLuaObject(object);
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if (obj == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.mobile_psychlua_functions.touchreleasedobjectcomplex_missing_object', "touchReleasedObjectComplex: {1} does not exist.", [object]));
				return false;
			}
			return TouchUtil.overlapsComplex(obj, cam) && TouchUtil.released;
		});

		Lua_helper.add_callback(lua, "touchOverlapsObject", function(object:String, ?camera:String):Bool
		{
			var obj = PlayState.instance.getLuaObject(object);
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if (obj == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.mobile_psychlua_functions.touchoverlapsobject_value_does_not_exist', "touchOverlapsObject: {1} does not exist.", [object]));
				return false;
			}
			return TouchUtil.overlaps(obj, cam);
		});

		Lua_helper.add_callback(lua, "touchOverlapsObjectComplex", function(object:String, ?camera:String):Bool
		{
			var obj = PlayState.instance.getLuaObject(object);
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if (obj == null)
			{
				FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.mobile_psychlua_functions.touchoverlapsobjectcomplex_missing_object', "touchOverlapsObjectComplex: {1} does not exist.", [object]));
				return false;
			}
			return TouchUtil.overlapsComplex(obj, cam);
		});
	}

	public static function getMobileControlsAsString():String
	{
		switch (MobileData.mode)
		{
			case 0:
				return 'left';
			case 1:
				return 'right';
			case 2:
				return 'custom';
			case 3:
				return 'hitbox';
			default:
				return 'none';
		}
	}
}

#if android
class AndroidFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua:State = funk.lua;
		Lua_helper.add_callback(lua, "isRooted", AndroidTools.isRooted());
		Lua_helper.add_callback(lua, "isDolbyAtmos", AndroidTools.isDolbyAtmos());
		Lua_helper.add_callback(lua, "isAndroidTV", AndroidTools.isAndroidTV());
		Lua_helper.add_callback(lua, "isTablet", AndroidTools.isTablet());
		Lua_helper.add_callback(lua, "isChromebook", AndroidTools.isChromebook());
		Lua_helper.add_callback(lua, "isDeXMode", AndroidTools.isDeXMode());

		Lua_helper.add_callback(lua, "backJustPressed", () -> FlxG.android.justPressed.BACK);
		Lua_helper.add_callback(lua, "backPressed", () -> FlxG.android.pressed.BACK);
		Lua_helper.add_callback(lua, "backJustReleased", () -> FlxG.android.justReleased.BACK);

		Lua_helper.add_callback(lua, "menuJustPressed", () -> FlxG.android.justPressed.MENU);
		Lua_helper.add_callback(lua, "menuPressed", () -> FlxG.android.pressed.MENU);
		Lua_helper.add_callback(lua, "menuJustReleased", () -> FlxG.android.justReleased.MENU);

		Lua_helper.add_callback(lua, "getCurrentOrientation", () -> PsychJNI.getCurrentOrientationAsString());
		Lua_helper.add_callback(lua, "setOrientation", function(?hint:String):Void
		{
			switch (hint.toLowerCase())
			{
				case 'portrait':
					hint = 'Portrait';
				case 'portraitupsidedown' | 'upsidedownportrait' | 'upsidedown':
					hint = 'PortraitUpsideDown';
				case 'landscapeleft' | 'leftlandscape':
					hint = 'LandscapeLeft';
				case 'landscaperight' | 'rightlandscape' | 'landscape':
					hint = 'LandscapeRight';
				default:
					hint = null;
			}
			if (hint == null)
				return FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.mobile_psychlua_functions.setorientation_no_orientation_specified', "setOrientation: No orientation specified."));
			PsychJNI.setOrientation(FlxG.stage.stageWidth, FlxG.stage.stageHeight, false, hint);
		});

		Lua_helper.add_callback(lua, "minimizeWindow", () -> AndroidTools.minimizeWindow());

		Lua_helper.add_callback(lua, "showToast", function(text:String, ?duration:Int, ?xOffset:Int, ?yOffset:Int) /* , ?gravity:Int*/
		{
			if (text == null)
				return FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.mobile_psychlua_functions.showtoast_no_text_specified', "showToast: No text specified."));
			else if (duration == null)
				return FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.mobile_psychlua_functions.showtoast_no_duration_specified', "showToast: No duration specified."));

			if (xOffset == null)
				xOffset = 0;
			if (yOffset == null)
				yOffset = 0;

			AndroidToast.makeText(text, duration, -1, xOffset, yOffset);
		});

		Lua_helper.add_callback(lua, "isScreenKeyboardShown", () -> PsychJNI.isScreenKeyboardShown());

		Lua_helper.add_callback(lua, "clipboardHasText", () -> PsychJNI.clipboardHasText());
		Lua_helper.add_callback(lua, "clipboardGetText", () -> PsychJNI.clipboardGetText());
		Lua_helper.add_callback(lua, "clipboardSetText", function(?text:String):Void
		{
			if (text != null)
				return FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.mobile_psychlua_functions.clipboardsettext_no_text_specified', "clipboardSetText: No text specified."));
			PsychJNI.clipboardSetText(text);
		});

		Lua_helper.add_callback(lua, "manualBackButton", () -> PsychJNI.manualBackButton());

		Lua_helper.add_callback(lua, "setActivityTitle", function(text:String):Void
		{
			if (text != null)
				return FunkinLua.luaTrace(Language.getPhrase('errors.script_debug.mobile_psychlua_functions.setactivitytitle_no_text_specified', "setActivityTitle: No text specified."));
			PsychJNI.setActivityTitle(text);
		});
	}
}
#end
#end
