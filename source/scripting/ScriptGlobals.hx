package scripting;

#if HSCRIPT_ALLOWED
import hxscript.syntax.Expr.ImportMode;
import hxscript.types.TypeCollection;

class ScriptGlobals {
	public static var registeredCount(default, null):Int = 0;
	public static var skippedCount(default, null):Int = 0;

	static var keepScriptError:Class<ScriptError> = ScriptError;
	static var keepScriptBytes:Class<ScriptBytes> = ScriptBytes;
	static var keepScriptDraw:Class<ScriptDraw> = ScriptDraw;

	public static final TYPE_IMPORTS:Array<String> = [
		'backend.Paths',
		'backend.Controls',
		'backend.CoolUtil',
		'backend.MusicBeatState',
		'backend.MusicBeatSubstate',
		'backend.CustomFadeTransition',
		'backend.ClientPrefs',
		'backend.Conductor',
		'backend.BaseStage',
		'backend.Difficulty',
		'backend.Mods',
		'backend.Language',
		'backend.PsychCamera',
		'backend.Song',
		'backend.Highscore',
		'backend.WeekData',
		'objects.Alphabet',
		'objects.Bar',
		'objects.Character',
		'objects.HealthIcon',
		'objects.Note',
		'objects.NoteSplash',
		'objects.StrumNote',
		'psychlua.CustomSubstate',
		'psychlua.ModchartSprite',
		'scripting.ScriptBytes',
		'scripting.ScriptDraw',
		'scripting.ScriptError',
		'states.PlayState',
		'states.LoadingState',
		'flixel.FlxG',
		'flixel.FlxBasic',
		'flixel.FlxObject',
		'flixel.FlxSprite',
		'flixel.FlxCamera',
		'flixel.sound.FlxSound',
		'flixel.math.FlxMath',
		'flixel.math.FlxPoint',
		'flixel.util.FlxTimer',
		'flixel.util.FlxColor',
		'flixel.util.FlxSort',
		'flixel.util.FlxStringUtil',
		'flixel.text.FlxText',
		'flixel.tweens.FlxEase',
		'flixel.tweens.FlxTween',
		'flixel.group.FlxGroup',
		'flixel.group.FlxSpriteGroup',
		'flixel.ui.FlxButton',
		'flixel.ui.FlxBar',
		'flixel.addons.display.FlxBackdrop',
		'flixel.addons.display.FlxRuntimeShader',
		'flixel.effects.FlxFlicker',
		'flixel.addons.transition.FlxTransitionableState',
		'openfl.display.Sprite',
		'openfl.display.Bitmap',
		'openfl.display.BitmapData',
		'openfl.display.BlendMode',
		'openfl.display.Shader',
		'openfl.display.Graphics',
		'openfl.filters.ShaderFilter',
		'openfl.filters.BlurFilter',
		'openfl.filters.GlowFilter',
		'openfl.filters.ColorMatrixFilter',
		'openfl.filters.DropShadowFilter',
		'openfl.geom.Matrix',
		'openfl.geom.Rectangle',
		'openfl.geom.Point',
		'openfl.geom.ColorTransform',
		'openfl.text.TextField',
		'openfl.text.TextFormat',
		'openfl.utils.Assets',
		'openfl.media.Sound',
		'openfl.events.Event',
		'openfl.events.MouseEvent',
		'lime.app.Application',
		'lime.system.System',
		'lime.utils.Assets',
		'lime.math.Rectangle',
		'lime.math.Vector2'
	];

	public static final buildTarget:String = psychlua.LuaUtils.getBuildTarget();

	public static function register():Void {
		registeredCount = 0;
		skippedCount = 0;

		for (path in TYPE_IMPORTS) {
			if (TypeCollection.main.fromPath(path) == null) {
				skippedCount++;
				trace('[ScriptGlobals] skipped missing type: $path');
				continue;
			}

			#if MODS_ALLOWED
			if (backend.ModSecurity.BLOCKED_CLASSES.exists(path))
				continue;
			#end

			if (!hxscript.Config.globalImports.exists(path))
				registeredCount++;
			hxscript.Config.globalImports.set(path, ImportMode.INormal);
		}

		trace('[ScriptGlobals] registered=$registeredCount skipped=$skippedCount');
	}

	public static function inject(vars:Map<String, Dynamic>, ?mod:String):Void {
		shared(function(name:String, value:Dynamic) vars.set(name, value), mod);
	}

	public static function shared(set:(String, Dynamic) -> Void, ?mod:String):Void {
		#if android
		set('File', mobile.backend.ScriptFile);
		set('FileSystem', mobile.backend.ScriptFileSystem);
		#elseif sys
		set('File', sys.io.File);
		set('FileSystem', sys.FileSystem);
		#end

		set('controls', backend.Controls.instance);
		set('buildTarget', buildTarget);
		set('getVar', getVar);
		set('setVar', setVar);
		set('removeVar', removeVar);
		set('debugPrint', debugPrint);
		set('switchState', switchState);
		set('buildScripted', function(path:String, ?args:Array<Dynamic>):Dynamic return ScriptRegistry.instantiate(path, args, mod));
		set('scriptedClass', function(path:String):Dynamic return ScriptRegistry.resolveClass(path, mod));
		set('getModSetting', function(saveTag:String, ?modName:String):Dynamic {
			if (modName == null)
				modName = mod;
			return psychlua.LuaUtils.getModSetting(saveTag, modName);
		});

		sharedInput(set);

		set('Function_Stop', psychlua.LuaUtils.Function_Stop);
		set('Function_Continue', psychlua.LuaUtils.Function_Continue);
		set('Function_StopLua', psychlua.LuaUtils.Function_StopLua);
		set('Function_StopHScript', psychlua.LuaUtils.Function_StopHScript);
		set('Function_StopAll', psychlua.LuaUtils.Function_StopAll);
	}

