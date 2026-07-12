package backend;

import debug.TraceDisplay;
import flixel.FlxState;
import objects.GlobalLoadingOverlay;

#if LUA_ALLOWED
import psychlua.FunkinLua;
#end

#if HSCRIPT_ALLOWED
import psychlua.HScript;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
import crowplexus.iris.Iris;
#end

import psychlua.LuaUtils;

#if sys
import sys.FileSystem;
#end

// Script layer on top of BaseMusicBeatState.
// Adds GlobalScript, per-state HScript/Lua infrastructure and beat callbacks.
//
// Hierarchy:
//   BaseMusicBeatState (camera, beat, mobile, stages)
//   └── MusicBeatState  (this file — + script hooks)
//       ├── TitleState / PlayState / etc.
//       └── CustomState

class MusicBeatState extends BaseMusicBeatState
{
	public static inline var Function_Continue:Int = 0;
	public static inline var Function_Stop:Int = 1;

	public static inline function stateScriptOverridesEnabled():Bool
		return ClientPrefs.data.useScriptableCustomStates;

	// Global scripts system
	#if LUA_ALLOWED
	public static var globalLuaScript:FunkinLua = null;
	#end
	
	#if HSCRIPT_ALLOWED
	public static var globalScript:HScript = null;
	public static var publicVariables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static var staticVariables:Map<String, Dynamic> = new Map<String, Dynamic>();
	#end
	
	// Global variables storage that persists across all states
	public static var globalVariables:Map<String, Dynamic> = new Map<String, Dynamic>();
	
	// State scripting system
	public var stateScripts:Array<Dynamic> = [];
	public var scriptsAllowed:Bool = true;
	public var scriptName:String = null;

	// Companion script — loaded automatically alongside any hardcoded state.
	// Path: scripts/states/{ClassName}.hx (or .lua), searched in mod → global mods → assets/shared.
	// Lifecycle hooks:
	//   onCreate / onCreatePost
	//   onUpdate / onUpdatePost
	//   onStepHit / onStepHitPost
	//   onBeatHit / onBeatHitPost
	//   onSectionHit / onSectionHitPost
	//   onDestroy / onDestroyPost
	// Legacy names are preserved for compatibility.
	#if HSCRIPT_ALLOWED
	public var companionScript:HScript = null;
	#end
	#if LUA_ALLOWED
	public var companionLuaScript:FunkinLua = null;
	#end

	// Optional constructor used by CustomState to pass script configuration
	public function new(?scriptsAllowed:Bool = false, ?scriptName:String = null)
	{
		super();
		this.scriptsAllowed = scriptsAllowed;
		this.scriptName = scriptName;
	}

	override function create() {
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end

		if(!_psychCameraInitialized) initPsychCamera();
		
		// Initialize TraceDisplay if it doesn't exist
		if(traceDisplay == null && TraceDisplay.instance == null) {
			traceDisplay = new TraceDisplay();
			if(FlxG.stage != null) {
				FlxG.stage.addChild(traceDisplay);
			}
		} else if (TraceDisplay.instance != null) {
			// Reuse existing instance
			traceDisplay = TraceDisplay.instance;
		}

		super.create();

		if(!skip) {
			// Call scripts before fade in - if they return Function_Stop, they handle their own transition
			var globalResult = callOnGlobalScript('onFadeIn');
			
			// Only use default transition if scripts didn't stop it
			if(globalResult != LuaUtils.Function_Stop) {
				openSubState(new CustomFadeTransition(0.7, true));
			}
		}
		FlxTransitionableState.skipNextTransOut = false;
		timePassedOnState = 0;

		// Auto-load companion script for this specific state class.
		// Skipped for ScriptableState/CustomState (they handle their own scripts),
		// and when running inside them as sub-instances.
		#if (HSCRIPT_ALLOWED && sys)
		var isScriptDriven:Bool = (this is backend.ScriptableState) || (this is psychlua.CustomState);
		if (!isScriptDriven && stateScriptOverridesEnabled())
			_loadCompanionScript();
		#end
	}

