package scripting;

#if HSCRIPT_ALLOWED
import hxscript.syntax.Expr.ImportMode;
import hxscript.types.TypeCollection;
import flixel.FlxG;

class ScriptGlobals {
	public static var registeredCount(default, null):Int = 0;
	public static var skippedCount(default, null):Int = 0;
	static var modSaveCache:Map<String, flixel.util.FlxSave> = new Map();

	static var keepScriptError:Class<ScriptError> = ScriptError;
	static var keepScriptBytes:Class<ScriptBytes> = ScriptBytes;
	static var keepScriptDraw:Class<ScriptDraw> = ScriptDraw;
	static var keepAssetLoader:Class<backend.AssetLoader> = backend.AssetLoader;
	static var keepScriptHttp:Class<backend.ScriptHttp> = backend.ScriptHttp;
	static var keepBuildInfo:Class<backend.BuildInfo> = backend.BuildInfo;
	static var keepSecurityReview:Class<backend.SecurityReview> = backend.SecurityReview;
	static var keepTransitionManager:Class<backend.TransitionManager> = backend.TransitionManager;
	static var keepTouchUtil:Class<mobile.backend.TouchUtil> = mobile.backend.TouchUtil;
	static var keepABotSpectrum:Class<objects.ABotSpectrum> = objects.ABotSpectrum;
	static var keepCursor:Class<objects.Cursor> = objects.Cursor;
	static var keepPsychFlxAnimate:Class<backend.PsychFlxAnimate> = backend.PsychFlxAnimate;
	#if DISCORD_ALLOWED
	static var keepDiscordClient:Class<backend.Discord.DiscordClient> = backend.Discord.DiscordClient;
	#end
	static var keepCutsceneHandler:Class<cutscenes.CutsceneHandler> = cutscenes.CutsceneHandler;
	static var keepRainShader:Class<shaders.RainShader> = shaders.RainShader;
	static var keepGameOverSubstate:Class<substates.GameOverSubstate> = substates.GameOverSubstate;
	static var keepStickerSubState:Class<substates.StickerSubState> = substates.StickerSubState;
	static var keepTitleState:Class<states.TitleState> = states.TitleState;
	static var keepMainMenuState:Class<states.MainMenuState> = states.MainMenuState;
	static var keepStoryMenuState:Class<states.StoryMenuState> = states.StoryMenuState;
	static var keepFreeplayState:Class<states.FreeplayState> = states.FreeplayState;
	static var keepFreeplayStateSelector:Class<states.FreeplayStateSelector> = states.FreeplayStateSelector;
	static var keepCreditsState:Class<states.CreditsState> = states.CreditsState;
	static var keepAchievementsMenuState:Class<states.AchievementsMenuState> = states.AchievementsMenuState;
	static var keepResetScoreSubState:Class<substates.ResetScoreSubState> = substates.ResetScoreSubState;
	static var keepOptionsState:Class<options.OptionsState> = options.OptionsState;
	static var keepGameplayChangersSubstate:Class<options.GameplayChangersSubstate> = options.GameplayChangersSubstate;
	static var keepFlxBitmapText:Class<flixel.text.FlxBitmapText> = flixel.text.FlxBitmapText;
	static var keepFlxMouseEvent:Dynamic = flixel.input.mouse.FlxMouseEvent;
	static var keepFlxVideoSprite:Class<hxvlc.flixel.FlxVideoSprite> = hxvlc.flixel.FlxVideoSprite;

