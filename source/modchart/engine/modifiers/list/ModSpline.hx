package modchart.engine.modifiers.list;

import flixel.math.FlxMath;
import modchart.backend.core.ModifierParameters;

class ModSpline extends Modifier {
	static inline final MAX_POINTS:Int = 40;
	static inline final MAX_LANES:Int = 16;
	static inline final AXIS_COUNT:Int = 3;
	static final AXES:Array<String> = ['x', 'y', 'z'];

	var activeID:Int;
	var magnitudeIDs:Array<Array<Int>>;
	var offsetIDs:Array<Array<Int>>;
	var laneMagnitudeIDs:Array<Array<Array<Int>>>;
	var laneOffsetIDs:Array<Array<Array<Int>>>;
	var resetIDs:Array<Int>;
	var laneResetIDs:Array<Array<Int>>;
	var typeIDs:Array<Int>;
	var xmodID:Int;
	var xmodLaneIDs:Array<Int>;

	public function new(pf) {
		super(pf);

		activeID = findID('modSpline');
		magnitudeIDs = [];
		offsetIDs = [];
		laneMagnitudeIDs = [];
		laneOffsetIDs = [];
		resetIDs = [];
		laneResetIDs = [];
		typeIDs = [];

		for (axis in AXES) {
			magnitudeIDs.push([for (point in 0...MAX_POINTS) findID('spline' + axis + point)]);
			offsetIDs.push([for (point in 0...MAX_POINTS) findID('spline' + axis + 'offset' + point)]);
			laneMagnitudeIDs.push([for (lane in 0...MAX_LANES) [for (point in 0...MAX_POINTS) findID('spline' + lane + axis + point)]]);
			laneOffsetIDs.push([for (lane in 0...MAX_LANES) [for (point in 0...MAX_POINTS) findID('spline' + lane + axis + 'offset' + point)]]);
			resetIDs.push(findID('spline' + axis + 'reset'));
			laneResetIDs.push([for (lane in 0...MAX_LANES) findID('spline' + lane + axis + 'reset')]);
			typeIDs.push(findID('spline' + axis + 'type'));
		}

		xmodID = findID('xmod');
		xmodLaneIDs = [for (lane in 0...MAX_LANES) findID('xmod' + lane)];
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		final lane = params.lane;
		final player = params.player;
		final xmod = isValidLane(lane) ? getUnsafeLaneMultiply(xmodID, xmodLaneIDs[lane], player) : getUnsafe(xmodID, player);
		final scrollDistance = Math.abs(params.distance * getScrollSpeed() * xmod);

		curPos.x += sampleAxis(0, lane, player, scrollDistance);
		curPos.y += sampleAxis(1, lane, player, scrollDistance);
		curPos.z += sampleAxis(2, lane, player, scrollDistance);

		return curPos;
	}

	function sampleAxis(axis:Int, lane:Int, player:Int, distance:Float):Float {
		consumeResets(axis, lane, player);

		var lastPosition = 0.0;
		var lastMagnitude = 0.0;
		var foundPoint = false;
		final interpolationType = getInterpolationType(axis, player);

		for (point in 0...MAX_POINTS) {
			final laneUsable = hasUsableLanePoint(axis, lane, point, player);
			final globalUsable = hasUsableGlobalPoint(axis, point, player);

			if (!laneUsable && !globalUsable) {
				if (point > 0 && isTerminatorPoint(axis, lane, point, player))
					break;
				continue;
			}

			final position = readPointOffset(axis, lane, point, player, laneUsable) * ARROW_SIZE / 100;
			final magnitude = readPointMagnitude(axis, lane, point, player, laneUsable) * ARROW_SIZE / 100;
			foundPoint = true;

			if (distance <= position) {
				if (position <= lastPosition)
					return magnitude;

				final ratio = FlxMath.bound((distance - lastPosition) / (position - lastPosition), 0, 1);
				return FlxMath.lerp(lastMagnitude, magnitude, easeSplineRatio(ratio, interpolationType));
			}

			lastPosition = position;
			lastMagnitude = magnitude;
		}

		return foundPoint ? lastMagnitude : 0;
	}

	inline function isValidLane(lane:Int):Bool
		return lane >= 0 && lane < MAX_LANES;

