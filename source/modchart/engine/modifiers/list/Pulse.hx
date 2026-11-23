package modchart.engine.modifiers.list;

import flixel.math.FlxMath;
import modchart.backend.core.ModifierParameters;
import modchart.backend.core.TransformMode;
import modchart.backend.core.VisualParameters;

class Pulse extends Modifier {
	var amountIDs:Array<Int>;
	var laneIDs:Array<Array<Int>>;
	var speedID:Int;
	var offsetID:Int;
	var minID:Int;
	var maxID:Int;
	var innerID:Int;
	var outerID:Int;
	var pathPeriodID:Int;
	var pathOffsetID:Int;

	public function new(pf) {
		super(pf);
		amountIDs = [findID('pulse'), findID('pulseX'), findID('pulseY')];
		laneIDs = [for (name in ['pulse', 'pulseX', 'pulseY']) [for (lane in 0...16) findID(name + lane)]];
		speedID = findID('pulseSpeed');
		offsetID = findID('pulseOffset');
		minID = findID('pulseMin');
		maxID = findID('pulseMax');
		innerID = findID('pulseInner');
		outerID = findID('pulseOuter');
		pathPeriodID = findID('pulsePeriod');
		pathOffsetID = findID('pulsePathOffset');
		setPercent('pulseSpeed', 1, -1);
		setPercent('pulseMin', 0.75, -1);
		setPercent('pulseMax', 1.25, -1);
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters):VisualParameters {
		final lane = getLaneSlot(params.lane, laneIDs[0].length);
		final player = params.player;
		final common = getUnsafeLaneAdd(amountIDs[0], laneIDs[0][lane], player);
		final x = common + getUnsafeLaneAdd(amountIDs[1], laneIDs[1][lane], player);
		final y = common + getUnsafeLaneAdd(amountIDs[2], laneIDs[2][lane], player);
		if (x != 0 || y != 0) {
			final wave = (sin((params.curBeat * getUnsafe(speedID, player) + getUnsafe(offsetID, player)) * Math.PI * 2) + 1) * 0.5;
			final scale = FlxMath.lerp(getUnsafe(minID, player), getUnsafe(maxID, player), wave);
			if (x != 0) data.scaleX *= FlxMath.lerp(1, scale, x);
			if (y != 0) data.scaleY *= FlxMath.lerp(1, scale, y);
		}

		final inner = getUnsafe(innerID, player);
		final outer = getUnsafe(outerID, player);
		if (inner != 0 || outer != 0) {
			final period = Math.max(0.05, 1 + getUnsafe(pathPeriodID, player));
			final pathOffset = getUnsafe(offsetID, player) + getUnsafe(pathOffsetID, player);
			final phase = (params.distance + 100 * pathOffset) / (0.4 * ARROW_SIZE * period);
			final pathScale = Math.max(0.01, 1 + inner * 0.5 + sin(phase) * outer * 0.5);
			data.scaleX *= pathScale;
			data.scaleY *= pathScale;
		}
		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool return true;
	override public function isActive(player:Int):Bool {
		for (axis in 0...amountIDs.length) {
			if (getUnsafe(amountIDs[axis], player) != 0) return true;
			for (id in laneIDs[axis]) if (getUnsafe(id, player) != 0) return true;
		}
		return getUnsafe(innerID, player) != 0 || getUnsafe(outerID, player) != 0;
	}
	override public function transformMode():TransformMode return TransformMode.FIELD;
}
