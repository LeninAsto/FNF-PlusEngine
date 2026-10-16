package modchart.backend.math;

import modchart.backend.util.ModchartUtil;

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:publicFields
final class Quaternion {
	var x:Float;
	var y:Float;
	var z:Float;
	var w:Float;

	// This could be inline, to make local quaternions abstracted away
	function new(x:Float, y:Float, z:Float, w:Float) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}

	@:pure @:noDebug
	inline function multiply(q:Quaternion):Quaternion {
		return new Quaternion(w * q.x
			+ x * q.w
			+ y * q.z
			- z * q.y, w * q.y
			- x * q.z
			+ y * q.w
			+ z * q.x, w * q.z
			+ x * q.y
			- y * q.x
			+ z * q.w,
			w * q.w
			- x * q.x
			- y * q.y
			- z * q.z);
	}

	@:pure @:noDebug
	inline function multiplyInPlace(q:Quaternion):Void {
		var x = this.x;
		var y = this.y;
		var z = this.z;
		var w = this.w;

		this.x = w * q.x + x * q.w + y * q.z - z * q.y;
		this.y = w * q.y - x * q.z + y * q.w + z * q.x;
		this.z = w * q.z + x * q.y - y * q.x + z * q.w;
		this.w = w * q.w - x * q.x - y * q.y - z * q.z;
	}

	@:pure @:noDebug
	inline function multiplyInVector(v:Vector3):Quaternion {
		final vx = v.x, vy = v.y, vz = v.z, w = this.w;

		// @formatter:off
		return new Quaternion(
			w * vx + y * vz - z * vy,
			w * vy - x * vz + z * vx,
			w * vz + x * vy - y * vx,
			-x * vx - y * vy - z * vz
		);
		// @formatter:on
	}

	@:pure @:noDebug
	inline function multiplyInv(q:Quaternion):Vector3 {
		final qw = q.w, qx = q.x, qy = q.y, qz = q.z;
		final nx = -x, ny = -y, nz = -z, w = this.w;

		// @formatter:off
		return new Vector3(
			qw * nx + qx * w + qy * nz - qz * ny,
			qw * ny - qx * nz + qy * w + qz * nx,
			qw * nz + qx * ny - qy * nx + qz * w
		);
		// @formatter:on
	}

	@:pure @:noDebug
	inline function rotateVector(v:Vector3):Vector3 {
		var qVec = multiplyInVector(v);
		return multiplyInv(qVec);
	}

	static function fromAxisAngle(axis:Vector3, angleRad:Float):Quaternion {
		var sinHalfAngle = ModchartUtil.sin(angleRad * .5);
		var cosHalfAngle = ModchartUtil.cos(angleRad * .5);
		return new Quaternion(axis.x * sinHalfAngle, axis.y * sinHalfAngle, axis.z * sinHalfAngle, cosHalfAngle);
	}

	/** Rotates into a caller-owned vector without allocating temporary quaternions. */
	public static function rotateEulerInto(v:Vector3, angleX:Float, angleY:Float, angleZ:Float, out:Vector3):Vector3 {
		if (angleX == 0 && angleY == 0 && angleZ == 0) {
			out.setTo(v.x, v.y, v.z);
			return out;
		}

		final halfRad = flixel.math.FlxAngle.TO_RAD * 0.5;
		final sx = ModchartUtil.sin(angleX * halfRad), cx = ModchartUtil.cos(angleX * halfRad);
		final sy = ModchartUtil.sin(angleY * halfRad), cy = ModchartUtil.cos(angleY * halfRad);
		final sz = ModchartUtil.sin(angleZ * halfRad), cz = ModchartUtil.cos(angleZ * halfRad);

		var ax = 0.0, ay = 0.0, az = 0.0, aw = 1.0;
		var bx = 0.0, by = 0.0, bz = 0.0, bw = 1.0;
		var cxq = 0.0, cyq = 0.0, czq = 0.0, cwq = 1.0;
		var squarePair = false;
		switch (Config.ROTATION_ORDER) {
			case Z_X_Y: ax = 0; ay = sy; az = 0; aw = cy; bx = sx; by = 0; bz = 0; bw = cx; cxq = 0; cyq = 0; czq = sz; cwq = cz;
			case X_Y_Z: ax = 0; ay = 0; az = sz; aw = cz; bx = 0; by = sy; bz = 0; bw = cy; cxq = sx; cyq = 0; czq = 0; cwq = cx;
			case X_Z_Y: ax = 0; ay = sy; az = 0; aw = cy; bx = 0; by = 0; bz = sz; bw = cz; cxq = sx; cyq = 0; czq = 0; cwq = cx;
			case Y_X_Z: ax = 0; ay = 0; az = sz; aw = cz; bx = sx; by = 0; bz = 0; bw = cx; cxq = 0; cyq = sy; czq = 0; cwq = cy;
			case Y_Z_X: ax = sx; ay = 0; az = 0; aw = cx; bx = 0; by = 0; bz = sz; bw = cz; cxq = 0; cyq = sy; czq = 0; cwq = cy;
			case Z_Y_X: ax = sx; ay = 0; az = 0; aw = cx; bx = 0; by = sy; bz = 0; bw = cy; cxq = 0; cyq = 0; czq = sz; cwq = cz;
			case X_Y_X: ax = sx; ay = 0; az = 0; aw = cx; bx = 0; by = sy; bz = 0; bw = cy; squarePair = true;
			case X_Z_X: ax = sx; ay = 0; az = 0; aw = cx; bx = 0; by = 0; bz = sz; bw = cz; squarePair = true;
			case Y_X_Y: ax = 0; ay = sy; az = 0; aw = cy; bx = sx; by = 0; bz = 0; bw = cx; squarePair = true;
			case Y_Z_Y: ax = 0; ay = sy; az = 0; aw = cy; bx = 0; by = 0; bz = sz; bw = cz; squarePair = true;
			case Z_X_Z: ax = 0; ay = 0; az = sz; aw = cz; bx = sx; by = 0; bz = 0; bw = cx; squarePair = true;
			case Z_Y_Z: ax = 0; ay = 0; az = sz; aw = cz; bx = 0; by = sy; bz = 0; bw = cy; squarePair = true;
		}

		// q = a * b * c, matching the legacy multiplyInPlace order exactly.
		final qx = aw * bx + ax * bw + ay * bz - az * by;
		final qy = aw * by - ax * bz + ay * bw + az * bx;
		final qz = aw * bz + ax * by - ay * bx + az * bw;
		final qw = aw * bw - ax * bx - ay * by - az * bz;
		if (squarePair) { cxq = qx; cyq = qy; czq = qz; cwq = qw; }
		final rx = qw * cxq + qx * cwq + qy * czq - qz * cyq;
		final ry = qw * cyq - qx * czq + qy * cwq + qz * cxq;
		final rz = qw * czq + qx * cyq - qy * cxq + qz * cwq;
		final rw = qw * cwq - qx * cxq - qy * cyq - qz * czq;

		// q * v * inverse(q), expanded to scalars.
		final tx = 2 * (ry * v.z - rz * v.y);
		final ty = 2 * (rz * v.x - rx * v.z);
		final tz = 2 * (rx * v.y - ry * v.x);
		out.setTo(v.x + rw * tx + (ry * tz - rz * ty), v.y + rw * ty + (rz * tx - rx * tz), v.z + rw * tz + (rx * ty - ry * tx));
		return out;
	}
}
