package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class Cubic extends Modifier {
	static final AXES = ['x', 'y', 'z'];

	var amountIDs:Array<Int>;
	var offsetIDs:Array<Int>;

	public function new(pf) {
		super(pf);

		amountIDs = [for (axis in AXES) findID('cubic' + axis)];
		offsetIDs = [for (axis in AXES) findID('cubic' + axis + 'Offset')];
	}

	inline function applyAxis(curPos:Vector3, params:ModifierParameters, axisIdx:Int, realAxisIdx:Int):Void {
		final player = params.player;
		final amount = getUnsafe(amountIDs[axisIdx], player);

		if (amount == 0)
			return;

		final offset = getUnsafe(offsetIDs[axisIdx], player) * HEIGHT;
		final t = (params.distance + offset) / HEIGHT;
		final shift = amount * t * t * t * ARROW_SIZE;

		switch (realAxisIdx) {
			case 0: curPos.x += shift;
			case 1: curPos.y += shift;
			case 2: curPos.z += shift;
		}
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		applyAxis(curPos, params, 0, 0);
		applyAxis(curPos, params, 1, 1);
		applyAxis(curPos, params, 2, 2);

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}