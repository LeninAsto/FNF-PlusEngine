package modchart.engine.modifiers;

import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import haxe.ds.Vector;
import modchart.backend.core.ArrowData;
import modchart.backend.core.ModifierOutput;
import modchart.backend.core.ModifierParameters;
import modchart.backend.core.PercentArray;
import modchart.backend.core.VisualParameters;
import modchart.backend.core.TransformMode;
import modchart.backend.macros.ModifiersMacro;
import modchart.backend.util.ModchartUtil;
import modchart.engine.modifiers.Modifier;
import modchart.engine.modifiers.list.*;
import modchart.engine.modifiers.list.false_paradise.*;

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:allow(modchart.engine.Modifier)
final class ModifierGroup {
	/**
	 * A `List` containing all compiled `Modifier` classes.
	 *
	 * This list is generated at compile time using `ModifiersMacro.get()`.
	 * It provides a collection of all available modifiers for use in the system.
	 */
	public static final COMPILED_MODIFIERS = ModifiersMacro.get();

	/**
	 * A collision-free registry storing modifier values by compact integer ID.
	 *
	 * **Usage Notes:**
	 * - Do not access `percents` directly; names are registered as compact IDs.
	 * - Use `getPercent(name, player)` to retrieve a value.
	 * - Use `setPercent(name, value, player)` to modify values safely.
	 *
	 * Names are resolved once; modifiers cache their IDs for the render hot path.
	 */
	public var percents(default, never):PercentArray = new PercentArray();
	@:noCompletion private var __explicitPercentPlayers:Array<Int> = [];

	/**
	 * A `StringMap` that maps modifier names/identifiers to their corresponding `Modifier` class.
	 * **Note**: This is not actually used internally-
	 */
	public var modifiers(default, never):StringMap<Modifier> = new StringMap();

	/**
	 * The current `PlayField` instance.
	 *
	 * When set, all stored modifiers are updated to reference the new `PlayField` instance.
	 */
	public var playfield(default, set):PlayField;

	public function set_playfield(newPlayfield:PlayField) {
		for (i in 0...__modifierCount) {
			@:privateAccess __sortedModifiers[i].pf = newPlayfield;
		}
		return playfield = newPlayfield;
	}

	@:noCompletion private var __modifierRegistrery:StringMap<Class<Modifier>> = new StringMap();

	/** Pre-allocated args struct to avoid per-call heap allocation in getPath(). */
	@:noCompletion private var __cachedArgs:ModifierParameters;
	/** Reused anchor args for straight holds so blocked mods follow the head uniformly. */
	@:noCompletion private var __cachedStraightArgs:ModifierParameters;
	public var dbgPathCalls(default, null):Int = 0;
	public var dbgModifierCalls(default, null):Int = 0;
	public var trackDebugStats:Bool = false;
	@:noCompletion private var __debugFrame:Int = -1;
	@:noCompletion private var __activeFrame:Int = -1;
	@:noCompletion private var __activeByMode:Array<Array<Array<Modifier>>> = [];
	static final __MODE_VALUES:Array<Int> = [1, 3, 5, 9, 15];

	@:noCompletion private var __sortedModifiers:Vector<Modifier> = new Vector<Modifier>(32);
	@:noCompletion private var __modifierCount:Int = 0;
	@:noCompletion private var __sortedIDs:Vector<String> = new Vector<String>(32);
	@:noCompletion private var __idCount:Int = 0;
	@:noCompletion private var __modSplineActiveID:Int = 0;
	@:noCompletion private var __knownPercentIDs:Vector<Int> = new Vector<Int>(256);
	@:noCompletion private var __knownPercentNames:Vector<String> = new Vector<String>(256);
	@:noCompletion private var __knownPercentCount:Int = 0;
	public var modifierCount(get, never):Int;
	inline function get_modifierCount():Int return __modifierCount;

