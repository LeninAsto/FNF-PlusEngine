package backend;

// ScriptableState — a MusicBeatState whose logic can be fully replaced by an HScript class.
//
// Inspired by the ScriptableState pattern in ALE-Psych:
//   https://github.com/ALE-Psych-Crew/ALE-Psych
//
// Design goals:
//   - Scripts live in  scripts/states/{StateName}.hx  (same path as CustomState).
//   - Load order: active mod → global mods → engine assets/shared → hardcoded fallback.
//   - Supports both the old callback style (function onCreate() {}) and the new class
//     style  (class TitleState extends MusicBeatState { override function create() {} }).
//   - Optional replacement via ScriptableState.tryCreate() for explicit engine calls.
//
// Usage from engine code:
//   MusicBeatState.switchState( ScriptableState.tryCreate('TitleState', new TitleState()) );
//
// Usage in a mod script (scripts/states/TitleState.hx):
//   class TitleState extends MusicBeatState {
//       var logo:FlxSprite;
//
//       override function create() {
//           logo = new FlxSprite(100, 100);
//           logo.loadGraphic(Paths.image('logoBumpin'));
//           add(logo);
//       }
//
//       override function update(elapsed:Float) {
//           super.update(elapsed);   // triggers beat/step counting in the host state
//       }
//   }
//
// NOTE: super.create() is called automatically by ScriptableState before your create().
//       Calling it again is safe — it becomes a no-op.
//       super.update(elapsed) IS forwarded to the host state, so call it to keep
//       beat/step tracking working.

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import backend.MusicBeatState;
import debug.TraceDisplay;
import backend.Mods;
import psychlua.LuaUtils;
import openfl.utils.Assets as OpenFlAssets;

#if HSCRIPT_ALLOWED
import psychlua.HScript;
import psychlua.ScriptedClass.ScriptClassHandler;
import psychlua.ScriptedClass.ScriptTemplateBase;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end

#if sys
import sys.FileSystem;
#end

class ScriptableState extends MusicBeatState
{
	static var _bypassNextOverrideFor:Map<String, Bool> = [];

	// Singleton reference — scripts can access the current ScriptableState via
	// `ScriptableState.instance` or through the `game` variable exposed in the script.
	public static var instance:ScriptableState;

	// Name used to find the script file (scripts/states/{stateName}.hx).
	public var stateName:String;
	var _fallbackState:flixel.FlxState;
	var _fallbackTriggered:Bool = false;

	#if HSCRIPT_ALLOWED
	var _script:HScript;
	var _scriptedObj:ScriptTemplateBase;
	// Guard: prevents super.create() from re-entering the init path if the
	// scripted class calls super.create() explicitly.
	var _baseCreateDone:Bool = false;
	// Guard: lets super.update() in a scripted method forward correctly.
	var _inScriptUpdate:Bool = false;
	#end

	public function new(name:String, ?fallbackState:flixel.FlxState)
	{
		super();
		stateName = name;
		_fallbackState = fallbackState;
	}

	// ─── Static helpers ────────────────────────────────────────────────────────

	/**
	 * Searches for a script for `name` in order:
	 *   1. Active mod directory  (mods/{currentMod}/scripts/states/{name}.hx)
	 *   2. Global mods           (mods/{globalMod}/scripts/states/{name}.hx)
	 *   3. Engine assets         (assets/shared/scripts/states/{name}.hx)
	 * Returns the absolute FS path if found, null otherwise.
	 */
	public static function findScript(name:String):Null<String>
	{
		var rel:String = 'scripts/states/$name.hx';

		#if sys
		#if MODS_ALLOWED
		// modFolders already applies currentModDirectory then globalMods priority
		var modded:String = Paths.modFolders(rel);
		if (FileSystem.exists(modded)) return modded;
		#end

		var shared:String = Paths.getSharedPath(rel);
		if (FileSystem.exists(shared)) return shared;
		#end

		// Fallback: scripts bundled inside the APK
		var assetPath:String = Paths.getSharedPath(rel);
		if (OpenFlAssets.exists(assetPath)) return assetPath;

		return null;
	}

	/** Returns true if a script for this name exists anywhere. **/
	public static function hasScript(name:String):Bool
		return findScript(name) != null;

	public static inline function overridesEnabled():Bool
		return ClientPrefs.data.useScriptableCustomStates;

