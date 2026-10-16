package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class LocalRotate extends Rotate {
	private final localOrigin:Vector3 = new Vector3();

	override public function getOrigin(curPos:Vector3, params:ModifierParameters):Vector3 {
		var fixedLane = Math.round(getKeyCount(params.player) * .5);
		localOrigin.setTo(getReceptorX(fixedLane, params.player), getReceptorY(fixedLane, params.player), 0);
		return localOrigin;
	}

	override public function getRotateName():String
		return 'localRotate';

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
