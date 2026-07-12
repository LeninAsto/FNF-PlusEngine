package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class SchmovinDrunk extends Modifier {
	final thtdiv = 1 / 222;

	override public function render(curPos:Vector3, params:ModifierParameters) {
		var phaseShift = params.lane * 0.5 + (params.distance * thtdiv) * Math.PI;
		curPos.x += sin(params.curBeat * .25 * Math.PI + phaseShift) * ARROW_SIZEDIV2 * getPercent('schmovinDrunk', params.player);

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function allowOnStraightHolds():Bool
		return false;
}