	/**
	 * Returns a ScriptableState for `name` if a script exists, otherwise `fallback`.
	 * Use this when explicitly switching to a potentially-scriptable state.
	 *
	 *   MusicBeatState.switchState( ScriptableState.tryCreate('TitleState', new TitleState()) );
	 */
	public static function tryCreate(name:String, ?fallback:flixel.FlxState):flixel.FlxState
	{
		#if (HSCRIPT_ALLOWED && sys)
		if (!overridesEnabled()) return fallback;
		if (_consumeOverrideBypass(name)) return fallback;
		if (hasScript(name)) return new ScriptableState(name, fallback);
		#end
		return fallback;
	}

	/**
	 * Given any FlxState, checks whether a script override exists for its class name.
	 * Returns a ScriptableState if so, null otherwise.
	 * Legacy helper for explicit/opt-in replacement flows.
	 */
	public static function tryOverride(state:flixel.FlxState):Null<ScriptableState>
	{
		#if (HSCRIPT_ALLOWED && sys && MODS_ALLOWED)
		if (!overridesEnabled()) return null;
		if ((state is ScriptableState)) return null; // prevent infinite redirect
		var fullName:String = Type.getClassName(Type.getClass(state));
		// Extract the simple class name (TitleState from funkin.ui.title.TitleState)
		var parts = fullName.split('.');
		var simpleName:String = parts[parts.length - 1];
		// PlayState has its own rich scripting system — never intercept it here.
		if (simpleName == 'PlayState') return null;
		if (_consumeOverrideBypass(simpleName)) return null;
		if (hasScript(simpleName)) return new ScriptableState(simpleName, state);
		#end
		return null;
	}

	static function _consumeOverrideBypass(name:String):Bool
	{
		if (!_bypassNextOverrideFor.exists(name)) return false;
		_bypassNextOverrideFor.remove(name);
		return true;
	}

	// ─── Lifecycle ─────────────────────────────────────────────────────────────

	override function create():Void
	{
		instance = this;

		if (!_baseCreateDone)
		{
			_baseCreateDone = true;
			// Clear old-state graphics BEFORE super.create() opens the fade
			// transition so that transition assets get tracked and survive
			// clearUnusedMemory.  This mirrors the hardcoded state pattern:
			//   clearStoredMemory → super.create (loads FadeTransition) → clearUnusedMemory
			#if sys
			Paths.clearStoredMemory();
			#end
			super.create(); // MusicBeatState init — loads FadeTransition, adds to localTrackedAssets
			#if sys
			Paths.clearUnusedMemory(); // FadeTransition is safe: it's in localTrackedAssets
			#end
		}

		#if (HSCRIPT_ALLOWED && sys)
		var path:String = findScript(stateName);
		if (path == null)
		{
			if (_switchToFallback('script file not found')) return;
		}
		else if (!_loadScript(path))
		{
			if (_switchToFallback('script failed to load')) return;
		}
		else if (!_hasScriptEntry())
		{
			if (_switchToFallback('script has no create entry')) return;
		}
		#end

		_callOnScript('create', []);
		_syncScriptFields();
	}

	override function update(elapsed:Float):Void
	{
		if (_inScriptUpdate)
		{
			// The scripted method called super.update() — forward to MusicBeatState
			// so beat/step tracking fires, mark as handled, then bail out.
			super.update(elapsed);
			_inScriptUpdate = false;
			return;
		}

		_inScriptUpdate = true;
		_callOnScript('update', [elapsed]);
		// If the script did NOT call super.update() (flag still true), call it
		// now so beats/steps always fire regardless of script implementation.
		if (_inScriptUpdate)
			super.update(elapsed);
		_inScriptUpdate = false;
	}

	override function destroy():Void
	{
		_callOnScript('destroy', []);

		#if HSCRIPT_ALLOWED
		if (_script != null)
		{
			_script.destroy();
			_script = null;
		}
		_scriptedObj = null;
		#end

		super.destroy();
		instance = null;
	}

	override function beatHit():Void
	{
		_callOnScript('beatHit', [curBeat]);
		super.beatHit();
	}

	override function stepHit():Void
	{
		_callOnScript('stepHit', [curStep]);
		super.stepHit();
	}

	override function sectionHit():Void
	{
		_callOnScript('sectionHit', [curSection]);
		super.sectionHit();
	}

	override function openSubState(subState:FlxSubState):Void
	{
		#if HSCRIPT_ALLOWED
		// WARNING: never call _callOnScript('openSubState', ...) here.
		// 'openSubState' is injected into the script scope as a reference to
		// this.openSubState, so _callOnScript would find it, call it, re-enter
		// this method and recurse infinitely — crashing the process with no trace.
		// Scripts should use  function onOpenSubState(className) {}  instead.
		try
		{
			if (_scriptedObj != null)
			{
				// Class-style script: call the override on the scripted object (safe).
				if (_scriptedObj.hasMethod('openSubState'))
					_scriptedObj.callMethod('openSubState', [Type.getClassName(Type.getClass(subState))]);
			}
			else if (_script != null)
			{
				// Callback style: look only for 'onOpenSubState', never the bare name.
				if (_script.exists('onOpenSubState'))
					_script.call('onOpenSubState', [Type.getClassName(Type.getClass(subState))]);
			}
		}
		catch (e:Dynamic)
		{
			trace('[ScriptableState:$stateName] Error in onOpenSubState(): $e');
		}
		#end

		// Sync any script-side field changes (e.g. persistentUpdate = false) before
		// opening the substate, so Flixel sees the correct value on the very next frame.
		_syncScriptFields();
		super.openSubState(subState);
	}

