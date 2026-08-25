package scripting;

#if HSCRIPT_ALLOWED
import backend.Mods;
import backend.Paths;
import hxscript.Environment;
import hxscript.Module;
import hxscript.syntax.Expr;
import hxscript.types.IScriptedType;
import hxscript.types.ScriptedClass;
import hxscript.types.TypeCollection;
import scripting.hscript.HScript;

using StringTools;

class ScriptRegistry {
	public static final CLASS_ROOTS:Array<String> = ['scripts/classes/', 'classes/'];
	public static inline var STAGE_PACKAGE:String = 'stages';
	public static inline var BASE_GAME_MOD:String = 'Friday Night Funkin';
	public static inline var SHARED_WORLD:String = '';
	public static var verbose:Bool = false;

	static var worlds:Map<String, ScriptWorld> = new Map();

	public static function loadStage(stage:String):backend.BaseStage {
		if (stage == null || stage.length < 1)
			return null;

		log('loadStage "$stage" current="${Mods.currentModDirectory}" globals=[${Mods.getGlobalMods().join(", ")}]');

		for (className in candidateNames(stage)) {
			var fullName:String = STAGE_PACKAGE + '.' + className;
			var resolved:ResolvedScript = resolveClassFile(fullName);
			if (resolved == null)
				continue;

			var inst:Dynamic = instantiate(fullName, [], resolved.mod);
			if (inst == null)
				return null;

			if (!(inst is backend.BaseStage)) {
				HScript.error('Scripted stage "$fullName" must extend BaseStage', errPos(fullName));
				return null;
			}

			trace('[ScriptRegistry] stage "$stage" -> $fullName');
			return cast inst;
		}

		log('no scripted stage found for "$stage"; hardcoded fallback will be used');
		return null;
	}

	public static function resolveClass(path:String, ?preferredMod:String):ScriptedClass {
		var resolved:ResolvedScript = resolveClassFile(path, preferredMod);
		if (resolved == null) {
			log('resolveClass "$path" failed: no file');
			return null;
		}

		var type:IScriptedType = worldFor(resolved.mod).resolve(path, resolved.file);
		if (type == null)
			return null;

		if (!(type is ScriptedClass)) {
			HScript.error('Scripted type "$path" is not a class', errPos(path));
			return null;
		}

		return cast type;
	}

	public static function instantiate(path:String, ?args:Array<Dynamic>, ?preferredMod:String):Dynamic {
		var cls:ScriptedClass = resolveClass(path, preferredMod);
		if (cls == null)
			return null;

		makeSafe(cls);

		if (cls.failed || !cls.initialized) {
			HScript.error('Scripted type "$path" did not initialize; check the previous hxscript error for the real cause.', errPos(path));
			return null;
		}

		try {
			return cls.typeCreateInstance(args == null ? [] : args);
		} catch (e:haxe.Exception) {
			HScript.error('Failed to instantiate "$path": ${e.details()}', errPos(path));
			return null;
		}
	}

	public static function classPaths(path:String):Array<String> {
		var relative:String = path.split('.').join('/') + '.hx';
		return [for (root in CLASS_ROOTS) root + relative];
	}

	public static function resolveClassFile(fullName:String, ?preferredMod:String):ResolvedScript {
		for (candidate in classFileCandidates(fullName, preferredMod)) {
			var exists:Bool = Paths.safeModPathExists(candidate.file);
			log('  check ${candidate.mod.length > 0 ? candidate.mod : "<shared>"} -> ${candidate.file} ${exists ? "OK" : "missing"}');
			if (exists)
				return candidate;
		}
		return null;
	}

	static function classFileCandidates(fullName:String, ?preferredMod:String):Array<ResolvedScript> {
		var relative:String = fullName.split('.').join('/') + '.hx';
		var candidates:Array<ResolvedScript> = [];
		var mods:Array<String> = [];

		function addMod(mod:String):Void {
			if (mod != null && mod.length > 0 && !mods.contains(mod))
				mods.push(mod);
		}

		addMod(preferredMod);
		#if MODS_ALLOWED
		addMod(Mods.currentModDirectory);
		for (mod in Mods.getGlobalMods())
			addMod(mod);
		for (mod in Mods.parseList().enabled)
			addMod(mod);
		#end
		addMod(BASE_GAME_MOD);

		for (mod in mods)
			for (root in CLASS_ROOTS)
				candidates.push({file: Paths.mods(mod + '/' + root + relative), mod: mod});

		for (root in CLASS_ROOTS) {
			candidates.push({file: Paths.mods(root + relative), mod: SHARED_WORLD});
			candidates.push({file: 'base_game/' + root + relative, mod: BASE_GAME_MOD});
		}

		return candidates;
	}

	static function worldFor(?mod:String):ScriptWorld {
		var key:String = (mod == null) ? SHARED_WORLD : mod;
		var world:ScriptWorld = worlds.get(key);
		if (world == null) {
			world = new ScriptWorld(key);
			worlds.set(key, world);
			log('created world="${key.length > 0 ? key : "<shared>"}"');
		}
		return world;
	}

	public static function disposeMod(?mod:String):Void {
		var key:String = (mod == null) ? SHARED_WORLD : mod;
		var world:ScriptWorld = worlds.get(key);
		if (world == null)
			return;
		world.dispose();
		worlds.remove(key);
		log('disposed world="${key.length > 0 ? key : "<shared>"}"');
	}

	public static function dispose():Void {
		for (world in worlds)
			world.dispose();
		worlds.clear();
		log('disposed all worlds');
	}

