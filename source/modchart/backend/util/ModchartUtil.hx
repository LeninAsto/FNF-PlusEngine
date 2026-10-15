package modchart.backend.util;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import haxe.ds.Vector;
import openfl.Vector as OFLVector;
import modchart.engine.events.Event;
import modchart.engine.events.types.AddEvent;
import modchart.engine.events.types.EaseEvent;
import openfl.geom.Matrix3D;

using StringTools;

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:keep class ModchartUtil {
	// Preserve atlas frame rotation for sprite-sheet packer compatibility.
	@:pure
	inline public static function getFrameAngle(spr:FlxSprite):Float {
		// return switch (spr.frame.angle) {
		// 	case ANGLE_90: 90;
		// 	case ANGLE_270 | ANGLE_NEG_90: 270;
		// 	default: 0; // ANGLE_0d
		// }
		return cast spr.frame.angle; // We can just do this, prevents an unused case warning too!
	}

	@:pure
	inline public static function resolveCameras(playfield:modchart.engine.PlayField, item:FlxSprite, ?filtered:Array<FlxCamera>):Array<FlxCamera> {
		@:privateAccess
		var playfieldCameras = playfield._cameras;

		@:privateAccess
		var cameras = item._cameras;

		if (filtered == null)
			filtered = [];
		else
			filtered.resize(0);
		if (cameras != null)
		{
			for (camera in cameras)
			{
				if (camera != null)
					filtered.push(camera);
			}
		}

		if (filtered.length == 0 && playfieldCameras != null)
		{
			for (camera in playfieldCameras)
			{
				if (camera != null)
					filtered.push(camera);
			}
		}

		if (filtered.length == 0)
		{
			final arrowCameras = Adapter.instance.getArrowCamera();
			if (arrowCameras != null)
			{
				for (camera in arrowCameras)
				{
					if (camera != null)
						filtered.push(camera);
				}
			}
		}

		if (filtered.length == 0 && FlxG.cameras.list != null)
		{
			for (camera in FlxG.cameras.list)
			{
				if (camera != null)
					filtered.push(camera);
			}
		}

		return filtered;
	}

	inline public static function findEntryFrom(event:Event) {
		final possibleLastEvent = event.parent.getLastEventBefore(event);

		var entryPerc = 0.;

		if (possibleLastEvent != null) {
			final evType = possibleLastEvent.getType();
			if (evType == EASE) {
				var castedEvent:EaseEvent = cast possibleLastEvent;
				@:privateAccess
				final from = castedEvent.entryPerc != null ? castedEvent.entryPerc : event.getModPercent(event.name, event.player);
				entryPerc = FlxMath.lerp(from, castedEvent.target, castedEvent.ease(1));
			} else if (evType == ADD) {
				var castedEvent:AddEvent = cast possibleLastEvent;
				@:privateAccess
				final from = castedEvent.entryPerc != null ? castedEvent.entryPerc : event.getModPercent(event.name, event.player);
				entryPerc = FlxMath.lerp(from, from + castedEvent.addAmount, castedEvent.ease(1));
			} else {
				entryPerc = possibleLastEvent.target;
			}
		} else {
			entryPerc = event.getModPercent(event.name, event.player);
		}

		return entryPerc;
	}

	@:pure @:noDebug
	inline public static function rotate3DVector(vec:Vector3, angleX:Float, angleY:Float, angleZ:Float):Vector3 {
		if (angleX == 0 && angleY == 0 && angleZ == 0)
			return vec;

		final RAD = FlxAngle.TO_RAD;
		final quatX = Quaternion.fromAxisAngle(Vector3D.X_AXIS, angleX * RAD);
		final quatY = Quaternion.fromAxisAngle(Vector3D.Y_AXIS, angleY * RAD);
		final quatZ = Quaternion.fromAxisAngle(Vector3D.Z_AXIS, angleZ * RAD);

		// this is confusing, X_Y_Z is done like this:
		// OUT = Z;
		// OUT *= Y
		// OUT *= X
		// But it feels wrong, so investigate this
		switch (Config.ROTATION_ORDER) {
			case Z_X_Y:
				quatY.multiplyInPlace(quatX);
				quatY.multiplyInPlace(quatZ);
				return quatY.rotateVector(vec);
			case X_Y_Z:
				quatZ.multiplyInPlace(quatY);
				quatZ.multiplyInPlace(quatX);
				return quatZ.rotateVector(vec);
			case X_Z_Y:
				quatY.multiplyInPlace(quatZ);
				quatY.multiplyInPlace(quatX);
				return quatY.rotateVector(vec);
			case Y_X_Z:
				quatZ.multiplyInPlace(quatX);
				quatZ.multiplyInPlace(quatY);
				return quatZ.rotateVector(vec);
			case Y_Z_X:
				quatX.multiplyInPlace(quatZ);
				quatX.multiplyInPlace(quatY);
				return quatX.rotateVector(vec);
			case Z_Y_X:
				quatX.multiplyInPlace(quatY);
				quatX.multiplyInPlace(quatZ);
				return quatX.rotateVector(vec);
			case X_Y_X:
				quatX.multiplyInPlace(quatY);
				quatX.multiplyInPlace(quatX);
				return quatX.rotateVector(vec);
			case X_Z_X:
				quatX.multiplyInPlace(quatZ);
				quatX.multiplyInPlace(quatX);
				return quatX.rotateVector(vec);
			case Y_X_Y:
				quatY.multiplyInPlace(quatX);
				quatY.multiplyInPlace(quatY);
				return quatY.rotateVector(vec);
			case Y_Z_Y:
				quatY.multiplyInPlace(quatZ);
				quatY.multiplyInPlace(quatY);
				return quatY.rotateVector(vec);
			case Z_X_Z:
				quatZ.multiplyInPlace(quatX);
				quatZ.multiplyInPlace(quatZ);
				return quatZ.rotateVector(vec);
			case Z_Y_Z:
				quatZ.multiplyInPlace(quatY);
				quatZ.multiplyInPlace(quatZ);
				return quatZ.rotateVector(vec);
		}
	}

	@:pure @:noDebug
	inline public static function rotate3DVectorInto(vec:Vector3, angleX:Float, angleY:Float, angleZ:Float, out:Vector3):Vector3 {
		return Quaternion.rotateEulerInto(vec, angleX, angleY, angleZ, out);
	}

	inline static public function getHoldUVT(arrow:FlxSprite, subs:Int):OFLVector<Float> {
		subs = Std.int(Math.max(1, subs));
		var frameAngle = -ModchartUtil.getFrameAngle(arrow);

		var uv = new OFLVector<Float>(12 * subs, true);

		var frameUV = arrow.frame.uv;

		// FlxFrame.uv intentionally stores right/bottom in width/height.
		// FlxRect.right/bottom would add x/y a second time.
		var left = frameUV.x;
		var top = frameUV.y;
		var right = frameUV.width;
		var bottom = frameUV.height;

		var frameWidth = right - left;
		var frameHeight = bottom - top;

		var subDivided = 1.0 / subs;

		// if the frame doesnt have rotation, we skip the rotated uv shit
		if ((frameAngle % 360) == 0) {
			for (curSub in 0...subs) {
				var uvOffset = subDivided * curSub;
				var subIndex = curSub * 12;

				uv[subIndex] = left; // U
				uv[subIndex + 1] = top + uvOffset * frameHeight; // V
				uv[subIndex + 2] = 1; // T

				uv[subIndex + 3] = right;
				uv[subIndex + 4] = top + uvOffset * frameHeight;
				uv[subIndex + 5] = 1;

				uv[subIndex + 6] = left;
				uv[subIndex + 7] = top + (uvOffset + subDivided) * frameHeight;
				uv[subIndex + 8] = 1;

				uv[subIndex + 9] = right;
				uv[subIndex + 10] = top + (uvOffset + subDivided) * frameHeight;
				uv[subIndex + 11] = 1;
			}
			return uv;
		}

		var angleRad = frameAngle * (Math.PI / 180);
		var cosA = ModchartUtil.cos(angleRad);
		var sinA = ModchartUtil.sin(angleRad);

		var uCenter = left + frameWidth * .5;
		var vCenter = top + frameHeight * .5;

		for (curSub in 0...subs) {
			var uvOffset = subDivided * curSub;
			var subIndex = curSub * 12;
			var vTop = top + uvOffset * frameHeight;
			var vBottom = top + (uvOffset + subDivided) * frameHeight;

			writeRotatedUV(uv, subIndex, left, vTop, uCenter, vCenter, cosA, sinA);
			writeRotatedUV(uv, subIndex + 3, right, vTop, uCenter, vCenter, cosA, sinA);
			writeRotatedUV(uv, subIndex + 6, left, vBottom, uCenter, vCenter, cosA, sinA);
			writeRotatedUV(uv, subIndex + 9, right, vBottom, uCenter, vCenter, cosA, sinA);
		}

		return uv;
	}

	private static inline function writeRotatedUV(uv:OFLVector<Float>, index:Int, u:Float, v:Float, centerU:Float, centerV:Float,
			cosA:Float, sinA:Float):Void {
		final x = u - centerU;
		final y = v - centerV;
		uv[index] = x * cosA - y * sinA + centerU;
		uv[index + 1] = x * sinA + y * cosA + centerV;
		uv[index + 2] = 1;
	}

	/**
		map should be. [
			top left x,  top left y,
			top right x, top right y,
			bot left x,  bot left y
			bot right x, bot right y
		]
	 */
	// gonna keep this shits inline cus are basic functions

	public static inline function getHalfPos():Vector3 {
		return new Vector3(Manager.ARROW_SIZEDIV2, Manager.ARROW_SIZEDIV2, 0, 0);
	}

	@:pure
	public static inline function sign(x:Int)
		return x == 0 ? 0 : x > 0 ? 1 : -1;

	@:pure
	public static inline function clamp(n:Float, l:Float, h:Float) {
		if (n < l)
			return l;
		if (n > h)
			return h;
		return n;
	}

	@:pure
	public static inline function sin(num:Float)
		return FlxMath.fastSin(num);

	@:pure
	public static inline function cos(num:Float)
		return FlxMath.fastCos(num);

	@:pure
	public static inline function tan(num:Float)
		return sin(num) / cos(num);

	@:pure
	@:deprecated("Use Vector3.interpolate instead.")
	inline public static function lerpVector3D(start:Vector3, end:Vector3, ratio:Float) {
		if (ratio == 0)
			return start;
		if (ratio == 1)
			return end;

		final diff = end.subtract(start);
		diff.scaleBy(ratio);

		return start.add(diff);
	}

	public static function coolTextFile(path:String):Array<String> {
		var trim:String;
		return [
			for (line in openfl.utils.Assets.getText(path).split("\n"))
				if ((trim = line.trim()) != "" && !trim.startsWith("#")) trim
		];
	}
}
