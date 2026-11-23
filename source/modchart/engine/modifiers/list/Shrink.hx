package modchart.engine.modifiers.list;

import flixel.math.FlxMath;
import modchart.backend.core.ModifierParameters;
import modchart.backend.core.TransformMode;
import modchart.backend.core.VisualParameters;

class Shrink extends Modifier {
	var multID:Int;
	var linearID:Int;
	var minID:Int;
	var maxID:Int;

	public function new(pf) {
		super(pf);
		multID = findID('shrinkToMult');
		linearID = findID('shrinkToLinear');
		minID = findID('shrinkToMin');
		maxID = findID('shrinkToMax');
		setPercent('shrinkToMin', 0.01, -1);
		setPercent('shrinkToMax', 8, -1);
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters):VisualParameters {
		if (params.distance < 0) return data;
		final player = params.player;
		var zoom = 1.0;
		final mult = getUnsafe(multID, player);
		if (mult != 0)
			zoom *= 1 / Math.max(0.0001, 1 + params.distance * (mult / 100));
		final linear = getUnsafe(linearID, player);
		if (linear != 0)
			zoom += params.distance * (0.5 * linear / ARROW_SIZE);
		zoom = FlxMath.bound(zoom, getUnsafe(minID, player), Math.max(getUnsafe(minID, player), getUnsafe(maxID, player)));
		data.scaleX *= zoom;
		data.scaleY *= zoom;
		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool return true;
	override public function isActive(player:Int):Bool
		return getUnsafe(multID, player) != 0 || getUnsafe(linearID, player) != 0;
	override public function transformMode():TransformMode return TransformMode.NOTE;
	override public function allowOnStraightHolds():Bool return false;
}
