package modchart.engine.modifiers.list;

import flixel.math.FlxMath;
import modchart.backend.core.ModifierParameters;
import modchart.backend.util.ModchartUtil;
class Boost extends Modifier {
	// Pre-computed IDs to avoid Std.string(lane) allocations in hot path
	var _boostID:Int;
	var _brakeID:Int;
	var _waveID:Int;
	var _waveMult:Int;
	var _boostIDs:Array<Int>;
	var _brakeIDs:Array<Int>;
	var _waveIDs:Array<Int>;

	public function new(pf) {
		super(pf);

		setPercent('waveMult', 1, -1);

		final maxKeys = 16;
		_boostID = findID('boost');
		_brakeID = findID('brake');
		_waveID = findID('wave');
		_waveMult = findID('waveMult');
		_boostIDs = [for (i in 0...maxKeys) findID('boost' + i)];
		_brakeIDs = [for (i in 0...maxKeys) findID('brake' + i)];
		_waveIDs = [for (i in 0...maxKeys) findID('wave' + i)];
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		var player = params.player;
		var lane = params.lane;

		var fYOffset = params.distance;

		final boost = (getUnsafe(_boostID, player) + getUnsafe(_boostIDs[lane], player));
		if (boost != 0) {
			var fEffectHeight = HEIGHT;
			var fNewYOffset = fYOffset * 1.5 / ((fYOffset + fEffectHeight / 1.2) / fEffectHeight);
			var fAccelYAdjust = .75 * boost * (fNewYOffset - fYOffset);
			fAccelYAdjust = ModchartUtil.clamp(fAccelYAdjust, -400, 400);

			curPos.y += fAccelYAdjust;
		}

		final brake = (getUnsafe(_brakeID, player) + getUnsafe(_brakeIDs[lane], player));

		if (brake != 0) {
			var fEffectHeight = HEIGHT;
			var fScale = FlxMath.remapToRange(fYOffset, 0., fEffectHeight, 0, 1.);
			var fNewYOffset = fYOffset * fScale;
			var fBrakeYAdjust = .75 * brake * (fNewYOffset - fYOffset);
			fBrakeYAdjust = ModchartUtil.clamp(fBrakeYAdjust, -400., 400.);
			curPos.y += fBrakeYAdjust;
		}
		final wave = (getUnsafe(_waveID, player) + getUnsafe(_waveIDs[lane], player));

		if (wave != 0) {
			curPos.y += wave * 20.0 * sin(fYOffset / 96.);
		}

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
