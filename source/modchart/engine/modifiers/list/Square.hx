package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class Square extends Modifier {
	override public function render(curPos:Vector3, params:ModifierParameters) {
		var player = params.player;
		final squarep = getPercent('square', player);

		if (squarep == 0)
			return curPos;

		final offset = getPercent("squareOffset", player);
		final period = getPercent("squarePeriod", player);
		final amp = (Math.PI * (params.distance + offset) / (ARROW_SIZE + (period * ARROW_SIZE)));

		curPos.x += squarep * square(amp);

		return curPos;
	}

	function square(angle:Float):Float {
		var fAngle = angle % (Math.PI * 2);
		return fAngle >= Math.PI ? -1.0 : 1.0;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function allowOnStraightHolds():Bool
		return false;
}