	inline function hasUsableGlobalPoint(axis:Int, point:Int, player:Int):Bool {
		final mag = getUnsafe(magnitudeIDs[axis][point], player);
		final off = getUnsafe(offsetIDs[axis][point], player);
		return (mag != 0 || off != 0)
			&& (hasUnsafeForPlayer(magnitudeIDs[axis][point], player) || hasUnsafeForPlayer(offsetIDs[axis][point], player));
	}

	inline function hasUsableLanePoint(axis:Int, lane:Int, point:Int, player:Int):Bool {
		if (!isValidLane(lane))
			return false;

		final magID = laneMagnitudeIDs[axis][lane][point];
		final offID = laneOffsetIDs[axis][lane][point];
		final mag = getUnsafe(magID, player);
		final off = getUnsafe(offID, player);
		return (mag != 0 || off != 0) && (hasUnsafeForPlayer(magID, player) || hasUnsafeForPlayer(offID, player));
	}

	function isTerminatorPoint(axis:Int, lane:Int, point:Int, player:Int):Bool {
		if (isValidLane(lane)) {
			final laneMagID = laneMagnitudeIDs[axis][lane][point];
			final laneOffID = laneOffsetIDs[axis][lane][point];
			if ((hasUnsafeForPlayer(laneMagID, player) || hasUnsafeForPlayer(laneOffID, player))
				&& getUnsafe(laneMagID, player) == 0
				&& getUnsafe(laneOffID, player) == 0)
				return true;
		}

		return (hasUnsafeForPlayer(magnitudeIDs[axis][point], player) || hasUnsafeForPlayer(offsetIDs[axis][point], player))
			&& getUnsafe(magnitudeIDs[axis][point], player) == 0
			&& getUnsafe(offsetIDs[axis][point], player) == 0;
	}

	inline function readPointMagnitude(axis:Int, lane:Int, point:Int, player:Int, useLane:Bool):Float
		return useLane ? getUnsafe(laneMagnitudeIDs[axis][lane][point], player) : getUnsafe(magnitudeIDs[axis][point], player);

	inline function readPointOffset(axis:Int, lane:Int, point:Int, player:Int, useLane:Bool):Float
		return useLane ? getUnsafe(laneOffsetIDs[axis][lane][point], player) : getUnsafe(offsetIDs[axis][point], player);

	function consumeResets(axis:Int, lane:Int, player:Int):Void {
		if (getUnsafe(resetIDs[axis], player) != 0) {
			clearAxis(axis, player);
			setUnsafe(resetIDs[axis], 0, player);
		}

		if (isValidLane(lane) && getUnsafe(laneResetIDs[axis][lane], player) != 0) {
			clearLane(axis, lane, player);
			setUnsafe(laneResetIDs[axis][lane], 0, player);
		}
	}

	function clearAxis(axis:Int, player:Int):Void {
		for (point in 0...MAX_POINTS) {
			setUnsafe(magnitudeIDs[axis][point], 0, player);
			setUnsafe(offsetIDs[axis][point], 0, player);
		}

		for (lane in 0...MAX_LANES)
			clearLane(axis, lane, player);
	}

	function clearLane(axis:Int, lane:Int, player:Int):Void {
		for (point in 0...MAX_POINTS) {
			setUnsafe(laneMagnitudeIDs[axis][lane][point], 0, player);
			setUnsafe(laneOffsetIDs[axis][lane][point], 0, player);
		}
	}

	inline function getInterpolationType(axis:Int, player:Int):Int {
		final rawType = getUnsafe(typeIDs[axis], player);
		if (rawType >= 150 || rawType == 2)
			return 2;
		if (rawType >= 50 || rawType == 1)
			return 1;
		return 0;
	}

	inline function easeSplineRatio(ratio:Float, interpolationType:Int):Float {
		return switch (interpolationType) {
			case 1:
				(1 - Math.cos(ratio * Math.PI)) * 0.5;
			case 2:
				ratio * ratio * (3 - (2 * ratio));
			default:
				ratio;
		}
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return getUnsafe(activeID, params.player) != 0;

	override public function isActive(player:Int):Bool
		return getUnsafe(activeID, player) != 0;

	override public function allowOnStraightHolds():Bool
		return false;
}