	public static function makeSafe(cls:ScriptedClass):Void {
		cls.safe = true;
		cls.onInstanceError = function(e:Dynamic, fun:String, ?inst:Dynamic) {
			HScript.error('${cls.path}.$fun(): $e', errPos(cls.path));
		};
	}

	static function candidateNames(stage:String):Array<String> {
		var capitalized:String = stage.charAt(0).toUpperCase() + stage.substr(1);
		return capitalized == stage ? [stage] : [capitalized, stage];
	}

	static inline function errPos(name:String):scripting.hscript.HScript.HScriptInfos
		return cast {fileName: name, showLine: false};

	public static function log(message:String):Void {
		if (verbose)
			trace('[ScriptRegistry] ' + message);
	}
}

typedef ResolvedScript = {
	var file:String;
	var mod:String;
}

class ScriptWorld {
	public var mod(default, null):String;
	public var environment(default, null):Environment;
	public var modules(default, null):Map<String, Module> = new Map();
	public var files(default, null):Map<String, String> = new Map();
	public var loading(default, null):Array<String> = [];
	public var failed(default, null):Array<String> = [];

	public function new(mod:String) {
		this.mod = mod;
		environment = new Environment();
		ScriptGlobals.inject(environment.variables, mod);
	}

	public function resolve(path:String, ?knownFile:String):IScriptedType {
		var found:IScriptedType = environment.resolve(path);
		if (found != null)
			return found;

		if (failed.contains(path))
			return null;

		var added:Array<Module> = [];
		if (!load(path, knownFile, added)) {
			failed.push(path);
			return null;
		}

		startAll(added);
		return environment.resolve(path);
	}

	public function dispose():Void {
		environment.snapshot();
		modules.clear();
		files.clear();
		loading.resize(0);
		failed.resize(0);
		environment = new Environment();
		ScriptGlobals.inject(environment.variables, mod);
	}

	function load(path:String, ?knownFile:String, added:Array<Module>):Bool {
		if (modules.exists(path))
			return true;
		if (loading.contains(path))
			return true;

		var file:String = knownFile;
		if (file == null) {
			var resolved:ResolvedScript = ScriptRegistry.resolveClassFile(path, mod);
			if (resolved != null)
				file = resolved.file;
		}

		if (file == null) {
			HScript.error('Unresolved import "$path": no compiled type and no script class file found', errPos(path));
			return false;
		}

		#if MODS_ALLOWED
		if (mod != null && mod.length > 0 && backend.ModSecurity.isBlocked(mod)) {
			HScript.error('Blocked scripted class "$path": mod "$mod" is not trusted', errPos(path));
			return false;
		}
		#end

		var code:String = Paths.safeFileContent(file);
		if (code == null || code.length == 0) {
			HScript.error('Empty scripted class file "$file"', errPos(path));
			return false;
		}

		loading.push(path);

		var parts:Array<String> = path.split('.');
		var name:String = parts.pop();
		var module:Module = new Module(code, name, parts, file);
		var hadError:Bool = false;
		module.onParsingError = function(e:haxe.Exception) {
			hadError = true;
			HScript.error('Parse error in "$file": ${e.details()}', errPos(path));
		};
		module.onProgramError = function(e:haxe.Exception) {
			hadError = true;
			HScript.error('Runtime error in "$file": ${e.details()}', errPos(path));
		};
		module.onTypeError = function(e:haxe.Exception, type:IScriptedType) {
			hadError = true;
			HScript.error('Type error in "${type.name}" from "$file": ${e.details()}', errPos(path));
		};

		if (hadError) {
			loading.remove(path);
			return false;
		}

		modules.set(path, module);
		files.set(path, file);
		environment.addModule(module);
		added.push(module);
		ScriptRegistry.log('loaded class="$path" file="$file" world="${mod.length > 0 ? mod : "<shared>"}" types=${Lambda.count(module.types)}');

		for (dependency in scriptedImports(module))
			if (!load(dependency, null, added)) {
				loading.remove(path);
				return false;
			}

		loading.remove(path);
		return true;
	}

	function scriptedImports(module:Module):Array<String> {
		var paths:Array<String> = [];

		for (decl in module.decls) {
			switch (decl.d) {
				case DImport(path, _):
					var parts:Array<String> = path.copy();
					if (parts.length > 0 && parts[parts.length - 1] == '*')
						continue;

					while (parts.length > 0 && !isTypeName(parts[parts.length - 1]))
						parts.pop();

					if (parts.length == 0)
						continue;

					var full:String = parts.join('.');
					if (isCompiledType(full) || modules.exists(full))
						continue;

					if (!paths.contains(full))
						paths.push(full);
				default:
			}
		}

		return paths;
	}

	static function isCompiledType(path:String):Bool {
		if (TypeCollection.main.fromPath(path) != null)
			return true;
		if (Type.resolveClass(path) != null || Type.resolveEnum(path) != null)
			return true;
		return false;
	}

	static inline function isTypeName(s:String):Bool
		return s.length > 0 && s.charAt(0) == s.charAt(0).toUpperCase();

	function startAll(added:Array<Module>):Void {
		for (module in added)
			module.init(environment);
		for (module in added)
			module.start(environment);
		for (module in added)
			module.startTypes(environment);

		for (module in added)
			for (type in module.types)
				if (type is ScriptedClass)
					ScriptRegistry.makeSafe(cast type);
	}

	static inline function errPos(name:String):scripting.hscript.HScript.HScriptInfos
		return cast {fileName: name, showLine: false};
}
#end
