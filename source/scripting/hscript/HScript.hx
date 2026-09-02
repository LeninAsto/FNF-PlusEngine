package scripting.hscript;

#if HSCRIPT_ALLOWED
import hxscript.Script;
import hxscript.runtime.Interp;
import hxscript.Config.ConfigBlacklistKind;
import hxscript.syntax.Expr.ImportMode;
import openfl.utils.Assets as OpenFlAssets;

typedef HScriptInfos = {
	> haxe.PosInfos,
	var ?funcName:String;
	var ?showLine:Null<Bool>;
	#if LUA_ALLOWED
	var ?isLua:Null<Bool>;
	#end
}

typedef HScriptCall = {
	var funName:String;
	var signature:Dynamic;
	var returnValue:Dynamic;
}

class HScript {
	public static var instances:Map<String, HScript> = new Map();

	public var script:Script;
	public var interp(get, never):Interp;
	inline function get_interp():Interp
		return script != null ? script.interp : null;

	public var name:String;
	public var filePath:String;
	public var modFolder:String;
	public var returnValue:Dynamic;
	public var scriptCode:String;
	public var origin:String;
	public var blocked:Bool = false;
	public var failed:Bool = false;
	public var varsToBring:Any = null;

	var presetDone:Bool = false;
	var hookCache:Map<String, Bool> = new Map();

	public static function setupConfig():Void {
		hxscript.Config.interpClass = PsychInterp;
		hxscript.Config.strictAccess = true;

		for (base in scripting.bridges.Bridges.bases)
			hxscript.Config.globalImports.set(base, ImportMode.INormal);

		scripting.ScriptGlobals.register();
		scripting.ScriptShims.register();

		#if MODS_ALLOWED
		var byType:Array<String> = hxscript.Config.blacklist.get(ConfigBlacklistKind.ByType);
		if (byType == null) {
			byType = [];
			hxscript.Config.blacklist.set(ConfigBlacklistKind.ByType, byType);
		}
		for (name => _ in backend.ModSecurity.BLOCKED_CLASSES)
			if (name.indexOf('.') >= 0 && !byType.contains(name))
				byType.push(name);

		var byPackage:Array<String> = hxscript.Config.blacklist.get(ConfigBlacklistKind.ByPackage(true));
		if (byPackage == null) {
			byPackage = [];
			hxscript.Config.blacklist.set(ConfigBlacklistKind.ByPackage(true), byPackage);
		}
		for (pack in backend.ModSecurity.BLOCKED_PACKAGES) {
			var name:String = pack;
			if (name.endsWith('.'))
				name = name.substr(0, name.length - 1);
			if (name.length > 0 && !byPackage.contains(name))
				byPackage.push(name);
		}
		#end

		trace('[HScript/hxscript] setup complete; bridges=${scripting.bridges.Bridges.bases.join(", ")}');
	}

	public function new(?parent:Dynamic, ?file:String, ?varsToBring:Any = null, ?manualRun:Bool = false) {
		if (file == null)
			file = '';

		filePath = file;
		origin = filePath;

		if (filePath != null && filePath.length > 0) {
			#if MODS_ALLOWED
			var normalized:String = filePath.replace('\\', '/');
			var resolvedModName:String = backend.Paths.getModFolderNameFromPath(normalized);
			if (resolvedModName != null && (backend.Mods.currentModDirectory == resolvedModName || backend.Mods.getGlobalMods().contains(resolvedModName)))
				modFolder = resolvedModName;
			#end
		}

		#if MODS_ALLOWED
		if (modFolder != null && backend.ModSecurity.isBlocked(modFolder)) {
			blocked = true;
			trace('[HScript/hxscript] blocked $file from untrusted mod "$modFolder"');
			return;
		}
		#end

		var code:String = file;
		var scriptName:String = null;
		if (parent == null && file != null) {
			var normalizedFile:String = file.replace('\\', '/');
			if (normalizedFile.contains('/') && !normalizedFile.contains('\n')) {
				#if sys
				if (sys.FileSystem.exists(normalizedFile))
					code = sys.io.File.getContent(normalizedFile);
				else
				#end
				if (OpenFlAssets.exists(normalizedFile))
					code = OpenFlAssets.getText(normalizedFile);
				scriptName = normalizedFile;
			}
		}

		#if LUA_ALLOWED
		if (scriptName == null && parent != null && Reflect.hasField(parent, 'scriptName'))
			scriptName = Reflect.field(parent, 'scriptName');
		if (parent != null && Reflect.hasField(parent, 'modFolder'))
			modFolder = Reflect.field(parent, 'modFolder');
		#end

		scriptCode = code;
		name = scriptName != null ? scriptName : (origin != null && origin.length > 0 ? origin : 'hscript');
		script = new Script(code, name);
		hookErrors();

		if (interp != null && (interp is PsychInterp))
			cast(interp, PsychInterp).parentInstance = flixel.FlxG.state;

		this.varsToBring = varsToBring;
		instances.set(name, this);

		if (!manualRun)
			run();
	}

	public function run():Dynamic {
		returnValue = null;
		if (script == null || script.program == null)
			return null;

		if (!presetDone) {
			script.setDefaults();
			preset();
			presetDone = true;
		}
		applyVarsToBring();

		try {
			returnValue = interp.execute(script.program);
			scripting.ScriptHooks.bindHScript(script.variables);
			hookCache.clear();
		} catch (e:haxe.Exception) {
			failed = true;
			returnValue = null;
			error(e.message, errorPos());
		}

		return returnValue;
	}

