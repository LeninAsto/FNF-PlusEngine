package backend;

import debug.TraceDisplay;
import flixel.FlxState;
import objects.GlobalLoadingOverlay;
import backend.ui.md3.NetworkCheckToast;
#if HSCRIPT_ALLOWED
import psychlua.backend.HScript;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
import crowplexus.iris.Iris;
#end
import psychlua.backend.LuaUtils;
#if sys
import sys.FileSystem;
#end

// Script layer on top of BaseMusicBeatState.
// Adds beat callbacks and keeps state script hooks disabled while the layer is rebuilt.
//
// Hierarchy:
//   BaseMusicBeatState (camera, beat, mobile, stages)
//   └── MusicBeatState  (this file — + script hooks)
//       └── TitleState / PlayState / etc.
class MusicBeatState extends BaseMusicBeatState
{
	public static inline var Function_Continue:Int = 0;
	public static inline var Function_Stop:Int = 1;

	public static inline function stateScriptOverridesEnabled():Bool
		return false;

	public static inline function stateScriptHooksEnabled():Bool
		return false;

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
	public var scriptOwnerMod:String = null;
	public var isScriptedState:Bool = false;

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
	var stateScriptDebugPanel:psychlua.backend.DebugLuaText = null;

	// Optional constructor used by scripted hosts to pass script configuration.
	public function new(?scriptsAllowed:Bool = false, ?scriptName:String = null)
	{
		super();
		this.scriptsAllowed = scriptsAllowed;
		this.scriptName = scriptName;
	}

	override function create()
	{
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end

		if (!_psychCameraInitialized)
			initPsychCamera();

		// Initialize TraceDisplay if it doesn't exist
		if (traceDisplay == null && TraceDisplay.instance == null)
		{
			traceDisplay = new TraceDisplay();
			if (FlxG.stage != null)
			{
				FlxG.stage.addChild(traceDisplay);
			}
		}
		else if (TraceDisplay.instance != null)
		{
			// Reuse existing instance
			traceDisplay = TraceDisplay.instance;
		}

		super.create();

		if (!skip)
		{
			// Call scripts before fade in - if they return Function_Stop, they handle their own transition
			var globalResult = callOnGlobalScript('onFadeIn');

			// Only use default transition if scripts didn't stop it
			if (!LuaUtils.isStop(globalResult))
			{
				openSubState(TransitionManager.create(0.7, true));
			}
		}
		FlxTransitionableState.skipNextTransOut = false;
		timePassedOnState = 0;

		// Auto-load companion script for this specific state class.
		// Disabled while the state scripting layer is being rebuilt.
		#if (HSCRIPT_ALLOWED && sys)
		if (stateScriptOverridesEnabled())
			_loadCompanionScript();
		#end
	}

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	public static function addScriptTextToDebug(text:String, color:FlxColor):Bool
	{
		if (states.PlayState.instance != null)
		{
			states.PlayState.instance.addTextToDebug(text, color);
			return true;
		}

		if (FlxG.state != null && FlxG.state.subState != null && Std.isOfType(FlxG.state.subState, MusicBeatSubstate))
		{
			cast(FlxG.state.subState, MusicBeatSubstate).addSubstateScriptTextToDebug(text, color);
			return true;
		}

		if (FlxG.state != null && Std.isOfType(FlxG.state, MusicBeatState))
		{
			cast(FlxG.state, MusicBeatState).addStateScriptTextToDebug(text, color);
			return true;
		}

		return false;
	}

	public function addStateScriptTextToDebug(text:String, color:FlxColor):Void
	{
		if (states.PlayState.instance == this)
		{
			states.PlayState.instance.addTextToDebug(text, color);
			return;
		}

		if (stateScriptDebugPanel == null)
		{
			stateScriptDebugPanel = new psychlua.backend.DebugLuaText();
			add(stateScriptDebugPanel);
		}
		stateScriptDebugPanel.pushMessage(text, color);
	}
	#end

	public static var traceDisplay:TraceDisplay;
	public static var timePassedOnState:Float = 0;
	private static var _lastSavedFullscreen:Bool = false;
	private static var _hasSavedFullscreen:Bool = false;

