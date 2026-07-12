package modchart;

import flixel.FlxBasic;
import flixel.tweens.FlxEase.EaseFunction;
import flixel.util.FlxSort;
import haxe.ds.StringMap;
import haxe.ds.Vector;
import modchart.backend.core.Node.NodeFunction;

using StringTools;

private typedef ScheduledPlayfieldOperation = {
	var beat:Float;
	var add:Bool;
	var name:Null<String>;
	var field:Int;
}

private class ManagedPlayfield {
	public var name:Null<String>;
	public var playfield:PlayField;
	public var active:Bool;

	public function new(name:Null<String>, playfield:PlayField, active:Bool = false) {
		this.name = name;
		this.playfield = playfield;
		this.active = active;
	}
}

/**
 * This assembles the modchart components, including:
 * - PlayFields
 * - Event Timeline
 * - Rendering
 */
@:allow(modchart.backend.ModifierGroup)
@:access(modchart.engine.PlayField)
#if !openfl_debug
@:fileXml('tags="haxe,release"') @:noDebug
#end
final class Manager extends FlxBasic {
	/**
	 * Instance of the Manager.
	 */
	public static var instance:Manager;

	/**
	 * Flag to enable or disable rendering of arrow paths.
	 * `Deprecated`
	 */
	@:deprecated("Use `Config.RENDER_ARROW_PATHS` instead.")
	public var renderArrowPaths:Bool = false;

	/**
	 * List of playfields managed by the Manager.
	 */
	public var playfields:Array<PlayField> = [];
	private var __namedPlayfields:StringMap<ManagedPlayfield> = new StringMap();
	private var __scheduledPlayfieldOps:Array<ScheduledPlayfieldOperation> = [];

	private var renderer:CtxRenderer;

	/** Exposes renderer stats for debug overlays. */
	public var rendererStats(get, never):CtxRenderer;
	inline function get_rendererStats() return renderer;

	public function new() {
		super();

		instance = this;
		renderer = new CtxRenderer();

		Adapter.init();
		Adapter.instance.onModchartingInitialization();

		addPlayfield();
	}

	/**
	 * Internal helper function to apply a function to each playfield.
	 *
	 * @param func The function to apply to each playfield.
	 * @param field Optionally, the specific playfield to target (-1 for all).
	 */
	public inline function iteratePlayfields(func:PlayField->Void, field:Int = -1) {
		// Apply to a specific playfield when requested.
		if (field != -1) {
			if (field < playfields.length && playfields[field] != null)
				return func(playfields[field]);
			return;
		}

		// Otherwise, apply the function to all playfields
		for (i in 0...playfields.length) {
			if (playfields[i] != null)
				func(playfields[i]);
		}
	}

	public function getNamedPlayfield(name:String):Null<PlayField> {
		final key = __normalizePlayfieldName(name);
		if (key == null)
			return null;

		final entry = __namedPlayfields.get(key);
		return entry != null ? entry.playfield : null;
	}

	/**
	 * Adds a modifier for all playfields or a specific one.
	 *
	 * @param name The name of the modifier.
	 * @param field Optionally, the specific playfield to target.
	 */
	public inline function addModifier(name:String, field:Int = -1)
		iteratePlayfields((pf) -> pf.addModifier(name), field);

	/**
	 * Adds a scripted modifier for all playfields or a specific one.
	 *
	 * @param name The name of the modifier.
	 * @param instance The instance of the modifier.
	 * @param field Optionally, the specific playfield to target.
	 */
	public inline function addScriptedModifier(name:String, instance:Modifier, field:Int = -1)
		iteratePlayfields((pf) -> pf.addScriptedModifier(name, instance), field);

	/**
	 * Sets the percent for a specific modifier for all playfields or a specific one.
	 *
	 * @param name The name of the modifier.
	 * @param value The percent value to set.
	 * @param player Optionally, the player to target.
	 * @param field Optionally, the specific playfield to target.
	 */
	public inline function setPercent(name:String, value:Float, player:Int = -1, field:Int = -1)
		iteratePlayfields((pf) -> pf.setPercent(name, value, player), field);

