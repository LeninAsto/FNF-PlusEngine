package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class SchmovinTipsy extends Modifier {
	override public function render(curPos:Vector3, params:ModifierParameters) {
		curPos.y += sin(params.curBeat / 4 * Math.PI + params.lane) * ARROW_SIZEDIV2 * getPercent('schmovinTipsy', params.player);
		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function allowOnStraightHolds():Bool
		return false;
}
