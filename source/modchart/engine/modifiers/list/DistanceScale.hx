package modchart.engine.modifiers.list;

import flixel.math.FlxMath;
import modchart.backend.core.ModifierParameters;
import modchart.backend.core.TransformMode;
import modchart.backend.core.VisualParameters;

class DistanceScale extends Modifier {
	var amountIDs:Array<Int>;
	var rangeID:Int;
	var minID:Int;
	var maxID:Int;

	public function new(pf) {
		super(pf);
		amountIDs = [findID('distanceScale'), findID('distanceScaleX'), findID('distanceScaleY')];
		rangeID = findID('distanceScaleRange');
		minID = findID('distanceScaleMin');
		maxID = findID('distanceScaleMax');
		setPercent('distanceScaleRange', 640, -1);
		setPercent('distanceScaleMin', 0.05, -1);
		setPercent('distanceScaleMax', 4, -1);
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters):VisualParameters {
		final player = params.player;
		final range = Math.max(1, Math.abs(getUnsafe(rangeID, player)));
		final distance = Math.abs(params.distance) / range;
		final min = getUnsafe(minID, player);
		final max = Math.max(min, getUnsafe(maxID, player));
		final common = getUnsafe(amountIDs[0], player);
		data.scaleX *= FlxMath.bound(1 + distance * (common + getUnsafe(amountIDs[1], player)), min, max);
		data.scaleY *= FlxMath.bound(1 + distance * (common + getUnsafe(amountIDs[2], player)), min, max);
		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool return true;
	override public function isActive(player:Int):Bool
		return getUnsafe(amountIDs[0], player) != 0 || getUnsafe(amountIDs[1], player) != 0 || getUnsafe(amountIDs[2], player) != 0;
	override public function transformMode():TransformMode return TransformMode.NOTE;
	override public function allowOnStraightHolds():Bool return false;
}