	/**
	 * Gets the percent for a specific modifier.
	 *
	 * @param name The name of the modifier.
	 * @param player The player to target.
	 * @param field Optionally, the specific playfield to target.
	 * @return The percent value for the modifier.
	 */
	public inline function getPercent(name:String, player:Int = 0, field:Int = 0):Float {
		final possiblePlayfield = playfields[field];

		if (possiblePlayfield != null)
			return possiblePlayfield.getPercent(name, player);

		return 0.;
	}

	/**
	 * Sets the raw value for a specific modifier (absolute value, not percentage).
	 *
	 * @param name The name of the modifier.
	 * @param value The raw value to set.
	 * @param player Optionally, the player to target.
	 * @param field Optionally, the specific playfield to target.
	 */
	public inline function setRawValue(name:String, value:Float, player:Int = -1, field:Int = -1)
		iteratePlayfields((pf) -> pf.setRawValue(name, value, player), field);

	/**
	 * Gets the raw value for a specific modifier.
	 *
	 * @param name The name of the modifier.
	 * @param player The player to target.
	 * @param field Optionally, the specific playfield to target.
	 * @return The raw value for the modifier.
	 */
	public inline function getRawValue(name:String, player:Int = 0, field:Int = 0):Float {
		final possiblePlayfield = playfields[field];

		if (possiblePlayfield != null)
			return possiblePlayfield.getRawValue(name, player);

		return 0.;
	}

	/**
	 * Adds an event to all playfields or a specific one.
	 *
	 * @param event The event to add.
	 * @param field Optionally, the specific playfield to target.
	 */
	public inline function addEvent(event:Event, field:Int = -1)
		iteratePlayfields((pf) -> pf.addEvent(event), field);

	/**
	 * Sets a specific value at a certain beat for all playfields or a specific one.
	 *
	 * @param name The name of the value.
	 * @param beat The beat at which the value should be set.
	 * @param value The value to set.
	 * @param player Optionally, the player to target.
	 * @param field Optionally, the specific playfield to target.
	 */
	public inline function set(name:String, beat:Float, value:Float, player:Int = -1, field:Int = -1)
		iteratePlayfields((pf) -> pf.set(name, beat, value, player), field);

	/**
	 * Applies easing to a modifier.
	 *
	 * @param name The name of the modifier.
	 * @param beat The beat at which to start easing.
	 * @param length The length of the easing.
	 * @param value The final value after easing.
	 * @param easeFunc The easing function to use.
	 * @param player Optionally, the player to target.
	 * @param field Optionally, the specific playfield to target.
	 */
	public inline function ease(name:String, beat:Float, length:Float, value:Float = 1, easeFunc:EaseFunction, player:Int = -1, field:Int = -1)
		iteratePlayfields((pf) -> pf.ease(name, beat, length, value, easeFunc, player), field);

	/**
	 * Adds easing to a modifier.
	 *
	 * @param name The name of the modifier.
	 * @param beat The beat at which to start easing.
	 * @param length The length of the easing.
	 * @param value The value to apply after easing.
	 * @param easeFunc The easing function to use.
	 * @param player Optionally, the player to target.
	 * @param field Optionally, the specific playfield to target.
	 */
	public inline function add(name:String, beat:Float, length:Float, value:Float = 1, easeFunc:EaseFunction, player:Int = -1, field:Int = -1)
		iteratePlayfields((pf) -> pf.add(name, beat, length, value, easeFunc, player), field);

	/**
	 * Sets and adds a value to a modifier.
	 *
	 * @param name The name of the modifier.
	 * @param beat The beat at which the value should be set.
	 * @param value The value to set.
	 * @param player Optionally, the player to target.
	 * @param field Optionally, the specific playfield to target.
	 */
	public inline function setAdd(name:String, beat:Float, value:Float, player:Int = -1, field:Int = -1)
		iteratePlayfields((pf) -> pf.setAdd(name, beat, value, player), field);

