package scripting;

#if HSCRIPT_ALLOWED
import backend.MusicBeatState;
import backend.MusicBeatSubstate;
import backend.Mods;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSubState;
import scripting.hscript.HScript;

using StringTools;

enum ResolveScope {
	ANY;
	LAUNCHED;
}

typedef ScriptedStateFile = {
	var file:String;
	var mod:String;
}

class ScriptedStates {
	public static var activeScriptedState:String = null;
	public static var activeScriptedMod:String = null;

	public static function hasState(name:String, scope:ResolveScope = ANY):Bool
		return resolveScript(fullName(ScriptRegistry.STATE_PACKAGE, name), scope) != null;

	public static function hasSubstate(name:String, scope:ResolveScope = ANY):Bool
		return resolveScript(fullName(ScriptRegistry.SUBSTATE_PACKAGE, name), scope) != null;

	public static function loadState(name:String, ?args:Array<Dynamic>, scope:ResolveScope = ANY):MusicBeatState {
		return loadStateFromResolved(name, resolveScript(fullName(ScriptRegistry.STATE_PACKAGE, name), scope), args);
	}

	public static function loadStateFromMod(name:String, ?args:Array<Dynamic>, ?mod:String):MusicBeatState {
		return loadStateFromResolved(name, resolveInMod(fullName(ScriptRegistry.STATE_PACKAGE, name), mod), args);
	}

	public static function loadSubstate(name:String, ?args:Array<Dynamic>, scope:ResolveScope = ANY):MusicBeatSubstate {
		var resolved:ScriptedStateFile = resolveScript(fullName(ScriptRegistry.SUBSTATE_PACKAGE, name), scope);
		if (resolved == null)
			return null;

		var inst:Dynamic = ScriptRegistry.instantiateResolved(fullName(ScriptRegistry.SUBSTATE_PACKAGE, name), resolved.file, resolved.mod, args);
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
		ScriptRegistry.disposeMod(folder);

		var state:MusicBeatState = loadState(entry, [], LAUNCHED);
		if (state == null) {
			Mods.launchedMod = previousLaunched;
			Mods.currentModDirectory = previousMod;
			Mods.pushGlobalMods();
			return false;
		}

		playMenuMusic(folder);
		MusicBeatState.switchState(state);
		return true;
		#else
		return false;
		#end
	}

	public static function exitToEngine():Void {
		states.PlayState.returnToScriptedState = null;
		activeScriptedState = null;
		activeScriptedMod = null;
		#if MODS_ALLOWED
		if (Mods.launchedMod != null && Mods.launchedMod.length > 0)
			ScriptRegistry.disposeMod(Mods.launchedMod);
		Mods.launchedMod = null;
		Mods.currentModDirectory = '';
		Mods.pushGlobalMods();
		#end
		MusicBeatState.switchState(new states.ModsMenuState());
	}

	static function loadStateFromResolved(name:String, resolved:ScriptedStateFile, ?args:Array<Dynamic>):MusicBeatState {
		if (resolved == null)
			return null;

		var full:String = fullName(ScriptRegistry.STATE_PACKAGE, name);
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

	static function resolveScript(full:String, scope:ResolveScope):ScriptedStateFile {
		return switch (scope) {
			case LAUNCHED:
				resolveInMod(full, Mods.launchedMod != null && Mods.launchedMod.length > 0 ? Mods.launchedMod : Mods.currentModDirectory);
			case ANY:
				var resolved = ScriptRegistry.resolveClassFile(full);
				resolved == null ? null : {file: resolved.file, mod: resolved.mod};
		}
	}

	static function resolveInMod(full:String, ?mod:String):ScriptedStateFile {
		if (mod != null && mod.length > 0) {
			for (relative in ScriptRegistry.classPaths(full)) {
				var file:String = Paths.mods(mod + '/' + relative);
				if (Paths.safeModPathExists(file))
					return {file: file, mod: mod};
			}
			return null;
		}

		for (relative in ScriptRegistry.classPaths(full)) {
			var shared:String = Paths.mods(relative);
			if (Paths.safeModPathExists(shared))
				return {file: shared, mod: ScriptRegistry.SHARED_WORLD};

			var base:String = 'base_game/' + relative;
			if (Paths.safeModPathExists(base))
				return {file: base, mod: ScriptRegistry.BASE_GAME_MOD};
		}
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
			MusicBeatState.switchState(new states.MainMenuState());
	}
}
#end
