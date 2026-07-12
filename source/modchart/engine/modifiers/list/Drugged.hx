package modchart.engine.modifiers.list;

import flixel.math.FlxMath;
import modchart.backend.core.ModifierParameters;
import modchart.backend.core.VisualParameters;

class Drugged extends Modifier {
	override public function render(curPos:Vector3, params:ModifierParameters) {
		var amplitude = 1.;
		var frequency = 1.;

		var x = (params.distance * 0.009) + (params.lane * 0.125);
		var y = 0.;
		y = sin(x * frequency);
		var t = 0.01 * (-Adapter.instance.getSongPosition() * 0.0025 * 130.0);
		y += sin(x * frequency * 2.1 + t) * 4.5;
		y += sin(x * frequency * 1.72 + t * 1.121) * 4.0;
		y += sin(x * frequency * 2.221 + t * 0.437) * 5.0;
		y += sin(x * frequency * 3.1122 + t * 4.269) * 2.5;
		y *= amplitude * 0.06;

		curPos.x += y * getPercent('drugged', params.player) * ARROW_SIZE * 0.8;

		return curPos;
	}

	override public function visuals(visuals:VisualParameters, params:ModifierParameters) {
		var drug = getPercent('drugged', params.player);

		var amplitude = 1.;
		var frequency = 1.;

		var x = (params.distance * 0.025) + (params.lane * 0.3);
		var y = 0.;
		y = sin(x * frequency);
		var t = 0.01 * (-Adapter.instance.getSongPosition() * 0.005 * 130.0);
		y += sin(x * frequency * 2.1 + t) * 4.5;
		y += sin(x * frequency * 1.72 + t * 1.121) * 4.0;
		y += sin(x * frequency * 2.221 + t * 0.437) * 5.0;
		y += sin(x * frequency * 3.1122 + t * 4.269) * 2.5;
		y *= amplitude * 0.06;

		y = -FlxMath.bound(y, -1, 1);

		var squishX = 1 + FlxMath.bound(y, -1, 0) * -1 * 0.6;
		var squishY = 1 + FlxMath.bound(y, 0, 1) * 0.6;

		visuals.scaleX = FlxMath.lerp(visuals.scaleX, visuals.scaleX * squishX, drug);
		visuals.scaleY = FlxMath.lerp(visuals.scaleY, visuals.scaleY * squishY, drug);

		var preproduct = Math.asin(y);
		// var cosdY = cos(preproduct);

		visuals.glow = FlxMath.lerp(visuals.glow, y * -.7, drug);
		visuals.glowR = FlxMath.lerp(visuals.glowR, visuals.glowR - (0.5 + sin(preproduct * 1.4) * .5), drug);
		visuals.glowG = FlxMath.lerp(visuals.glowG, visuals.glowG + (0.4 + cos(preproduct * 0.5) * .6), drug);
		visuals.glowB = FlxMath.lerp(visuals.glowB, visuals.glowB - (0.2 + tan(preproduct) * .8), drug);

		return visuals;

		// curPos.x += y * getPercent('drugged', params.player);
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function allowOnStraightHolds():Bool
		return false;
}
