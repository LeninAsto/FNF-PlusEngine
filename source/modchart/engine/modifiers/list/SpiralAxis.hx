package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class SpiralAxis extends Modifier {
	var amountIDs:Array<Int>;
	var periodIDs:Array<Int>;
	var offsetIDs:Array<Int>;
	var speedIDs:Array<Int>;
	var spacingIDs:Array<Int>;

	public function new(pf) {
		super(pf);
		amountIDs = [findID('spiralX'), findID('spiralY'), findID('spiralZ')];
		periodIDs = [findID('spiralXPeriod'), findID('spiralYPeriod'), findID('spiralZPeriod')];
		offsetIDs = [findID('spiralXOffset'), findID('spiralYOffset'), findID('spiralZOffset')];
		speedIDs = [findID('spiralXSpeed'), findID('spiralYSpeed'), findID('spiralZSpeed')];
		spacingIDs = [findID('spiralXSpacing'), findID('spiralYSpacing'), findID('spiralZSpacing')];
	}

	override public function render(pos:Vector3, params:ModifierParameters) {
		final player = params.player;
		for (axis in 0...3) {
			final amount = getUnsafe(amountIDs[axis], player);
			if (amount == 0) continue;
			final radius = (-params.distance * 0.25) + getUnsafe(spacingIDs[axis], player) * ARROW_SIZEDIV2 * params.lane;
			final phase = params.distance * 0.01 * (1 + getUnsafe(periodIDs[axis], player))
				+ params.curBeat * getUnsafe(speedIDs[axis], player) + getUnsafe(offsetIDs[axis], player);
			final shift = (axis == 0 ? cos(phase) : sin(phase)) * radius * amount;
			if (axis == 0) pos.x += shift;
			else if (axis == 1) pos.y += shift;
			else pos.z += shift;
		}
		return pos;
	}

	override public function shouldRun(params:ModifierParameters):Bool return true;
	override public function isActive(player:Int):Bool
		return getUnsafe(amountIDs[0], player) != 0 || getUnsafe(amountIDs[1], player) != 0 || getUnsafe(amountIDs[2], player) != 0;
	override public function allowOnStraightHolds():Bool return false;
}
