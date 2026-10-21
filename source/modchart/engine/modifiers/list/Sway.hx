package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;
import modchart.backend.core.TransformMode;

class Sway extends Modifier {
	var amountIDs:Array<Int>;
	var speedID:Int;
	var periodID:Int;
	var offsetID:Int;
	var lanePhaseID:Int;

	public function new(pf) {
		super(pf);
		amountIDs = [findID('swayX'), findID('swayY'), findID('swayZ')];
		speedID = findID('swaySpeed');
		periodID = findID('swayPeriod');
		offsetID = findID('swayOffset');
		lanePhaseID = findID('swayLanePhase');
		setPercent('swaySpeed', 1, -1);
		setPercent('swayPeriod', 4, -1);
	}

	override public function render(pos:Vector3, params:ModifierParameters) {
		final player = params.player;
		final period = Math.max(0.001, Math.abs(getUnsafe(periodID, player)));
		final phase = ((params.curBeat * getUnsafe(speedID, player)) / period + getUnsafe(offsetID, player)
			+ params.lane * getUnsafe(lanePhaseID, player)) * Math.PI * 2;
		final wave = sin(phase);
		pos.x += wave * getUnsafe(amountIDs[0], player);
		pos.y += wave * getUnsafe(amountIDs[1], player);
		pos.z += wave * getUnsafe(amountIDs[2], player);
		return pos;
	}

	override public function shouldRun(params:ModifierParameters):Bool return true;
	override public function isActive(player:Int):Bool
		return getUnsafe(amountIDs[0], player) != 0 || getUnsafe(amountIDs[1], player) != 0 || getUnsafe(amountIDs[2], player) != 0;
	override public function transformMode():TransformMode return TransformMode.FIELD;
}
