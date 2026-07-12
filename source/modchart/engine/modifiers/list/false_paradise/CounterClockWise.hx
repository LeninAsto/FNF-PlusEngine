package modchart.engine.modifiers.list.false_paradise;

import modchart.backend.core.ModifierParameters;
import modchart.backend.util.ModchartUtil;

class CounterClockWise extends Modifier {
	override public function render(curPos:Vector3, params:ModifierParameters) {
		var strumTime = params.songTime + params.distance;
		var centerX = WIDTH * .5;
		var centerY = HEIGHT * .5;
		var radiusOffset = ARROW_SIZE * (params.lane - 1.5);

		var crochet = Adapter.instance.getCurrentCrochet();

		var radius = 200 + radiusOffset * cos(strumTime / crochet * .25 / 16 * Math.PI);
		var outX = centerX + cos(strumTime / crochet / 4 * Math.PI) * radius;
		var outY = centerY + sin(strumTime / crochet / 4 * Math.PI) * radius;

		return ModchartUtil.lerpVector3D(curPos, new Vector3(outX, outY, 0, 0), getPercent('counterClockWise', params.player));
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return getPercent('counterclockwise', params.player) != 0;
}
