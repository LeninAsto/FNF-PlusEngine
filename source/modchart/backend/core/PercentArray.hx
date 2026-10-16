package modchart.backend.core;

import haxe.ds.StringMap;
import haxe.ds.Vector;

/**
 * Collision-free registry for modifier values.
 *
 * Names are resolved once to compact integer IDs. Hot modifier code keeps those
 * IDs and reads the player vectors directly, avoiding both repeated string
 * lookups and the old 16-bit hash collisions.
 */
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
final class PercentArray {
	private var ids:StringMap<Int> = new StringMap();
	private var names:Array<String> = [];
	private var values:Array<Vector<Float>> = [];

	public function new() {}

	@:noDebug
	public function getID(key:String):Int {
		final normalized = key.toLowerCase();
		final existing = ids.get(normalized);
		if (existing != null)
			return existing;

		final id = names.length;
		ids.set(normalized, id);
		names.push(normalized);
		values.push(null);
		return id;
	}

	@:noDebug
	inline public function set(key:String, value:Vector<Float>):Void
		setUnsafe(getID(key), value);

	@:noDebug
	inline public function get(key:String):Vector<Float>
		return getUnsafe(getID(key));

	@:noDebug
	public function addAlias(parent:String, alias:String):Int {
		final id = getID(parent);
		ids.set(alias.toLowerCase(), id);
		return id;
	}

	@:noDebug
	inline public function getName(id:Int):Null<String>
		return id >= 0 && id < names.length ? names[id] : null;

	@:noDebug
	inline public function getUnsafe(id:Int):Vector<Float>
		return id >= 0 && id < values.length ? values[id] : null;

	@:noDebug
	public function setUnsafe(id:Int, value:Vector<Float>):Void {
		while (values.length <= id)
			values.push(null);
		values[id] = value;
	}
}
