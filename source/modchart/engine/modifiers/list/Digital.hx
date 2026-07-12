package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class Digital extends Modifier {
	static final SERIES = ['digital', 'digitalz', 'tandigital', 'tandigitalz'];

	var amountIDs:Array<Int>;
	var stepsIDs:Array<Int>;
	var offsetIDs:Array<Int>;
	var periodIDs:Array<Int>;

	public function new(pf) {
		super(pf);

		amountIDs = [for (name in SERIES) findID(name)];
		stepsIDs = [for (name in SERIES) findID(name + 'Steps')];
		offsetIDs = [for (name in SERIES) findID(name + 'Offset')];
		periodIDs = [for (name in SERIES) findID(name + 'Period')];

		for (name in SERIES)
			setPercent(name + 'Steps', 1, -1);
	}

	inline function computeWave(seriesIdx:Int, params:ModifierParameters):Float {
		final player = params.player;
		final amount = getUnsafe(amountIDs[seriesIdx], player);

		if (amount == 0)
			return 0;

		final period = Math.max(0.05, 1 + getUnsafe(periodIDs[seriesIdx], player));
		final offset = getUnsafe(offsetIDs[seriesIdx], player);
		final steps = Math.max(1, Std.int(Math.round(8 * Math.max(0.125, getUnsafe(stepsIDs[seriesIdx], player)))));
		final angle = ((params.distance / (ARROW_SIZE * period)) + offset) * Math.PI;
		var wave = seriesIdx >= 2 ? tan(angle) : sin(angle);

		if (!Math.isFinite(wave))
			wave = 0;

		wave = Math.round(wave * steps) / steps;
		return wave * ARROW_SIZE * amount;
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		final xShift = computeWave(0, params) + computeWave(2, params);
		final zShift = computeWave(1, params) + computeWave(3, params);

		curPos.x += xShift;
		curPos.z += zShift;

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function allowOnStraightHolds():Bool
		return false;
}