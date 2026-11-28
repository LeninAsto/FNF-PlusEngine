package modchart.engine.modifiers.list.false_paradise;

import modchart.backend.core.ModifierParameters;

class ParadiseColumnSwap extends Modifier {
	override public function render(pos:Vector3, params:ModifierParameters) {
		final lane = params.lane % 4;
		final invert = getPercent('paradiseinvert', params.player);
		final flip = getPercent('paradiseflip', params.player);
		pos.x += ARROW_SIZE * (lane % 2 == 0 ? 1 : -1) * invert;
		pos.x -= ARROW_SIZE * (lane - 1.5) * flip * 2;
		return pos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return getPercent('paradiseinvert', params.player) != 0 || getPercent('paradiseflip', params.player) != 0;
}
