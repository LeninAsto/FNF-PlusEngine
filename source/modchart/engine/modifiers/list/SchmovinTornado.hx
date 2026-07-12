package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class SchmovinTornado extends Modifier {
	override public function render(curPos:Vector3, params:ModifierParameters) {
		final tord = getPercent('schmovinTornado', params.player);

		if (tord == 0)
			return curPos;
		final columnShift = params.lane * Math.PI / 3;
		final strumNegator = (-cos(-columnShift) + 1) / 2 * ARROW_SIZE * 3;
		curPos.x += ((-cos((params.distance / 135) - columnShift) + 1) / 2 * ARROW_SIZE * 3 - strumNegator) * tord;

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function allowOnStraightHolds():Bool
		return false;
}
