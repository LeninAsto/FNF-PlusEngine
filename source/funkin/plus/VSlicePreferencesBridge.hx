package funkin.plus;

import backend.ClientPrefs;
import flixel.FlxG;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import funkin.PlayerSettings;
import funkin.input.Controls.Control;
import funkin.input.Controls.KeyboardScheme;
import funkin.input.PreciseInputManager;
import funkin.save.Save;

/**
 * Keeps the official Funkin runtime coordinated with Plus Engine preferences.
 *
 * Plus/Psych remains the source of truth; Funkin's save options are mirrored at
 * runtime so VSlice code and mods can keep using the official Preferences API.
 */
class VSlicePreferencesBridge
{
	static var syncing:Bool = false;

	public static function syncFromPlus(?flushVSliceSave:Bool = false):Void
	{
		if (syncing) return;
		syncing = true;

		try
		{
			var save:Save = Save.instance;
			var options:Dynamic = save.options;

			setField(options, 'framerate', getFramerate());
			setField(options, 'downscroll', ClientPrefs.data.downScroll);
			setField(options, 'flashingLights', ClientPrefs.data.flashing);
			setField(options, 'zoomCamera', ClientPrefs.data.camZooms);
			setField(options, 'autoPause', ClientPrefs.data.autoPause);
			setField(options, 'globalOffset', ClientPrefs.data.noteOffset);
			setField(options, 'unlockedFramerate', false);
			setField(options, 'naughtyness', ClientPrefs.data.vsliceNaughtyness);
			setField(options, 'subtitles', ClientPrefs.data.vsliceSubtitles);
			setField(options, 'strumlineBackgroundOpacity', Std.int(FlxMath.bound(ClientPrefs.data.vsliceStrumlineBackgroundOpacity, 0, 100)));
			setField(options, 'autoFullscreen', ClientPrefs.data.vsliceAutoFullscreen);
			setField(options, 'vsyncMode', ClientPrefs.data.vsync ? 'On' : 'Off');
			setField(options, 'debugDisplay', 'Off');
			setField(options, 'hapticsMode', normalizeHapticsMode(ClientPrefs.data.vsliceHapticsMode));
			setField(options, 'hapticsIntensityMultiplier', FlxMath.bound(ClientPrefs.data.vsliceHapticsIntensity, 0, 5));
			syncScreenshotOptions(options);

			FlxG.autoPause = ClientPrefs.data.autoPause;
			ClientPrefs.applyFramePacing();

			if (flushVSliceSave) Save.system.flush();
		}
		catch (e:Dynamic)
		{
			VSliceDebugLog.warning('VSlice Preferences', 'Could not sync Plus preferences into Funkin runtime: ${Std.string(e)}');
		}

		syncing = false;
	}

	public static function syncControlsFromPlus():Void
	{
		if (PlayerSettings.player1 == null) return;

		try
		{
			var controls = PlayerSettings.player1.controls;

			controls.setKeyboardScheme(KeyboardScheme.None);
			for (entry in keyboardMap())
			{
				var keys:Array<FlxKey> = ClientPrefs.keyBinds.get(entry.plus);
				if (keys != null) controls.bindKeys(entry.vslice, keys.copy());
			}
			PreciseInputManager.instance.initializeKeys(controls);

			for (gamepadId in controls.gamepadsAdded.copy())
				controls.removeGamepad(gamepadId);

			for (i in 0...FlxG.gamepads.numActiveGamepads)
			{
				var gamepad:FlxGamepad = FlxG.gamepads.getByID(i);
				if (gamepad == null) continue;

				for (entry in gamepadMap())
				{
					var buttons:Array<FlxGamepadInputID> = ClientPrefs.gamepadBinds.get(entry.plus);
					if (buttons != null) controls.bindButtons(entry.vslice, gamepad.id, buttons.copy());
				}

				if (!controls.gamepadsAdded.contains(gamepad.id))
					controls.gamepadsAdded.push(gamepad.id);
				PreciseInputManager.instance.initializeButtons(controls, gamepad);
			}
		}
		catch (e:Dynamic)
		{
			VSliceDebugLog.warning('VSlice Controls', 'Could not sync Plus controls into Funkin runtime: ${Std.string(e)}');
		}
	}

