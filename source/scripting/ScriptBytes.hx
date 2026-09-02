package scripting;

@:keep
class ScriptBytes {
	public static function toIntArray(bytes:haxe.io.Bytes, start:Int = 0, length:Int = -1):Array<Int> {
		if (bytes == null)
			return [];

		var from:Int = start < 0 ? 0 : start;
		if (from > bytes.length)
			return [];

		var count:Int = length < 0 ? bytes.length - from : length;
		if (from + count > bytes.length)
			count = bytes.length - from;

		var out:Array<Int> = [];
		for (i in 0...count)
			out.push(bytes.get(from + i));
		return out;
	}

	public static function fixedName(bytes:haxe.io.Bytes, start:Int, width:Int):String {
		if (bytes == null || start < 0 || start + width > bytes.length)
			return '';

		var out:StringBuf = new StringBuf();
		for (i in 0...width) {
			var c:Int = bytes.get(start + i);
			if (c != 0)
				out.addChar(c);
		}
		return out.toString().toUpperCase();
	}
}
