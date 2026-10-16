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

		curPos.x += xVal * tipsy;
		curPos.y += yVal * tipsy;
		curPos.z += zVal * tipsy;
		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function isActive(player:Int):Bool
		return getPercent('tipsy', player) != 0 || getPercent('tipsyX', player) != 0
			|| getPercent('tipsyY', player) != 0 || getPercent('tipsyZ', player) != 0;

	override public function allowOnStraightHolds():Bool
		return false;
}
