package modchart.backend.util;

import haxe.ds.Vector;

class SortUtil {
	@:pure
	@:noDebug
	inline public static function nullSort<T:Dynamic>(vector:Vector<T>, func:(T, T) -> Int):Vector<T> {
		vector.sort((a, b) -> {
			if (a == null || b == null)
				return 0;
			return func(a, b);
		});

		return vector;
	}
}