	/**
	 * Adds a repeater event for all playfields or a specific one.
	 *
	 * @param beat The beat at which the repeater starts.
	 * @param length The length of the repeat action.
	 * @param callback The callback function to execute.
	 * @param field Optionally, the specific playfield to target.
	 */
	public inline function repeater(beat:Float, length:Float, callback:Event->Void, field:Int = -1)
		iteratePlayfields((pf) -> pf.repeater(beat, length, callback), field);

	/**
	 * Adds a callback event for all playfields or a specific one.
	 *
	 * @param beat The beat at which the callback will be triggered.
	 * @param callback The callback function to execute.
	 * @param field Optionally, the specific playfield to target.
	 */
	public inline function callback(beat:Float, callback:Event->Void, field:Int = -1)
		iteratePlayfields((pf) -> pf.callback(beat, callback), field);

	/**
	 * Schedules a callback to run once at a specific beat (alias for callback).
	 *
	 * @param beat The beat at which the callback will be triggered.
	 * @param callback The callback function to execute.
	 * @param field Optionally, the specific playfield to target.
	 */
	public inline function scheduleCallback(beat:Float, callback:Event->Void, field:Int = -1)
		iteratePlayfields((pf) -> pf.scheduleCallback(beat, callback), field);

	/**
	 * Creates a node linking inputs and outputs to a function.
	 *
	 * @param input The list of input names.
	 * @param output The list of output names.
	 * @param func The function to execute for the node.
	 * @param field Optionally, the specific playfield to target.
	 */
	public inline function node(input:Array<String>, output:Array<String>, func:NodeFunction, field:Int = -1)
		iteratePlayfields((pf) -> pf.node(input, output, func), field);

	/**
	 * Creates an alias for a given modifier.
	 *
	 * @param name The original modifier name.
	 * @param alias The alias name.
	 * @param field The specific playfield to apply the alias to.
	 */
	public inline function alias(name:String, alias:String, field:Int)
		iteratePlayfields((pf) -> pf.alias(name, alias), field);

	/**
	 * Creates and adds a new playfield to the Manager.
	 */
	public function addPlayfield(?name:String, ?beat:Float):Int {
		if (beat != null && !Math.isNaN(beat)) {
			__scheduledPlayfieldOps.push({
				beat: beat,
				add: true,
				name: __normalizePlayfieldName(name),
				field: -1
			});
			if (name != null)
				__getOrCreateNamedPlayfield(name);
			return -1;
		}

		if (name == null || name.trim().length <= 0) {
			playfields.push(new PlayField());
			return playfields.length - 1;
		}

		final entry = __getOrCreateNamedPlayfield(name);
		__activateNamedPlayfield(entry);
		return __findPlayfieldIndex(entry.playfield);
	}

	public function removePlayfield(field:Int, ?beat:Float):Bool {
		if (beat != null && !Math.isNaN(beat)) {
			__scheduledPlayfieldOps.push({
				beat: beat,
				add: false,
				name: null,
				field: field
			});
			return true;
		}

		return __removePlayfieldAt(field);
	}

	public function removeNamedPlayfield(name:String, ?beat:Float):Bool {
		final key = __normalizePlayfieldName(name);
		if (key == null)
			return false;

		if (beat != null && !Math.isNaN(beat)) {
			__scheduledPlayfieldOps.push({
				beat: beat,
				add: false,
				name: key,
				field: -1
			});
			return true;
		}

		return __removeNamedPlayfieldNow(key);
	}

	/**
	 * Adds a playfield to the Manager.
	 */
	public inline function appendPlayfield(playfield:PlayField) {
		playfields.push(playfield);
	}

