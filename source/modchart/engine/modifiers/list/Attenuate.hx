package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class Attenuate extends Modifier {
	static final AXES = ['', 'x', 'y', 'z'];

	var attenuateIDs:Array<Int>;
	var attenuateOffsetIDs:Array<Int>;

	public function new(pf) {
		super(pf);

		attenuateIDs = [for (axis in AXES) findID('attenuate' + axis)];
		attenuateOffsetIDs = [for (axis in AXES) findID('attenuate' + axis + 'Offset')];
	}

	inline function applyAxis(curPos:Vector3, params:ModifierParameters, axisIdx:Int, realAxisIdx:Int):Void {
		final player = params.player;
		final amount = getUnsafe(attenuateIDs[axisIdx], player);

		if (amount == 0)
			return;

		final offset = getUnsafe(attenuateOffsetIDs[axisIdx], player) * ARROW_SIZE;
		final factor = 1 + (amount * Math.max(0, params.distance + offset) / HEIGHT);

		switch (realAxisIdx) {
			case 0:
				final originX = getReceptorX(params.lane, player) + ARROW_SIZEDIV2;
				curPos.x = originX + ((curPos.x - originX) * factor);
			case 1:
				final originY = getReceptorY(params.lane, player) + ARROW_SIZEDIV2;
				curPos.y = originY + ((curPos.y - originY) * factor);
			case 2:
				curPos.z *= factor;
		}
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		applyAxis(curPos, params, 0, 0); // attenuate -> x
		applyAxis(curPos, params, 1, 0); // attenuatex -> x
		applyAxis(curPos, params, 2, 1); // attenuatey -> y
		applyAxis(curPos, params, 3, 2); // attenuatez -> z

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}