	override function update(elapsed:Float)
	{
		#if (cpp && lime_openal)
		if (AudioDeviceMonitor.update(Std.int(elapsed * 1000)))
			onAudioDeviceReopened();
		#end
		NetworkCheckToast.updateRequests();

		// everyStep();
		var oldStep:Int = curStep;
		timePassedOnState += elapsed;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if (curStep > 0)
				stepHit();

			if (PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		var fullscreen:Bool = backend.WindowMode.isFullscreen();
		if (FlxG.save.data != null && (!_hasSavedFullscreen || _lastSavedFullscreen != fullscreen))
		{
			FlxG.save.data.fullscreen = fullscreen;
			_lastSavedFullscreen = fullscreen;
			_hasSavedFullscreen = true;
		}

		// Screenshot support with F10 (F5 is used by Freeplay reload)
		#if desktop
		if (FlxG.keys.justPressed.F10)
		{
			backend.Screenshot.capture();
		}

		if (FlxG.keys.justPressed.F12 && !Std.isOfType(FlxG.state, states.ModsMenuState))
		{
			persistentUpdate = persistentDraw = true;
			#if HSCRIPT_ALLOWED
			scripting.ScriptedStates.exitToEngine();
			#else
			#if MODS_ALLOWED
			Mods.launchedMod = null;
			Mods.currentModDirectory = '';
			if (FlxG.save != null && FlxG.save.data != null)
			{
				FlxG.save.data.launchedMod = null;
				FlxG.save.flush();
			}
			Mods.pushGlobalMods();
			Mods.resetWindowBrand();
			backend.Language.reloadPhrases();
			#end
			MusicBeatState.switchState(new states.ModsMenuState());
			#end
			return;
		}
		#end

		// Call global script update
		callOnGlobalScript('onUpdate', [elapsed]);

		stagesFunc(function(stage:BaseStage)
		{
			stage.update(elapsed);
		});

		super.update(elapsed);
	}

	/** Restarts menu/state music after OpenAL changes its physical output. */
	function onAudioDeviceReopened():Void
	{
		var music = FlxG.sound.music;
		if (music == null || !music.playing) return;

		var time = music.time;
		music.pause();
		music.time = time;
		music.play();
	}

	public static function switchState(nextState:FlxState = null)
	{
		if (nextState == null)
			nextState = FlxG.state;
		if (nextState == FlxG.state)
		{
			resetState();
			return;
		}

		#if HSCRIPT_ALLOWED
		nextState = backend.ScriptableState.tryCreateFromFallback(nextState);
		#end
		#if MODS_ALLOWED
		preserveLaunchedModContext(nextState);
		#end

		// Call scripts before switching - they can stop the default transition
		var globalResult = callOnGlobalScript('onSwitchState', [Type.getClassName(Type.getClass(nextState))]);

		// If scripts stopped the transition, they handle it themselves
		if (LuaUtils.isStop(globalResult))
		{
			// Script is handling the transition, just switch without custom transition
			FlxG.switchState(nextState);
			return;
		}

		if (FlxTransitionableState.skipNextTransIn)
			FlxG.switchState(nextState);
		else
			startTransition(nextState);
		FlxTransitionableState.skipNextTransIn = false;
	}

	#if MODS_ALLOWED
	static function preserveLaunchedModContext(nextState:FlxState):Void
	{
		if (nextState == null || Mods.launchedMod == null || Mods.launchedMod.length < 1)
			return;

		#if HSCRIPT_ALLOWED
		if (Std.isOfType(nextState, MusicBeatState)) {
			var musicState:MusicBeatState = cast nextState;
			if (musicState.isScriptedState && musicState.scriptOwnerMod != null && musicState.scriptOwnerMod.length > 0) {
				Mods.currentModDirectory = musicState.scriptOwnerMod;
				Mods.pushGlobalMods();
				return;
			}
		}
		#end

		// Hardcoded states reached from a launched mod still belong to that
		// launched asset context. Otherwise Credits/Mods/etc. can clear the mod
		// folder and every Paths.image()/sound() lookup starts returning null.
		Mods.currentModDirectory = Mods.launchedMod;
		Mods.pushGlobalMods();
	}
	#end

	public static function resetState()
	{
		// Call scripts before resetting - they can stop the default transition
		var globalResult = callOnGlobalScript('onResetState');

		// If scripts stopped the transition, they handle it themselves
		if (LuaUtils.isStop(globalResult))
		{
			// Script is handling the transition, just reset without custom transition
			FlxG.switchState(_makeCurrentStateReset());
			return;
		}

		if (FlxTransitionableState.skipNextTransIn)
			FlxG.switchState(_makeCurrentStateReset());
		else
			startTransition();
		FlxTransitionableState.skipNextTransIn = false;
	}

	/**
	 * Returns a lambda that creates a fresh instance of the current state.
	 * Handles ScriptableState properly (FlxG.resetState breaks it because
	 * ScriptableState requires a constructor argument).
	 */
	static function _makeCurrentStateReset():() -> flixel.FlxState
	{
		#if (HSCRIPT_ALLOWED && sys)
		var cs = FlxG.state;
		if (cs is backend.MusicBeatState)
		{
			var scripted:backend.MusicBeatState = cast cs;
			if (scripted.isScriptedState && scripted.scriptName != null)
			{
				var name:String = scripted.scriptName;
				var owner:String = scripted.scriptOwnerMod;
				return () -> scripting.ScriptedStates.loadStateFromMod(name, [], owner);
			}
		}
		if (cs is backend.ScriptableState)
		{
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
		if (nextState == null)
			nextState = FlxG.state;
		GlobalLoadingOverlay.showPersistent();

		// Call scripts when transition starts - if they return Function_Stop, they handle their own transition
		var isReset:Bool = (nextState == FlxG.state);
		var globalResult = callOnGlobalScript('onStartTransition', [isReset, Type.getClassName(Type.getClass(nextState))]);

		// If scripts stopped it, they're handling the transition themselves
		if (LuaUtils.isStop(globalResult))
		{
			if (isReset)
				FlxG.switchState(_makeCurrentStateReset());
			else
				FlxG.switchState(nextState);
			return;
		}

		FlxG.state.openSubState(TransitionManager.create(0.7, false));
		if (nextState == FlxG.state)
		{
			var resetFn = _makeCurrentStateReset();
			TransitionManager.setFinishCallback(function() FlxG.switchState(resetFn));
		}
		else
		{
			TransitionManager.setFinishCallback(function() FlxG.switchState(nextState));
		}
	}

	public static function getState():MusicBeatState
	{
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

		if (stateScriptDebugPanel != null)
		{
			stateScriptDebugPanel.destroy();
			stateScriptDebugPanel = null;
		}

		#if HSCRIPT_ALLOWED
		if (companionScript != null)
		{
			companionScript.destroy();
			companionScript = null;
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
		if (FileSystem.exists(modded))
			path = modded;
		#end

		if (path == null)
		{
			var shared:String = Paths.getSharedPath(rel);
			if (FileSystem.exists(shared))
				path = shared;
		}

		if (path == null)
			return;

		try
		{
			companionScript = new HScript(null, path);
			injectReturnConstants(companionScript);

			// Expose useful variables — 'game' points to the actual hardcoded state
			companionScript.set('game', this);
			companionScript.set('add', this.add);
			companionScript.set('remove', this.remove);
			companionScript.set('insert', this.insert);
			companionScript.set('openSubState', this.openSubState);

			// Shared/static var helpers for state companion scripts.
			companionScript.set('setSharedVar', function(n:String, v:Dynamic)
			{
				MusicBeatState.globalVariables.set(n, v);
				variables.set(n, v);
				return v;
			});
			companionScript.set('getSharedVar', function(n:String, ?def:Dynamic = null):Dynamic
			{
				if (MusicBeatState.globalVariables.exists(n))
					return MusicBeatState.globalVariables.get(n);
				if (variables.exists(n))
					return variables.get(n);
				return def;
			});
			companionScript.set('setStaticVar', function(n:String, v:Dynamic)
			{
				MusicBeatState.staticVariables.set(n, v);
				return v;
			});
			companionScript.set('getStaticVar',
				function(n:String, ?def:Dynamic = null):Dynamic return MusicBeatState.staticVariables.exists(n) ? MusicBeatState.staticVariables.get(n) : def);

			trace('[CompanionScript] Loaded for state "$clsName": $path');
		}
		catch (e:crowplexus.hscript.Expr.Error)
		{
			var msg = crowplexus.hscript.Printer.errorToString(e, false);
			trace('[CompanionScript] HScript error in $path:\n$msg');
			addStateScriptTextToDebug('$path: $msg', FlxColor.RED);
		}
		catch (e:Dynamic)
		{
			trace('[CompanionScript] Failed to load $path: $e');
		}
	}
	#end

	/**
	 * Calls a callback on the companion script(s).
	 * On HScript: tries `onXxx` then bare `xxx` for legacy companion scripts.
	 * On Lua: calls the function directly.
	 */
	public function callOnCompanionScript(funcName:String, args:Array<Dynamic> = null):Dynamic
	{
		if (args == null)
			args = [];
		var ret:Dynamic = LuaUtils.Function_Continue;
		if (!MusicBeatState.stateScriptOverridesEnabled())
			return ret;

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
					if (companionScript.exists(bare))
						fn = bare;
				}
				if (fn != null)
				{
					var callValue = companionScript.call(fn, args);
					if (callValue != null && callValue.returnValue != null && callValue.returnValue != LuaUtils.Function_Continue)
						ret = callValue.returnValue;
				}
			}
			catch (e:Dynamic)
			{
				trace('[CompanionScript] Error calling $funcName: $e');
				@:privateAccess
				var fileName = companionScript.origin != null ? companionScript.origin : "CompanionScript";
				addStateScriptTextToDebug('$fileName: Runtime error in $funcName: $e', FlxColor.RED);
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
		for (key in globalVariables.keys())
		{
			if (key.startsWith('${modName}_'))
				keysToRemove.push(key);
		}

		for (key in keysToRemove)
		{
			globalVariables.remove(key);
			trace('MusicBeatState: Removed shared var: $key');
		}
	}

	public static function initGlobalScript():Void
	{
		if (!stateScriptHooksEnabled())
			return;

		#if HSCRIPT_ALLOWED
		#if MODS_ALLOWED
		Mods.loadTopMod();
		#end

		if (globalScript != null)
			return; // Already initialized

		#if MODS_ALLOWED
		var scriptPath:String = Paths.modFolders('scripts/GlobalScript.hx');
		if (scriptPath == null || !FileSystem.exists(scriptPath))
			scriptPath = Paths.getSharedPath('scripts/GlobalScript.hx');
		#else
		var scriptPath:String = Paths.getSharedPath('scripts/GlobalScript.hx');
		#end

		if (scriptPath == null)
		{
			trace('GlobalScript: scriptPath is null, Paths may not be initialized yet');
			return;
		}

		if (FileSystem.exists(scriptPath))
		{
			try
			{
				trace('GlobalScript: Loading script from: $scriptPath');

				// Create the script in manual mode so we can inject globals before parsing
				// This avoids parse-time errors like "Unknown variable" inside functions.
				globalScript = new HScript(null, scriptPath, null, true);

				if (globalScript == null)
				{
					trace('GlobalScript: Failed to create HScript instance');
					return;
				}

				trace('GlobalScript: HScript created successfully');

				// Initialize Maps if null (safety check)
				if (globalVariables == null)
				{
					trace('GlobalScript: WARNING - globalVariables was null, initializing...');
					globalVariables = new Map<String, Dynamic>();
				}
				#if HSCRIPT_ALLOWED
				if (staticVariables == null)
				{
					trace('GlobalScript: WARNING - staticVariables was null, initializing...');
					staticVariables = new Map<String, Dynamic>();
				}
				if (publicVariables == null)
				{
					trace('GlobalScript: WARNING - publicVariables was null, initializing...');
					publicVariables = new Map<String, Dynamic>();
				}
				#end

				trace('GlobalScript: Setting up global functions...');

				// Global variables functions
				try
				{
					globalScript.set('setGlobalVar', function(name:String, value:Dynamic)
					{
						if (globalVariables != null)
						{
							globalVariables.set(name, value);
							trace('GlobalScript: Global var set - $name = $value');
						}
						return value;
					});
				}
				catch (e:Dynamic)
				{
					trace('GlobalScript: Error setting setGlobalVar: $e');
				}

				try
				{
					globalScript.set('getGlobalVar', function(name:String, ?defaultValue:Dynamic = null):Dynamic
					{
						if (globalVariables != null && globalVariables.exists(name))
						{
							return globalVariables.get(name);
						}
						return defaultValue;
					});
				}
				catch (e:Dynamic)
				{
					trace('GlobalScript: Error setting getGlobalVar: $e');
				}

				try
				{
					globalScript.set('hasGlobalVar', function(name:String):Bool
					{
						return globalVariables != null && globalVariables.exists(name);
					});
				}
				catch (e:Dynamic)
				{
					trace('GlobalScript: Error setting hasGlobalVar: $e');
				}

				try
				{
					globalScript.set('removeGlobalVar', function(name:String):Bool
					{
						if (globalVariables != null && globalVariables.exists(name))
						{
							globalVariables.remove(name);
							return true;
						}
						return false;
					});
				}
				catch (e:Dynamic)
				{
					trace('GlobalScript: Error setting removeGlobalVar: $e');
				}

				// Static variables access
				#if HSCRIPT_ALLOWED
				try
				{
					globalScript.set('setStaticVar', function(name:String, value:Dynamic)
					{
						if (staticVariables != null)
						{
							staticVariables.set(name, value);
						}
						return value;
					});
				}
				catch (e:Dynamic)
				{
					trace('GlobalScript: Error setting setStaticVar: $e');
				}

				try
				{
					globalScript.set('getStaticVar', function(name:String, ?defaultValue:Dynamic = null):Dynamic
					{
						return (staticVariables != null && staticVariables.exists(name)) ? staticVariables.get(name) : defaultValue;
					});
				}
				catch (e:Dynamic)
				{
					trace('GlobalScript: Error setting getStaticVar: $e');
				}

				// Public variables access
				try
				{
					globalScript.set('setPublicVar', function(name:String, value:Dynamic)
					{
						if (publicVariables != null)
						{
							publicVariables.set(name, value);
						}
						return value;
					});
				}
				catch (e:Dynamic)
				{
					trace('GlobalScript: Error setting setPublicVar: $e');
				}

				try
				{
					globalScript.set('getPublicVar', function(name:String, ?defaultValue:Dynamic = null):Dynamic
					{
						return (publicVariables != null && publicVariables.exists(name)) ? publicVariables.get(name) : defaultValue;
					});
				}
				catch (e:Dynamic)
				{
					trace('GlobalScript: Error setting getPublicVar: $e');
				}
				#end

				trace('GlobalScript: Functions configured successfully');

				// Now parse and execute the script with the injected globals available
				globalScript.parse(true);
				globalScript.execute();
				trace('GlobalScript: Script parsed and executed successfully');

				// Call onCreate if it exists.
				try
				{
					if (globalScript.exists('onCreate'))
					{
						globalScript.call('onCreate');
						trace('GlobalScript: onCreate() called successfully');
					}
					else
					{
						trace('GlobalScript: No onCreate() function found');
					}
				}
				catch (e:Dynamic)
				{
					trace('GlobalScript: Error calling onCreate: $e');
					addScriptTextToDebug('$scriptPath: Runtime error in onCreate: $e', FlxColor.RED);
				}

				trace('GlobalScript initialized successfully from: $scriptPath');
				}
				catch (e:IrisError)
				{
					trace('GlobalScript IrisError caught');
					try
					{
						var errorMsg = Printer.errorToString(e, false);
						trace('GlobalScript Error: $errorMsg');
						addScriptTextToDebug('$scriptPath: $errorMsg', FlxColor.RED);
					}
					catch (printerError:Dynamic)
					{
						trace('GlobalScript: Error while processing IrisError: $printerError');
						trace('GlobalScript: Original error object: $e');
					}
				}
				catch (e:Dynamic)
				{
					trace('GlobalScript Error (unexpected): $e');
					trace('GlobalScript Error Type: ${Type.typeof(e)}');
					#if HSCRIPT_ALLOWED
					try
					{
						addScriptTextToDebug('$scriptPath: Unexpected error: $e', FlxColor.RED);
					}
					catch (displayError:Dynamic)
					{
						trace('GlobalScript: Could not add error to script debug overlay: $displayError');
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
				if (!stateScriptHooksEnabled())
					return returnVal;

				#if HSCRIPT_ALLOWED
				if (globalScript != null && globalScript.exists(funcToCall))
				{
					try
					{
						var callValue = globalScript.call(funcToCall, args);
						if (callValue != null && callValue.returnValue != null)
						{
							var myValue:Dynamic = callValue.returnValue;
							if (myValue != LuaUtils.Function_Continue)
								returnVal = myValue;
						}
					}
					catch (e:Dynamic)
					{
						trace('GlobalScript Error calling $funcToCall: $e');
						@:privateAccess
						var fileName = globalScript.origin != null ? globalScript.origin : "GlobalScript";
						addScriptTextToDebug('$fileName: Runtime error in $funcToCall: $e', FlxColor.RED);
					}
				}
				#end

				return returnVal;
			}

			#if HSCRIPT_ALLOWED
			private function injectReturnConstants(script:HScript):Void
			{
				if (script == null)
					return;

				script.set('Function_Continue', LuaUtils.Function_Continue);
				script.set('Function_Stop', LuaUtils.Function_Stop);
			}
			#end
		}

