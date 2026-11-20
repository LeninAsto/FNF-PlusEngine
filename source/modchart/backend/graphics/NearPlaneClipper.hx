package modchart.backend.graphics;

import modchart.backend.math.Vector3;
import modchart.backend.math.View3D;
import openfl.Vector;

final class NearPlaneClipper {
	final x:Array<Float> = [0, 0, 0, 0];
	final y:Array<Float> = [0, 0, 0, 0];
	final z:Array<Float> = [0, 0, 0, 0];
	final u:Array<Float> = [0, 0, 0, 0];
	final v:Array<Float> = [0, 0, 0, 0];
	final point:Vector3 = new Vector3();

	public function new() {}

	public function clipQuad(view:View3D, world:Vector<Float>, distances:Vector<Float>, uv:Vector<Float>, quad:Int,
		vertices:Vector<Float>, uvt:Vector<Float>, hold:Bool):Bool {
		final vertexOffset = quad * 4;
		final uvOffset = quad * 12;
		final resultOffset = quad * 8;
		var first = clipTriangle(view, world, distances, uv, vertexOffset, uvOffset, 0, 1, hold ? 3 : 2,
			vertices, uvt, resultOffset, hold);
		var second = clipTriangle(view, world, distances, uv, vertexOffset, uvOffset, hold ? 0 : 1, hold ? 2 : 3,
			hold ? 3 : 2, vertices, uvt, resultOffset + 4, hold);
		return first || second;
	}

	private function clipTriangle(view:View3D, world:Vector<Float>, distances:Vector<Float>, uv:Vector<Float>,
		vertexOffset:Int, uvOffset:Int, a:Int, b:Int, c:Int, vertices:Vector<Float>, uvt:Vector<Float>, out:Int, hold:Bool):Bool {
		var count = 0;
		var prev = c;
		for (i in 0...3) {
			final cur = i == 0 ? a : (i == 1 ? b : c);
			final d0 = distances[vertexOffset + prev];
			final d1 = distances[vertexOffset + cur];
			if ((d0 >= 0) != (d1 >= 0)) {
				final t = d0 / (d0 - d1);
				write(world, uv, vertexOffset, uvOffset, prev, cur, t, count++);
			}
			if (d1 >= 0)
				write(world, uv, vertexOffset, uvOffset, cur, cur, 0, count++);
			prev = cur;
		}
		if (count < 3) {
			for (i in 0...4) {
				vertices[(out + i) * 2] = 0;
				vertices[(out + i) * 2 + 1] = 0;
				uvt[(out + i) * 3] = 0;
				uvt[(out + i) * 3 + 1] = 0;
				uvt[(out + i) * 3 + 2] = 1;
			}
			return false;
		}
		for (i in 0...4) {
			final k = i < count ? i : count - 1;
			point.setTo(x[k], y[k], z[k]);
			view.transformVector(point);
			vertices[(out + i) * 2] = point.x;
			vertices[(out + i) * 2 + 1] = point.y;
			uvt[(out + i) * 3] = u[k];
			uvt[(out + i) * 3 + 1] = v[k];
			uvt[(out + i) * 3 + 2] = hold ? 1 : 1 / Math.max(0.0001, point.z);
		}
		return true;
	}

	private inline function write(world:Vector<Float>, uv:Vector<Float>, base:Int, uvBase:Int,
		from:Int, to:Int, t:Float, out:Int):Void {
		final a = (base + from) * 3;
		final b = (base + to) * 3;
		final ua = uvBase + from * 3;
		final ub = uvBase + to * 3;
		x[out] = world[a] + (world[b] - world[a]) * t;
		y[out] = world[a + 1] + (world[b + 1] - world[a + 1]) * t;
		z[out] = world[a + 2] + (world[b + 2] - world[a + 2]) * t;
		u[out] = uv[ua] + (uv[ub] - uv[ua]) * t;
		v[out] = uv[ua + 1] + (uv[ub + 1] - uv[ua + 1]) * t;
	}

	public static function indices(quads:Int):Vector<Int> {
		final result = new Vector<Int>(quads * 12, true);
		for (quad in 0...quads) for (triangle in 0...2) {
			final vertex = quad * 8 + triangle * 4;
			final index = quad * 12 + triangle * 6;
			result[index] = vertex;
			result[index + 1] = vertex + 1;
			result[index + 2] = vertex + 2;
			result[index + 3] = vertex;
			result[index + 4] = vertex + 2;
			result[index + 5] = vertex + 3;
		}
		return result;
	}
}

