package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class Square extends Modifier {
	var amountIDs:Array<Int>;
	var periodIDs:Array<Int>;
	var offsetIDs:Array<Int>;

	public function new(pf) {
		super(pf);
		amountIDs = [findID('square'), findID('squareY'), findID('squareZ')];
		periodIDs = [findID('squarePeriod'), findID('squareYPeriod'), findID('squareZPeriod')];
		offsetIDs = [findID('squareOffset'), findID('squareYOffset'), findID('squareZOffset')];
	}

	inline function wave(axis:Int, params:ModifierParameters):Float {
		final amount = getUnsafe(amountIDs[axis], params.player);
		if (amount == 0) return 0;
		final period = Math.max(0.01, 1 + getUnsafe(periodIDs[axis], params.player));
		final angle = Math.PI * (params.distance + getUnsafe(offsetIDs[axis], params.player) * 100) / (ARROW_SIZE * period);
		final normalized = (angle % (Math.PI * 2) + Math.PI * 2) % (Math.PI * 2);
		return amount * ARROW_SIZEDIV2 * (normalized >= Math.PI ? -1 : 1);
	}

	override public function render(pos:Vector3, params:ModifierParameters) {
		pos.x += wave(0, params);
		pos.y += wave(1, params);
		pos.z += wave(2, params);
		return pos;
	}

	override public function shouldRun(params:ModifierParameters):Bool return true;
	override public function isActive(player:Int):Bool
		return getUnsafe(amountIDs[0], player) != 0 || getUnsafe(amountIDs[1], player) != 0 || getUnsafe(amountIDs[2], player) != 0;
	override public function allowOnStraightHolds():Bool return false;
}
