package backend3D;

import backend3D.SM3DData.SM3DVec3;

class SMCoordinateConverter
{
	/**
	 * StepMania/NotITG charts usually treat -Z as distance into the screen.
	 * Plus software meshes use +Z as forward distance so depth math stays positive.
	 */
	public static inline function stepmaniaToPlusWorld(point:SM3DVec3, scale:Float = 1):SM3DVec3
	{
		return new SM3DVec3(point.x * scale, point.y * scale, -point.z * scale);
	}

	/**
	 * Away3D is Y-up, while NotITG model scripts commonly use negative Y for up.
	 */
	public static inline function stepmaniaToAway3D(point:SM3DVec3, scale:Float = 1):SM3DVec3
	{
		return new SM3DVec3(point.x * scale, -point.y * scale, -point.z * scale);
	}

	public static function projectPlusWorld(point:SM3DVec3, camera:SM3DVec3, originX:Float, originY:Float, focalLength:Float = 700,
			nearClip:Float = 1):SM3DProjectedPoint
	{
		var dz = (point.z - camera.z);
		var depth = Math.max(nearClip, focalLength + dz);
		var scale = focalLength / depth;
		return new SM3DProjectedPoint(originX + (point.x - camera.x) * scale, originY + (point.y - camera.y) * scale, depth, scale);
	}
}

class SM3DProjectedPoint
{
	public var x:Float;
	public var y:Float;
	public var depth:Float;
	public var scale:Float;

	public function new(x:Float, y:Float, depth:Float, scale:Float)
	{
		this.x = x;
		this.y = y;
		this.depth = depth;
		this.scale = scale;
	}
}
