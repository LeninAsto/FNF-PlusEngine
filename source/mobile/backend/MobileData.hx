package mobile.backend;

import haxe.ds.Map;
import haxe.Json;
import haxe.io.Path;
import flixel.util.FlxSave;

#if sys
import sys.FileSystem;
import sys.io.File;
#end
import openfl.Assets;

/**
 * ...
 * @author: Karim Akra (rewor by Lenin)
 */
class MobileData
{
	public static var actionModes:Map<String, TouchButtonsData> = new Map();
	public static var dpadModes:Map<String, TouchButtonsData> = new Map();
	public static var extraActions:Map<String, ExtraActions> = new Map();

	public static var mode(get, set):Int;
	public static var forcedMode:Null<Int>;
	public static var save:FlxSave;

	public static function init()
	{
		save = new FlxSave();
		save.bind('MobileControls', CoolUtil.getSavePath());

		// Load hardcoded data first
		loadHardcodedDPadModes();
		loadHardcodedActionModes();

		// Then allow mods to override if needed
		#if MODS_ALLOWED
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'mobile/'))
		{
			readDirectory(Path.join([folder, 'DPadModes']), dpadModes);
			readDirectory(Path.join([folder, 'ActionModes']), actionModes);
		}
		#end

		for (data in ExtraActions.createAll())
			extraActions.set(data.getName(), data);
	}

	static function loadHardcodedDPadModes():Void
	{
		// LEFT_FULL
		dpadModes.set('LEFT_FULL', {
			buttons: [
				{button: 'buttonUp', graphic: 'up', x: 98, y: 405, color: '0xFF12FA05'},
				{button: 'buttonLeft', graphic: 'left', x: 0, y: 500, color: '0xFFC24B99'},
				{button: 'buttonRight', graphic: 'right', x: 196, y: 500, color: '0xFFF9393F'},
				{button: 'buttonDown', graphic: 'down', x: 98, y: 596, color: '0xFF00FFFF'}
			]
		});

		// RIGHT_FULL
		dpadModes.set('RIGHT_FULL', {
			buttons: [
				{button: 'buttonUp', graphic: 'up', x: 1022, y: 314, color: '0xFF12FA05'},
				{button: 'buttonLeft', graphic: 'left', x: 896, y: 413, color: '0xFFC24B99'},
				{button: 'buttonRight', graphic: 'right', x: 1148, y: 413, color: '0xFFF9393F'},
				{button: 'buttonDown', graphic: 'down', x: 1022, y: 521, color: '0xFF00FFFF'}
			]
		});

		// LEFT_RIGHT
		dpadModes.set('LEFT_RIGHT', {
			buttons: [
				{button: 'buttonLeft', graphic: 'left', x: 0, y: 587, color: '0xFFC24B99'},
				{button: 'buttonRight', graphic: 'right', x: 127, y: 587, color: '0xFFF9393F'}
			]
		});

		// UP_DOWN
		dpadModes.set('UP_DOWN', {
			buttons: [
				{button: 'buttonUp', graphic: 'up', x: 0, y: 472, color: '0xFF12FA05'},
				{button: 'buttonDown', graphic: 'down', x: 0, y: 596, color: '0xFF00FFFF'}
			]
		});

		// MENU_CHARACTER
		dpadModes.set('MENU_CHARACTER', {
			buttons: [
				{button: 'buttonUp', graphic: 'up', x: 105, y: 0, color: '0xFF12FA05'},
				{button: 'buttonLeft', graphic: 'left', x: 0, y: 95, color: '0xFFC24B99'},
				{button: 'buttonRight', graphic: 'right', x: 196, y: 95, color: '0xFFF9393F'},
				{button: 'buttonDown', graphic: 'down', x: 98, y: 192, color: '0xFF00FFFF'}
			]
		});

		// DIALOGUE_PORTRAIT
		dpadModes.set('DIALOGUE_PORTRAIT', {
			buttons: [
				{button: 'buttonUp', graphic: 'up', x: 98, y: 405, color: '0xFF12FA05'},
				{button: 'buttonLeft', graphic: 'left', x: 0, y: 500, color: '0xFFC24B99'},
				{button: 'buttonRight', graphic: 'right', x: 196, y: 500, color: '0xFFF9393F'},
				{button: 'buttonDown', graphic: 'down', x: 98, y: 596, color: '0xFF00FFFF'},
				{button: 'buttonUp2', graphic: 'up', x: 105, y: 0, color: '0xFF12FA05'},
				{button: 'buttonLeft2', graphic: 'left', x: 0, y: 95, color: '0xFFC24B99'},
				{button: 'buttonRight2', graphic: 'right', x: 196, y: 95, color: '0xFFF9393F'},
				{button: 'buttonDown2', graphic: 'down', x: 98, y: 192, color: '0xFF00FFFF'}
			]
		});
	}

	static function loadHardcodedActionModes():Void
	{
		// A
		actionModes.set('A', {
			buttons: [
				{button: 'buttonA', graphic: 'a', x: 1156, y: 596, color: '0xFF0000'}
			]
		});

		// B
		actionModes.set('B', {
			buttons: [
				{button: 'buttonB', graphic: 'b', x: 1156, y: 596, color: '0xFFCB00'}
			]
		});

		// P
		actionModes.set('P', {
			buttons: [
				{button: 'buttonP', graphic: 'p', x: 1156, y: 2, color: '0xE5DE00'}
			]
		});

		// E
		actionModes.set('E', {
			buttons: [
				{button: 'buttonE', graphic: 'e', x: 1148, y: 339, color: '0xFF7D00'}
			]
		});

		// A_B
		actionModes.set('A_B', {
			buttons: [
				{button: 'buttonA', graphic: 'a', x: 1156, y: 596, color: '0xFF0000'},
				{button: 'buttonB', graphic: 'b', x: 1032, y: 596, color: '0xFFCB00'}
			]
		});

		// B_C
		actionModes.set('B_C', {
			buttons: [
				{button: 'buttonC', graphic: 'c', x: 1032, y: 596, color: '0x44FF00'},
				{button: 'buttonB', graphic: 'b', x: 1156, y: 596, color: '0xFFCB00'}
			]
		});

		// E_X
		actionModes.set('E_X', {
			buttons: [
				{button: 'buttonE', graphic: 'e', x: 1148, y: 339, color: '0xFF7D00'},
				{button: 'buttonX', graphic: 'x', x: 908, y: 596, color: '0x99062D'}
			]
		});

		// A_B_C
		actionModes.set('A_B_C', {
			buttons: [
				{button: 'buttonA', graphic: 'a', x: 1156, y: 596, color: '0xFF0000'},
				{button: 'buttonB', graphic: 'b', x: 1032, y: 596, color: '0xFFCB00'},
				{button: 'buttonC', graphic: 'c', x: 908, y: 596, color: '0x44FF00'}
			]
		});

		// A_B_X_Y
		actionModes.set('A_B_X_Y', {
			buttons: [
				{button: 'buttonA', graphic: 'a', x: 1156, y: 596, color: '0xFF0000'},
				{button: 'buttonB', graphic: 'b', x: 1032, y: 596, color: '0xFFCB00'},
				{button: 'buttonX', graphic: 'x', x: 908, y: 596, color: '0x99062D'},
				{button: 'buttonY', graphic: 'y', x: 784, y: 596, color: '0x4A35B9'}
			]
		});

		// B_X_Y
		actionModes.set('B_X_Y', {
			buttons: [
				{button: 'buttonB', graphic: 'b', x: 1156, y: 596, color: '0xFFCB00'},
				{button: 'buttonX', graphic: 'x', x: 1032, y: 596, color: '0x99062D'},
				{button: 'buttonY', graphic: 'y', x: 908, y: 596, color: '0x4A35B9'}
			]
		});

		// B_C_X_Y_Z
		actionModes.set('B_C_X_Y_Z', {
			buttons: [
				{button: 'buttonX', graphic: 'x', x: 908, y: 472, color: '0x99062D'},
				{button: 'buttonC', graphic: 'c', x: 908, y: 596, color: '0x44FF00'},
				{button: 'buttonY', graphic: 'y', x: 1032, y: 472, color: '0x4A35B9'},
				{button: 'buttonB', graphic: 'b', x: 1032, y: 596, color: '0xFFCB00'},
				{button: 'buttonZ', graphic: 'z', x: 1156, y: 472, color: '0xCCB98E'}
			]
		});

		// A_B_C_X_Y_Z
		actionModes.set('A_B_C_X_Y_Z', {
			buttons: [
				{button: 'buttonX', graphic: 'x', x: 908, y: 472, color: '0x99062D'},
				{button: 'buttonC', graphic: 'c', x: 908, y: 596, color: '0x44FF00'},
				{button: 'buttonY', graphic: 'y', x: 1032, y: 472, color: '0x4A35B9'},
				{button: 'buttonB', graphic: 'b', x: 1032, y: 596, color: '0xFFCB00'},
				{button: 'buttonZ', graphic: 'z', x: 1156, y: 472, color: '0xCCB98E'},
				{button: 'buttonA', graphic: 'a', x: 1156, y: 596, color: '0xFF0000'}
			]
		});

		// A_B_C_D_V_X_Y_Z
		actionModes.set('A_B_C_D_V_X_Y_Z', {
			buttons: [
				{button: 'buttonV', graphic: 'v', x: 770, y: 462, color: '0x49A9B2'},
				{button: 'buttonD', graphic: 'd', x: 770, y: 587, color: '0x0078FF'},
				{button: 'buttonX', graphic: 'x', x: 896, y: 462, color: '0x99062D'},
				{button: 'buttonC', graphic: 'c', x: 896, y: 587, color: '0x44FF00'},
				{button: 'buttonY', graphic: 'y', x: 1148, y: 462, color: '0x4A35B9'},
				{button: 'buttonB', graphic: 'b', x: 1022, y: 587, color: '0xFFCB00'},
				{button: 'buttonZ', graphic: 'z', x: 1274, y: 462, color: '0xCCB98E'},
				{button: 'buttonA', graphic: 'a', x: 1274, y: 587, color: '0xFF0000'}
			]
		});

		// CHART_EDITOR
		actionModes.set('CHART_EDITOR', {
			buttons: [
				{button: 'buttonV', graphic: 'v', x: 784, y: 472, color: '0x49A9B2'},
				{button: 'buttonD', graphic: 'd', x: 784, y: 596, color: '0x0078FF'},
				{button: 'buttonX', graphic: 'x', x: 908, y: 472, color: '0x99062D'},
				{button: 'buttonZ', graphic: 'z', x: 908, y: 596, color: '0xCCB98E'},
				{button: 'buttonY', graphic: 'y', x: 1032, y: 472, color: '0x4A35B9'},
				{button: 'buttonC', graphic: 'c', x: 1032, y: 596, color: '0x44FF00'},
				{button: 'buttonH', graphic: 'h', x: 1156, y: 472, color: '0xF3A505'},
				{button: 'buttonA', graphic: 'a', x: 1156, y: 596, color: '0xFF0000'},
				{button: 'buttonUp2', graphic: 'up', x: 340, y: 463, color: '0xFF12FA05'},
				{button: 'buttonDown2', graphic: 'down', x: 340, y: 596, color: '0xFF00FFFF'},
				{button: 'buttonF', graphic: 'f', x: 1030, y: 348, color: '0xB1FC00'},
				{button: 'buttonG', graphic: 'g', x: 1156, y: 348, color: '0xFF009D'}
			]
		});

		// CHARACTER_EDITOR
		actionModes.set('CHARACTER_EDITOR', {
			buttons: [
				{button: 'buttonV', graphic: 'v', x: 784, y: 472, color: '0x49A9B2'},
				{button: 'buttonD', graphic: 'd', x: 784, y: 596, color: '0x0078FF'},
				{button: 'buttonX', graphic: 'x', x: 908, y: 472, color: '0x99062D'},
				{button: 'buttonC', graphic: 'c', x: 908, y: 596, color: '0x44FF00'},
				{button: 'buttonY', graphic: 'y', x: 1032, y: 472, color: '0x4A35B9'},
				{button: 'buttonB', graphic: 'b', x: 1032, y: 596, color: '0xFFCB00'},
				{button: 'buttonZ', graphic: 'z', x: 1156, y: 472, color: '0xCCB98E'},
				{button: 'buttonA', graphic: 'a', x: 1156, y: 596, color: '0xFF0000'},
				{button: 'buttonS', graphic: 's', x: 660, y: 596, color: '0xEA00FF'},
				{button: 'buttonF', graphic: 'f', x: 870, y: 2, color: '0xFF009D'}
			]
		});

		// NOTE_SPLASH_EDITOR
		actionModes.set('NOTE_SPLASH_EDITOR', {
			buttons: [
				{button: 'buttonV', graphic: 'v', x: 908, y: 596, color: '0x0078FF'},
				{button: 'buttonC', graphic: 'c', x: 784, y: 596, color: '0x44FF00'},
				{button: 'buttonF', graphic: 'f', x: 1032, y: 472, color: '0x4A35B9'},
				{button: 'buttonB', graphic: 'b', x: 1032, y: 596, color: '0xFFCB00'},
				{button: 'buttonZ', graphic: 'z', x: 1156, y: 472, color: '0xCCB98E'},
				{button: 'buttonA', graphic: 'a', x: 1156, y: 596, color: '0xFF0000'}
			]
		});

		// MENU_CHARACTER
		actionModes.set('MENU_CHARACTER', {
			buttons: [
				{button: 'buttonC', graphic: 'c', x: 908, y: 0, color: '0x44FF00'},
				{button: 'buttonB', graphic: 'b', x: 1032, y: 0, color: '0xFFCB00'},
				{button: 'buttonA', graphic: 'a', x: 1156, y: 0, color: '0xFF0000'}
			]
		});

		// DIALOGUE_PORTRAIT
		actionModes.set('DIALOGUE_PORTRAIT', {
			buttons: [
				{button: 'buttonX', graphic: 'x', x: 908, y: 0, color: '0x99062D'},
				{button: 'buttonY', graphic: 'y', x: 1032, y: 0, color: '0x4A35B9'},
				{button: 'buttonB', graphic: 'b', x: 1032, y: 125, color: '0xFFCB00'},
				{button: 'buttonZ', graphic: 'z', x: 1156, y: 0, color: '0xCCB98E'},
				{button: 'buttonA', graphic: 'a', x: 1156, y: 125, color: '0xFF0000'}
			]
		});
	}

	public static function setTouchPadCustom(touchPad:TouchPad):Void
	{
		if (save.data.buttons == null)
		{
			save.data.buttons = new Array();
			for (buttons in touchPad)
				save.data.buttons.push(FlxPoint.get(buttons.x, buttons.y));
		}
		else
		{
			var tempCount:Int = 0;
			for (buttons in touchPad)
			{
				save.data.buttons[tempCount] = FlxPoint.get(buttons.x, buttons.y);
				tempCount++;
			}
		}

		save.flush();
	}

	public static function getTouchPadCustom(touchPad:TouchPad):TouchPad
	{
		var tempCount:Int = 0;

		if (save.data.buttons == null)
			return touchPad;

		for (buttons in touchPad)
		{
			if (save.data.buttons[tempCount] != null)
			{
				buttons.x = save.data.buttons[tempCount].x;
				buttons.y = save.data.buttons[tempCount].y;
			}
			tempCount++;
		}

		return touchPad;
	}

	public static function setButtonsColors(buttonsInstance:Dynamic):Dynamic
	{
		// Dynamic Controls Color
		var data:Dynamic;
		if (ClientPrefs.data.dynamicColors)
			data = ClientPrefs.data;
		else
			data = ClientPrefs.defaultData;

		for (i => button in [
			buttonsInstance.buttonLeft,
			buttonsInstance.buttonDown,
			buttonsInstance.buttonUp,
			buttonsInstance.buttonRight])
		{
			button.color = data.arrowRGB[i][0];
			button.label.color = data.arrowRGB[i][0];
			button.label.updateColorTransform();
		}

		return buttonsInstance;
	}

	public static function readDirectory(folder:String, map:Dynamic)
	{
		folder = folder.contains(':') ? folder.split(':')[1] : folder;

		#if (MODS_ALLOWED && !mobile)
		// On desktop, use FileSystem for mod support
		if (FileSystem.exists(folder))
		{
			for (file in Paths.readDirectory(folder))
			{
				var fileWithNoLib:String = file.contains(':') ? file.split(':')[1] : file;
				if (Path.extension(fileWithNoLib) == 'json')
				{
					var fullPath:String = Path.join([folder, Path.withoutDirectory(file)]);
					var str:String = File.getContent(fullPath);
					var json:TouchButtonsData = cast Json.parse(str);
					var mapKey:String = Path.withoutDirectory(Path.withoutExtension(fileWithNoLib));
					map.set(mapKey, json);
				}
			}
		}
		#else
		// On mobile or when mods are disabled, use Assets
		for (file in Assets.list())
		{
			if (file.startsWith(folder) && Path.extension(file) == 'json')
			{
				var fileWithNoLib:String = file.contains(':') ? file.split(':')[1] : file;
				var str:String = Assets.getText(file);
				var json:TouchButtonsData = cast Json.parse(str);
				var mapKey:String = Path.withoutDirectory(Path.withoutExtension(fileWithNoLib));
				map.set(mapKey, json);
			}
		}
		#end
	}

	static function set_mode(mode:Int = 3)
	{
		save.data.mobileControlsMode = mode;
		save.flush();
		return mode;
	}

	static function get_mode():Int
	{
		if (forcedMode != null)
			return forcedMode;

		if (save.data.mobileControlsMode == null)
		{
			save.data.mobileControlsMode = 3;
			save.flush();
		}

		return save.data.mobileControlsMode;
	}
}

typedef TouchButtonsData =
{
	buttons:Array<ButtonsData>
}

typedef ButtonsData =
{
	button:String, // what TouchButton should be used, must be a valid TouchButton var from TouchPad as a string.
	graphic:String, // the graphic of the button, usually can be located in the TouchPad xml .
	x:Float, // the button's X position on screen.
	y:Float, // the button's Y position on screen.
	color:String // the button color, default color is white.
}

enum ExtraActions
{
	SINGLE;
	DOUBLE;
	NONE;
}
