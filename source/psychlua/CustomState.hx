package psychlua;

// CustomState - A state driven entirely by an HScript/Lua script.
//
// Inspired by ALE-Psych's CustomState:
//   https://github.com/ALE-Psych-Crew/ALE-Psych
// Credits: AlejoGDOfficial, immalloy, KirbyKid256, Ens4lada, Slushi-Github, ExecutorIQ
//
// Key differences from the original:
//   - Uses Plus Engine's HScript/Iris + FunkinLua systems instead of RuleScript.
//   - Script path uses flat layout:  scripts/states/{name}.hx  (no subfolder).
//   - A companion "global state" script at scripts/states/global.hx
//     is always loaded alongside the specific state script.
//   - Full pre/post callback lifecycle matches the rest of Plus Engine.
//   - F12 opens the mods menu (same as the old ModState).
//   - showError() displays a visual overlay for script errors.
//   - callOnScripts / setOnScripts support exclusions and ignoreStops.
//   - Shared/public/static variable helpers are exposed to scripts.

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import backend.MusicBeatState;
import debug.TraceDisplay;
import states.MainMenuState;
import states.ModsMenuState;
import psychlua.LuaUtils;

#if HSCRIPT_ALLOWED
import psychlua.HScript;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
import crowplexus.iris.Iris;
#end

#if LUA_ALLOWED
import psychlua.FunkinLua;
#end

#if sys
import sys.FileSystem;
#end

class CustomState extends MusicBeatState
{
	// Singleton reference accessible from scripts via `CustomState.instance`
	public static var instance:CustomState = null;

	// Name used to locate the script file (scripts/states/{stateName}.hx)
	public var stateName:String = '';

	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	#end

	#if LUA_ALLOWED
	public var luaArray:Array<FunkinLua> = [];
	#end

	// Error overlay
	public var errorText:FlxText;
	public var bgSprite:FlxSprite;
	public var hasError:Bool = false;

	public function new(name:String)
	{
		super();
		stateName = name;
	}

	override function create():Void
	{
		instance = this;
		persistentDraw = true;

		// Initialize base state first (camera, fade transition, global script hooks)
		super.create();

		errorText = new FlxText(10, 50, FlxG.width - 20, "ERROR!", 16);
		errorText.color = FlxColor.RED;
		errorText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		errorText.visible = false;
		add(errorText);

		#if HSCRIPT_ALLOWED
		MusicBeatState.publicVariables.clear();
		#end

		// Load all scripts from the folder first, then the state-specific one
		loadScriptsFromFolder(stateName);
		// Load companion global-state script:  scripts/states/global.hx  (or .lua)
		loadCustomScript('global');

		callOnScripts('onCreate');

		var plusVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Plus Engine v" + MainMenuState.plusEngineVersion, 12);
		plusVer.scrollFactor.set();
		plusVer.alpha = 0.8;
		plusVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(plusVer);

		MusicBeatState.callOnGlobalScript('onStateCreate', [stateName]);
		callOnScripts('onCreatePost');
		MusicBeatState.callOnGlobalScript('onStateCreatePost', [stateName]);
	}

	override function update(elapsed:Float):Void
	{
		MusicBeatState.callOnGlobalScript('onStateUpdate', [stateName, elapsed]);
		callOnScripts('onUpdate', [elapsed]);
		super.update(elapsed);
		callOnScripts('onUpdatePost', [elapsed]);
		MusicBeatState.callOnGlobalScript('onStateUpdatePost', [stateName, elapsed]);

		// F12 opens the mods menu
		if (FlxG.keys.justPressed.F12)
			MusicBeatState.switchState(new ModsMenuState());
	}

	override function destroy():Void
	{
		MusicBeatState.callOnGlobalScript('onStateDestroy', [stateName]);
		callOnScripts('onDestroy');

		#if LUA_ALLOWED
		for (script in luaArray)
		{
			if (script != null)
			{
				script.call('onDestroy', []);
				script.stop();
			}
		}
		luaArray = [];
		#end

		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
			if (script != null) script.destroy();
		hscriptArray = [];
		#end

		super.destroy();

		callOnScripts('onDestroyPost');
		instance = null;
	}

	override function stepHit():Void
	{
		callOnScripts('onStepHit', [curStep]);
		super.stepHit();
		callOnScripts('onStepHitPost', [curStep]);
	}

