package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;
import modchart.backend.util.ModchartUtil;

class Tangent extends Modifier {
	var drunkIDs:Array<Int>;
	var tipsyIDs:Array<Int>;
	var bumpyIDs:Array<Int>;
	var drunkSpeedIDs:Array<Int>;
	var drunkPeriodIDs:Array<Int>;
	var drunkOffsetIDs:Array<Int>;
	var tipsySpeedIDs:Array<Int>;
	var tipsyOffsetIDs:Array<Int>;
	var bumpyPeriodIDs:Array<Int>;
	var bumpyOffsetIDs:Array<Int>;
	var cosecantID:Int;
	var limitID:Int;

	public function new(pf) {
		super(pf);
		drunkIDs = [findID('drunkTan'), findID('drunkTanY'), findID('drunkTanZ')];
		tipsyIDs = [findID('tipsyTanX'), findID('tipsyTan'), findID('tipsyTanZ')];
		bumpyIDs = [findID('bumpyTanX'), findID('bumpyTanY'), findID('bumpyTan')];
		drunkSpeedIDs = [for (name in ['drunkTan', 'drunkTanY', 'drunkTanZ']) findID(name + 'Speed')];
		drunkPeriodIDs = [for (name in ['drunkTan', 'drunkTanY', 'drunkTanZ']) findID(name + 'Period')];
		drunkOffsetIDs = [for (name in ['drunkTan', 'drunkTanY', 'drunkTanZ']) findID(name + 'Offset')];
		tipsySpeedIDs = [for (name in ['tipsyTanX', 'tipsyTan', 'tipsyTanZ']) findID(name + 'Speed')];
		tipsyOffsetIDs = [for (name in ['tipsyTanX', 'tipsyTan', 'tipsyTanZ']) findID(name + 'Offset')];
		bumpyPeriodIDs = [for (name in ['bumpyTanX', 'bumpyTanY', 'bumpyTan']) findID(name + 'Period')];
		bumpyOffsetIDs = [for (name in ['bumpyTanX', 'bumpyTanY', 'bumpyTan']) findID(name + 'Offset')];
		cosecantID = findID('cosecant');
		limitID = findID('tangentLimit');
		setPercent('tangentLimit', 4, -1);
	}

	inline function tangentWave(value:Float, limit:Float, useCosecant:Bool):Float {
		var result = tan(value);
		if (useCosecant) {
			final sine = sin(value);
			result = Math.abs(sine) < 0.0001 ? (sine < 0 ? -limit : limit) : 1 / sine;
		}
		return ModchartUtil.clamp(result, -limit, limit);
	}

	inline function axisShift(axis:Int, params:ModifierParameters, player:Int, limit:Float, useCosecant:Bool):Float {
		var result = 0.0;
		final drunk = getUnsafe(drunkIDs[axis], player);
		if (drunk != 0) {
			final phase = params.songTime * 0.001 * (1 + getUnsafe(drunkSpeedIDs[axis], player))
				+ params.lane * 0.2 + params.distance * (10 + getUnsafe(drunkPeriodIDs[axis], player) * 10) / HEIGHT
				+ getUnsafe(drunkOffsetIDs[axis], player);
			result += tangentWave(phase, limit, useCosecant) * ARROW_SIZEDIV2 * drunk;
		}
		final tipsy = getUnsafe(tipsyIDs[axis], player);
		if (tipsy != 0) {
			final phase = params.songTime * 0.001 * (1.2 + getUnsafe(tipsySpeedIDs[axis], player) * 1.2)
				+ params.lane * 1.8 + getUnsafe(tipsyOffsetIDs[axis], player);
			result += tangentWave(phase, limit, useCosecant) * ARROW_SIZE * 0.4 * tipsy;
		}
		final bumpy = getUnsafe(bumpyIDs[axis], player);
		if (bumpy != 0) {
			final period = Math.max(0.01, 24 + getUnsafe(bumpyPeriodIDs[axis], player) * 24);
			final phase = (params.distance + getUnsafe(bumpyOffsetIDs[axis], player) * 100) / period;
			result += tangentWave(phase, limit, useCosecant) * 40 * bumpy;
		}
		return result;
	}

	override public function render(pos:Vector3, params:ModifierParameters) {
		final player = params.player;
		final limit = Math.max(0.1, Math.abs(getUnsafe(limitID, player)));
		final useCosecant = getUnsafe(cosecantID, player) > 0.5;
		pos.x += axisShift(0, params, player, limit, useCosecant);
		pos.y += axisShift(1, params, player, limit, useCosecant);
		pos.z += axisShift(2, params, player, limit, useCosecant);
		return pos;
	}

	override public function shouldRun(params:ModifierParameters):Bool return true;
	override public function isActive(player:Int):Bool {
		for (axis in 0...3)
			if (getUnsafe(drunkIDs[axis], player) != 0 || getUnsafe(tipsyIDs[axis], player) != 0 || getUnsafe(bumpyIDs[axis], player) != 0) return true;
		return false;
	}
	override public function allowOnStraightHolds():Bool return false;
}
