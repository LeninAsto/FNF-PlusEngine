package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class SawTooth extends Modifier {
	var amountIDs:Array<Int>;
	var periodIDs:Array<Int>;
	var offsetIDs:Array<Int>;

	public function new(pf) {
		super(pf);
		amountIDs = [findID('sawtooth'), findID('sawtoothY'), findID('sawtoothZ')];
		periodIDs = [findID('sawtoothPeriod'), findID('sawtoothYPeriod'), findID('sawtoothZPeriod')];
		offsetIDs = [findID('sawtoothOffset'), findID('sawtoothYOffset'), findID('sawtoothZOffset')];
	}

	inline function wave(axis:Int, params:ModifierParameters):Float {
		final amount = getUnsafe(amountIDs[axis], params.player);
		if (amount == 0) return 0;
		final period = Math.max(0.01, 1 + getUnsafe(periodIDs[axis], params.player));
		final phase = (0.5 / period * (params.distance + getUnsafe(offsetIDs[axis], params.player) * 100)) / ARROW_SIZE;
		return amount * ARROW_SIZE * (phase - Math.floor(phase));
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
