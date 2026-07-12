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
}
