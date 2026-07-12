package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;
import modchart.backend.core.VisualParameters;

// Circular motion based on the lane.
// Naming this `Radionic` since it seems like a Radionic Graphic.
// Inspired by `The Poenix NotITG Modchart` at 0:35
// Warning!: This should be AFTER regular modifiers (drunk, beat, transform, etc) and BEFORE rotation modifiers.
class Radionic extends Modifier {
	override public function render(pos:Vector3, params:ModifierParameters) {
		final perc = getPercent('radionic', params.player);

		if (perc == 0)
			return pos;

		final reverse = pf.modifiers.modifiers.get('reverse');

		final angle = ((1 / Adapter.instance.getCurrentCrochet()) * ((params.songTime + params.distance) * Math.PI * .25) + (Math.PI * params.player));
		final offsetX = pos.x - getReceptorX(params.lane, params.player);
		final offsetY = reverse != null ? (pos.y - reverse.render(pos, params).y) : 0;

		final circf = ARROW_SIZE + params.lane * ARROW_SIZE;

		final sinAng = sin(angle);
		final cosAng = cos(angle);

		final radionicVec = new Vector3();

		radionicVec.x = WIDTH * 0.5 + ((sinAng * offsetY + cosAng * (circf + offsetX)) * 0.7) * 1.125;
		radionicVec.y = HEIGHT * 0.5 + ((cosAng * offsetY + sinAng * (circf + offsetX)) * 0.7) * 0.875;
		radionicVec.z = pos.z;

		return pos.interpolate(radionicVec, perc, pos);
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters):VisualParameters {
		final perc = getPercent('radionic', params.player);
		
		if (perc == 0)
			return data;
			
		final amount = 0.6;

		data.scaleX = perc * (data.scaleY = 1 + amount - FlxEase.cubeOut((params.curBeat - Math.floor(params.curBeat))) * amount);
		data.glow = perc * (-(amount - FlxEase.cubeOut((params.curBeat - Math.floor(params.curBeat))) * amount) * 2);

		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
