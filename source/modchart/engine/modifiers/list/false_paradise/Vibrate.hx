package modchart.engine.modifiers.list.false_paradise;

import modchart.backend.core.ModifierParameters;

class Vibrate extends Modifier {
	override public function render(curPos:Vector3, params:ModifierParameters) {
		var vib = getPercent('vibrate', params.player);
		curPos.x += (Math.random() - 0.5) * vib * 20;
		curPos.y += (Math.random() - 0.5) * vib * 20;

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return getPercent('vibrate', params.player) != 0;
}
