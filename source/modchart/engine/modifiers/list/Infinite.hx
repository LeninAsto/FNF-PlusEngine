package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;
import modchart.backend.util.ModchartUtil;

class Infinite extends Modifier {
	override function render(pos:Vector3, params:ModifierParameters) {
		var perc = getPercent('infinite', params.player);

		if (perc == 0)
			return pos;

		var infinite = new Vector3();

		// alternate the angles
		var rat = params.lane % 2 == 0 ? 1 : -1;
		// adding 45° so arrow hit position is at center
		var fTime = (-params.distance * Math.PI * 0.001) + rat * Math.PI / 2;
		// used for make the curve
		final invTransf = (2 / (3 - cos(fTime * 2)));

		// apply the scroll
		infinite.setTo(WIDTH * .5 + invTransf * cos(fTime) * 580, HEIGHT * .5 + invTransf * (sin(fTime * 2) * .5) * 750, 0);

		return ModchartUtil.lerpVector3D(pos, infinite, perc);
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
