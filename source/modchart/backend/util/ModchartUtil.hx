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
	// pain (we need this if we want support for sprite sheet packer)
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
	inline public static function resolveCameras(playfield:modchart.engine.PlayField, item:FlxSprite):Array<FlxCamera> {
		@:privateAccess
		var playfieldCameras = #if (flixel >= "5.7.0") playfield.getCameras() #else playfield._cameras #end;

		@:privateAccess
		var cameras = #if (flixel >= "5.7.0") item.getCameras() #else item._cameras #end;

		// fallback to def arrow cameras
		if (cameras == null || cameras.length == 0) {
			if (playfieldCameras == null || playfieldCameras.length == 0)
				cameras = Adapter.instance.getArrowCamera();
			else
				cameras = playfieldCameras;
		}

		if (cameras == null || cameras.length == 0)
			cameras = FlxG.cameras.list;

		if (cameras == null || cameras.length == 0)
			return [];

		var filtered:Array<FlxCamera> = [];
		for (camera in cameras)
		{
			if (camera != null)
				filtered.push(camera);
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
				entryPerc = (castedEvent.ease(1) * castedEvent.target);
			} else if (evType == ADD) {
				var castedEvent:AddEvent = cast possibleLastEvent;
				@:privateAccess
				entryPerc = (castedEvent.entryPerc + (castedEvent.ease(1) * castedEvent.addAmount));
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

	inline static public function getHoldUVT(arrow:FlxSprite, subs:Int):OFLVector<Float> {
		var frameAngle = -ModchartUtil.getFrameAngle(arrow);

		var uv = new OFLVector<Float>(12 * subs, true);

		var frameUV = arrow.frame.uv;

		// i do not like this
		// but i was suggested to do this instead by theo -swordcube
		var left = #if (flixel >= "6.1.0") frameUV.left #else frameUV.x #end;
		var right = #if (flixel >= "6.1.0") frameUV.right #else frameUV.y #end;
		var top = #if (flixel >= "6.1.0") frameUV.top #else frameUV.width #end;
		var bottom = #if (flixel >= "6.1.0") frameUV.bottom #else frameUV.height #end;

		var frameWidth = top - left;
		var frameHeight = bottom - right;

		var subDivided = 1.0 / subs;

		// if the frame doesnt have rotation, we skip the rotated uv shit
		if ((frameAngle % 360) == 0) {
			for (curSub in 0...subs) {
				var uvOffset = subDivided * curSub;
				var subIndex = curSub * 12;

				uv[subIndex] = left; // U
				uv[subIndex + 1] = right + uvOffset * frameHeight; // V
				uv[subIndex + 2] = 1; // T

				uv[subIndex + 3] = top;
				uv[subIndex + 4] = right + uvOffset * frameHeight;
				uv[subIndex + 5] = 1;

				uv[subIndex + 6] = left;
				uv[subIndex + 7] = right + (uvOffset + subDivided) * frameHeight;
				uv[subIndex + 8] = 1;

				uv[subIndex + 9] = top;
				uv[subIndex + 10] = right + (uvOffset + subDivided) * frameHeight;
				uv[subIndex + 11] = 1;
			}
			return uv;
		}

		var angleRad = frameAngle * (Math.PI / 180);
		var cosA = ModchartUtil.cos(angleRad);
		var sinA = ModchartUtil.sin(angleRad);

		var uCenter = left + frameWidth * .5;
		var vCenter = right + frameHeight * .5;

		// my brain is not braining anymore
		// i give up
		for (curSub in 0...subs) {
			var uvOffset = subDivided * curSub;
			var subIndex = curSub * 8;

			// uv coords before rotation
			var uvCoords = [
				[left, right + uvOffset * frameHeight], // tl
				[top, right + uvOffset * frameHeight], // tr
				[left, right + (uvOffset + subDivided) * frameHeight], // bl
				[top, right + (uvOffset + subDivided) * frameHeight] // br
			];

			// apply rotation
			for (i in 0...4) {
				var u = uvCoords[i][0] - uCenter; // x
				var v = uvCoords[i][1] - vCenter; // y

				var uRot = u * cosA - v * sinA;
				var vRot = u * sinA + v * cosA;

				var base = subIndex + i * 3;

				uv[base] = uRot + uCenter; // U
				uv[base + 1] = vRot + vCenter; // V
				uv[base + 2] = 1; // T
			}
		}

		return uv;
	}

	/**
		map should be. [
			top left x,  top left y,
			top right x, top right y,
			bot left x,  bot left y
			bot right x, bot right y
		]
	 */
	inline static public function appendUVRotation(map:Array<Float>, angle:Float) {
		return map;
	}

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
