package options;

#if MODS_ALLOWED
import backend.ModSecurity;

/**
 * Per-check toggles for the mod-security scanner. One BOOL row per pattern
 * (`saveFile`, `Sys.command`, etc.). Toggles are stored in
 * `ClientPrefs.data.modSecurityChecks` and read on every scan via
 * `ModSecurity.isCheckEnabled`. On close, all enabled mods are re-scanned so
 * the change takes effect immediately (mods whose only finding came from a
 * now-disabled check get auto-trusted; no extra prompt unless new risks remain).
 *
 * Note: the "ModSecurity (tamper)" pattern is intentionally not exposed --
 * disabling it would let a mod neutralize the security system by simply
 * referencing the class name.
 */
class ModSecurityChecksSubState extends BaseOptionsMenu {
	// option description so users understand what each check actually flags.
	static final DESCRIPTIONS:Map<String, String> = [
		"saveFile" => "Lua\nMay be used to write arbitrary\nfiles to disk via the engine's\nsaveFile callback.",
		"deleteFile" => "Lua\nCan be used to permanently\ndelete files from disk via the\nengine's deleteFile callback.",
		"os.execute" => "Lua\nExploitable to run arbitrary\nshell commands on the host system.",
		"os.remove" => "Lua\nCan be used to delete files\nfrom disk directly,\nbypassing engine abstractions.",
		"os.rename" => "Lua\nMay be used to rename or\nrelocate files anywhere on disk.",
		"os.exit" => "Lua\nCan be used to forcefully\nterminate the game process.",
		"io.popen" => "Lua\nExploitable to spawn external\nprocesses and capture their output.",
		"loadstring" => "Lua\nAllows execution of arbitrary\nLua code compiled from a\nstring at runtime.",
		"dofile" => "Lua\nCan be used to load and execute\narbitrary Lua files at runtime.",
		"loadfile" => "Lua\nMay be used to load arbitrary\nLua files as executable chunks.",
		"getTextFromFile" => "Lua\nCan be used to read the contents\nof arbitrary files via the\nengine callback.",
		"io.open" => "Lua\nExploitable to open any file\non disk for reading or writing.",
		"os.getenv" => "Lua\nMay be used to extract sensitive\nenvironment variables from\nthe host system.",
		"os.tmpname" => "Lua\nCan be used to generate and\nprobe temp-file paths on disk.",
		"os.setlocale" => "Lua\nMay be used to alter the\nprocess locale,\naffecting system-wide behaviour.",
		"Sys.command" => "Haxe\nExploitable to execute arbitrary\nshell commands on the host system.",
		"Sys.exit" => "Haxe\nCan be used to forcefully\nterminate the game process.",
		"sys.io.File" => "Haxe\nAllows reading and writing\narbitrary files on disk.",
		"sys.io.Process" => "Haxe\nExploitable to spawn and interact\nwith arbitrary external processes.",
		"sys.FileSystem" => "Haxe\nCan be used to list,\ninspect, create, or delete files and directories.",
		"cpp.Lib.load" => "Haxe\nExploitable to load arbitrary\nnative C++ libraries at runtime.",
		"openfl.Lib.application" => "Haxe\nMay be used to access and\nmanipulate the underlying\nOpenFL application object.",
		"Type.resolveClass" => "Haxe\nCan be used to look up and\nobtain references to arbitrary\nclasses at runtime.",
		"Type.createInstance" => "Haxe\nMay be used to instantiate\narbitrary classes from\nruntime references.",
		"Reflect.callMethod" => "Haxe\nExploitable to invoke arbitrary\nmethods via reflection,\nbypassing normal call paths.",
		"import sys" => "Haxe\nGrants access to the sys package,\nenabling file and process APIs.",
		"import cpp" => "Haxe\nGrants access to the cpp package,\nenabling native library interop.",
		"import Sys" => "Haxe\nGrants access to the top-level\nSys class and its\nsystem-level APIs.",
	];

	/** Set by any toggle's setter; `commit` persists + rescans when it's true. **/
	static var pendingChanged:Bool = false;

	public function new() {
		title = Language.getPhrase('mod_security_checks_menu', 'Mod Security Checks');
		rpcTitle = 'Mod Security Checks';
		for (o in buildOptions())
			addOption(o);
		super();
	}

	/**
	 * One BOOL toggle per user-toggleable security check, read/written straight through the
	 * `ModSecurity` per-check map. Shared by this substate and the embedded modal.
	 * @return the toggle options, in scanner order
	 */
	public static function buildOptions():Array<Option> {
		var opts:Array<Option> = [];
		final names = ModSecurity.getAllCheckNames();
		for (i in 0...names.length) {
			final name = names[i];
			if (name == "ModSecurity (tamper)")
				continue; // not user-toggleable
			final desc = DESCRIPTIONS.exists(name) ? DESCRIPTIONS.get(name) : 'Scan mod scripts for usage of "$name".';
			final opt = new Option(name, desc, name, BOOL);
			opt.defaultValue = true;
			// Missing map entries default to enabled (matches ModSecurity.isCheckEnabled).
			opt.getValue = function():Dynamic return ModSecurity.isCheckEnabled(name);
			opt.setValue = function(v:Dynamic):Dynamic {
				ModSecurity.setCheckEnabled(name, v == true);
				pendingChanged = true;
				return v;
			};
			opts.push(opt);
		}
		return opts;
	}

	/** Persists the toggles and re-scans all enabled mods, if anything changed since the last commit. **/
	public static function commit():Void {
		if (!pendingChanged)
			return;
		ClientPrefs.saveSettings();
		ModSecurity.rescanAll();
		pendingChanged = false;
	}

	override function destroy():Void {
		commit();
		super.destroy();
	}
}
#end