	public static final TYPE_IMPORTS:Array<String> = [
		'backend.Paths',
		'backend.Achievements',
		'backend.AssetLoader',
			'backend.ScriptHttp',
		'haxe.Json',
		'backend.BuildInfo',
		'backend.SecurityReview',
		'mobile.backend.TouchUtil',
		'mobile.backend.MobileData',
		'backend.Controls',
		'backend.CoolUtil',
		'backend.MusicBeatState',
		'backend.MusicBeatSubstate',
		'backend.CustomFadeTransition',
		'backend.TransitionManager',
		'backend.ClientPrefs',
		'backend.Conductor',
		'backend.BaseStage',
		'backend.PsychFlxAnimate',
		#if DISCORD_ALLOWED
		'backend.Discord.DiscordClient',
		#end
		'backend.Difficulty',
		'backend.Mods',
		'backend.Language',
		'backend.PsychCamera',
		'backend.Song',
		'backend.StageData',
		'backend.Highscore',
		'backend.WeekData',
		'objects.Alphabet',
		'objects.Bar',
		'objects.Character',
		'objects.HealthIcon',
		'objects.ABotSpectrum',
		'objects.Cursor',
		'objects.Note',
		'objects.NoteSplash',
		'objects.StrumNote',
		'objects.MenuItem',
		'psychlua.backend.CustomSubstate',
		'psychlua.backend.ModchartSprite',
		'scripting.ScriptBytes',
		'scripting.ScriptDraw',
		'scripting.ScriptError',
		'cutscenes.CutsceneHandler',
		'shaders.RainShader',
		'states.TitleState',
		'states.MainMenuState',
		'states.StoryMenuState',
		'states.ModsMenuState',
		'states.PlayState',
		'states.FreeplayState',
		'states.FreeplayStateSelector',
		'states.CreditsState',
		'states.AchievementsMenuState',
		'states.LoadingState',
		'options.OptionsState',
		'options.GameplayChangersSubstate',
		'substates.GameOverSubstate',
		'substates.ResetScoreSubState',
		'substates.StickerSubState',
		'flixel.text.FlxBitmapText',
		'flixel.input.mouse.FlxMouseEvent',
		'hxvlc.flixel.FlxVideoSprite',
		'states.ModsMenuState',
		'states.editors.MasterEditorMenu',
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
		'flixel.util.FlxAxes',
		'flixel.util.FlxSort',
		'flixel.util.FlxStringUtil',
		'flixel.text.FlxText',
		'flixel.tweens.FlxEase',
		'flixel.tweens.FlxTween',
		'flixel.group.FlxGroup',
		'flixel.group.FlxTypedGroup',
		'flixel.group.FlxSpriteGroup',
		'flixel.graphics.FlxGraphic',
		'flixel.ui.FlxButton',
		'flixel.ui.FlxBar',
		'flixel.addons.display.FlxBackdrop',
		'flixel.addons.display.FlxTiledSprite',
		'flixel.addons.display.FlxRuntimeShader',
		'flixel.effects.FlxFlicker',
		'flixel.addons.transition.FlxTransitionableState',
		'openfl.utils.AssetType',
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
		'openfl.filters.ShaderFilter',
		'openfl.media.Sound',
		'openfl.events.Event',
		'openfl.events.MouseEvent',
		'lime.app.Application',
		'lime.system.System',
		'lime.utils.Assets',
		'lime.math.Rectangle',
		'lime.math.Vector2',
	];

	public static final buildTarget:String = psychlua.backend.LuaUtils.getBuildTarget();

