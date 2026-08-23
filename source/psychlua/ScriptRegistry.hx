package psychlua;

#if HSCRIPT_ALLOWED
import backend.Mods;
import backend.Paths;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.iris.Iris;
import haxe.io.Path;
import psychlua.ScriptedClass.ScriptClassHandler;

using StringTools;

class ScriptRegistry
{
	public static var CLASS_ROOTS:Array<String> = ['scripts/classes/', 'classes/'];
	public static inline var STAGE_PACKAGE:String = 'stages';
	public static inline var BASE_GAME_MOD:String = 'Friday Night Funkin';
	public static var verbose:Bool = true;

	static var worlds:Map<String, ScriptWorld> = [];

	public static function loadStage(stage:String):backend.BaseStage
	{
		if (stage == null || stage.length < 1)
		{
			log('loadStage ignored empty stage key');
			return null;
		}

		#if MODS_ALLOWED
		log('loadStage "$stage" current="${Mods.currentModDirectory}" globals=[${Mods.getGlobalMods().join(", ")}] enabled=[${Mods.parseList().enabled.join(", ")}]');
		#else
		log('loadStage "$stage" without MODS_ALLOWED');
		#end

		for (className in candidateNames(stage))
		{
			var fullName:String = STAGE_PACKAGE + '.' + className;
			var resolved:ResolvedScript = resolveClassFile(fullName);
			if (resolved == null)
				continue;

			var handler:ScriptClassHandler = resolveClass(fullName, resolved.mod);
			if (handler == null)
			{
				trace('[ScriptRegistry] stage "$fullName" exists but did not register a class.');
				return null;
			}

			trace('[ScriptRegistry] stage "$stage" -> $fullName from ${resolved.mod} (${resolved.file})');
			return new ScriptedStage(handler, fullName, resolved.file);
		}

		log('no scripted stage found for "$stage"; hardcoded fallback will be used');
		return null;
	}

	public static function resolveClass(fullName:String, ?preferredMod:String):ScriptClassHandler
	{
		log('resolveClass "$fullName" preferred="${preferredMod}"');
		var resolved:ResolvedScript = resolveClassFile(fullName, preferredMod);
		if (resolved == null)
		{
			log('resolveClass "$fullName" failed: no file');
			return null;
		}

		var world:ScriptWorld = worldFor(resolved.mod);
		if (!world.loadClass(fullName, resolved.file))
		{
			log('resolveClass "$fullName" failed: loadClass returned false');
			return null;
		}

		var handler:ScriptClassHandler = world.getClass(fullName);
		log(handler != null ? 'resolveClass "$fullName" registered handler in "${resolved.mod}"' : 'resolveClass "$fullName" loaded file but handler is missing');
		return handler;
	}

	static function worldFor(mod:String):ScriptWorld
	{
		if (mod == null)
			mod = '';

		var world:ScriptWorld = worlds.get(mod);
		if (world == null)
		{
			world = new ScriptWorld(mod);
			worlds.set(mod, world);
		}
		return world;
	}

	public static function resolveClassFile(fullName:String, ?preferredMod:String):ResolvedScript
	{
		log('resolveClassFile "$fullName" preferred="${preferredMod}"');
		for (candidate in classFileCandidates(fullName, preferredMod))
		{
			var exists:Bool = Paths.safeModPathExists(candidate.file);
			log('  check ${candidate.mod.length > 0 ? candidate.mod : "<bare>"} -> ${candidate.file} ${exists ? "OK" : "missing"}');
			if (exists)
				return candidate;
		}
		log('  no file found for "$fullName"');
		return null;
	}

	static function classFileCandidates(fullName:String, ?preferredMod:String):Array<ResolvedScript>
	{
		var relative:String = fullName.split('.').join('/') + '.hx';
		var candidates:Array<ResolvedScript> = [];
		var mods:Array<String> = [];

		function addMod(mod:String):Void
		{
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

		log('classFileCandidates "$fullName" relative="$relative" mods=[${mods.join(", ")}]');

		for (mod in mods)
		{
			for (root in CLASS_ROOTS)
				candidates.push({file: Paths.mods(mod + '/' + root + relative), mod: mod});
		}

		for (root in CLASS_ROOTS)
		{
			candidates.push({file: Paths.mods(root + relative), mod: ''});
			candidates.push({file: 'base_game/' + root + relative, mod: BASE_GAME_MOD});
		}

		return candidates;
	}

	static function candidateNames(stage:String):Array<String>
	{
		var capitalized:String = stage.charAt(0).toUpperCase() + stage.substr(1);
		return capitalized == stage ? [stage] : [capitalized, stage];
	}

	public static function log(message:String):Void
	{
		if (verbose)
			trace('[ScriptRegistry] ' + message);
	}
}

private typedef ResolvedScript =
{
	var file:String;
	var mod:String;
}

private class ScriptWorld
{
	public var mod:String;
	var script:HScript;
	var loaded:Map<String, String> = [];
	var loading:Array<String> = [];

