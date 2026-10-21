package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;
import modchart.backend.util.ModchartUtil;

class Tornado extends Modifier {
	var amountIDs:Array<Int>;
	var laneIDs:Array<Array<Int>>;
	var periodIDs:Array<Int>;
	var offsetIDs:Array<Int>;

	public function new(pf) {
		super(pf);
		amountIDs = [findID('tornado'), findID('tornadoY'), findID('tornadoZ')];
		periodIDs = [findID('tornadoPeriod'), findID('tornadoYPeriod'), findID('tornadoZPeriod')];
		offsetIDs = [findID('tornadoOffset'), findID('tornadoYOffset'), findID('tornadoZOffset')];
		laneIDs = [
			[for (lane in 0...16) findID('tornado' + lane)],
			[for (lane in 0...16) findID('tornadoY' + lane)],
			[for (lane in 0...16) findID('tornadoZ' + lane)]
		];
	}

	override public function render(pos:Vector3, params:ModifierParameters) {
		final lane = getLaneSlot(params.lane, laneIDs[0].length);
		final tornadoX = getUnsafeLaneAdd(amountIDs[0], laneIDs[0][lane], params.player);
		final tornadoY = getUnsafeLaneAdd(amountIDs[1], laneIDs[1][lane], params.player);
		final tornadoZ = getUnsafeLaneAdd(amountIDs[2], laneIDs[2][lane], params.player);

		if (tornadoX == 0 && tornadoY == 0 && tornadoZ == 0)
			return pos;

		var keyCount = getKeyCount();
		var bWideField = keyCount > 4;
		var iTornadoWidth = bWideField ? 4 : 3;

		var iColNum = params.lane;
		var iStartCol = iColNum - iTornadoWidth;
		var iEndCol = iColNum + iTornadoWidth;
		iStartCol = Math.round(ModchartUtil.clamp(iStartCol, 0, keyCount));
		iEndCol = Math.round(ModchartUtil.clamp(iEndCol, 0, keyCount));

		var fXOffset = ((ARROW_SIZE * 1.5) - (ARROW_SIZE * params.lane));

		var fMinX = -fXOffset;
		var fMaxX = fXOffset;

		final fRealPixelOffset = fXOffset;
		var fPositionBetween = scale(fRealPixelOffset, fMinX, fMaxX, -1, 1);

		var fRads = Math.acos(fPositionBetween);
		fRads += (params.distance * 0.8) * 6 / HEIGHT * (1 + getUnsafe(periodIDs[0], params.player));
		fRads += getUnsafe(offsetIDs[0], params.player);

		final fAdjustedPixelOffset = scale(cos(fRads), -1, 1, fMinX, fMaxX);

		pos.x -= (fAdjustedPixelOffset - fRealPixelOffset) * tornadoX;
		if (tornadoY != 0)
			pos.y += sin(fRads * (1 + getUnsafe(periodIDs[1], params.player)) + getUnsafe(offsetIDs[1], params.player)) * ARROW_SIZE * 1.5 * tornadoY;
		if (tornadoZ != 0)
			pos.z += cos(fRads * (1 + getUnsafe(periodIDs[2], params.player)) + getUnsafe(offsetIDs[2], params.player)) * ARROW_SIZE * 1.5 * tornadoZ;

		return pos;
	}

	inline function scale(x:Float, l1:Float, h1:Float, l2:Float, h2:Float) {
		return (x - l1) * (h2 - l2) / (h1 - l1) + l2;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function isActive(player:Int):Bool
	{
		for (axis in 0...amountIDs.length) {
			if (getUnsafe(amountIDs[axis], player) != 0) return true;
			for (id in laneIDs[axis]) if (getUnsafe(id, player) != 0) return true;
		}
		return false;
	}

	override public function allowOnStraightHolds():Bool
		return false;
}
