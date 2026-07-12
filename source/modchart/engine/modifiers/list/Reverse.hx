package modchart.engine.modifiers.list;

import flixel.math.FlxMath;
import modchart.backend.core.ModifierParameters;
import modchart.backend.util.ModchartUtil;

// Default modifier
// Handles scroll speed, scroll angle and reverse modifiers
class Reverse extends Modifier {
	public static inline var DEFAULT_SPAWN_TIME:Float = 2000;

	// Pre-computed hashed IDs for all lane-specific percent keys. Avoids Std.string(lane) allocation in hot path.
	var _splitID:Int;
	var _alternateID:Int;
	var _crossID:Int;
	var _reverseID:Int;
	var _reverseIDs:Array<Int>;
	var _unboundedReverseID:Int;
	var _centeredID:Int;
	var _xmodID:Int;
	var _randomSpeedID:Int;
	var _xmodIDs:Array<Int>;
	var _scrollAngleXID:Int;
	var _scrollAngleYID:Int;
	var _scrollAngleZID:Int;
	var _scrollAngleXIDs:Array<Int>;
	var _scrollAngleYIDs:Array<Int>;
	var _scrollAngleZIDs:Array<Int>;
	var _curvedScrollPeriodID:Int;
	var _curvedScrollXID:Int;
	var _curvedScrollYID:Int;
	var _curvedScrollZID:Int;
	var _spawnTimeID:Int;
	var _curvedScrollXIDs:Array<Int>;
	var _curvedScrollYIDs:Array<Int>;
	var _curvedScrollZIDs:Array<Int>;

	public function new(pf) {
		super(pf);

		setPercent('xmod', 1, -1);

		final maxKeys = 16;
		_splitID = findID('split');
		_alternateID = findID('alternate');
		_crossID = findID('cross');
		_reverseID = findID('reverse');
		_unboundedReverseID = findID('unboundedReverse');
		_centeredID = findID('centered');
		_xmodID = findID('xmod');
		_randomSpeedID = findID('randomspeed');
		_scrollAngleXID = findID('scrollAngleX');
		_scrollAngleYID = findID('scrollAngleY');
		_scrollAngleZID = findID('scrollAngleZ');
		_curvedScrollPeriodID = findID('curvedScrollPeriod');
		_curvedScrollXID = findID('curvedScrollX');
		_curvedScrollYID = findID('curvedScrollY');
		_curvedScrollZID = findID('curvedScrollZ');
		_spawnTimeID = findID('spawnTime');

		_reverseIDs = [for (i in 0...maxKeys) findID('reverse' + i)];
		_xmodIDs = [for (i in 0...maxKeys) findID('xmod' + i)];
		_scrollAngleXIDs = [for (i in 0...maxKeys) findID('scrollAngleX' + i)];
		_scrollAngleYIDs = [for (i in 0...maxKeys) findID('scrollAngleY' + i)];
		_scrollAngleZIDs = [for (i in 0...maxKeys) findID('scrollAngleZ' + i)];
		_curvedScrollXIDs = [for (i in 0...maxKeys) findID('curvedScrollX' + i)];
		_curvedScrollYIDs = [for (i in 0...maxKeys) findID('curvedScrollY' + i)];
		_curvedScrollZIDs = [for (i in 0...maxKeys) findID('curvedScrollZ' + i)];
	}

	public inline function getSpawnTime(player:Int = 0):Float {
		final value = getUnsafe(_spawnTimeID, player);
		return value > 0 ? value : DEFAULT_SPAWN_TIME;
	}

