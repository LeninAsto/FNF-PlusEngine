package scripting;

#if HSCRIPT_ALLOWED
import backend.AssetLoader;
import backend.MusicBeatState;
import backend.MusicBeatSubstate;
import backend.Mods;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSubState;
import openfl.utils.AssetType;
import scripting.hscript.HScript;

using StringTools;

enum ResolveScope {
	ANY;
	LAUNCHED;
	ENGINE;
	PRIORITY;
}

typedef ScriptedStateFile = {
	var full:String;
	var file:String;
	var mod:String;
}

class ScriptedStates {
	public static var activeScriptedState:String = null;
	public static var activeScriptedMod:String = null;

	public static function hasState(name:String, scope:ResolveScope = ANY):Bool
		return resolveScript(ScriptRegistry.STATE_PACKAGE, name, scope) != null;

	public static function hasSubstate(name:String, scope:ResolveScope = ANY):Bool
		return resolveScript(ScriptRegistry.SUBSTATE_PACKAGE, name, scope) != null;

	public static function loadState(name:String, ?args:Array<Dynamic>, scope:ResolveScope = ANY):MusicBeatState {
		return loadStateFromResolved(name, resolveScript(ScriptRegistry.STATE_PACKAGE, name, scope), args);
	}

	public static function loadStateFromMod(name:String, ?args:Array<Dynamic>, ?mod:String):MusicBeatState {
		return loadStateFromResolved(name, resolveInModCandidates(candidateFullNames(ScriptRegistry.STATE_PACKAGE, name), mod), args);
	}

	public static function loadSubstate(name:String, ?args:Array<Dynamic>, scope:ResolveScope = ANY):MusicBeatSubstate {
		var resolved:ScriptedStateFile = resolveScript(ScriptRegistry.SUBSTATE_PACKAGE, name, scope);
		if (resolved == null)
			return null;

		var inst:Dynamic = ScriptRegistry.instantiateResolved(resolved.full, resolved.file, resolved.mod, args);
		if (inst == null)
			return null;

		if (!Std.isOfType(inst, MusicBeatSubstate)) {
			HScript.error('Scripted substate "$name" must extend MusicBeatSubstate', errPos(name));
			return null;
		}

		var substate:MusicBeatSubstate = cast inst;
		substate.scriptName = className(name);
		substate.scriptOwnerMod = resolved.mod;
		substate.isScriptedSubstate = true;
		return substate;
	}

	public static function switchToState(name:String, ?args:Array<Dynamic>, scope:ResolveScope = ANY):Bool {
		var state:MusicBeatState = loadState(name, args, scope);
		if (state == null)
			return false;

		MusicBeatState.switchState(state);
		return true;
	}

	public static function openSubstate(name:String, ?args:Array<Dynamic>, scope:ResolveScope = ANY):Bool {
		var substate:MusicBeatSubstate = loadSubstate(name, args, scope);
		if (substate == null || FlxG.state == null)
			return false;

		FlxG.state.openSubState(substate);
		return true;
	}

	public static function launchMod(folder:String):Bool {
		#if MODS_ALLOWED
		if (folder == null || folder.trim().length < 1 || !Mods.isLaunchable(folder))
			return false;

		var previousMod:String = Mods.currentModDirectory;
		var previousLaunched:String = Mods.launchedMod;
		var entry:String = Mods.getEntryState(folder);

		Mods.launchedMod = folder;
		Mods.currentModDirectory = folder;
		Mods.pushGlobalMods();
		Mods.applyWindowBrand(folder);
		ScriptRegistry.disposeMod(folder);
		GlobalScriptManager.loadForMod(folder);

		var state:MusicBeatState = loadState(entry, [], LAUNCHED);
		if (state == null) {
			GlobalScriptManager.dispose();
			Mods.launchedMod = previousLaunched;
			Mods.currentModDirectory = previousMod;
			Mods.pushGlobalMods();
			if (previousLaunched != null && previousLaunched.length > 0)
				Mods.applyWindowBrand(previousLaunched);
			else
				Mods.resetWindowBrand();
			if (previousLaunched != null && previousLaunched.length > 0)
				GlobalScriptManager.loadForMod(previousLaunched);
			return false;
		}

		FlxG.save.data.launchedMod = folder;
		FlxG.save.flush();
		playMenuMusic(folder);
		MusicBeatState.switchState(state);
		return true;
		#else
		return false;
		#end
	}

	/**
	 * Drops the session-only launch context without choosing a destination state.
	 *
	 * Enabling a mod is not the same operation as launching it.  Callers that
	 * restart the engine after changing the enabled list need this so InitState
	 * does not attempt to reopen an old scripted entry point.
	 */
	public static function clearLaunchedModContext():Void {
		states.PlayState.returnToScriptedState = null;
		activeScriptedState = null;
		activeScriptedMod = null;
		#if MODS_ALLOWED
		if (Mods.launchedMod != null && Mods.launchedMod.length > 0)
			ScriptRegistry.disposeMod(Mods.launchedMod);
		GlobalScriptManager.dispose();
		Mods.launchedMod = null;
		Mods.currentModDirectory = '';
		FlxG.save.data.launchedMod = null;
		FlxG.save.flush();
		Mods.pushGlobalMods();
		Mods.resetWindowBrand();
		backend.Language.reloadPhrases();
		#end
	}

