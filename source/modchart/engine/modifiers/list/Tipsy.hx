package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class Tipsy extends Modifier {
	override public function render(curPos:Vector3, params:ModifierParameters) {
		var player = params.player;

		var xVal = getPercent('tipsyX', player);
		var yVal = getPercent('tipsy', player) + getPercent('tipsyY', player);
		var zVal = getPercent('tipsyZ', player);

		if (xVal == 0 && yVal == 0 && zVal == 0)
			return curPos;

		var speed = getPercent('tipsySpeed', player);
		var offset = getPercent('tipsyOffset', player);

		var tipsy = (cos((params.songTime * 0.001 * ((speed * 1.2) + 1.2) + params.lane * ((offset * 1.8) + 1.8))) * ARROW_SIZE * .4);

		var tipAddition = new Vector3(xVal, yVal, zVal);
		tipAddition.scaleBy(tipsy);

		return curPos.add(tipAddition);
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function allowOnStraightHolds():Bool
		return false;
}
