package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class Bumpy extends Modifier {
	// Pre-computed IDs indexed by axisIdx (0='', 1='x', 2='y', 3='z') to avoid Std.string(lane) allocations.
	static final AXES = ['', 'x', 'y', 'z'];

	var _bumpyAmtID:Array<Int>;
	var _bumpyAmtLaneIDs:Array<Array<Int>>;
	var _bumpyOffID:Array<Int>;
	var _bumpyOffLaneIDs:Array<Array<Int>>;
	var _bumpyPeriodID:Array<Int>;
	var _bumpyPeriodLaneIDs:Array<Array<Int>>;
	var _bumpyMultID:Array<Int>;
	var _bumpyMultLaneIDs:Array<Array<Int>>;
	// bumpyAngle variants
	var _angAmtID:Array<Int>;
	var _angAmtLaneIDs:Array<Array<Int>>;
	var _angOffID:Array<Int>;
	var _angOffLaneIDs:Array<Array<Int>>;
	var _angPeriodID:Array<Int>;
	var _angPeriodLaneIDs:Array<Array<Int>>;
	var _angMultID:Array<Int>;
	var _angMultLaneIDs:Array<Array<Int>>;

	public function new(pf) {
		super(pf);

		for (x in ['', 'X', 'Y', 'Z']) {
			setPercent('bumpy' + x + 'Mult', 1, -1);
			setPercent('bumpyAngle' + x + 'Mult', 1, -1);
		}

		final maxKeys = 16;
		_bumpyAmtID = [for (a in AXES) findID('bumpy' + a)];
		_bumpyAmtLaneIDs = [for (a in AXES) [for (l in 0...maxKeys) findID('bumpy' + a + l)]];
		_bumpyOffID = [for (a in AXES) findID('bumpy' + a + 'Offset')];
		_bumpyOffLaneIDs = [for (a in AXES) [for (l in 0...maxKeys) findID('bumpy' + a + l + 'Offset')]];
		_bumpyPeriodID = [for (a in AXES) findID('bumpy' + a + 'Period')];
		_bumpyPeriodLaneIDs = [for (a in AXES) [for (l in 0...maxKeys) findID('bumpy' + a + l + 'Period')]];
		_bumpyMultID = [for (a in AXES) findID('bumpy' + a + 'Mult')];
		_bumpyMultLaneIDs = [for (a in AXES) [for (l in 0...maxKeys) findID('bumpy' + a + l + 'Mult')]];

		_angAmtID = [for (a in AXES) findID('bumpyAngle' + a)];
		_angAmtLaneIDs = [for (a in AXES) [for (l in 0...maxKeys) findID('bumpyAngle' + a + l)]];
		_angOffID = [for (a in AXES) findID('bumpyAngle' + a + 'Offset')];
		_angOffLaneIDs = [for (a in AXES) [for (l in 0...maxKeys) findID('bumpyAngle' + a + l + 'Offset')]];
		_angPeriodID = [for (a in AXES) findID('bumpyAngle' + a + 'Period')];
		_angPeriodLaneIDs = [for (a in AXES) [for (l in 0...maxKeys) findID('bumpyAngle' + a + l + 'Period')]];
		_angMultID = [for (a in AXES) findID('bumpyAngle' + a + 'Mult')];
		_angMultLaneIDs = [for (a in AXES) [for (l in 0...maxKeys) findID('bumpyAngle' + a + l + 'Mult')]];
	}

	// axisIdx: 0='' 1='x' 2='y' 3='z'; realAxisIdx: 0=z 1=x 2=y
	private inline function applyBumpy(curPos:Vector3, params:ModifierParameters, axisIdx:Int, realAxisIdx:Int) {
		final lane = params.lane;
		final player = params.player;
		var distance = params.distance;

		var offset = getUnsafe(_bumpyOffID[axisIdx], player);
		var period = getUnsafe(_bumpyPeriodID[axisIdx], player);
		var mult = getUnsafe(_bumpyMultID[axisIdx], player);
		var amt = getUnsafe(_bumpyAmtID[axisIdx], player);
		if (Config.COLUMN_SPECIFIC_MODIFIERS) {
			offset += getUnsafe(_bumpyOffLaneIDs[axisIdx][lane], player);
			period += getUnsafe(_bumpyPeriodLaneIDs[axisIdx][lane], player);
			mult += getUnsafe(_bumpyMultLaneIDs[axisIdx][lane], player);
			amt += getUnsafe(_bumpyAmtLaneIDs[axisIdx][lane], player);
		}

		if (amt == 0)
			return;

		final scrollSpeed = getScrollSpeed();
		final bumpyMath = 40 * sin(((distance * 0.01) + (100.0 * offset) / ((period * (mult * 24.0)) +
			24.0)) / ((scrollSpeed * mult) / 2)) * (getKeyCount() / 2.0);
		final shift = amt * bumpyMath;

		if (realAxisIdx == 1) curPos.x += shift;
		else if (realAxisIdx == 2) curPos.y += shift;
		else curPos.z += shift;
	}

	// axisIdx: 0='' 1='x' 2='y' 3='z'; realAxisIdx: 0=z 1=x 2=y
	private inline function applyAngle(vis:VisualParameters, params:ModifierParameters, axisIdx:Int, realAxisIdx:Int) {
		final lane = params.lane;
		final player = params.player;
		var distance = params.distance;

		var offset = getUnsafe(_angOffID[axisIdx], player);
		var period = getUnsafe(_angPeriodID[axisIdx], player);
		var mult = getUnsafe(_angMultID[axisIdx], player);
		var amt = getUnsafe(_angAmtID[axisIdx], player);
		if (Config.COLUMN_SPECIFIC_MODIFIERS) {
			offset += getUnsafe(_angOffLaneIDs[axisIdx][lane], player);
			period += getUnsafe(_angPeriodLaneIDs[axisIdx][lane], player);
			mult += getUnsafe(_angMultLaneIDs[axisIdx][lane], player);
			amt += getUnsafe(_angAmtLaneIDs[axisIdx][lane], player);
		}

		if (amt == 0)
			return;

		final scrollSpeed = getScrollSpeed();
		final bumpyMath = 40 * sin(((distance * 0.01) + (100.0 * offset) / ((period * (mult * 24.0)) +
			24.0)) / ((scrollSpeed * mult) / 2)) * (getKeyCount() / 2.0);
		final shift = amt * bumpyMath;

		if (realAxisIdx == 1) vis.angleX += shift;
		else if (realAxisIdx == 2) vis.angleY += shift;
		else vis.angleZ += shift;
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		applyBumpy(curPos, params, 0, 0); // '' → z
		applyBumpy(curPos, params, 1, 1); // 'x' → x
		applyBumpy(curPos, params, 2, 2); // 'y' → y
		applyBumpy(curPos, params, 3, 0); // 'z' → z

		return curPos;
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters) {
		applyAngle(data, params, 0, 0); // '' → z
		applyAngle(data, params, 1, 1); // 'x' → x
		applyAngle(data, params, 2, 2); // 'y' → y
		applyAngle(data, params, 3, 0); // 'z' → z

		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function allowOnStraightHolds():Bool
		return false;
}