	public static function exitToEngine():Void {
		clearLaunchedModContext();
		MusicBeatState.switchState(new states.ModsMenuState());
	}

	/** Opens the mod browser without ending an active launched-mod session. */
	public static function openModsMenu():Void {
		MusicBeatState.switchState(new states.ModsMenuState());
	}

	static function loadStateFromResolved(name:String, resolved:ScriptedStateFile, ?args:Array<Dynamic>):MusicBeatState {
		if (resolved == null)
			return null;

		var full:String = resolved.full;
		var inst:Dynamic = ScriptRegistry.instantiateResolved(full, resolved.file, resolved.mod, args);
		if (inst == null)
			return null;

		if (!Std.isOfType(inst, MusicBeatState)) {
			HScript.error('Scripted state "$name" must extend MusicBeatState', errPos(name));
			return null;
		}

		var state:MusicBeatState = cast inst;
		state.scriptName = className(name);
		state.scriptOwnerMod = resolved.mod;
		state.isScriptedState = true;
		activeScriptedState = state.scriptName;
		activeScriptedMod = resolved.mod;
		return state;
	}

	static function resolveScript(pack:String, name:String, scope:ResolveScope):ScriptedStateFile {
		var candidates:Array<String> = candidateFullNames(pack, name);
		var launchedMod:String = Mods.launchedMod;
		var hasLaunchedMod:Bool = launchedMod != null && launchedMod.length > 0;
		return switch (scope) {
			case LAUNCHED:
				hasLaunchedMod ? resolveInModCandidates(candidates, launchedMod) : null;
			case ENGINE:
				resolveEngineCandidates(candidates);
			case PRIORITY:
				hasLaunchedMod ? resolveInModCandidates(candidates, launchedMod) : null;
			case ANY:
				resolveAnyCandidate(candidates);
		}
	}

	static function resolveAnyCandidate(candidates:Array<String>):ScriptedStateFile {
		for (full in candidates) {
			var resolved = ScriptRegistry.resolveClassFile(full);
			if (resolved != null)
				return {full: full, file: resolved.file, mod: resolved.mod};
		}
		return null;
	}

	static function resolveEngineCandidates(candidates:Array<String>):ScriptedStateFile {
		for (full in candidates) {
			for (relative in ScriptRegistry.classPaths(full)) {
				var sharedAssets:String = Paths.getSharedPath(relative);
				if (AssetLoader.exists(sharedAssets, AssetType.TEXT))
					return {full: full, file: sharedAssets, mod: ScriptRegistry.SHARED_WORLD};

				#if MODS_ALLOWED
				var shared:String = Paths.mods(relative);
				if (AssetLoader.exists(shared, AssetType.TEXT))
					return {full: full, file: shared, mod: ScriptRegistry.SHARED_WORLD};

				var base:String = 'base_game/' + relative;
				if (AssetLoader.exists(base, AssetType.TEXT))
					return {full: full, file: base, mod: ScriptRegistry.BASE_GAME_MOD};
				#end
			}
		}
		return null;
	}

	static function resolveInModCandidates(candidates:Array<String>, ?mod:String):ScriptedStateFile {
		#if MODS_ALLOWED
		if (mod != null && mod.length > 0) {
			for (full in candidates) {
				for (relative in ScriptRegistry.classPaths(full)) {
					var file:String = Paths.mods(mod + '/' + relative);
					if (AssetLoader.exists(file, AssetType.TEXT))
						return {full: full, file: file, mod: mod};
				}
			}
			return null;
		}
		#end

		return null;
	}

	static function playMenuMusic(folder:String):Void {
		var music:String = Mods.getMenuMusic(folder);
		if (music == null || music.length < 1 || FlxG.sound == null)
			return;

		try
			FlxG.sound.playMusic(Paths.music(music), 0.7, true)
		catch (_:Dynamic) {}
	}

	static function fullName(pack:String, name:String):String {
		if (name == null)
			name = '';
		name = name.trim();
		if (name.indexOf('.') >= 0)
			return name;
		return pack + '.' + className(name);
	}

	static function candidateFullNames(pack:String, name:String):Array<String> {
		var exact:String = fullName(pack, name);
		var parts:Array<String> = exact.split('.');
		var cls:String = parts.pop();
		var wrapper:String = parts.concat([cls + 'Script']).join('.');
		return wrapper == exact ? [exact] : [wrapper, exact];
	}

	static function className(name:String):String {
		if (name == null)
			return '';
		name = name.trim();
		if (name.indexOf('.') >= 0) {
			var parts:Array<String> = name.split('.');
			return parts[parts.length - 1];
		}
		return name;
	}

	static inline function errPos(name:String):scripting.hscript.HScript.HScriptInfos
		return cast {fileName: name, showLine: false};
}

class ScriptedReturnState extends MusicBeatState {
	var target:String;
	var scope:ResolveScope;
	var args:Array<Dynamic>;
	var done:Bool = false;

	public function new(target:String, ?scope:ResolveScope, ?args:Array<Dynamic>) {
		this.target = target;
		this.scope = scope != null ? scope : LAUNCHED;
		this.args = args;
		super();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (done)
			return;

		done = true;
		if (!ScriptedStates.switchToState(target, args, scope))
			MusicBeatState.switchState(backend.ScriptableState.tryCreate('MainMenuState', new states.MainMenuState()));
	}
}
#end
