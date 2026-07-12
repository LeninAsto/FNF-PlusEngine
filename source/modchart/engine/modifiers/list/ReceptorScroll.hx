package modchart.engine.modifiers.list;

import flixel.math.FlxMath;
import modchart.backend.core.ModifierParameters;
import modchart.backend.core.VisualParameters;

class ReceptorScroll extends Modifier {
	override public function render(curPos:Vector3, params:ModifierParameters) {
		final perc = getPercent('receptorScroll', params.player);

		if (perc == 0)
			return curPos;

		final moveSpeed = Adapter.instance.getCurrentCrochet() * 4;

		var diff = -params.distance;
		var songTime = Adapter.instance.getSongPosition();
		var vDiff = -(diff - songTime) / moveSpeed;
		var reversed = Math.floor(vDiff) % 2 == 0;

		var startY = curPos.y;
		var revPerc = reversed ? 1 - vDiff % 1 : vDiff % 1;
		// haha perc 30
		var upscrollOffset = 50;
		var downscrollOffset = HEIGHT - 150;

		var endY = upscrollOffset + ((downscrollOffset - ARROW_SIZEDIV2) * revPerc) + ARROW_SIZEDIV2;

		curPos.y = FlxMath.lerp(startY, endY, perc);
		return curPos;
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters):VisualParameters {
		final perc = getPercent('receptorScroll', params.player);
		if (perc == 0)
			return data;

		final moveSpeed = Adapter.instance.getCurrentCrochet() * 4;
		var songTime = Adapter.instance.getSongPosition();
		var currentCycle = Math.floor(songTime / moveSpeed) % 2;
		var noteTime = songTime + params.distance;
		var noteCycle = Math.floor(noteTime / moveSpeed) % 2;
		
		if (currentCycle == noteCycle) {
			data.alpha = 1.0;
		} else {
			data.alpha = 0.3;
		}

		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