	inline private function __loadModifiers() {
		for (cls in COMPILED_MODIFIERS) {
			var name = Type.getClassName(cls);
			name = name.substring(name.lastIndexOf('.') + 1, name.length);
			__modifierRegistrery.set(name.toLowerCase(), cast cls);
		}
	}

	public function new(playfield:PlayField) {
		this.playfield = playfield;
		// Pre-allocate reusable args struct to avoid 1 heap alloc per getPath() call
		__cachedArgs = {songTime: 0, hitTime: 0, distance: 0, sourceTime: 0, curBeat: 0};
		__cachedStraightArgs = {songTime: 0, hitTime: 0, distance: 0, sourceTime: 0, curBeat: 0};
		__modSplineActiveID = percents.getID('modSpline');

		__loadModifiers();
	}

	/**
	 * Computes the transformed position and visual properties of an arrow based on active modifiers.
	 * Now uses a global cache system for better performance.
	 *
	 * @param pos The initial `Vector3` position of the arrow.
	 * @param data The `ArrowData` containing arrow properties such as lane, player, and timing.
	 * @param posDiff (Optional) A positional offset applied to the arrow.
	 * @param allowVis (Optional) If `true`, visual modifications will be applied.
	 * @param allowPos (Optional) If `true`, positional transformations will be applied.
	 * @return A `ModifierOutput` structure containing the modified position and visuals.
	 *
	 * **Processing Steps:**
	 * - Checks global cache first
	 * - If cache miss, calculates modifiers and stores result
	 * - Retrieves the current song position and beat.
	 * - Iterates through all active modifiers, applying transformations if conditions are met.
	 * - Adjusts the `z` position based on `Config.Z_SCALE` and projects the final position.
	 */
	public inline function getPath(pos:Vector3, data:ArrowData, ?posDiff:Float = 0, ?allowVis:Bool = true, ?allowPos:Bool = true, ?transformMode:Int = 15):ModifierOutput {
		final outPos = new Vector3();
		final outVisuals:VisualParameters = {};
		final out:ModifierOutput = {pos: outPos, visuals: outVisuals};
		return getPathInto(pos, data, out, outPos, outVisuals, posDiff, allowVis, allowPos, transformMode);
	}

	/** Allocation-free renderer path. Public wrappers keep the old API intact. */
	public function getPathInto(pos:Vector3, data:ArrowData, out:ModifierOutput, outPos:Vector3, visuals:VisualParameters,
			?posDiff:Float = 0, ?allowVis:Bool = true, ?allowPos:Bool = true, ?transformMode:Int = 15):ModifierOutput {
		if (trackDebugStats && __debugFrame != playfield.state.frameId) {
			__debugFrame = playfield.state.frameId;
			dbgPathCalls = 0;
			dbgModifierCalls = 0;
		}
		if (trackDebugStats)
			dbgPathCalls++;
		__refreshActiveModifiers();

		visuals.scaleX = 1;
		visuals.scaleY = 1;
		visuals.alpha = 1;
		visuals.glow = 0;
		visuals.glowR = 1;
		visuals.glowG = 1;
		visuals.glowB = 1;
		visuals.angleX = 0;
		visuals.angleY = 0;
		visuals.angleZ = 0;
		visuals.skewX = 0;
		visuals.skewY = 0;

		if (!allowVis && !allowPos) {
			outPos.setTo(pos.x, pos.y, pos.z);
			out.pos = outPos;
			out.visuals = visuals;
			out.rawX = pos.x;
			out.rawY = pos.y;
			out.rawZ = pos.z;
			return out;
		}

		final hitTime = data.hitTime + posDiff;
		final distance = data.distance + posDiff;
		
		final songPos = playfield.state.songPosition;
		final beat = playfield.state.beat;

		// Reuse pre-allocated args to avoid per-call heap allocation
		final args = __cachedArgs;
		args.songTime = songPos;
		args.curBeat = beat;
		args.hitTime = hitTime;
		args.distance = distance;
		args.sourceTime = data.sourceTime;
		args.lane = data.lane;
		args.player = data.player;
		args.isTapArrow = data.isTapArrow;
		args.straightHolds = data.straightHolds;
		args.isHoldBody = data.isHoldBody;

		final straightArgs = __cachedStraightArgs;
		straightArgs.songTime = songPos;
		straightArgs.curBeat = beat;
		straightArgs.hitTime = data.sourceTime;
		straightArgs.distance = Math.max(0, data.sourceTime - songPos);
		straightArgs.sourceTime = data.sourceTime;
		straightArgs.lane = data.lane;
		straightArgs.player = data.player;
		straightArgs.isTapArrow = data.isTapArrow;
		straightArgs.straightHolds = data.straightHolds;
		straightArgs.isHoldBody = data.isHoldBody;

		// Iterate the frame-local active list in registration order.
		final mods = __activeByMode[data.player][__modeIndex(transformMode)];
		final len = mods.length;

		for (i in 0...len) {
			final mod = mods[i];
			final useStraightAnchor = args.straightHolds && !mod.allowOnStraightHolds();
			final activeArgs = useStraightAnchor ? straightArgs : args;

			if (!mod.shouldRun(activeArgs))
				continue;
			if (trackDebugStats)
				dbgModifierCalls++;

			if (allowPos)
				pos = mod.render(pos, activeArgs);
			if (allowVis)
				visuals = mod.visuals(visuals, activeArgs);
		}
		pos.z *= 0.001 * Config.Z_SCALE;
		final rawX = pos.x;
		final rawY = pos.y;
		final rawZ = pos.z;
		pos = playfield.view.transformVector(pos);
		outPos.setTo(pos.x, pos.y, pos.z);
		out.pos = outPos;
		out.visuals = visuals;
		out.rawX = rawX;
		out.rawY = rawY;
		out.rawZ = rawZ;
		return out;
	}

