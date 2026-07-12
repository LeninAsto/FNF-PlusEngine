package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class Invert extends Modifier {
	var invID = 0;
	var flpID = 0;

	public function new(pf) {
		super(pf);

		invID = findID('invert');
		flpID = findID('flip');
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		final player = params.player;
		final invert = -(params.lane % 2 - 0.5) * 2;
		final flip = (params.lane - 1.5) * -2;

		curPos.x += ARROW_SIZE * (invert * getUnsafe(invID, player) + flip * getUnsafe(flpID, player));

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
