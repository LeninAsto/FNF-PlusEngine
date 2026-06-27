package backend;

import flixel.FlxG;
import flixel.FlxSubState;
import debug.TraceDisplay;
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

class ScriptableSubstate extends MusicBeatSubstate
{
	static var _bypassNextOverrideFor:Map<String, Bool> = [];

	public static var instance:ScriptableSubstate;

	public var substateName:String;
	var _fallbackSubstate:FlxSubState;
	var _fallbackTriggered:Bool = false;

	#if HSCRIPT_ALLOWED
	var _script:HScript;
	var _scriptedObj:ScriptTemplateBase;
	var _baseCreateDone:Bool = false;
	var _inScriptUpdate:Bool = false;
	#end

	public function new(name:String, ?fallbackSubstate:FlxSubState)
	{
		super();
		substateName = name;
		_fallbackSubstate = fallbackSubstate;
	}

	public function hasSubstateMethod(methodName:String):Bool
	{
		return _resolveCallableMethodTarget(methodName) != null;
	}

	public function callSubstateMethod(methodName:String, ?args:Array<Dynamic>, ?defaultValue:Dynamic = null):Dynamic
	{
		if (args == null) args = [];

		try
		{
			var resolved = _resolveCallableMethodTarget(methodName);
			if (resolved == null)
			{
				trace('[ScriptableSubstate:$substateName] Tried to call missing substate method "$methodName".');
				return defaultValue;
			}

			return Reflect.callMethod(resolved.target, resolved.method, args);
		}
		catch (e:Dynamic)
		{
			trace('[ScriptableSubstate:$substateName] Error calling substate method "$methodName": $e');
		}

		return defaultValue;
	}

	public function hasSubstateField(fieldName:String):Bool
	{
		return _resolveFieldTarget(fieldName) != null;
	}

	public function getSubstateField(fieldName:String, ?defaultValue:Dynamic = null):Dynamic
	{
		try
		{
			var resolved = _resolveFieldTarget(fieldName);
			if (resolved == null)
				return defaultValue;

			return Reflect.field(resolved, fieldName);
		}
		catch (e:Dynamic)
		{
			trace('[ScriptableSubstate:$substateName] Error reading substate field "$fieldName": $e');
		}

		return defaultValue;
	}

	public function setSubstateField(fieldName:String, value:Dynamic):Dynamic
	{
		try
		{
			var resolved = _resolveFieldTarget(fieldName);
			if (resolved == null)
			{
				trace('[ScriptableSubstate:$substateName] Tried to set missing substate field "$fieldName".');
				return value;
			}

			Reflect.setField(resolved, fieldName, value);
		}
		catch (e:Dynamic)
		{
			trace('[ScriptableSubstate:$substateName] Error writing substate field "$fieldName": $e');
		}

		return value;
	}

	public function hasParentStateMethod(methodName:String):Bool
	{
		var parent = getParentState();
		if (parent == null || methodName == null || methodName.length < 1) return false;
		var method:Dynamic = Reflect.field(parent, methodName);
		return method != null && Reflect.isFunction(method);
	}

	public function callParentStateMethod(methodName:String, ?args:Array<Dynamic>, ?defaultValue:Dynamic = null):Dynamic
	{
		if (args == null) args = [];

		try
		{
			var parent = getParentState();
			if (parent == null)
			{
				trace('[ScriptableSubstate:$substateName] Tried to call parent state method "$methodName" without parent state.');
				return defaultValue;
			}

			var method:Dynamic = Reflect.field(parent, methodName);
			if (method == null || !Reflect.isFunction(method))
			{
				trace('[ScriptableSubstate:$substateName] Tried to call missing parent state method "$methodName".');
				return defaultValue;
			}

			return Reflect.callMethod(parent, method, args);
		}
		catch (e:Dynamic)
		{
			trace('[ScriptableSubstate:$substateName] Error calling parent state method "$methodName": $e');
		}

		return defaultValue;
	}

	function _addTouchPadScript(d:String, a:String):Void
	{
		addTouchPad(d, a);
		_refreshScriptMobileRefs();
	}

