package modchart.engine.modifiers.list.false_paradise;

import modchart.backend.core.ModifierParameters;
import modchart.backend.util.ModchartUtil;

class Spiral extends Modifier {
	override public function render(curPos:Vector3, params:ModifierParameters) {
		var player = params.player;
		var PI = Math.PI;
		var centerX = WIDTH * .5;
		var centerY = HEIGHT * .5;
		var radiusOffset = -params.distance * .25;
		var crochet = Adapter.instance.getCurrentCrochet();
		var radius = radiusOffset + getPercent('spiralDist', player) * params.lane;
		var outX = centerX + cos(-params.distance / crochet * PI + params.curBeat * (PI * .25)) * radius;
		var outY = centerY + sin(-params.distance / crochet * PI - params.curBeat * (PI * .25)) * radius;

		return ModchartUtil.lerpVector3D(curPos, new Vector3(outX, outY, radius / (centerY * 4) - 1, 0), getPercent('spiral', player));
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return getPercent('spiral', params.player) != 0;
}