	public static function getVar(name:String):Dynamic
		return backend.MusicBeatState.getVariables().get(name);

	public static function setVar(name:String, value:Dynamic):Dynamic {
		backend.MusicBeatState.getVariables().set(name, value);
		return value;
	}

	public static function removeVar(name:String):Bool {
		if (!backend.MusicBeatState.getVariables().exists(name))
			return false;
		backend.MusicBeatState.getVariables().remove(name);
		return true;
	}

	public static function debugPrint(text:String, ?color:FlxColor):Void
		ScriptError.show(text, color == null ? FlxColor.WHITE : color);

	public static function switchState(state:flixel.FlxState):Void
		backend.MusicBeatState.switchState(state);

	static function sharedInput(set:(String, Dynamic) -> Void):Void {
		set('keyboardJustPressed', keyboardJustPressed);
		set('keyboardPressed', keyboardPressed);
		set('keyboardReleased', keyboardReleased);
		set('anyGamepadJustPressed', anyGamepadJustPressed);
		set('anyGamepadPressed', anyGamepadPressed);
		set('anyGamepadReleased', anyGamepadReleased);
		set('gamepadAnalogX', gamepadAnalogX);
		set('gamepadAnalogY', gamepadAnalogY);
		set('gamepadJustPressed', gamepadJustPressed);
		set('gamepadPressed', gamepadPressed);
		set('gamepadReleased', gamepadReleased);
		set('keyJustPressed', keyJustPressed);
		set('keyPressed', keyPressed);
		set('keyReleased', keyReleased);
	}

	public static function anyGamepadJustPressed(name:String):Bool
		return flixel.FlxG.gamepads.anyJustPressed(name);

	public static function anyGamepadPressed(name:String):Bool
		return flixel.FlxG.gamepads.anyPressed(name);

	public static function anyGamepadReleased(name:String):Bool
		return flixel.FlxG.gamepads.anyJustReleased(name);

	public static function keyboardJustPressed(name:String):Dynamic
		return Reflect.getProperty(flixel.FlxG.keys.justPressed, name);

	public static function keyboardPressed(name:String):Dynamic
		return Reflect.getProperty(flixel.FlxG.keys.pressed, name);

	public static function keyboardReleased(name:String):Dynamic
		return Reflect.getProperty(flixel.FlxG.keys.justReleased, name);

	public static function gamepadAnalogX(id:Int, ?leftStick:Bool = true):Float {
		var controller = flixel.FlxG.gamepads.getByID(id);
		return controller == null ? 0.0 : controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
	}

	public static function gamepadAnalogY(id:Int, ?leftStick:Bool = true):Float {
		var controller = flixel.FlxG.gamepads.getByID(id);
		return controller == null ? 0.0 : controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
	}

	public static function gamepadJustPressed(id:Int, name:String):Bool {
		var controller = flixel.FlxG.gamepads.getByID(id);
		return controller != null && Reflect.getProperty(controller.justPressed, name) == true;
	}

	public static function gamepadPressed(id:Int, name:String):Bool {
		var controller = flixel.FlxG.gamepads.getByID(id);
		return controller != null && Reflect.getProperty(controller.pressed, name) == true;
	}

	public static function gamepadReleased(id:Int, name:String):Bool {
		var controller = flixel.FlxG.gamepads.getByID(id);
		return controller != null && Reflect.getProperty(controller.justReleased, name) == true;
	}

	public static function keyJustPressed(name:String = ''):Bool {
		return switch (name.toLowerCase()) {
			case 'left': backend.Controls.instance.NOTE_LEFT_P;
			case 'down': backend.Controls.instance.NOTE_DOWN_P;
			case 'up': backend.Controls.instance.NOTE_UP_P;
			case 'right': backend.Controls.instance.NOTE_RIGHT_P;
			default: backend.Controls.instance.justPressed(name);
		}
	}

	public static function keyPressed(name:String = ''):Bool {
		return switch (name.toLowerCase()) {
			case 'left': backend.Controls.instance.NOTE_LEFT;
			case 'down': backend.Controls.instance.NOTE_DOWN;
			case 'up': backend.Controls.instance.NOTE_UP;
			case 'right': backend.Controls.instance.NOTE_RIGHT;
			default: backend.Controls.instance.pressed(name);
		}
	}

	public static function keyReleased(name:String = ''):Bool {
		return switch (name.toLowerCase()) {
			case 'left': backend.Controls.instance.NOTE_LEFT_R;
			case 'down': backend.Controls.instance.NOTE_DOWN_R;
			case 'up': backend.Controls.instance.NOTE_UP_R;
			case 'right': backend.Controls.instance.NOTE_RIGHT_R;
			default: backend.Controls.instance.justReleased(name);
		}
	}
}
#end
