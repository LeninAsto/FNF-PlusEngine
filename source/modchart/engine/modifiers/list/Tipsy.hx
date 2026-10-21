package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class Tipsy extends Modifier {
	var amountIDs:Array<Int>;
	var yID:Int;
	var baseSpeedID:Int;
	var baseOffsetID:Int;
	var speedIDs:Array<Int>;
	var offsetIDs:Array<Int>;
	var laneIDs:Array<Array<Int>>;

	public function new(pf) {
		super(pf);
		amountIDs = [findID('tipsyX'), findID('tipsy'), findID('tipsyZ')];
		yID = findID('tipsyY');
		baseSpeedID = findID('tipsySpeed');
		baseOffsetID = findID('tipsyOffset');
		speedIDs = [findID('tipsyXSpeed'), findID('tipsyYSpeed'), findID('tipsyZSpeed')];
		offsetIDs = [findID('tipsyXOffset'), findID('tipsyYOffset'), findID('tipsyZOffset')];
		laneIDs = [
			[for (lane in 0...16) findID('tipsyX' + lane)],
			[for (lane in 0...16) findID('tipsy' + lane)],
			[for (lane in 0...16) findID('tipsyZ' + lane)]
		];
	}

	inline function shift(params:ModifierParameters, axis:Int, amount:Float, baseSpeed:Float, baseOffset:Float):Float {
		final player = params.player;
		final speed = hasUnsafeForPlayer(speedIDs[axis], player) ? getUnsafe(speedIDs[axis], player) : baseSpeed;
		final offset = hasUnsafeForPlayer(offsetIDs[axis], player) ? getUnsafe(offsetIDs[axis], player) : baseOffset;
		return cos(params.songTime * 0.001 * ((speed * 1.2) + 1.2) + params.lane * ((offset * 1.8) + 1.8)) * ARROW_SIZE * .4 * amount;
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		final player = params.player;
		final lane = getLaneSlot(params.lane, laneIDs[0].length);
		final baseSpeed = getUnsafe(baseSpeedID, player);
		final baseOffset = getUnsafe(baseOffsetID, player);

		final xVal = getUnsafe(amountIDs[0], player) + getUnsafe(laneIDs[0][lane], player);
		final yVal = getUnsafe(amountIDs[1], player) + getUnsafe(yID, player) + getUnsafe(laneIDs[1][lane], player);
		final zVal = getUnsafe(amountIDs[2], player) + getUnsafe(laneIDs[2][lane], player);

		if (xVal == 0 && yVal == 0 && zVal == 0)
			return curPos;

		curPos.x += shift(params, 0, xVal, baseSpeed, baseOffset);
		curPos.y += shift(params, 1, yVal, baseSpeed, baseOffset);
		curPos.z += shift(params, 2, zVal, baseSpeed, baseOffset);
		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function isActive(player:Int):Bool
	{
		if (getUnsafe(amountIDs[0], player) != 0 || getUnsafe(amountIDs[1], player) != 0
			|| getUnsafe(amountIDs[2], player) != 0 || getUnsafe(yID, player) != 0) return true;
		for (axis in laneIDs) for (id in axis) if (getUnsafe(id, player) != 0) return true;
		return false;
	}

	override public function allowOnStraightHolds():Bool
		return false;
}
