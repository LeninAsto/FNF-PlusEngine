package scripting;

import flixel.FlxStrip;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;

@:keep
class ScriptDraw {
	public static function uploadQuads(strip:FlxStrip, vertices:Array<Float>, uvs:Array<Float>, quads:Int):Void {
		if (strip == null || vertices == null || uvs == null || quads <= 0) {
			if (strip != null)
				strip.visible = false;
			return;
		}

		var floats:Int = quads * 8;
		if (vertices.length < floats || uvs.length < floats) {
			strip.visible = false;
			return;
		}

		var v:DrawData<Float> = strip.vertices;
		var t:DrawData<Float> = strip.uvtData;
		var n:DrawData<Int> = strip.indices;

		if (v.length != floats)
			v.length = floats;
		if (t.length != floats)
			t.length = floats;

		for (i in 0...floats) {
			v[i] = vertices[i];
			t[i] = uvs[i];
		}

		var indexCount:Int = quads * 6;
		if (n.length != indexCount)
			n.length = indexCount;

		for (q in 0...quads) {
			var base:Int = q * 4;
			var at:Int = q * 6;

			n[at] = base;
			n[at + 1] = base + 1;
			n[at + 2] = base + 2;
			n[at + 3] = base;
			n[at + 4] = base + 2;
			n[at + 5] = base + 3;
		}

		strip.visible = true;
	}

	public static function clearStrip(strip:FlxStrip):Void {
		if (strip == null)
			return;

		strip.vertices.length = 0;
		strip.uvtData.length = 0;
		strip.indices.length = 0;
		strip.visible = false;
	}
}