	override function closeSubState():Void
	{
		_callOnScript('closeSubState', []);
		_syncScriptFields();
		super.closeSubState();
	}

	override function onFocus():Void
	{
		_callOnScript('onFocus', []);
		super.onFocus();
	}

	override function onFocusLost():Void
	{
		_callOnScript('onFocusLost', []);
		super.onFocusLost();
	}

	// ─── Script loading ────────────────────────────────────────────────────────

	#if HSCRIPT_ALLOWED
	function _loadScript(path:String):Bool
	{
		try
		{
			_script = new HScript(null, path);

			// Core variables exposed to the script
			_script.set('game',          this);
			_script.set('add',           this.add);
			_script.set('remove',        this.remove);
			_script.set('insert',        this.insert);
			_script.set('openSubState',  this.openSubState);
			_script.set('stateName',     stateName);
			_script.set('scriptableState', this);
			_script.set('controls',      backend.Controls.instance);

			// Load the shared state preset (defines boilerplate helpers
			// so individual state scripts don't have to repeat them).
			// Search order: active mod → global mods → engine assets.
			var presetPath:Null<String> = _findPreset();
			if (presetPath != null)
				_script.executeFile(presetPath);

			// Expose persistentUpdate/persistentDraw as script-writable variables.
			// After each lifecycle call _syncScriptFields() reads them back.
			_script.set('persistentUpdate', this.persistentUpdate);
			_script.set('persistentDraw',   this.persistentDraw);

			// Shared variable helpers (same API as CustomState)
			_script.set('setSharedVar', function(n:String, v:Dynamic) {
				MusicBeatState.globalVariables.set(n, v);
				variables.set(n, v);
				return v;
			});
			_script.set('getSharedVar', function(n:String, ?def:Dynamic = null):Dynamic {
				if (MusicBeatState.globalVariables.exists(n)) return MusicBeatState.globalVariables.get(n);
				if (variables.exists(n)) return variables.get(n);
				return def;
			});
			_script.set('hasSharedVar',    function(n:String):Bool
				return MusicBeatState.globalVariables.exists(n) || variables.exists(n));
			_script.set('removeSharedVar', function(n:String):Bool {
				var r = false;
				if (MusicBeatState.globalVariables.remove(n)) r = true;
				if (variables.remove(n)) r = true;
				return r;
			});

			// Public variables (shared between scripts within the same state)
			_script.set('setPublicVar', function(n:String, v:Dynamic) { MusicBeatState.publicVariables.set(n, v); return v; });
			_script.set('getPublicVar', function(n:String, ?def:Dynamic = null):Dynamic
				return MusicBeatState.publicVariables.exists(n) ? MusicBeatState.publicVariables.get(n) : def);

			// Static variables (persist across all state switches)
			_script.set('setStaticVar', function(n:String, v:Dynamic) { MusicBeatState.staticVariables.set(n, v); return v; });
			_script.set('getStaticVar', function(n:String, ?def:Dynamic = null):Dynamic
				return MusicBeatState.staticVariables.exists(n) ? MusicBeatState.staticVariables.get(n) : def);

			// State-local variables
			_script.set('setStateVar', function(n:String, v:Dynamic) { variables.set(n, v); return v; });
			_script.set('getStateVar', function(n:String, ?def:Dynamic = null):Dynamic
				return variables.exists(n) ? variables.get(n) : def);

			// Mobile helpers
			_script.set('addTouchPad',         function(d:String, a:String) addTouchPad(d, a));
			_script.set('removeTouchPad',       function() removeTouchPad());
			_script.set('addTouchPadCamera',    function(?t:Bool = false) addTouchPadCamera(t));
			_script.set('addMobileControls',    function(?t:Bool = false) addMobileControls(t));
			_script.set('removeMobileControls', function() removeMobileControls());

			// Try to find a class definition named after the state
			var classDef:ScriptClassHandler = _script.getScriptedClass(stateName);
			if (classDef != null)
			{
				// Instantiate the scripted class.
				// __superInstance will be a freshly-created Haxe MusicBeatState
				// (not this ScriptableState) — that is OK.  The ScriptableState
				// already ran super.create() before we get here.
				var instance:Dynamic = classDef.hnew([]);
				if ((instance is ScriptTemplateBase))
				{
					_scriptedObj = cast instance;

					// Inject the most useful variables directly into the class
					// interpreter so the script can use them without `game.xxx`.
					if (_scriptedObj.__interp != null)
					{
						_scriptedObj.__interp.variables.set('game',          this);
						_scriptedObj.__interp.variables.set('add',           this.add);
						_scriptedObj.__interp.variables.set('remove',        this.remove);
						_scriptedObj.__interp.variables.set('insert',        this.insert);
						_scriptedObj.__interp.variables.set('stateName',     stateName);
						_scriptedObj.__interp.variables.set('openSubState',  this.openSubState);
						_scriptedObj.__interp.variables.set('scriptableState', this);
					}
				}
			}

			return true;
		}
		catch (e:IrisError)
		{
			var msg:String = Printer.errorToString(e, false);
			trace('[ScriptableState] HScript error in $path:\n$msg');
			if (TraceDisplay.instance != null)
				TraceDisplay.addHScriptError(msg, path);
		}
		catch (e:Dynamic)
		{
			trace('[ScriptableState] Failed to load $path: $e');
		}

		return false;
	}

