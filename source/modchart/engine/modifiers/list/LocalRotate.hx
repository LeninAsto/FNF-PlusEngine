package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class LocalRotate extends Rotate {
	override public function getOrigin(curPos:Vector3, params:ModifierParameters):Vector3 {
		var fixedLane = Math.round(getKeyCount(params.player) * .5);
		return new Vector3(getReceptorX(fixedLane, params.player), getReceptorY(fixedLane, params.player));
	}

	override public function getRotateName():String
		return 'localRotate';

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
