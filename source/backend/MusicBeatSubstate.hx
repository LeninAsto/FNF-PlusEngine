package backend;

import flixel.FlxSubState;
import debug.TraceDisplay;

#if LUA_ALLOWED
import psychlua.FunkinLua;
#end

#if HSCRIPT_ALLOWED
import psychlua.HScript;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end

import psychlua.LuaUtils;

#if sys
import sys.FileSystem;
#end

// Script layer on top of BaseMusicBeatSubstate.
// Adds GlobalScript forwarding and per-substate HScript/Lua callbacks.
//
// Hierarchy:
//   BaseMusicBeatSubstate (beat, mobile controls)
//   └── MusicBeatSubstate (this file — + script hooks)

class MusicBeatSubstate extends BaseMusicBeatSubstate
{
	public static inline var Function_Continue:Int = 0;
	public static inline var Function_Stop:Int = 1;

	public static var instance:MusicBeatSubstate;
	
	// Variables map for substate-specific data
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	
	// MusicBeatSubstate specific scripts (run on all MusicBeatSubstate instances)
	#if LUA_ALLOWED
	public static var musicBeatSubstateLuaScript:FunkinLua = null;
	#end
	
	#if HSCRIPT_ALLOWED
	public static var musicBeatSubstateScript:HScript = null;
	#end

	// Companion script — loaded automatically alongside any hardcoded substate.
	// Path: scripts/substates/{ClassName}.hx (or .lua), searched in mod → global mods → assets/shared.
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

	public function new()
	{
		super();
	}

	override function create()
	{
		instance = this;
		controls.isInSubstate = true;
		super.create();
		#if (HSCRIPT_ALLOWED && MODS_ALLOWED && sys)
		// Skip companion for CustomSubstate (Lua-driven substates handle their own scripts)
		if (!(this is psychlua.CustomSubstate) && MusicBeatState.stateScriptOverridesEnabled())
			_loadCompanionScript();
		#end
	}
	public static function getSubstate():MusicBeatSubstate
	{
		return instance;
	}

	// Get the parent MusicBeatState (shadows Base version which returns BaseMusicBeatState)
	public function getParentState():MusicBeatState
	{
		if (FlxG.state != null && Std.isOfType(FlxG.state, MusicBeatState))
			return cast(FlxG.state, MusicBeatState);
		return null;
	}

	override function update(elapsed:Float)
	{
		// Call global script update
		MusicBeatState.callOnGlobalScript('onSubstateUpdate', [elapsed]);

		super.update(elapsed);
	}

	override public function stepHit():Void
	{
		// Call global script
		MusicBeatState.callOnGlobalScript('onSubstateStepHit', [curStep]);

		super.stepHit();
	}

	override public function beatHit():Void
	{
		// Call global script
		MusicBeatState.callOnGlobalScript('onSubstateBeatHit', [curBeat]);

		super.beatHit();
	}

	override public function sectionHit():Void
	{
		// Call global script
		MusicBeatState.callOnGlobalScript('onSubstateSectionHit', [curSection]);

		super.sectionHit();
	}

	override function destroy()
	{
		if (instance == this)
		{
			controls.isInSubstate = false;
			instance = null;
		}
		#if LUA_ALLOWED
		if (companionLuaScript != null)
		{
			// Legacy destroy hook for Lua companion scripts
			companionLuaScript.call('onDestroy', []);
		}
		#end
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
	
	// ── Companion script helpers ─────────────────────────────────────────────────

	#if (HSCRIPT_ALLOWED && sys)
	function _loadCompanionScript():Void
	{
		var fullName:String = Type.getClassName(Type.getClass(this));
		var parts = fullName.split('.');
		var clsName:String = parts[parts.length - 1];
		var rel:String = 'scripts/substates/$clsName.hx';

		var path:String = null;

		#if MODS_ALLOWED
		var modded:String = Paths.modFolders(rel);
		if (FileSystem.exists(modded)) path = modded;
		#end

		if (path == null)
		{
			var shared:String = Paths.getSharedPath(rel);
			if (FileSystem.exists(shared)) path = shared;
		}

		#if LUA_ALLOWED
		var luaRel:String = 'scripts/substates/$clsName.lua';
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
			catch(e:Dynamic) { trace('[CompanionSubstate] Lua error in $luaPath: $e'); }
		}
		#end

		if (path == null) return;

		try
		{
			companionScript = new HScript(null, path);
			injectReturnConstants(companionScript);

			// Expose the substate itself and its parent state
			companionScript.set('game',           this);
			companionScript.set('parentState',    getParentState());
			companionScript.set('add',            this.add);
			companionScript.set('remove',         this.remove);
			companionScript.set('close',          this.close);

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

			trace('[CompanionSubstate] Loaded for "$clsName": $path');
		}
		catch(e:crowplexus.hscript.Expr.Error)
		{
			var msg = crowplexus.hscript.Printer.errorToString(e, false);
			trace('[CompanionSubstate] HScript error in $path:\n$msg');
			if (debug.TraceDisplay.instance != null)
				debug.TraceDisplay.addHScriptError(msg, path);
		}
		catch(e:Dynamic)
		{
			trace('[CompanionSubstate] Failed to load $path: $e');
		}
	}
	#end

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
				trace('[CompanionSubstate] Runtime error calling $funcName: $e');
			}
		}
		#end

		return ret;
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
