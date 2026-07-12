package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class Beat extends Modifier {
	// Pre-computed IDs indexed by axisIdx (0='', 1='x', 2='y', 3='z') to avoid Std.string(lane) allocations.
	static final AXES = ['', 'x', 'y', 'z'];

	var beatAmtIDs:Array<Int>;
	var beatAmtLaneIDs:Array<Array<Int>>;
	var beatSpeedIDs:Array<Int>;
	var beatOffsetIDs:Array<Int>;
	var beatMultIDs:Array<Int>;

	public function new(pf) {
		super(pf);

		for (x in AXES)
			setPercent('beat${x}Speed', 1);

		final maxKeys = 16;
		beatAmtIDs = [for (a in AXES) findID('beat' + a)];
		beatAmtLaneIDs = [for (a in AXES) [for (l in 0...maxKeys) findID('beat' + a + l)]];
		beatSpeedIDs = [for (a in AXES) findID('beat' + a + 'Speed')];
		beatOffsetIDs = [for (a in AXES) findID('beat' + a + 'Offset')];
		beatMultIDs = [for (a in AXES) findID('beat' + a + 'Mult')];
	}

	static final fAccelTime:Float = 0.2;
	static final fTotalTime:Float = 0.5;

	static final zeroOneFactor = 1 / fAccelTime;
	static final oneZeroFactor = 1 / fTotalTime;

	@:dox(hide)
	@:noCompletion private inline function beatMath(params:ModifierParameters, offset:Float, mult:Float, speed:Float):Float {
		var fBeat = ((params.curBeat * speed) + offset) + fAccelTime;

		if (fBeat <= 0)
			return 0;

		final bEvenBeat = Std.int(fBeat) % 2 != 0;
		fBeat = (fBeat % 1 + 1) % 1;

		if (fBeat >= fTotalTime)
			return 0;
		var fAmount:Float;

		if (fBeat < fAccelTime) {
			fAmount = Math.pow(fBeat * zeroOneFactor, 2);
		} else {
			final fcBeat = fBeat * oneZeroFactor;
			fAmount = (1 - fcBeat) * (1 + fcBeat);
		}

		if (bEvenBeat)
			fAmount *= -1;

		return 20 * fAmount * cos(params.distance * 0.01 * mult);
	}

	// axisIdx: 0='' 1='x' 2='y' 3='z'; realAxisIdx: 0=x 1=y 2=z
	@:dox(hide)
	@:noCompletion private inline function computeBeat(curPos:Vector3, params:ModifierParameters, axisIdx:Int, realAxisIdx:Int) {
		final lane = params.lane;
		final player = params.player;

		var amount = getUnsafe(beatAmtIDs[axisIdx], player);
		if (Config.COLUMN_SPECIFIC_MODIFIERS)
			amount += getUnsafe(beatAmtLaneIDs[axisIdx][lane], player);

		if (amount == 0)
			return curPos;

		final speed = getUnsafe(beatSpeedIDs[axisIdx], player);
		final offset = getUnsafe(beatOffsetIDs[axisIdx], player);
		final mult = getUnsafe(beatMultIDs[axisIdx], player);

		final shift = beatMath(params, offset, 1 + mult, speed) * amount;

		if (realAxisIdx == 0) curPos.x += shift;
		else if (realAxisIdx == 1) curPos.y += shift;
		else curPos.z += shift;

		return curPos;
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		computeBeat(curPos, params, 0, 0); // '' → x
		computeBeat(curPos, params, 1, 0); // 'x' → x
		computeBeat(curPos, params, 2, 1); // 'y' → y
		computeBeat(curPos, params, 3, 2); // 'z' → z

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function allowOnStraightHolds():Bool
		return false;
}
