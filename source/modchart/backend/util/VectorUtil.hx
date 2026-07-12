package modchart.backend.util;

import openfl.Vector;

class VectorUtil {
	public static function toIntFlash<T:Int>(stdv:haxe.ds.Vector<T>) {
		var _ = new Vector<T>(stdv.length, true);
		for (i in 0...stdv.length) {
			_[i] = stdv[i];
		}

		return _;
	}

	public static function toFloatFlash<T:Float>(stdv:haxe.ds.Vector<T>) {
		var _ = new Vector<T>(stdv.length, true);
		for (i in 0...stdv.length) {
			_[i] = stdv[i];
		}

		return _;
	}
}