	private function __refreshActiveModifiers():Void {
		final frame = playfield.state.frameId;
		if (__activeFrame == frame)
			return;
		__activeFrame = frame;
		final players = Adapter.instance.getPlayerCount();
		while (__activeByMode.length < players)
			__activeByMode.push([[], [], [], [], []]);
		for (player in 0...players) {
			final modes = __activeByMode[player];
			for (active in modes) active.resize(0);
			for (i in 0...__modifierCount) {
				final mod = __sortedModifiers[i];
				if (mod == null || !mod.isActive(player))
					continue;
				for (modeIndex in 0...__MODE_VALUES.length)
					if (mod.supportsMode(cast __MODE_VALUES[modeIndex]))
						modes[modeIndex].push(mod);
			}
		}
	}

	private inline function __modeIndex(mode:Int):Int {
		return switch (mode) {
			case 1: 0;
			case 3: 1;
			case 5: 2;
			case 9: 3;
			default: 4;
		}
	}

	public inline function addScriptedModifier(name:String, instance:Modifier)
		__addModifier(name, instance);

	public inline function addModifier(name:String) {
		var lowerName = __normalizeModifierName(name);
		if (modifiers.exists(lowerName))
			return;

		var modifierClass:Null<Class<Modifier>> = __modifierRegistrery.get(lowerName);
		if (modifierClass == null) {
			trace('$name modifier was not found !');

			return;
		}
		var newModifier = Type.createInstance(modifierClass, [playfield]);
		__addModifier(lowerName, newModifier);
	}

	inline function __normalizeModifierName(name:String):String {
		final lowerName = name.toLowerCase();
		return switch (lowerName) {
			case 'fieldrotate': 'field';
			default: lowerName;
		}
	}