	public static function register():Void {
		registeredCount = 0;
		skippedCount = 0;

		for (path in TYPE_IMPORTS) {
			if (TypeCollection.main.fromPath(path) == null) {
				skippedCount++;
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
		#if sys
		set('File', sys.io.File);
		set('FileSystem', sys.FileSystem);
		#end

		set('controls', backend.Controls.instance);
		set('buildTarget', buildTarget);
		set('BuildInfo', backend.BuildInfo);
		set('TransitionManager', backend.TransitionManager);
		set('Json', haxe.Json);
		set('parseJson', parseJson);
		set('stringifyJson', stringifyJson);
		set('ScriptHttp', backend.ScriptHttp);
		set('Http', backend.ScriptHttp);
		set('Cursor', objects.Cursor);
		set('setCursor', function(name:String, ?scale:Float = 1.0, ?offsetX:Int = 0, ?offsetY:Int = 0):Bool return objects.Cursor.setCustom(name, scale, offsetX, offsetY, mod));
		set('resetCursor', function():Void objects.Cursor.resetCustom());
		set('TouchUtil', mobile.backend.TouchUtil);
		set('X', flixel.util.FlxAxes.X);
		set('Y', flixel.util.FlxAxes.Y);
		set('XY', flixel.util.FlxAxes.XY);
		set('TEXT', openfl.utils.AssetType.TEXT);
		set('IMAGE', openfl.utils.AssetType.IMAGE);
		set('SOUND', openfl.utils.AssetType.SOUND);
		set('MUSIC', openfl.utils.AssetType.MUSIC);
		set('BINARY', openfl.utils.AssetType.BINARY);
		set('FONT', openfl.utils.AssetType.FONT);
		#if DISCORD_ALLOWED
		set('DiscordClient', backend.Discord.DiscordClient);
		set('Discord', backend.Discord.DiscordClient);
		#end
		set('getVar', getVar);
		set('setVar', setVar);
		set('removeVar', removeVar);
		set('getModSave', function(key:String, ?defaultValue:Dynamic = null, ?modName:String = null):Dynamic {
			return getModSave(key, defaultValue, modName == null ? mod : modName);
		});
		set('setModSave', function(key:String, value:Dynamic, ?modName:String = null):Dynamic {
			return setModSave(key, value, modName == null ? mod : modName);
		});
		set('flushModSave', function(?modName:String = null):Void flushModSave(modName == null ? mod : modName));
		set('debugPrint', debugPrint);
		set('getObjX', getObjX);
		set('getObjY', getObjY);
		set('setObjX', setObjX);
		set('setObjY', setObjY);
		set('setObjScale', setObjScale);
		set('lerp', lerp);
		set('clamp', clamp);
		set('randomFloat', randomFloat);
		set('switchState', switchState);
		set('switchToState', function(name:String, ?args:Array<Dynamic>):Bool return ScriptedStates.switchToState(name, args));
		set('openScriptedSubstate', function(name:String, ?args:Array<Dynamic>):Bool return ScriptedStates.openSubstate(name, args));
		set('launchMod', function(folder:String):Bool return ScriptedStates.launchMod(folder));
		set('exitToEngine', function():Void {
			ScriptedStates.exitToEngine();
		});
		set('setExitTarget', function(name:String):Void {
			states.PlayState.setExitTarget(name);
		});
		set('exitToState', function(name:String):Void {
			states.PlayState.exitToState(name);
		});
		set('buildScripted', function(path:String, ?args:Array<Dynamic>):Dynamic return ScriptRegistry.instantiate(path, args, mod));
		set('scriptedClass', function(path:String):Dynamic return ScriptRegistry.resolveClass(path, mod));
		set('getModSetting', function(saveTag:String, ?modName:String):Dynamic {
			if (modName == null)
				modName = mod;
			return psychlua.backend.LuaUtils.getModSetting(saveTag, modName);
		});

		sharedInput(set);

		set('Function_Stop', psychlua.backend.LuaUtils.Function_Stop);
		set('Function_Continue', psychlua.backend.LuaUtils.Function_Continue);
		set('Function_StopLua', psychlua.backend.LuaUtils.Function_StopLua);
		set('Function_StopHScript', psychlua.backend.LuaUtils.Function_StopHScript);
		set('Function_StopAll', psychlua.backend.LuaUtils.Function_StopAll);
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

	public static function resolveModSaveName(?modName:String = null):String {
		var folder:String = modName;
		if (folder == null || folder.length <= 0)
			folder = backend.Mods.launchedMod;
		if (folder == null || folder.length <= 0)
			folder = backend.Mods.currentModDirectory;
		if (folder == null || folder.length <= 0)
			folder = 'global';

		folder = StringTools.replace(folder, '\\', '_');
		folder = StringTools.replace(folder, '/', '_');
		folder = StringTools.replace(folder, ':', '_');
		folder = StringTools.replace(folder, ' ', '_');
		folder = StringTools.replace(folder, '{', '');
		folder = StringTools.replace(folder, '}', '');
		folder = StringTools.replace(folder, '(', '');
		folder = StringTools.replace(folder, ')', '');
		folder = StringTools.replace(folder, '[', '');
		folder = StringTools.replace(folder, ']', '');
		return folder;
	}

	static function getModSaveFile(?modName:String = null):flixel.util.FlxSave {
		var saveName:String = resolveModSaveName(modName);
		var cached:flixel.util.FlxSave = modSaveCache.get(saveName);
		if (cached != null)
			return cached;

		var save:flixel.util.FlxSave = new flixel.util.FlxSave();
		save.bind(saveName, backend.CoolUtil.getSavePath() + '/mods');
		modSaveCache.set(saveName, save);
		return save;
	}

	static function getLegacyModSaveBucket(saveName:String):Dynamic {
		var root:Dynamic = FlxG.save.data.modSaves;
		if (root == null)
			return null;

		var bucket:Dynamic = Reflect.field(root, saveName);
		if (bucket != null)
			return bucket;

		var launched:String = backend.Mods.launchedMod;
		if (launched != null && launched.length > 0)
			return Reflect.field(root, launched);

		return null;
	}

	public static function getModSave(key:String, ?defaultValue:Dynamic = null, ?modName:String = null):Dynamic {
		var saveName:String = resolveModSaveName(modName);
		var save:flixel.util.FlxSave = getModSaveFile(saveName);
		var value:Dynamic = Reflect.field(save.data, key);
		if (value == null) {
			var legacyBucket:Dynamic = getLegacyModSaveBucket(saveName);
			if (legacyBucket != null) {
				var legacyValue:Dynamic = Reflect.field(legacyBucket, key);
				if (legacyValue != null) {
					Reflect.setField(save.data, key, legacyValue);
					save.flush();
					return legacyValue;
				}
			}
		}
		return value == null ? defaultValue : value;
	}

	public static function setModSave(key:String, value:Dynamic, ?modName:String = null):Dynamic {
		var save:flixel.util.FlxSave = getModSaveFile(modName);
		Reflect.setField(save.data, key, value);
		save.flush();
		return value;
	}

	public static function flushModSave(?modName:String = null):Void
		getModSaveFile(modName).flush();

	public static function debugPrint(text:String, ?color:FlxColor):Void
		ScriptError.show(text, color == null ? FlxColor.WHITE : color);

	public static function parseJson(text:String):Dynamic
		return haxe.Json.parse(text);

	public static function stringifyJson(value:Dynamic, ?replacer:Dynamic = null, ?space:Dynamic = null):String
		return haxe.Json.stringify(value, replacer, space);

	public static function getObjX(obj:Dynamic):Float
		return obj == null ? 0 : Reflect.getProperty(obj, 'x');

	public static function getObjY(obj:Dynamic):Float
		return obj == null ? 0 : Reflect.getProperty(obj, 'y');

	public static function setObjX(obj:Dynamic, value:Float):Float {
		if (obj != null)
			Reflect.setProperty(obj, 'x', value);
		return value;
	}

	public static function setObjY(obj:Dynamic, value:Float):Float {
		if (obj != null)
			Reflect.setProperty(obj, 'y', value);
		return value;
	}

	public static function setObjScale(obj:Dynamic, x:Float, ?y:Float):Void {
		if (obj == null)
			return;
		var scale:Dynamic = Reflect.getProperty(obj, 'scale');
		if (scale != null)
			scale.set(x, y == null ? x : y);
	}

	public static inline function lerp(a:Float, b:Float, ratio:Float):Float
		return a + (b - a) * ratio;

	public static inline function clamp(value:Float, min:Float, max:Float):Float
		return Math.max(min, Math.min(max, value));

	public static function randomFloat(min:Float, max:Float):Float
		return min + (max - min) * (FlxG.random.int(0, 1000000) / 1000000.0);

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
