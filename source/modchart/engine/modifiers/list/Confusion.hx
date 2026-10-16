package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;
import modchart.backend.core.VisualParameters;

class Confusion extends Modifier {
	// Pre-computed IDs indexed by axisIdx (0='', 1='x', 2='y', 3='z') to avoid Std.string(lane) allocations.
	static final AXES = ['', 'x', 'y', 'z'];

	var confusionIDs:Array<Int>;
	var confusionLaneIDs:Array<Array<Int>>;
	var angleIDs:Array<Int>;
	var angleLaneIDs:Array<Array<Int>>;
	var confusionOffIDs:Array<Int>;
	var confusionOffLaneIDs:Array<Array<Int>>;
	// dizzy/roll/twirl IDs (one per realAxisIdx: 0=z/dizzy, 1=x/roll, 2=y/twirl)
	var dizzySpeedIDs:Array<Int>; // [dizzySpeed, rollSpeed, twirlSpeed]
	var dizzyIDs:Array<Int>;      // [dizzy,      roll,      twirl]

	public function new(pf) {
		super(pf);

		final maxKeys = 16;
		confusionIDs = [for (a in AXES) findID('confusion' + a)];
		confusionLaneIDs = [for (a in AXES) [for (l in 0...maxKeys) findID('confusion' + a + l)]];
		angleIDs = [for (a in AXES) findID('angle' + a)];
		angleLaneIDs = [for (a in AXES) [for (l in 0...maxKeys) findID('angle' + a + l)]];
		confusionOffIDs = [for (a in AXES) findID('confusionOffset' + a)];
		confusionOffLaneIDs = [for (a in AXES) [for (l in 0...maxKeys) findID('confusionOffset' + a + l)]];
		// realAxisIdx 0='z'→dizzy, 1='x'→roll, 2='y'→twirl
		dizzyIDs = [findID('dizzy'), findID('roll'), findID('twirl')];
		dizzySpeedIDs = [findID('dizzySpeed'), findID('rollSpeed'), findID('twirlSpeed')];
	}

	// axisIdx: 0='' 1='x' 2='y' 3='z'; realAxisIdx: 0=z 1=x 2=y
	private inline function applyConfusion(vis:VisualParameters, params:ModifierParameters, axisIdx:Int, realAxisIdx:Int) {
		final lane = getLaneSlot(params.lane, confusionLaneIDs[axisIdx].length);
		final player = params.player;

		var confVal = getUnsafe(confusionIDs[axisIdx], player);
		var angVal = getUnsafe(angleIDs[axisIdx], player);
		var offVal = getUnsafe(confusionOffIDs[axisIdx], player);
		if (Config.COLUMN_SPECIFIC_MODIFIERS) {
			confVal = getUnsafeLaneAdd(confusionIDs[axisIdx], confusionLaneIDs[axisIdx][lane], player);
			angVal = getUnsafeLaneAdd(angleIDs[axisIdx], angleLaneIDs[axisIdx][lane], player);
			offVal = getUnsafeLaneAdd(confusionOffIDs[axisIdx], confusionOffLaneIDs[axisIdx][lane], player);
		}

		var angle = 0.;
		// PlusEngine keeps confusion as a static angle. Continuous rotation
		// belongs to dizzy/roll/twirl below.
		angle += confVal;
		angle += angVal;
		angle += offVal;

		// dizzy/roll/twirl: realAxisIdx 0→dizzy, 1→roll, 2→twirl
		final dc = getUnsafe(dizzyIDs[realAxisIdx], player);
		if (dc != 0)
			angle += dc * (params.distance * 0.1 * (1 + getUnsafe(dizzySpeedIDs[realAxisIdx], player)));

		if (realAxisIdx == 1) vis.angleX += angle;
		else if (realAxisIdx == 2) vis.angleY += angle;
		else vis.angleZ += angle;
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters) {
		// axisIdx 0='' realAxisIdx 0=z, axisIdx 1='x' realAxisIdx 1=x, etc.
		applyConfusion(data, params, 0, 0); // '' → z
		applyConfusion(data, params, 1, 1); // 'x' → x
		applyConfusion(data, params, 2, 2); // 'y' → y
		applyConfusion(data, params, 3, 0); // 'z' → z (same dizzy bucket as '')

		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function isActive(player:Int):Bool {
		for (axis in 0...confusionIDs.length) {
			if (getUnsafe(confusionIDs[axis], player) != 0 || getUnsafe(angleIDs[axis], player) != 0
				|| getUnsafe(confusionOffIDs[axis], player) != 0)
				return true;
			if (Config.COLUMN_SPECIFIC_MODIFIERS)
				for (lane in 0...confusionLaneIDs[axis].length)
					if (getUnsafe(confusionLaneIDs[axis][lane], player) != 0 || getUnsafe(angleLaneIDs[axis][lane], player) != 0
						|| getUnsafe(confusionOffLaneIDs[axis][lane], player) != 0)
						return true;
		}
		for (i in 0...dizzyIDs.length)
			if (getUnsafe(dizzyIDs[i], player) != 0)
				return true;
		return false;
	}
}