	public function new(mod:String)
	{
		this.mod = mod;
		script = new HScript(null, '', null, true);
		ScriptRegistry.log('world="${mod}" roots=${ScriptRegistry.CLASS_ROOTS.join(", ")}');
	}

	public function getClass(fullName:String):ScriptClassHandler
	{
		var shortName:String = shortClassName(fullName);
		var handler:ScriptClassHandler = script.getScriptedClass(shortName);
		if (handler != null)
		{
			@:privateAccess script.interp.customClasses.set(fullName, handler);
			@:privateAccess script.interp.imports.set(shortName, handler);
		}
		return handler;
	}

	public function loadClass(fullName:String, file:String):Bool
	{
		if (loaded.exists(fullName))
		{
			ScriptRegistry.log('loadClass "$fullName" skipped: already loaded from ${loaded.get(fullName)}');
			return true;
		}
		if (loading.contains(fullName))
		{
			ScriptRegistry.log('loadClass "$fullName" skipped: currently loading');
			return true;
		}
		if (mod != null && mod.length > 0 && backend.ModSecurity.isBlocked(mod))
		{
			ScriptRegistry.log('blocked $fullName from untrusted mod "$mod"');
			return false;
		}

		ScriptRegistry.log('loadClass "$fullName" from $file');
		loading.push(fullName);

		var code:String = Paths.safeFileContent(file);
		if (code == null)
		{
			ScriptRegistry.log('loadClass "$fullName" failed: file content is null');
			loading.remove(fullName);
			return false;
		}

		for (dependency in scriptedImports(code))
		{
			ScriptRegistry.log('  import "$dependency" from "$fullName"');
			var resolved:ResolvedScript = ScriptRegistry.resolveClassFile(dependency, mod);
			if (resolved != null)
				loadClass(dependency, resolved.file);
			else
				ScriptRegistry.log('  import "$dependency" not found as scripted class; leaving as native/engine import');
		}

		for (dependency in loaded.keys())
			exposeAlias(dependency);

		try
		{
			script.executeFile(file);
			loaded.set(fullName, file);
			exposeAlias(fullName);
			ScriptRegistry.log('loaded $fullName from $file');
		}
		catch (e:IrisError)
		{
			Iris.error(crowplexus.hscript.Printer.errorToString(e, false), cast {fileName: file, showLine: true});
			loading.remove(fullName);
			return false;
		}
		catch (e:Dynamic)
		{
			ScriptRegistry.log('failed $fullName from $file: $e');
			loading.remove(fullName);
			return false;
		}

		loading.remove(fullName);
		return true;
	}

	function exposeAlias(fullName:String):Void
	{
		var handler:ScriptClassHandler = script.getScriptedClass(shortClassName(fullName));
		if (handler == null)
			return;

		@:privateAccess script.interp.customClasses.set(fullName, handler);
		@:privateAccess script.interp.imports.set(shortClassName(fullName), handler);
	}

	static function scriptedImports(code:String):Array<String>
	{
		var imports:Array<String> = [];
		var rx:EReg = ~/import\s+([A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)+)(?:\s+as\s+[A-Za-z_][A-Za-z0-9_]*)?\s*;/g;
		while (rx.match(code))
		{
			var path:String = rx.matched(1);
			code = rx.matchedRight();

			if (path.endsWith('.*'))
				continue;
			if (Type.resolveClass(path) != null || Type.resolveEnum(path) != null)
				continue;
			if (!imports.contains(path))
				imports.push(path);
		}
		return imports;
	}

	static function shortClassName(fullName:String):String
	{
		var parts:Array<String> = fullName.split('.');
		return parts[parts.length - 1];
	}
}
#end