	public static inline function getFramerate():Int
	{
		return Std.int(Math.max(30, ClientPrefs.data.framerate));
	}

	public static inline function practiceMode():Bool
	{
		return boolSetting('practice');
	}

	public static inline function botPlayMode():Bool
	{
		return boolSetting('botplay');
	}

	public static function playbackRate():Float
	{
		var value:Float = ClientPrefs.getGameplaySetting('songspeed');
		return FlxMath.bound(value, 0.05, 5);
	}

	public static function healthGain():Float
	{
		var value:Float = ClientPrefs.getGameplaySetting('healthgain');
		return Math.max(0, value);
	}

	public static function healthLoss():Float
	{
		var value:Float = ClientPrefs.getGameplaySetting('healthloss');
		return Math.max(0, value);
	}

	public static inline function instakillOnMiss():Bool
	{
		return boolSetting('instakill') || boolSetting('perfect');
	}

	public static inline function perfectMode():Bool
	{
		return boolSetting('perfect');
	}

	public static inline function noDropPenalty():Bool
	{
		return boolSetting('nodroppenalty');
	}

	public static inline function opponentDrain():Bool
	{
		return boolSetting('opponentdrain');
	}

	public static function scrollSpeed(chartSpeed:Null<Float>):Float
	{
		var baseSpeed:Float = chartSpeed ?? 1.0;
		var setting:Float = ClientPrefs.getGameplaySetting('scrollspeed');
		var type:String = Std.string(ClientPrefs.getGameplaySetting('scrolltype'));

		return switch (type.toLowerCase())
		{
			case 'constant':
				Math.max(0.1, setting);
			default:
				Math.max(0.1, baseSpeed * setting);
		}
	}

	static inline function setField(target:Dynamic, name:String, value:Dynamic):Void
	{
		if (target != null) Reflect.setField(target, name, value);
	}

	static inline function boolSetting(name:String):Bool
	{
		return ClientPrefs.getGameplaySetting(name) == true;
	}

	static function syncScreenshotOptions(options:Dynamic):Void
	{
		var screenshot:Dynamic = Reflect.field(options, 'screenshot');
		if (screenshot == null)
		{
			screenshot = {};
			setField(options, 'screenshot', screenshot);
		}

		setField(screenshot, 'shouldHideMouse', ClientPrefs.data.vsliceScreenshotHideMouse);
		setField(screenshot, 'fancyPreview', ClientPrefs.data.vsliceScreenshotFancyPreview);
		setField(screenshot, 'previewOnSave', ClientPrefs.data.vsliceScreenshotPreviewOnSave);
	}

	static function normalizeHapticsMode(mode:String):String
	{
		if (mode == null) return 'All';
		return switch (mode.toLowerCase())
		{
			case 'none': 'None';
			case 'notes only', 'notes_only', 'notesonly': 'Notes Only';
			default: 'All';
		}
	}

	static function keyboardMap():Array<{plus:String, vslice:Control}>
	{
		return [
			{plus: 'note_left', vslice: Control.NOTE_LEFT},
			{plus: 'note_down', vslice: Control.NOTE_DOWN},
			{plus: 'note_up', vslice: Control.NOTE_UP},
			{plus: 'note_right', vslice: Control.NOTE_RIGHT},
			{plus: 'ui_left', vslice: Control.UI_LEFT},
			{plus: 'ui_down', vslice: Control.UI_DOWN},
			{plus: 'ui_up', vslice: Control.UI_UP},
			{plus: 'ui_right', vslice: Control.UI_RIGHT},
			{plus: 'accept', vslice: Control.ACCEPT},
			{plus: 'back', vslice: Control.BACK},
			{plus: 'pause', vslice: Control.PAUSE},
			{plus: 'reset', vslice: Control.RESET},
			{plus: 'fullscreen', vslice: Control.WINDOW_FULLSCREEN},
			{plus: 'volume_up', vslice: Control.VOLUME_UP},
			{plus: 'volume_down', vslice: Control.VOLUME_DOWN},
			{plus: 'volume_mute', vslice: Control.VOLUME_MUTE}
		];
	}

	static inline function gamepadMap():Array<{plus:String, vslice:Control}>
	{
		return keyboardMap();
	}
}