	public static var traceDisplay:TraceDisplay;
	public static var timePassedOnState:Float = 0;
	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;
		timePassedOnState += elapsed;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = backend.WindowMode.borderlessFullscreen;
		
		// Screenshot support with F5
		#if desktop
		if (FlxG.keys.justPressed.F5)
		{
			backend.Screenshot.capture();
		}
		#end
		
		// Call global script update
		callOnGlobalScript('onUpdate', [elapsed]);
		
		stagesFunc(function(stage:BaseStage) {
			stage.update(elapsed);
		});

		super.update(elapsed);
	}

	public static function switchState(nextState:FlxState = null) {
		if(nextState == null) nextState = FlxG.state;
		if(nextState == FlxG.state)
		{
			resetState();
			return;
		}

		// State replacement is opt-in only (explicit tryCreate usage).
		// By default, hardcoded states run with companion scripts from scripts/states/*.

		// Call scripts before switching - they can stop the default transition
		var globalResult = callOnGlobalScript('onSwitchState', [Type.getClassName(Type.getClass(nextState))]);
		
		// If scripts stopped the transition, they handle it themselves
		if(globalResult == LuaUtils.Function_Stop) {
			// Script is handling the transition, just switch without custom transition
			FlxG.switchState(nextState);
			return;
		}
		
		if(FlxTransitionableState.skipNextTransIn) FlxG.switchState(nextState);
		else startTransition(nextState);
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function resetState() {
		// Call scripts before resetting - they can stop the default transition
		var globalResult = callOnGlobalScript('onResetState');
		
		// If scripts stopped the transition, they handle it themselves
		if(globalResult == LuaUtils.Function_Stop) {
			// Script is handling the transition, just reset without custom transition
			FlxG.switchState(_makeCurrentStateReset());
			return;
		}
		
		if(FlxTransitionableState.skipNextTransIn) FlxG.switchState(_makeCurrentStateReset());
		else startTransition();
		FlxTransitionableState.skipNextTransIn = false;
	}

	/**
	 * Returns a lambda that creates a fresh instance of the current state.
	 * Handles ScriptableState properly (FlxG.resetState breaks it because
	 * ScriptableState requires a constructor argument).
	 */
	static function _makeCurrentStateReset():()->flixel.FlxState {
		#if (HSCRIPT_ALLOWED && sys)
		var cs = FlxG.state;
		if (cs is backend.ScriptableState) {
			var name:String = (cast cs : backend.ScriptableState).stateName;
			return () -> new backend.ScriptableState(name);
		}
		#end
		var cls = Type.getClass(FlxG.state);
		return () -> Type.createInstance(cls, []);
	}

	// Custom made Trans in
	public static function startTransition(nextState:FlxState = null)
	{
		if(nextState == null)
			nextState = FlxG.state;
		GlobalLoadingOverlay.showPersistent();

		// Call scripts when transition starts - if they return Function_Stop, they handle their own transition
		var isReset:Bool = (nextState == FlxG.state);
		var globalResult = callOnGlobalScript('onStartTransition', [isReset, Type.getClassName(Type.getClass(nextState))]);
		
		// If scripts stopped it, they're handling the transition themselves
		if(globalResult == LuaUtils.Function_Stop) {
			if(isReset)
				FlxG.switchState(_makeCurrentStateReset());
			else
				FlxG.switchState(nextState);
			return;
		}
		
		FlxG.state.openSubState(new CustomFadeTransition(0.7, false));
		if(nextState == FlxG.state) {
			var resetFn = _makeCurrentStateReset();
			CustomFadeTransition.finishCallback = function() FlxG.switchState(resetFn);
		} else {
			CustomFadeTransition.finishCallback = function() FlxG.switchState(nextState);
		}
	}

	public static function getState():MusicBeatState {
		return cast(FlxG.state, MusicBeatState);
	}

	// Bridge static methods — Haxe does not inherit static fields,
	// so these delegate to the definitions in BaseMusicBeatState.
	public static function getVariables():Map<String, Dynamic>
		return BaseMusicBeatState.getVariables();

	public static function getVideoHandlers():Map<String, Dynamic>
		return BaseMusicBeatState.getVideoHandlers();

	override public function stepHit():Void
	{
		callOnGlobalScript('onStepHit', [curStep]);
		super.stepHit();
	}

	override public function beatHit():Void
	{
		callOnGlobalScript('onBeatHit', [curBeat]);
		super.beatHit();
	}

	override public function sectionHit():Void
	{
		callOnGlobalScript('onSectionHit', [curSection]);
		super.sectionHit();
	}

	override function destroy():Void
	{
		super.destroy();

		#if HSCRIPT_ALLOWED
		if (companionScript != null)
		{
			companionScript.destroy();
			companionScript = null;
		}
		#end
		#if LUA_ALLOWED
		if (companionLuaScript != null)
		{
			companionLuaScript.stop();
			companionLuaScript = null;
		}
		#end
	}

	// ─── Companion script helpers ──────────────────────────────────────────────

	#if (HSCRIPT_ALLOWED && sys)
	/**
	 * Loads the companion script for the current state class.
	 * Search order: active mod → global mods → assets/shared.
	 * File: scripts/states/{ClassName}.hx (and .lua if LUA_ALLOWED).
	 */
	function _loadCompanionScript():Void
	{
		// Get simple class name from the fully-qualified one
		var fullName:String = Type.getClassName(Type.getClass(this));
		var parts = fullName.split('.');
		var clsName:String = parts[parts.length - 1];
		var rel:String = 'scripts/states/$clsName.hx';

		var path:String = null;

		#if MODS_ALLOWED
		// modFolders checks currentModDirectory then global mods in priority order
		var modded:String = Paths.modFolders(rel);
		if (FileSystem.exists(modded)) path = modded;
		#end

		if (path == null)
		{
			var shared:String = Paths.getSharedPath(rel);
			if (FileSystem.exists(shared)) path = shared;
		}

		#if LUA_ALLOWED
		// Also check for a Lua companion
		var luaRel:String = 'scripts/states/$clsName.lua';
		var luaPath:String = null;
		#if MODS_ALLOWED
		var moddedLua:String = Paths.modFolders(luaRel);
		if (FileSystem.exists(moddedLua)) luaPath = moddedLua;
		#end
		if (luaPath == null)
		{
			var sharedLua:String = Paths.getSharedPath(luaRel);
			if (FileSystem.exists(sharedLua)) luaPath = sharedLua;
		}
		if (luaPath != null)
		{
			try { companionLuaScript = new FunkinLua(luaPath); }
			catch(e:Dynamic) { trace('[CompanionScript] Lua error in $luaPath: $e'); }
		}
		#end

		if (path == null) return;

		try
		{
			companionScript = new HScript(null, path);
			injectReturnConstants(companionScript);

			// Expose useful variables — 'game' points to the actual hardcoded state
			companionScript.set('game',         this);
			companionScript.set('add',          this.add);
			companionScript.set('remove',       this.remove);
			companionScript.set('insert',       this.insert);
			companionScript.set('openSubState', this.openSubState);

			// Shared/static var helpers (same API as CustomState)
			companionScript.set('setSharedVar', function(n:String, v:Dynamic) {
				MusicBeatState.globalVariables.set(n, v);
				variables.set(n, v);
				return v;
			});
			companionScript.set('getSharedVar', function(n:String, ?def:Dynamic = null):Dynamic {
				if (MusicBeatState.globalVariables.exists(n)) return MusicBeatState.globalVariables.get(n);
				if (variables.exists(n)) return variables.get(n);
				return def;
			});
			companionScript.set('setStaticVar', function(n:String, v:Dynamic) {
				MusicBeatState.staticVariables.set(n, v); return v;
			});
			companionScript.set('getStaticVar', function(n:String, ?def:Dynamic = null):Dynamic
				return MusicBeatState.staticVariables.exists(n) ? MusicBeatState.staticVariables.get(n) : def);

			trace('[CompanionScript] Loaded for state "$clsName": $path');
		}
		catch(e:crowplexus.hscript.Expr.Error)
		{
			var msg = crowplexus.hscript.Printer.errorToString(e, false);
			trace('[CompanionScript] HScript error in $path:\n$msg');
			if (debug.TraceDisplay.instance != null)
				debug.TraceDisplay.addHScriptError(msg, path);
		}
		catch(e:Dynamic)
		{
			trace('[CompanionScript] Failed to load $path: $e');
		}
	}
	#end

	/**
	 * Calls a callback on the companion script(s).
	 * On HScript: tries `onXxx` then bare `xxx` (CustomState convention).
	 * On Lua: calls the function directly.
	 */
	public function callOnCompanionScript(funcName:String, args:Array<Dynamic> = null):Dynamic
	{
		if (args == null) args = [];
		var ret:Dynamic = LuaUtils.Function_Continue;
		if (!MusicBeatState.stateScriptOverridesEnabled()) return ret;

		#if LUA_ALLOWED
		if (companionLuaScript != null)
		{
			var v = companionLuaScript.call(funcName, args);
			if (v != null && v != LuaUtils.Function_Continue) ret = v;
		}
		#end

		#if HSCRIPT_ALLOWED
		if (companionScript != null)
		{
			try
			{
				// Try bare name first (onCreate), then try without 'on' prefix as fallback
				var fn:String = companionScript.exists(funcName) ? funcName : null;
				if (fn == null && funcName.startsWith('on'))
				{
					var bare = funcName.charAt(2).toLowerCase() + funcName.substr(3);
					if (companionScript.exists(bare)) fn = bare;
				}
				if (fn != null)
				{
					var callValue = companionScript.call(fn, args);
					if (callValue != null && callValue.returnValue != null && callValue.returnValue != LuaUtils.Function_Continue)
						ret = callValue.returnValue;
				}
			}
			catch(e:Dynamic)
			{
				trace('[CompanionScript] Error calling $funcName: $e');
				@:privateAccess
				var fileName = companionScript.origin != null ? companionScript.origin : "CompanionScript";
				debug.TraceDisplay.addHScriptError('Runtime error in $funcName: $e', fileName);
			}
		}
		#end

		return ret;
	}

	// Global Script Management
	public static function clearAllSharedVars():Void
	{
		globalVariables.clear();
		trace('MusicBeatState: All shared vars cleared globally');
	}
	
	public static function clearModSharedVars(modName:String):Void
	{
		var keysToRemove:Array<String> = [];
		for(key in globalVariables.keys())
		{
			if(key.startsWith('${modName}_'))
				keysToRemove.push(key);
		}
		
		for(key in keysToRemove)
		{
			globalVariables.remove(key);
			trace('MusicBeatState: Removed shared var: $key');
		}
	}
	
	public static function initGlobalScript():Void
	{
		#if MODS_ALLOWED
		Mods.loadTopMod();
		#end
		
		// Try to load Lua GlobalScript first
		#if (LUA_ALLOWED && sys)
		if(globalLuaScript == null)
		{
			#if MODS_ALLOWED
			var luaPath:String = Paths.modFolders('scripts/GlobalScript.lua');
			if(!FileSystem.exists(luaPath))
				luaPath = Paths.getSharedPath('scripts/GlobalScript.lua');
			#else
			var luaPath:String = Paths.getSharedPath('scripts/GlobalScript.lua');
			#end
			
			if(FileSystem.exists(luaPath))
			{
				trace('Loading Global Lua Script from: $luaPath');
				globalLuaScript = new FunkinLua(luaPath);
				trace('GlobalScript (Lua) initialized successfully');
			}
		}
		#end
		
		// Then load HScript GlobalScript
		if(globalScript != null) return; // Already initialized
		
		#if MODS_ALLOWED
		var scriptPath:String = Paths.modFolders('scripts/GlobalScript.hx');
		if(scriptPath == null || !FileSystem.exists(scriptPath))
			scriptPath = Paths.getSharedPath('scripts/GlobalScript.hx');
		#else
		var scriptPath:String = Paths.getSharedPath('scripts/GlobalScript.hx');
		#end
		
		if(scriptPath == null) {
			trace('GlobalScript: scriptPath is null, Paths may not be initialized yet');
			return;
		}
		
		if(FileSystem.exists(scriptPath))
		{
			try
			{
				trace('GlobalScript: Loading script from: $scriptPath');
				
				// Create the script in manual mode so we can inject globals before parsing
				// This avoids parse-time errors like "Unknown variable" inside functions.
				globalScript = new HScript(null, scriptPath, null, true);
				
				if(globalScript == null) {
					trace('GlobalScript: Failed to create HScript instance');
					return;
				}
				
				trace('GlobalScript: HScript created successfully');
				
				// Initialize Maps if null (safety check)
				if(globalVariables == null) {
					trace('GlobalScript: WARNING - globalVariables was null, initializing...');
					globalVariables = new Map<String, Dynamic>();
				}
				#if HSCRIPT_ALLOWED
				if(staticVariables == null) {
					trace('GlobalScript: WARNING - staticVariables was null, initializing...');
					staticVariables = new Map<String, Dynamic>();
				}
				if(publicVariables == null) {
					trace('GlobalScript: WARNING - publicVariables was null, initializing...');
					publicVariables = new Map<String, Dynamic>();
				}
				#end
				
				trace('GlobalScript: Setting up global functions...');
				
				// Global variables functions
				try {
					globalScript.set('setGlobalVar', function(name:String, value:Dynamic) {
						if(globalVariables != null) {
							globalVariables.set(name, value);
							trace('GlobalScript: Global var set - $name = $value');
						}
						return value;
					});
				} catch(e:Dynamic) {
					trace('GlobalScript: Error setting setGlobalVar: $e');
				}
				
				try {
					globalScript.set('getGlobalVar', function(name:String, ?defaultValue:Dynamic = null):Dynamic {
						if (globalVariables != null && globalVariables.exists(name)) {
							return globalVariables.get(name);
						}
						return defaultValue;
					});
				} catch(e:Dynamic) {
					trace('GlobalScript: Error setting getGlobalVar: $e');
				}
				
				try {
					globalScript.set('hasGlobalVar', function(name:String):Bool {
						return globalVariables != null && globalVariables.exists(name);
					});
				} catch(e:Dynamic) {
					trace('GlobalScript: Error setting hasGlobalVar: $e');
				}
				
				try {
					globalScript.set('removeGlobalVar', function(name:String):Bool {
						if (globalVariables != null && globalVariables.exists(name)) {
							globalVariables.remove(name);
							return true;
						}
						return false;
					});
				} catch(e:Dynamic) {
					trace('GlobalScript: Error setting removeGlobalVar: $e');
				}
				
				// Static variables access
				#if HSCRIPT_ALLOWED
				try {
					globalScript.set('setStaticVar', function(name:String, value:Dynamic) {
						if(staticVariables != null) {
							staticVariables.set(name, value);
						}
						return value;
					});
				} catch(e:Dynamic) {
					trace('GlobalScript: Error setting setStaticVar: $e');
				}
				
				try {
					globalScript.set('getStaticVar', function(name:String, ?defaultValue:Dynamic = null):Dynamic {
						return (staticVariables != null && staticVariables.exists(name)) ? staticVariables.get(name) : defaultValue;
					});
				} catch(e:Dynamic) {
					trace('GlobalScript: Error setting getStaticVar: $e');
				}
				
				// Public variables access
				try {
					globalScript.set('setPublicVar', function(name:String, value:Dynamic) {
						if(publicVariables != null) {
							publicVariables.set(name, value);
						}
						return value;
					});
				} catch(e:Dynamic) {
					trace('GlobalScript: Error setting setPublicVar: $e');
				}
				
				try {
					globalScript.set('getPublicVar', function(name:String, ?defaultValue:Dynamic = null):Dynamic {
						return (publicVariables != null && publicVariables.exists(name)) ? publicVariables.get(name) : defaultValue;
					});
				} catch(e:Dynamic) {
					trace('GlobalScript: Error setting getPublicVar: $e');
				}
				
				trace('GlobalScript: Functions configured successfully');
				
				// Now parse and execute the script with the injected globals available
				globalScript.parse(true);
				globalScript.execute();
				trace('GlobalScript: Script parsed and executed successfully');
				
				// Call onCreate if it exists (like PlayState and CustomState do)
				try {
					if (globalScript.exists('onCreate')) {
						globalScript.call('onCreate');
						trace('GlobalScript: onCreate() called successfully');
					} else {
						trace('GlobalScript: No onCreate() function found');
					}
				} catch(e:Dynamic) {
					trace('GlobalScript: Error calling onCreate: $e');
				}
				
				trace('GlobalScript initialized successfully from: $scriptPath');
			}
			catch(e:IrisError)
			{
				trace('GlobalScript IrisError caught');
				try {
					var errorMsg = Printer.errorToString(e, false);
					trace('GlobalScript Error: $errorMsg');
					if(TraceDisplay.instance != null)
						TraceDisplay.addHScriptError(errorMsg, scriptPath);
				} catch(printerError:Dynamic) {
					trace('GlobalScript: Error while processing IrisError: $printerError');
					trace('GlobalScript: Original error object: $e');
				}
			}
			catch(e:Dynamic)
			{
				trace('GlobalScript Error (unexpected): $e');
				trace('GlobalScript Error Type: ${Type.typeof(e)}');
				#if HSCRIPT_ALLOWED
				try {
					if(TraceDisplay.instance != null)
						TraceDisplay.addHScriptError('Unexpected error: $e', scriptPath);
				} catch(displayError:Dynamic) {
					trace('GlobalScript: Could not add error to TraceDisplay: $displayError');
				}
				#end
			}
		}
		else
		{
			trace('No GlobalScript found at: $scriptPath');
		}
		#end
	}
	
	public static function callOnGlobalScript(funcToCall:String, args:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		
		// Call on global Lua script first
		#if LUA_ALLOWED
		if(globalLuaScript != null)
		{
			var ret:Dynamic = globalLuaScript.call(funcToCall, args != null ? args : []);
			if(ret != null && ret != LuaUtils.Function_Continue)
				returnVal = ret;
		}
		#end
		
		// Then call on global HScript
		#if HSCRIPT_ALLOWED
		if(globalScript != null && globalScript.exists(funcToCall))
		{
			try {
				var callValue = globalScript.call(funcToCall, args);
				if(callValue != null && callValue.returnValue != null)
				{
					var myValue:Dynamic = callValue.returnValue;
					if(myValue != LuaUtils.Function_Continue)
						returnVal = myValue;
				}
			}
			catch(e:Dynamic) {
				trace('GlobalScript Error calling $funcToCall: $e');
				@:privateAccess
				var fileName = globalScript.origin != null ? globalScript.origin : "GlobalScript";
				TraceDisplay.addHScriptError('Runtime error in $funcToCall: $e', fileName);
			}
		}
		#end
		
		return returnVal;
	}

	#if HSCRIPT_ALLOWED
	private function injectReturnConstants(script:HScript):Void
	{
		if (script == null) return;

		script.set('Function_Continue', LuaUtils.Function_Continue);
		script.set('Function_Stop', LuaUtils.Function_Stop);
	}
	#end
}