	/**
	 * Updates all playfields in the game loop.
	 *
	 * @param elapsed The time elapsed since the last update.
	 */
	override function update(elapsed:Float):Void {
		super.update(elapsed);

		__updateScheduledPlayfieldOps(Adapter.instance.getCurrentBeat());

		iteratePlayfields(pf -> pf.update(elapsed));
	}

	/**
	 * Draws all playfields, sorting them by z-order before drawing.
	 */
	override function draw():Void {
		var playerItems = Adapter.instance.getArrowItems();

		if (playerItems == null)
			return;
		renderer.emit(playerItems, playfields);
	}

	/**
	 * Destroys all playfields and cleans up.
	 */
	override function destroy():Void {
		super.destroy();

		Adapter.instance.onModchartingDispose();

		iteratePlayfields(pf -> {
			pf.destroy();
		});

		for (entry in __namedPlayfields) {
			if (!entry.active)
				entry.playfield.destroy();
		}
		__namedPlayfields = new StringMap();
		__scheduledPlayfieldOps.resize(0);
	}

	private inline function __normalizePlayfieldName(name:Null<String>):Null<String> {
		if (name == null)
			return null;

		final trimmed = name.trim();
		return trimmed.length > 0 ? trimmed.toLowerCase() : null;
	}

	private function __getOrCreateNamedPlayfield(name:String):ManagedPlayfield {
		final key = __normalizePlayfieldName(name);
		var entry = __namedPlayfields.get(key);
		if (entry != null)
			return entry;

		final playfield = new PlayField();
		playfield.displayName = name.trim();
		entry = new ManagedPlayfield(key, playfield);
		__namedPlayfields.set(key, entry);
		return entry;
	}

	private function __activateNamedPlayfield(entry:ManagedPlayfield):Void {
		if (entry == null || entry.active)
			return;

		playfields.push(entry.playfield);
		entry.active = true;
	}

	private function __findPlayfieldIndex(playfield:PlayField):Int {
		for (index => entry in playfields) {
			if (entry == playfield)
				return index;
		}
		return -1;
	}

	private function __removePlayfieldAt(field:Int):Bool {
		if (field < 0 || field >= playfields.length)
			return false;

		final playfield = playfields[field];
		if (playfield == null)
			return false;

		playfields[field] = null;
		if (playfield.displayName != null)
			__namedPlayfields.remove(__normalizePlayfieldName(playfield.displayName));
		playfield.destroy();
		return true;
	}

	private function __removeNamedPlayfieldNow(name:String):Bool {
		final entry = __namedPlayfields.get(name);
		if (entry == null)
			return false;

		if (entry.active) {
			final field = __findPlayfieldIndex(entry.playfield);
			if (field != -1)
				playfields[field] = null;
		}

		entry.active = false;
		entry.playfield.destroy();
		__namedPlayfields.remove(name);
		return true;
	}

	private function __updateScheduledPlayfieldOps(curBeat:Float):Void {
		var index = 0;
		while (index < __scheduledPlayfieldOps.length) {
			final operation = __scheduledPlayfieldOps[index];
			if (curBeat < operation.beat) {
				index++;
				continue;
			}

			if (operation.add) {
				if (operation.name == null) {
					playfields.push(new PlayField());
				} else {
					final entry = __namedPlayfields.get(operation.name);
					if (entry != null)
						__activateNamedPlayfield(entry);
				}
			} else if (operation.name != null) {
				__removeNamedPlayfieldNow(operation.name);
			} else {
				__removePlayfieldAt(operation.field);
			}

			__scheduledPlayfieldOps.splice(index, 1);
		}
	}

	// Constants for hold and arrow sizes
	public static var HOLD_SIZE:Float = 50 * 0.7;
	public static var HOLD_SIZEDIV2:Float = (50 * 0.7) * 0.5;
	public static var ARROW_SIZE:Float = 160 * 0.7;
	public static var ARROW_SIZEDIV2:Float = (160 * 0.7) * 0.5;
}