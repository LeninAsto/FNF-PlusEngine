package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class Asymptote extends Modifier {
	var asymptoteID:Int;
	var offsetID:Int;
	var scaleID:Int;

	public function new(pf) {
		super(pf);

		asymptoteID = findID('asymptote');
		offsetID = findID('asymptoteOffset');
		scaleID = findID('asymptoteScale');
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		final player = params.player;
		final amount = getUnsafe(asymptoteID, player);

		if (amount == 0)
			return curPos;

		final receptorX = getReceptorX(params.lane, player) + ARROW_SIZEDIV2;
		final offset = getUnsafe(offsetID, player) * HEIGHT;
		final scale = Math.max(0.05, 1 + getUnsafe(scaleID, player));
		final distance = Math.abs(params.distance + offset) / (HEIGHT * scale);
		final approach = distance / (1 + distance);

		curPos.x = receptorX + ((curPos.x - receptorX) * (1 - amount + (amount * approach)));

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}