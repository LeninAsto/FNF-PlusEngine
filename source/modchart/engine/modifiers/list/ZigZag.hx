package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class ZigZag extends Modifier {
	var amountIDs:Array<Int>;
	var periodIDs:Array<Int>;
	var offsetIDs:Array<Int>;
	var laneIDs:Array<Array<Int>>;

	public function new(pf) {
		super(pf);
		amountIDs = [findID('zigZag'), findID('zigZagY'), findID('zigZagZ')];
		periodIDs = [findID('zigZagPeriod'), findID('zigZagYPeriod'), findID('zigZagZPeriod')];
		offsetIDs = [findID('zigZagOffset'), findID('zigZagYOffset'), findID('zigZagZOffset')];
		laneIDs = [
			[for (lane in 0...16) findID('zigZag' + lane)],
			[for (lane in 0...16) findID('zigZagY' + lane)],
			[for (lane in 0...16) findID('zigZagZ' + lane)]
		];
	}

	inline function wave(axis:Int, params:ModifierParameters):Float {
		final lane = getLaneSlot(params.lane, laneIDs[axis].length);
		final amount = getUnsafeLaneAdd(amountIDs[axis], laneIDs[axis][lane], params.player);
		if (amount == 0) return 0;
		final period = Math.max(0.01, 1 + getUnsafe(periodIDs[axis], params.player));
		final theta = -(params.distance + getUnsafe(offsetIDs[axis], params.player) * 100) / (ARROW_SIZE * period) * Math.PI;
		final triangle = Math.acos(cos(theta + Math.PI * 0.5)) / Math.PI * 2 - 1;
		return triangle * ARROW_SIZEDIV2 * amount;
	}

	override public function render(pos:Vector3, params:ModifierParameters) {
		pos.x += wave(0, params);
		pos.y += wave(1, params);
		pos.z += wave(2, params);
		return pos;
	}

	override public function shouldRun(params:ModifierParameters):Bool return true;
	override public function isActive(player:Int):Bool {
		for (axis in 0...amountIDs.length) {
			if (getUnsafe(amountIDs[axis], player) != 0) return true;
			for (id in laneIDs[axis]) if (getUnsafe(id, player) != 0) return true;
		}
		return false;
	}
	override public function allowOnStraightHolds():Bool return false;
}