	public function getReverseValue(dir:Int, player:Int) {
		var kNum = getKeyCount();
		var val:Float = 0;
		if (dir >= Math.floor(kNum * 0.5))
			val = val + getUnsafe(_splitID, player);

		if ((dir % 2) == 1)
			val = val + getUnsafe(_alternateID, player);

		var first = kNum * 0.25;
		var last = kNum - 1 - first;

		if (dir >= first && dir <= last)
			val = val + getUnsafe(_crossID, player);

		val = val + getUnsafe(_reverseID, player) + getUnsafe(_reverseIDs[dir], player);

		if (getUnsafe(_unboundedReverseID, player) == 0) {
			val %= 2;
			if (val > 1)
				val = 2 - val;
		}

		// downscroll
		if (Adapter.instance.getDownscroll())
			val = 1 - val;
		return val;
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		var player = params.player;
		var initialY = Adapter.instance.getDefaultReceptorY(params.lane, player) + ARROW_SIZEDIV2;
		var reversePerc = getReverseValue(params.lane, player);
		var shift = FlxMath.lerp(initialY, HEIGHT - initialY, reversePerc);

		var centerPercent = getUnsafe(_centeredID, params.player);
		shift = FlxMath.lerp(shift, (HEIGHT * 0.5) - ARROW_SIZEDIV2, centerPercent);

		var distance = params.distance;

		distance *= Adapter.instance.getCurrentScrollSpeed();

		// Reuse curPos as a scroll accumulator to avoid allocating a new Vector3.
		// Save original x/z, then use them as the scroll start (0,lerped,0).
		var origX = curPos.x;
		var origZ = curPos.z;
		curPos.x = 0;
		curPos.y = FlxMath.lerp(distance, -distance, reversePerc);
		curPos.z = 0;

		applyScrollMods(curPos, params);

		curPos.x = origX + curPos.x;
		curPos.y = shift + curPos.y;
		curPos.z = origZ + curPos.z;

		return curPos;
	}

	// Modifies scroll in-place
	function applyScrollMods(scroll:Vector3, params:ModifierParameters) {
		var player = params.player;
		var lane = params.lane;
		var angleX = 0.;
		var angleY = 0.;
		var angleZ = 0.;

		// Speed (no string allocation)
		scroll.y = scroll.y * (getUnsafe(_xmodID, player) + getUnsafe(_xmodIDs[lane], player));

		final randomSpeed = Math.max(0, getUnsafe(_randomSpeedID, player));
		if (randomSpeed > 0 && params.distance > 0)
		{
			final randomOffset = (__stableRandom(params.sourceTime, lane, player) * 2) - 1;
			final randomMultiplier = Math.max(0.05, 1 + (randomOffset * randomSpeed));
			scroll.y *= randomMultiplier;
		}

		// Main
		angleX = angleX + getUnsafe(_scrollAngleXID, player) + getUnsafe(_scrollAngleXIDs[lane], player);
		angleY = angleY + getUnsafe(_scrollAngleYID, player) + getUnsafe(_scrollAngleYIDs[lane], player);
		angleZ = angleZ + getUnsafe(_scrollAngleZID, player) + getUnsafe(_scrollAngleZIDs[lane], player);

		// Curved
		final shiftCurved:Float = params.distance * 0.25 * (1 + getUnsafe(_curvedScrollPeriodID, player));

		angleX = angleX + shiftCurved * (getUnsafe(_curvedScrollXID, player) + getUnsafe(_curvedScrollXIDs[lane], player));
		angleY = angleY + shiftCurved * (getUnsafe(_curvedScrollYID, player) + getUnsafe(_curvedScrollYIDs[lane], player));
		angleZ = angleZ + shiftCurved * (getUnsafe(_curvedScrollZID, player) + getUnsafe(_curvedScrollZIDs[lane], player));

		// angleY doesnt do anything if angleX and angleZ are disabled
		if (angleX == 0 && angleZ == 0)
			return;

		// rotate3DVector allocates internally; only call when actually needed
		var rotated = ModchartUtil.rotate3DVector(scroll, angleX, angleY, angleZ);
		scroll.x = rotated.x;
		scroll.y = rotated.y;
		scroll.z = rotated.z;
	}

	inline function __stableRandom(sourceTime:Float, lane:Int, player:Int):Float {
		final seed = (sourceTime * 0.001 * 12.9898) + (lane * 78.233) + (player * 37.719);
		return Math.abs(sin(seed) * 43758.5453123) % 1;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