	public inline function setPercent(name:String, value:Float, player:Int = -1) {
		__activeFrame = -1;
		final id = percents.getID(name);
		final lowerName = name.toLowerCase();
		final canonicalName = percents.getName(id) ?? lowerName;
		__rememberPercent(id, canonicalName);
		final possiblePercs = percents.getUnsafe(id);
		final generate = possiblePercs == null;
		final percs = generate ? __getPercentTemplate() : possiblePercs;

		if (player == -1)
			for (_ in 0...percs.length)
				percs[_] = value;
		else
			percs[player] = value;

		__markExplicit(id, player);

		// if the percent list already was generated, we dont need to set it again
		if (generate)
			percents.setUnsafe(id, percs);

		if (canonicalName.indexOf('spline') == 0 && canonicalName != 'modspline')
			__setUnsafe(__modSplineActiveID, 1, player);
	}

	public inline function getPercent(name:String, player:Int):Float {
		final percs = percents.get(name);

		if (percs != null)
			return percs[player];
		return 0;
	}

	public inline function addAlias(parent:String, alias:String):Int
		return percents.addAlias(parent, alias);

	public inline function resolvePercentID(name:String):Int
		return percents.getID(name);

	public inline function getPercentByID(id:Int, player:Int):Float
		return __getUnsafe(id, player);

	public inline function setRawValue(name:String, value:Float, player:Int = -1) setPercent(name, value, player);

	public inline function getRawValue(name:String, player:Int) return getPercent(name, player);

	public function resetPercents(player:Int = -1):Void {
		__activeFrame = -1;
		for (i in 0...__knownPercentCount) {
			final id = __knownPercentIDs[i];
			final percs = percents.getUnsafe(id);
			if (percs == null)
				continue;

			final value = __getDefaultPercent(__knownPercentNames[i]);
			if (player == -1)
				for (p in 0...percs.length)
					percs[p] = value;
			else if (player >= 0 && player < percs.length)
				percs[player] = value;
		}

		if (__modSplineActiveID != 0)
			__setUnsafe(__modSplineActiveID, 0, player);
	}

	inline private function __getUnsafe(id:Int, player:Int) {
		final percs = percents.getUnsafe(id);

		if (percs != null)
			return percs[player];
		return 0;
	}

	inline private function __hasUnsafe(id:Int):Bool
		return percents.getUnsafe(id) != null;

	inline private function __hasUnsafeForPlayer(id:Int, player:Int):Bool
		return (percents.getUnsafe(id) != null) && id < __explicitPercentPlayers.length
			&& ((__explicitPercentPlayers[id] & __playerMask(player)) != 0);

	inline private function __setUnsafe(id:Int, value:Float, player:Int = -1) {
		var possiblePercs = percents.getUnsafe(id);
		var generate = possiblePercs == null;
		var percs = generate ? __getPercentTemplate() : possiblePercs;

		if (player == -1)
			for (_ in 0...percs.length)
				percs[_] = value;
		else
			percs[player] = value;

		__markExplicit(id, player);

		if (generate)
			percents.setUnsafe(id, percs);
	}

	inline private function __markExplicit(id:Int, player:Int):Void {
		while (__explicitPercentPlayers.length <= id)
			__explicitPercentPlayers.push(0);
		__explicitPercentPlayers[id] = __explicitPercentPlayers[id] | __playerMask(player);
	}

	inline private function __playerMask(player:Int):Int {
		if (player == -1) {
			var mask = 0;
			for (i in 0...Adapter.instance.getPlayerCount())
				mask = mask | (1 << i);
			return mask;
		}

		return (player >= 0 && player < 31) ? (1 << player) : 0;
	}

	@:noCompletion
	inline private function __addModifier(name:String, modifier:Modifier) {
		__activeFrame = -1;
		modifiers.set(name, modifier);
		@:privateAccess modifier.pf = playfield;

		// update modifier identificators
		if (__idCount > (__sortedIDs.length - 1)) {
			final oldIDs = __sortedIDs.copy();
			__sortedIDs = new Vector<String>(oldIDs.length + 8);

			for (i in 0...oldIDs.length)
				__sortedIDs[i] = oldIDs[i];
		}
		__sortedIDs[__idCount++] = name;

		// update modifier list
		if (__modifierCount > (__sortedModifiers.length - 1)) {
			final oldMods = __sortedModifiers.copy();
			__sortedModifiers = new Vector<Modifier>(oldMods.length + 8);

			for (i in 0...oldMods.length)
				__sortedModifiers[i] = oldMods[i];
		}
		__sortedModifiers[__modifierCount++] = modifier;
	}