	override function beatHit():Void
	{
		callOnScripts('onBeatHit', [curBeat]);
		super.beatHit();
		callOnScripts('onBeatHitPost', [curBeat]);
	}

	override function sectionHit():Void
	{
		callOnScripts('onSectionHit', [curSection]);
		super.sectionHit();
		callOnScripts('onSectionHitPost', [curSection]);
	}

	override function onFocus():Void
	{
		callOnScripts('onFocus');
		super.onFocus();
	}

	override function onFocusLost():Void
	{
		callOnScripts('onFocusLost');
		super.onFocusLost();
	}

	override function openSubState(subState:FlxSubState):Void
	{
		callOnScripts('onOpenSubState', [Type.getClassName(Type.getClass(subState))]);
		super.openSubState(subState);
	}

	override function closeSubState():Void
	{
		callOnScripts('onCloseSubState');
		super.closeSubState();
	}

	// ─────────────────────────────────────────────
	// Error overlay
	// ─────────────────────────────────────────────

	public function showError(text:String):Void
	{
		hasError = true;

		if (bgSprite == null)
		{
			bgSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
			add(bgSprite);
		}

		errorText.text = text;
		errorText.visible = true;
		remove(errorText);
		add(errorText);

		trace('[CustomState] Error: $text');
	}

	// ─────────────────────────────────────────────
	// Script loading
	// ─────────────────────────────────────────────

	// Loads the main script for stateName plus every other .hx/.lua in the same folder.
	public function loadScriptsFromFolder(name:String):Void
	{
		#if sys
		var mainHxPath:String  = getScriptPath(name, '.hx');
		var mainLuaPath:String = getScriptPath(name, '.lua');
		var scriptFolder:String = haxe.io.Path.directory(mainHxPath);
		var mainFileName:String = haxe.io.Path.withoutDirectory(mainHxPath);

		#if LUA_ALLOWED
		if (FileSystem.exists(mainLuaPath))
		{
			loadLuaScript(mainLuaPath);
			trace('[CustomState] Loaded main Lua: $mainLuaPath');
		}
		if (FileSystem.exists(scriptFolder) && FileSystem.isDirectory(scriptFolder))
		{
			for (file in FileSystem.readDirectory(scriptFolder))
			{
				if (!file.endsWith('.lua')) continue;
				var full:String = haxe.io.Path.join([scriptFolder, file]);
				if (full == mainLuaPath) continue;
				loadLuaScript(full);
				trace('[CustomState] Loaded extra Lua: $file');
			}
		}
		#end

		#if HSCRIPT_ALLOWED
		if (FileSystem.exists(mainHxPath))
		{
			loadHScript(mainHxPath);
			trace('[CustomState] Loaded main HScript: $mainHxPath');
		}
		if (FileSystem.exists(scriptFolder) && FileSystem.isDirectory(scriptFolder))
		{
			for (file in FileSystem.readDirectory(scriptFolder))
			{
				if (!file.endsWith('.hx')) continue;
				if (file == mainFileName) continue;
				var full:String = haxe.io.Path.join([scriptFolder, file]);
				loadHScript(full);
				trace('[CustomState] Loaded extra HScript: $file');
			}
		}
		#end
		#end
	}

	// Loads a single script by name from scripts/states/{name}.hx (or .lua).
	public function loadCustomScript(name:String):Void
	{
		#if sys
		#if HSCRIPT_ALLOWED
		var hxPath:String = getScriptPath(name, '.hx');
		if (FileSystem.exists(hxPath)) { loadHScript(hxPath); return; }
		#end
		#if LUA_ALLOWED
		var luaPath:String = getScriptPath(name, '.lua');
		if (FileSystem.exists(luaPath)) loadLuaScript(luaPath);
		#end
		#end
	}