	function _removeTouchPadScript():Void
	{
		removeTouchPad();
		_refreshScriptMobileRefs();
	}

	function _addTouchPadCameraScript(?t:Bool = false):Void
	{
		addTouchPadCamera(t);
		_refreshScriptMobileRefs();
	}

	function _addMobileControlsScript(?t:Bool = false):Void
	{
		addMobileControls(t);
		_refreshScriptMobileRefs();
	}

	function _removeMobileControlsScript():Void
	{
		removeMobileControls();
		_refreshScriptMobileRefs();
	}

	function _resolveCallableMethodTarget(methodName:String):Dynamic
	{
		if (methodName == null || methodName.length < 1) return null;

		var ownMethod:Dynamic = Reflect.field(this, methodName);
		if (ownMethod != null && Reflect.isFunction(ownMethod))
			return {target: this, method: ownMethod};

		if (_fallbackSubstate != null)
		{
			var fallbackMethod:Dynamic = Reflect.field(_fallbackSubstate, methodName);
			if (fallbackMethod != null && Reflect.isFunction(fallbackMethod))
				return {target: _fallbackSubstate, method: fallbackMethod};
		}

		return null;
	}

	function _resolveFieldTarget(fieldName:String):Dynamic
	{
		if (fieldName == null || fieldName.length < 1) return null;
		if (Reflect.hasField(this, fieldName)) return this;
		if (_fallbackSubstate != null && Reflect.hasField(_fallbackSubstate, fieldName)) return _fallbackSubstate;
		return null;
	}

	public static function findScript(name:String):Null<String>
	{
		var rel:String = 'scripts/substates/$name.hx';

		#if sys
		#if MODS_ALLOWED
		var modded:String = Paths.modFolders(rel);
		if (FileSystem.exists(modded)) return modded;
		#end

		var shared:String = Paths.getSharedPath(rel);
		if (FileSystem.exists(shared)) return shared;
		#end

		var assetPath:String = Paths.getSharedPath(rel);
		if (OpenFlAssets.exists(assetPath)) return assetPath;

		return null;
	}

	public static function hasScript(name:String):Bool
		return findScript(name) != null;

	public static inline function overridesEnabled():Bool
		return ClientPrefs.data.useScriptableCustomStates;

	public static function tryCreate(name:String, ?fallback:FlxSubState):FlxSubState
	{
		#if (HSCRIPT_ALLOWED && sys)
		if (!overridesEnabled()) return fallback;
		if (_consumeOverrideBypass(name)) return fallback;
		if (hasScript(name)) return new ScriptableSubstate(name, fallback);
		#end
		return fallback;
	}

	static function _consumeOverrideBypass(name:String):Bool
	{
		if (!_bypassNextOverrideFor.exists(name)) return false;
		_bypassNextOverrideFor.remove(name);
		return true;
	}

	override function create():Void
	{
		instance = this;

		if (!_baseCreateDone)
		{
			_baseCreateDone = true;
			super.create();
		}

		#if (HSCRIPT_ALLOWED && sys)
		var path:String = findScript(substateName);
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
			super.update(elapsed);
			_inScriptUpdate = false;
			return;
		}

		_inScriptUpdate = true;
		_callOnScript('update', [elapsed]);
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
		if (instance == this) instance = null;
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

