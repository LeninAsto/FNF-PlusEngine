package modchart.engine.modifiers.list.false_paradise;

import modchart.backend.core.ModifierParameters;

class ParadiseDistortWiggle extends Modifier {
	override public function render(pos:Vector3, params:ModifierParameters) {
		final amount = getPercent('paradisedistortwiggle', params.player);
		final period = getPercent('paradisedistortwiggleperiod', params.player) + 200;
		final scratch = getPercent('paradisedistortwigglescratch', params.player);
		if (period != 0)
			pos.x += Math.sin(pos.y / period + params.curBeat + scratch) * amount * 20;
		return pos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return getPercent('paradisedistortwiggle', params.player) != 0;
}
