package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class StraightHolds extends Modifier {
	override public function shouldRun(params:ModifierParameters):Bool
		return false;
}