package modchart.backend.core;

import haxe.ds.Vector;

// basicly 2d vector with string hashing
// used to store modifier values
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
final class PercentArray {
	private var vector:Vector<Vector<Float>>;

	public function new() {
		vector = new Vector<Vector<Float>>(Std.int(Math.pow(2, 16))); // preallocate by max 16-bit integer
	}

	// hash the key to a 16-bit integer (case-insensitive: avoids String.toLowerCase() allocation in callers)
	@:noDebug @:noCompletion inline private function __hashKey(key:String):Int {
		var hash:Int = 0;
		var len = key.length;
		for (i in 0...len) {
			var c = StringTools.unsafeCodeAt(key, i);
			// inline lowercase: 'A'-'Z' (65-90) -> 'a'-'z' (97-122)
			if (c >= 65 && c <= 90)
				c += 32;
			hash = hash * 31 + c;
		}

		return hash & 0xFFFF; // 16-bit hash
	}

	@:noDebug
	inline public function set(key:String, value:Vector<Float>):Void
		setUnsafe(__hashKey(key), value);

	@:noDebug
	public function get(key:String):Vector<Float>
		return getUnsafe(__hashKey(key));

	@:noDebug
	inline public function getUnsafe(id:Int):Vector<Float>
		return vector.get(id);

	@:noDebug
	inline public function setUnsafe(id:Int, value:Vector<Float>):Void
		vector.set(id, value);
}