	function applyVarsToBring():Void {
		if (varsToBring == null)
			return;
		for (key in Reflect.fields(varsToBring))
			set(key.trim(), Reflect.field(varsToBring, key));
	}

	function hookErrors():Void {
		script.onParsingError = function(e:haxe.Exception) {
			failed = true;
			error(e.message, errorPos());
		};
		script.onProgramError = function(e:haxe.Exception) {
			failed = true;
			error(e.message, errorPos());
		};
	}

	function errorPos(?funcName:String):HScriptInfos {
		var pos:HScriptInfos = (interp != null) ? cast interp.posInfos() : cast {fileName: name, showLine: false};
		if (funcName != null)
			pos.funcName = funcName;
		return pos;
	}

	function preset():Void {
		scripting.ScriptGlobals.shared(function(name:String, value:Dynamic) set(name, value), modFolder);
		set('this', this);
		set('game', flixel.FlxG.state);
		set('FlxG', flixel.FlxG);
		set('FlxSprite', flixel.FlxSprite);
		set('FlxText', flixel.text.FlxText);
		set('FlxCamera', flixel.FlxCamera);
		set('FlxTimer', flixel.util.FlxTimer);
		set('FlxTween', flixel.tweens.FlxTween);
		set('FlxEase', flixel.tweens.FlxEase);
		set('PlayState', states.PlayState);
		set('Paths', backend.Paths);
		set('Conductor', backend.Conductor);
		set('ClientPrefs', backend.ClientPrefs);
		set('Character', objects.Character);
		set('Alphabet', objects.Alphabet);
		set('Note', objects.Note);
		set('CustomSubstate', psychlua.CustomSubstate);
		set('ModchartSprite', psychlua.ModchartSprite);
		#if (!flash && sys)
		set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		#end
		set('ShaderFilter', openfl.filters.ShaderFilter);
		set('addHaxeLibrary', addHaxeLibrary);
	}

	function addHaxeLibrary(libName:String, ?libPackage:String = ''):Void {
		var path:String = (libPackage != null && libPackage.length > 0) ? '$libPackage.$libName' : libName;
		var c:Dynamic = #if MODS_ALLOWED backend.ModSecurity.safeResolveClass(path) #else Type.resolveClass(path) #end;
		if (c == null)
			c = Type.resolveEnum(path);
		if (c != null)
			set(libName, c);
		else
			error('addHaxeLibrary: unable to resolve $path', errorPos());
	}

	public function set(name:String, value:Dynamic):Void {
		if (script != null)
			script.variables.set(name, value);
		hookCache.remove(name);
	}

	public function get(name:String):Dynamic
		return script != null ? script.variables.get(name) : null;

	public function exists(name:String):Bool
		return script != null && script.variables.exists(name);

	public function definesHook(hook:String):Bool {
		if (script == null)
			return false;
		var known:Null<Bool> = hookCache.get(hook);
		if (known != null)
			return known;
		var value:Dynamic = script.variables.get(hook);
		var defined:Bool = value != null && Reflect.isFunction(value);
		hookCache.set(hook, defined);
		return defined;
	}

	public function defineHook(func:String):Void
		hookCache.remove(func);

	public function call(funcToCall:String, ?args:Array<Dynamic>):Dynamic {
		var ret:HScriptCall = callDetailed(funcToCall, args);
		return ret == null ? null : ret.returnValue;
	}

	public function callDetailed(funcToCall:String, ?args:Array<Dynamic>):HScriptCall {
		if (funcToCall == null || funcToCall.length < 1 || script == null)
			return null;

		var fn:Dynamic = script.variables.get(funcToCall);
		if (fn == null)
			fn = interp.getLocal(funcToCall);
		if (!Reflect.isFunction(fn))
			return null;

		try {
			return {
				funName: funcToCall,
				signature: fn,
				returnValue: Reflect.callMethod(interp, fn, args == null ? [] : args)
			};
		} catch (e:haxe.Exception) {
			failed = true;
			error(e.message, errorPos(funcToCall));
		}
		return null;
	}

	public function destroy():Void {
		if (name != null)
			instances.remove(name);
		if (script != null && script.variables != null)
			script.variables.clear();
		hookCache.clear();
		script = null;
	}

	public static function warn(x:Dynamic, ?pos:HScriptInfos):Void
		report('WARNING', x, pos, flixel.util.FlxColor.YELLOW);

	public static function error(x:Dynamic, ?pos:HScriptInfos):Void
		report('ERROR', x, pos, flixel.util.FlxColor.RED);

	public static function fatal(x:Dynamic, ?pos:HScriptInfos):Void
		report('FATAL', x, pos, 0xFFBB0000);

	static function report(kind:String, x:Dynamic, ?pos:HScriptInfos, ?color:flixel.util.FlxColor):Void {
		if (pos == null)
			pos = cast {fileName: 'hxscript', showLine: false};
		if (pos.showLine == null)
			pos.showLine = true;

		var msgInfo:String = (pos.funcName != null ? '(${pos.funcName}) - ' : '') + '${pos.fileName}:';
		if (pos.showLine == true)
			msgInfo += '${pos.lineNumber}:';
		msgInfo += ' $x';
		scripting.ScriptError.show('$kind: $msgInfo', color);
	}
}
#end
