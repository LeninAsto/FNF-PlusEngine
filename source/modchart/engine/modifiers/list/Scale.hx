package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;
import modchart.backend.core.VisualParameters;

class Scale extends Modifier {
	// Pre-computed IDs indexed by axisIdx (0='', 1='x', 2='y') to avoid Std.string(lane) allocations.
	static final AXES_S = ['', 'x', 'y'];

	var scaleIDs:Array<Int>;
	var scaleLaneIDs:Array<Array<Int>>;
	var tinyIDs:Array<Int>;
	var tinyLaneIDs:Array<Array<Int>>;
	var miniID:Int;
	var miniLaneIDs:Array<Int>;
	var stretchID:Int;
	var stretchLaneIDs:Array<Int>;

	public function new(pf) {
		super(pf);

		setPercent('scale', 1, -1);
		setPercent('scaleX', 1, -1);
		setPercent('scaleY', 1, -1);
		setPercent('stretch', 0, -1);

		final maxKeys = 16;
		scaleIDs = [for (a in AXES_S) findID('scale' + a)];
		scaleLaneIDs = [for (a in AXES_S) [for (l in 0...maxKeys) findID('scale' + a + l)]];
		tinyIDs = [for (a in AXES_S) findID('tiny' + a)];
		tinyLaneIDs = [for (a in AXES_S) [for (l in 0...maxKeys) findID('tiny' + a + l)]];
		miniID = findID('mini');
		miniLaneIDs = [for (l in 0...maxKeys) findID('mini' + l)];
		stretchID = findID('stretch');
		stretchLaneIDs = [for (l in 0...maxKeys) findID('stretch' + l)];
	}

	// axisIdx: 0='' 1='x' 2='y'; realAxisIdx: 0=both 1=x 2=y
	private inline function applyScale(vis:VisualParameters, params:ModifierParameters, axisIdx:Int, realAxisIdx:Int) {
		final lane = params.lane;
		final player = params.player;

		var scaleV = getUnsafe(scaleIDs[axisIdx], player);
		var tinyV = getUnsafe(tinyIDs[axisIdx], player);
		var miniV = getUnsafe(miniID, player);
		if (Config.COLUMN_SPECIFIC_MODIFIERS) {
			scaleV += getUnsafe(scaleLaneIDs[axisIdx][lane], player);
			tinyV += getUnsafe(tinyLaneIDs[axisIdx][lane], player);
			miniV += getUnsafe(miniLaneIDs[lane], player);
		}

		var scale = scaleV;
		scale *= 1 - tinyV * 0.5;
		scale *= 1 - miniV * 0.5;

		if (realAxisIdx == 1) vis.scaleX *= scale;
		else if (realAxisIdx == 2) vis.scaleY *= scale;
		else { vis.scaleX *= scale; vis.scaleY *= scale; }
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters) {
		applyScale(data, params, 0, 0); // '' → both
		applyScale(data, params, 1, 1); // 'x' → x
		applyScale(data, params, 2, 2); // 'y' → y

		// stretch sub-mod: compress X and elongate Y
		var stretchV = getUnsafe(stretchID, params.player);
		if (Config.COLUMN_SPECIFIC_MODIFIERS)
			stretchV += getUnsafe(stretchLaneIDs[params.lane], params.player);
		if (stretchV != 0) {
			data.scaleX *= 1.0 - 0.5 * stretchV;
			data.scaleY *= 1.0 + stretchV;
		}

		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
