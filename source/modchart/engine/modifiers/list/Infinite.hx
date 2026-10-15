package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;
class Infinite extends Modifier {
	override function render(pos:Vector3, params:ModifierParameters) {
		var perc = getPercent('infinite', params.player);

		if (perc == 0)
			return pos;

		// alternate the angles
		var rat = params.lane % 2 == 0 ? 1 : -1;
		// adding 45° so arrow hit position is at center
		var fTime = (-params.distance * Math.PI * 0.001) + rat * Math.PI / 2;
		// used for make the curve
		final invTransf = (2 / (3 - cos(fTime * 2)));

		// apply the scroll
		final targetX = WIDTH * .5 + invTransf * cos(fTime) * 580;
		final targetY = HEIGHT * .5 + invTransf * (sin(fTime * 2) * .5) * 750;
		pos.x += (targetX - pos.x) * perc;
		pos.y += (targetY - pos.y) * perc;
		pos.z += (0 - pos.z) * perc;
		return pos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
