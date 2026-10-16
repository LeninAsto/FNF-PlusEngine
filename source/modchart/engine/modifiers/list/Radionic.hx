package modchart.engine.modifiers.list;

import flixel.math.FlxMath;
import modchart.backend.core.ModifierParameters;
import modchart.backend.core.VisualParameters;

// Circular motion based on the lane.
// Naming this `Radionic` since it seems like a Radionic Graphic.
// Inspired by `The Poenix NotITG Modchart` at 0:35
// Warning!: This should be AFTER regular modifiers (drunk, beat, transform, etc) and BEFORE rotation modifiers.
class Radionic extends Modifier {
	private final reverseInput:Vector3 = new Vector3();

	override public function render(pos:Vector3, params:ModifierParameters) {
		final perc = getPercent('radionic', params.player);

		if (perc == 0)
			return pos;

		final reverse = pf.modifiers.modifiers.get('reverse');

		final angle = ((1 / Adapter.instance.getCurrentCrochet()) * ((params.songTime + params.distance) * Math.PI * .25) + (Math.PI * params.player));
		final offsetX = pos.x - getReceptorX(params.lane, params.player);
		var offsetY = 0.0;
		if (reverse != null) {
			pos.copyToOutput(reverseInput);
			offsetY = pos.y - reverse.render(reverseInput, params).y;
		}

		final circf = ARROW_SIZE + params.lane * ARROW_SIZE;

		final sinAng = sin(angle);
		final cosAng = cos(angle);

		final targetX = WIDTH * 0.5 + ((sinAng * offsetY + cosAng * (circf + offsetX)) * 0.7) * 1.125;
		final targetY = HEIGHT * 0.5 + ((cosAng * offsetY + sinAng * (circf + offsetX)) * 0.7) * 0.875;
		pos.x += (targetX - pos.x) * perc;
		pos.y += (targetY - pos.y) * perc;
		return pos;
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters):VisualParameters {
		final perc = getPercent('radionic', params.player);
		
		if (perc == 0)
			return data;
			
		final amount = 0.6;
		final strength = FlxMath.bound(perc, 0, 1);
		final pulse = FlxEase.cubeOut(params.curBeat - Math.floor(params.curBeat));
		final pulseScale = 1 + amount - pulse * amount;
		final scale = FlxMath.lerp(1, pulseScale, strength);

		data.scaleX *= scale;
		data.scaleY *= scale;
		data.glow += strength * (-(amount - pulse * amount) * 2);

		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function isActive(player:Int):Bool
		return getPercent('radionic', player) != 0;
}