	function _hasScriptEntry():Bool
	{
		if (_scriptedObj != null) return _scriptedObj.hasMethod('create');
		if (_script == null) return false;

		return _script.exists('onCreate')
			|| _script.exists('create');
	}

	function _switchToFallback(reason:String):Bool
	{
		if (_fallbackTriggered || _fallbackState == null) return false;

		_fallbackTriggered = true;
		_bypassNextOverrideFor.set(stateName, true);
		trace('[ScriptableState:$stateName] Falling back to hardcoded state: ' + reason);
		MusicBeatState.switchState(_fallbackState);
		return true;
	}
	#end

	// ─── Dispatch helper ───────────────────────────────────────────────────────

	/**
	 * Calls a lifecycle method on the scripted object or, if none exists, a
	 * top-level callback function (`onXxx` first, then bare `xxx`) for backwards
	 * compatibility with the CustomState callback style.
	 * Errors thrown inside the script are caught and logged so a faulty script
	 * does not bring down the whole game.
	 */
	function _callOnScript(method:String, args:Array<Dynamic>):Void
	{
		#if HSCRIPT_ALLOWED
		if (args == null) args = [];

		try
		{
			if (_scriptedObj != null)
			{
				// Class-based: delegate to the override method
				if (_scriptedObj.hasMethod(method))
					_scriptedObj.callMethod(method, args);
			}
			else if (_script != null)
			{
				// Callback style: try onXxx first (CustomState convention), then bare name
				var cbName:String = 'on' + method.charAt(0).toUpperCase() + method.substr(1);
				if (_script.exists(cbName))
					_script.call(cbName, args);
				else if (_script.exists(method))
					_script.call(method, args);
			}
		}
		catch (e:Dynamic)
		{
			trace('[ScriptableState:$stateName] Error in $method(): $e');
		}
		#end
	}

	#if HSCRIPT_ALLOWED
	/**
	 * Reads back persistentUpdate/persistentDraw from the script's variable scope
	 * and applies them to the real state fields.
	 * Called after lifecycle methods that typically set these fields.
	 */
	function _syncScriptFields():Void
	{
		if (_script == null) return;
		if (_script.exists('persistentUpdate'))
			this.persistentUpdate = _script.get('persistentUpdate');
		if (_script.exists('persistentDraw'))
			this.persistentDraw = _script.get('persistentDraw');
	}
	#end

	#if HSCRIPT_ALLOWED
	/**
	 * Finds the shared state preset file in the standard search order:
	 *   mods/{currentMod}/scripts/states/_statePreset.hx
	 *   mods/{globalMod}/scripts/states/_statePreset.hx
	 *   assets/shared/scripts/states/_statePreset.hx
	 */
	function _findPreset():Null<String>
	{
		var rel:String = 'scripts/states/_statePreset.hx';

		#if sys
		#if MODS_ALLOWED
		var modded:String = Paths.modFolders(rel);
		if (FileSystem.exists(modded)) return modded;
		#end

		var shared:String = Paths.getSharedPath(rel);
		if (FileSystem.exists(shared)) return shared;
		#end

		// Fallback: preset bundled inside the APK
		var assetPath:String = Paths.getSharedPath(rel);
		if (OpenFlAssets.exists(assetPath)) return assetPath;

		return null;
	}
	#end
}
