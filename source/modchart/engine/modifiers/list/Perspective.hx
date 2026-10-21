package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;
import modchart.backend.core.TransformMode;
import modchart.backend.core.VisualParameters;

class Perspective extends Modifier {
	var skewID:Int;
	var tiltID:Int;
	var incomingID:Int;
	var spaceID:Int;
	var hallwayID:Int;
	var distantID:Int;
	var strengthID:Int;

	public function new(pf) {
		super(pf);
		skewID = findID('perspectiveSkew');
		tiltID = findID('perspectiveTilt');
		incomingID = findID('incoming');
		spaceID = findID('space');
		hallwayID = findID('hallway');
		distantID = findID('distant');
		strengthID = findID('perspectiveStrength');
		setPercent('perspectiveStrength', 1, -1);
	}

	inline function getTilt(player:Int):Float
		return getUnsafe(tiltID, player) + getUnsafe(distantID, player) - getUnsafe(hallwayID, player)
			+ getUnsafe(spaceID, player) - getUnsafe(incomingID, player);

	override public function render(pos:Vector3, params:ModifierParameters) {
		final player = params.player;
		final skew = getUnsafe(skewID, player) + getUnsafe(spaceID, player) + getUnsafe(incomingID, player);
		final tilt = getTilt(player);
		if (skew == 0 && tilt == 0) return pos;

		final travel = params.distance * getScrollSpeed();
		final strength = getUnsafe(strengthID, player);
		final side = player == 0 ? -1 : 1;
		pos.x += travel * skew * side * 0.35 * strength;
		pos.z -= Math.abs(travel) * tilt * strength;
		return pos;
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters):VisualParameters {
		final player = params.player;
		data.fieldAngleX -= getTilt(player) * 30 * getUnsafe(strengthID, player);
		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool return true;
	override public function isActive(player:Int):Bool
		return getUnsafe(skewID, player) != 0 || getUnsafe(tiltID, player) != 0 || getUnsafe(incomingID, player) != 0
			|| getUnsafe(spaceID, player) != 0 || getUnsafe(hallwayID, player) != 0 || getUnsafe(distantID, player) != 0;
	override public function allowOnStraightHolds():Bool return false;
	override public function transformMode():TransformMode return TransformMode.FIELD;
}