	@:noCompletion
	inline private function __getPercentTemplate():Vector<Float> {
		final vector = new Vector<Float>(Adapter.instance.getPlayerCount());
		for (i in 0...vector.length)
			vector[i] = 0;
		return vector;
	}

	function __rememberPercent(id:Int, lowerName:String):Void {
		for (i in 0...__knownPercentCount)
			if (__knownPercentIDs[i] == id)
				return;

		if (__knownPercentCount >= __knownPercentIDs.length) {
			final oldIDs = __knownPercentIDs.copy();
			final oldNames = __knownPercentNames.copy();
			__knownPercentIDs = new Vector<Int>(oldIDs.length + 128);
			__knownPercentNames = new Vector<String>(oldNames.length + 128);
			for (i in 0...oldIDs.length) {
				__knownPercentIDs[i] = oldIDs[i];
				__knownPercentNames[i] = oldNames[i];
			}
		}

		__knownPercentIDs[__knownPercentCount] = id;
		__knownPercentNames[__knownPercentCount] = lowerName;
		__knownPercentCount++;
	}

	function __getDefaultPercent(name:String):Float {
		return switch (name) {
			case 'xmod' | 'scale' | 'scalex' | 'scaley' | 'alpha' | 'wavemult':
				1;
			case 'beatspeed' | 'beatxspeed' | 'beatyspeed' | 'beatzspeed':
				1;
			case 'bumpymult' | 'bumpyxmult' | 'bumpyymult' | 'bumpyzmult'
				| 'bumpyanglemult' | 'bumpyanglexmult' | 'bumpyangleymult' | 'bumpyanglezmult':
				1;
			case 'suddenstart' | 'hiddenstart':
				5;
			case 'suddenend' | 'hiddenend':
				3;
			case 'suddenglow' | 'hiddenglow':
				1;
			case 'spawntime':
				2000;
			case 'carouselstart' | 'carouselend':
				Math.NaN;
			default:
				if (__isXmodLane(name) || __isScaleLane(name) || __isAlphaLane(name) || __isBumpyMultLane(name))
					1;
				else
					0;
		}
	}

	inline function __isXmodLane(name:String):Bool
		return name.length > 4 && name.indexOf('xmod') == 0 && __isUnsignedInt(name.substr(4));

	function __isScaleLane(name:String):Bool {
		if (name.indexOf('scale') != 0)
			return false;

		var suffix = name.substr(5);
		if (suffix.length == 0)
			return false;
		if (suffix.charAt(0) == 'x' || suffix.charAt(0) == 'y')
			suffix = suffix.substr(1);
		return suffix.length > 0 && __isUnsignedInt(suffix);
	}

	inline function __isAlphaLane(name:String):Bool
		return name.length > 5 && name.indexOf('alpha') == 0 && __isUnsignedInt(name.substr(5));

	function __isBumpyMultLane(name:String):Bool {
		if (name.indexOf('bumpy') != 0 || name.length <= 9)
			return false;
		if (name.lastIndexOf('mult') != name.length - 4)
			return false;

		var middle = name.substr(5, name.length - 9);
		if (middle.indexOf('angle') == 0)
			middle = middle.substr(5);
		if (middle.length > 0 && (middle.charAt(0) == 'x' || middle.charAt(0) == 'y' || middle.charAt(0) == 'z'))
			middle = middle.substr(1);
		return middle.length > 0 && __isUnsignedInt(middle);
	}

	function __isUnsignedInt(value:String):Bool {
		for (i in 0...value.length) {
			final c = StringTools.unsafeCodeAt(value, i);
			if (c < 48 || c > 57)
				return false;
		}
		return value.length > 0;
	}
}