	#if HSCRIPT_ALLOWED
	public function loadHScript(path:String):Void
	{
		try
		{
			var newScript:HScript = new HScript(null, path);

			newScript.set('game',         this);
			newScript.set('add',          this.add);
			newScript.set('remove',       this.remove);
			newScript.set('insert',       this.insert);
			newScript.set('openSubState', this.openSubState);
			newScript.set('stateName',    stateName);
			newScript.set('customState',  this);

			// Shared variable helpers (persist across state changes via globalVariables)
			newScript.set('setSharedVar', function(n:String, v:Dynamic) {
				MusicBeatState.globalVariables.set(n, v);
				variables.set(n, v);
				return v;
			});
			newScript.set('getSharedVar', function(n:String, ?def:Dynamic = null):Dynamic {
				if (MusicBeatState.globalVariables.exists(n)) return MusicBeatState.globalVariables.get(n);
				if (variables.exists(n)) return variables.get(n);
				return def;
			});
			newScript.set('hasSharedVar',    function(n:String):Bool    return MusicBeatState.globalVariables.exists(n) || variables.exists(n));
			newScript.set('removeSharedVar', function(n:String):Bool {
				var r = false;
				if (MusicBeatState.globalVariables.remove(n)) r = true;
				if (variables.remove(n)) r = true;
				return r;
			});
			newScript.set('clearSharedVars', function() {
				MusicBeatState.globalVariables.clear();
				variables.clear();
			});

			// Public variables (shared between scripts in the same state)
			newScript.set('setPublicVar', function(n:String, v:Dynamic) { MusicBeatState.publicVariables.set(n, v); return v; });
			newScript.set('getPublicVar', function(n:String, ?def:Dynamic = null):Dynamic
				return MusicBeatState.publicVariables.exists(n) ? MusicBeatState.publicVariables.get(n) : def);

			// Static variables (persist across all states)
			newScript.set('setStaticVar', function(n:String, v:Dynamic) { MusicBeatState.staticVariables.set(n, v); return v; });
			newScript.set('getStaticVar', function(n:String, ?def:Dynamic = null):Dynamic
				return MusicBeatState.staticVariables.exists(n) ? MusicBeatState.staticVariables.get(n) : def);

			// State variables
			newScript.set('setStateVar', function(n:String, v:Dynamic) { variables.set(n, v); return v; });
			newScript.set('getStateVar', function(n:String, ?def:Dynamic = null):Dynamic
				return variables.exists(n) ? variables.get(n) : def);

			// Mobile helpers
			newScript.set('addTouchPad',        function(d:String, a:String) addTouchPad(d, a));
			newScript.set('removeTouchPad',      function() removeTouchPad());
			newScript.set('addTouchPadCamera',   function(?t:Bool = false) addTouchPadCamera(t));
			newScript.set('addMobileControls',   function(?t:Bool = false) addMobileControls(t));
			newScript.set('removeMobileControls',function() removeMobileControls());

			if (newScript.exists('onCreate')) newScript.call('onCreate');
			hscriptArray.push(newScript);
		}
		catch (e:IrisError)
		{
			var msg:String = Printer.errorToString(e, false);
			showError('HScript Error in ${_fileName(path)}:\n$msg');
			TraceDisplay.addHScriptError(msg, path);
		}
		catch (e:Dynamic)
		{
			showError('Script error in ${_fileName(path)}: $e');
			trace('[CustomState] Failed to load $path: $e');
		}
	}

	// Add a script at runtime (used by Lua callbacks / external callers).
	public function addHScript(scriptFile:String):Bool
	{
		#if sys
		var path:String = Paths.modFolders(scriptFile);
		if (!FileSystem.exists(path)) path = Paths.getSharedPath(scriptFile);
		if (FileSystem.exists(path))
		{
			if (Iris.instances.exists(path)) return false;
			loadHScript(path);
			return true;
		}
		#end
		return false;
	}
	#end

	#if LUA_ALLOWED
	public function loadLuaScript(path:String):Void
	{
		try
		{
			var newScript:FunkinLua = new FunkinLua(path);
			luaArray.push(newScript);
		}
		catch (e:Dynamic)
		{
			trace('[CustomState] Failed to load Lua $path: $e');
		}
	}
	#end

	// ─────────────────────────────────────────────
	// Script callbacks
	// ─────────────────────────────────────────────

	public function callOnScripts(funcName:String, args:Array<Dynamic> = null,
		ignoreStops:Bool = false,
		exclusions:Array<String> = null,
		excludeValues:Array<Dynamic> = null):Dynamic
	{
		var ret:Dynamic = callOnLuas(funcName, args, ignoreStops, exclusions, excludeValues);
		if (ret == LuaUtils.Function_StopHScript || ret == LuaUtils.Function_StopAll) return ret;

		var hret:Dynamic = callOnHScript(funcName, args, ignoreStops, exclusions, excludeValues);
		if (hret != null && hret != LuaUtils.Function_Continue) ret = hret;
		return ret;
	}