	override function close():Void
	{
		_callOnScript('close', []);
		_syncScriptFields();
		super.close();
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

	#if HSCRIPT_ALLOWED
	function _loadScript(path:String):Bool
	{
		try
		{
			_script = new HScript(null, path);

			_script.set('game', this);
			_script.set('add', this.add);
			_script.set('remove', this.remove);
			_script.set('insert', this.insert);
			_script.set('close', this.close);
			_script.set('substateName', substateName);
			_script.set('scriptableSubstate', this);
			_script.set('parentState', getParentState());
			_script.set('controls', backend.Controls.instance);
			_script.set('hasSubstateMethod', this.hasSubstateMethod);
			_script.set('callSubstateMethod', this.callSubstateMethod);
			_script.set('hasSubstateField', this.hasSubstateField);
			_script.set('getSubstateField', this.getSubstateField);
			_script.set('setSubstateField', this.setSubstateField);
			_script.set('hasParentStateMethod', this.hasParentStateMethod);
			_script.set('callParentStateMethod', this.callParentStateMethod);
			_script.set('hasGameMethod', this.hasSubstateMethod);
			_script.set('callGameMethod', this.callSubstateMethod);
			_script.set('hasGameField', this.hasSubstateField);
			_script.set('getGameField', this.getSubstateField);
			_script.set('setGameField', this.setSubstateField);

			var presetPath:Null<String> = _findPreset();
			if (presetPath != null)
				_script.executeFile(presetPath);

			_script.set('persistentUpdate', this.persistentUpdate);
			_script.set('persistentDraw', this.persistentDraw);

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
			_script.set('hasSharedVar', function(n:String):Bool
				return MusicBeatState.globalVariables.exists(n) || variables.exists(n));
			_script.set('removeSharedVar', function(n:String):Bool {
				var r = false;
				if (MusicBeatState.globalVariables.remove(n)) r = true;
				if (variables.remove(n)) r = true;
				return r;
			});

			_script.set('setPublicVar', function(n:String, v:Dynamic) { MusicBeatState.publicVariables.set(n, v); return v; });
			_script.set('getPublicVar', function(n:String, ?def:Dynamic = null):Dynamic
				return MusicBeatState.publicVariables.exists(n) ? MusicBeatState.publicVariables.get(n) : def);

			_script.set('setStaticVar', function(n:String, v:Dynamic) { MusicBeatState.staticVariables.set(n, v); return v; });
			_script.set('getStaticVar', function(n:String, ?def:Dynamic = null):Dynamic
				return MusicBeatState.staticVariables.exists(n) ? MusicBeatState.staticVariables.get(n) : def);

			_script.set('setStateVar', function(n:String, v:Dynamic) { variables.set(n, v); return v; });
			_script.set('getStateVar', function(n:String, ?def:Dynamic = null):Dynamic
				return variables.exists(n) ? variables.get(n) : def);

			_script.set('addTouchPad', _addTouchPadScript);
			_script.set('removeTouchPad', _removeTouchPadScript);
			_script.set('addTouchPadCamera', _addTouchPadCameraScript);
			_script.set('addMobileControls', _addMobileControlsScript);
			_script.set('removeMobileControls', _removeMobileControlsScript);

			var classDef:ScriptClassHandler = _script.getScriptedClass(substateName);
			if (classDef != null)
			{
				var scriptedInstance:Dynamic = classDef.hnew([]);
				if ((scriptedInstance is ScriptTemplateBase))
				{
					_scriptedObj = cast scriptedInstance;

					if (_scriptedObj.__interp != null)
					{
						_scriptedObj.__interp.variables.set('game', this);
						_scriptedObj.__interp.variables.set('add', this.add);
						_scriptedObj.__interp.variables.set('remove', this.remove);
						_scriptedObj.__interp.variables.set('insert', this.insert);
						_scriptedObj.__interp.variables.set('close', this.close);
						_scriptedObj.__interp.variables.set('substateName', substateName);
						_scriptedObj.__interp.variables.set('scriptableSubstate', this);
						_scriptedObj.__interp.variables.set('parentState', getParentState());
						_scriptedObj.__interp.variables.set('hasSubstateMethod', this.hasSubstateMethod);
						_scriptedObj.__interp.variables.set('callSubstateMethod', this.callSubstateMethod);
						_scriptedObj.__interp.variables.set('hasSubstateField', this.hasSubstateField);
						_scriptedObj.__interp.variables.set('getSubstateField', this.getSubstateField);
						_scriptedObj.__interp.variables.set('setSubstateField', this.setSubstateField);
						_scriptedObj.__interp.variables.set('hasParentStateMethod', this.hasParentStateMethod);
						_scriptedObj.__interp.variables.set('callParentStateMethod', this.callParentStateMethod);
						_scriptedObj.__interp.variables.set('hasGameMethod', this.hasSubstateMethod);
						_scriptedObj.__interp.variables.set('callGameMethod', this.callSubstateMethod);
						_scriptedObj.__interp.variables.set('hasGameField', this.hasSubstateField);
						_scriptedObj.__interp.variables.set('getGameField', this.getSubstateField);
						_scriptedObj.__interp.variables.set('setGameField', this.setSubstateField);
					}
				}
			}

			_refreshScriptMobileRefs();

			return true;
		}
		catch (e:IrisError)
		{
			var msg:String = Printer.errorToString(e, false);
			trace('[ScriptableSubstate] HScript error in $path:\n$msg');
			if (TraceDisplay.instance != null)
				TraceDisplay.addHScriptError(msg, path);
		}
		catch (e:Dynamic)
		{
			trace('[ScriptableSubstate] Failed to load $path: $e');
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
		if (_fallbackTriggered || _fallbackSubstate == null) return false;

		_fallbackTriggered = true;
		_bypassNextOverrideFor.set(substateName, true);
		trace('[ScriptableSubstate:$substateName] Falling back to hardcoded substate: ' + reason);

		final parent = getParentState();
		if (parent != null)
			parent.openSubState(_fallbackSubstate);
		else if (FlxG.state != null)
			FlxG.state.openSubState(_fallbackSubstate);

		close();
		return true;
	}
	#end

	function _callOnScript(method:String, args:Array<Dynamic>):Void
	{
		#if HSCRIPT_ALLOWED
		if (args == null) args = [];

		try
		{
			if (_scriptedObj != null)
			{
				if (_scriptedObj.hasMethod(method))
					_scriptedObj.callMethod(method, args);
			}
			else if (_script != null)
			{
				var cbName:String = 'on' + method.charAt(0).toUpperCase() + method.substr(1);
				if (_script.exists(cbName))
					_script.call(cbName, args);
				else if (_script.exists(method))
					_script.call(method, args);
			}
		}
		catch (e:Dynamic)
		{
			trace('[ScriptableSubstate:$substateName] Error in $method(): $e');
		}
		#end
	}

	#if HSCRIPT_ALLOWED
	function _syncScriptFields():Void
	{
		if (_script == null) return;
		if (_script.exists('persistentUpdate'))
			this.persistentUpdate = _script.get('persistentUpdate');
		if (_script.exists('persistentDraw'))
			this.persistentDraw = _script.get('persistentDraw');
	}

	function _refreshScriptMobileRefs():Void
	{
		if (_script != null)
		{
			_script.set('touchPad', this.touchPad);
			_script.set('touchPadCam', this.touchPadCam);
			_script.set('mobileControls', this.mobileControls);
			_script.set('mobileControlsInstance', this.mobileControls != null ? this.mobileControls.instance : null);
			_script.set('mobileControlsCam', this.mobileControlsCam);
		}

		if (_scriptedObj != null && _scriptedObj.__interp != null)
		{
			_scriptedObj.__interp.variables.set('touchPad', this.touchPad);
			_scriptedObj.__interp.variables.set('touchPadCam', this.touchPadCam);
			_scriptedObj.__interp.variables.set('mobileControls', this.mobileControls);
			_scriptedObj.__interp.variables.set('mobileControlsInstance', this.mobileControls != null ? this.mobileControls.instance : null);
			_scriptedObj.__interp.variables.set('mobileControlsCam', this.mobileControlsCam);
		}
	}

	function _findPreset():Null<String>
	{
		var rel:String = 'scripts/substates/_substatePreset.hx';

		#if sys
		#if MODS_ALLOWED
		var modded:String = Paths.modFolders(rel);
		if (FileSystem.exists(modded)) return modded;
		#end

		var shared:String = Paths.getSharedPath(rel);
		if (FileSystem.exists(shared)) return shared;
		#end

		var assetPath:String = Paths.getSharedPath(rel);
		if (OpenFlAssets.exists(assetPath)) return assetPath;

		return null;
	}
	#end
}
