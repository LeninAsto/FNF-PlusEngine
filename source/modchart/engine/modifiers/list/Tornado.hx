package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;
import modchart.backend.util.ModchartUtil;

class Tornado extends Modifier {
	// math from open itg
	// hmm, looks familiar.... isnt this invert sine?
	override public function render(pos:Vector3, params:ModifierParameters) {
		var tornado = getPercent('tornado', params.player);

		if (tornado == 0)
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
		fRads += (params.distance * 0.8) * 6 / HEIGHT;

		final fAdjustedPixelOffset = scale(cos(fRads), -1, 1, fMinX, fMaxX);

		pos.x -= (fAdjustedPixelOffset - fRealPixelOffset) * tornado;

		return pos;
	}

	inline function scale(x:Float, l1:Float, h1:Float, l2:Float, h2:Float) {
		return (x - l1) * (h2 - l2) / (h1 - l1) + l2;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function allowOnStraightHolds():Bool
		return false;
}
