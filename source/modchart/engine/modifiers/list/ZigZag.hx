package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class ZigZag extends Modifier {
	override public function render(curPos:Vector3, params:ModifierParameters) {
		final zigzag = getPercent('zigZag', params.player);

		if (zigzag == 0)
			return curPos;

		var theta = -params.distance / ARROW_SIZE * Math.PI;
		var outRelative = Math.acos(cos(theta + Math.PI / 2)) / Math.PI * 2 - 1;

		curPos.x += outRelative * ARROW_SIZEDIV2 * zigzag;

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function allowOnStraightHolds():Bool
		return false;
}