	public function callOnLuas(funcName:String, args:Array<Dynamic> = null,
		ignoreStops:Bool = false,
		exclusions:Array<String> = null,
		excludeValues:Array<Dynamic> = null):Dynamic
	{
		var ret:Dynamic = LuaUtils.Function_Continue;
		#if LUA_ALLOWED
		if (exclusions == null)    exclusions    = [];
		if (excludeValues == null) excludeValues = [];
		if (args == null)          args          = [];
		excludeValues.push(LuaUtils.Function_Continue);

		for (script in luaArray)
		{
			if (script == null || script.closed || exclusions.contains(script.scriptName)) continue;
			var v:Dynamic = script.call(funcName, args);
			if ((v == LuaUtils.Function_StopLua || v == LuaUtils.Function_StopAll)
				&& !excludeValues.contains(v) && !ignoreStops) { ret = v; break; }
			if (v != null && !excludeValues.contains(v)) ret = v;
		}
		#end
		return ret;
	}

	public function callOnHScript(funcName:String, args:Array<Dynamic> = null,
		ignoreStops:Bool = false,
		exclusions:Array<String> = null,
		excludeValues:Array<Dynamic> = null):Dynamic
	{
		var ret:Dynamic = LuaUtils.Function_Continue;
		#if HSCRIPT_ALLOWED
		if (exclusions == null)    exclusions    = [];
		if (excludeValues == null) excludeValues = [];
		excludeValues.push(LuaUtils.Function_Continue);

		for (script in hscriptArray)
		{
			@:privateAccess
			if (script == null || !script.exists(funcName) || exclusions.contains(script.origin)) continue;
			try
			{
				var callValue = script.call(funcName, args);
				if (callValue != null)
				{
					var v:Dynamic = callValue.returnValue;
					if ((v == LuaUtils.Function_StopHScript || v == LuaUtils.Function_StopAll)
						&& !excludeValues.contains(v) && !ignoreStops) { ret = v; break; }
					if (v != null && !excludeValues.contains(v)) ret = v;
				}
			}
			catch (e:Dynamic)
			{
				@:privateAccess
				var fn:String = script.origin ?? "unknown";
				showError('HScript Runtime Error in ${_fileName(fn)}:\nFunction: $funcName\nError: $e');
				TraceDisplay.addHScriptError('Runtime error in $funcName: $e', fn);
			}
		}
		#end
		return ret;
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null):Void
	{
		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
	}

	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null):Void
	{
		#if LUA_ALLOWED
		if (exclusions == null) exclusions = [];
		for (script in luaArray)
		{
			if (script == null || script.closed || exclusions.contains(script.scriptName)) continue;
			script.set(variable, arg);
		}
		#end
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null):Void
	{
		#if HSCRIPT_ALLOWED
		if (exclusions == null) exclusions = [];
		for (script in hscriptArray)
		{
			@:privateAccess
			if (exclusions.contains(script.origin)) continue;
			script.set(variable, arg);
		}
		#end
	}

	// ─────────────────────────────────────────────
	// Path resolution
	// ─────────────────────────────────────────────

	static function getScriptPath(name:String, ext:String):String
	{
		#if (MODS_ALLOWED && sys)
		var modPath:String = Paths.modFolders('scripts/states/$name$ext');
		if (FileSystem.exists(modPath)) return modPath;
		#end
		return Paths.getSharedPath('scripts/states/$name$ext');
	}

	// Returns true if a script for this state name exists.
	public static function hasScript(name:String):Bool
	{
		#if sys
		#if HSCRIPT_ALLOWED
		if (FileSystem.exists(getScriptPath(name, '.hx'))) return true;
		#end
		#if LUA_ALLOWED
		if (FileSystem.exists(getScriptPath(name, '.lua'))) return true;
		#end
		#end
		return false;
	}

	// ─────────────────────────────────────────────
	// Utilities
	// ─────────────────────────────────────────────

	static function _fileName(path:String):String
	{
		if (path == null) return "unknown";
		var p = path.split('/'); p = p[p.length - 1].split('\\');
		var n = p[p.length - 1];
		var dot = n.lastIndexOf('.');
		return dot >= 0 ? n.substr(0, dot) : n;
	}
}
