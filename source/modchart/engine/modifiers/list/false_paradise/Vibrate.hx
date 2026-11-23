package modchart.engine.modifiers.list.false_paradise;

import modchart.backend.core.ModifierParameters;

class Vibrate extends Modifier {
	var amountIDs:Array<Int>;
	var speedID:Int;
	var frequencyID:Int;

	public function new(pf) {
		super(pf);
		amountIDs = [findID('vibrate'), findID('vibrateX'), findID('vibrateY'), findID('vibrateZ')];
		speedID = findID('vibrateSpeed');
		frequencyID = findID('vibrateFrequency');
		setPercent('vibrateSpeed', 1, -1);
		setPercent('vibrateFrequency', 30, -1);
	}

	inline function noise(seed:Float):Float
		return ((Math.abs(sin(seed) * 43758.5453123) % 1) * 2) - 1;

	override public function render(curPos:Vector3, params:ModifierParameters) {
		final player = params.player;
		final common = getUnsafe(amountIDs[0], player);
		final frequency = Math.max(1, Math.abs(getUnsafe(frequencyID, player)));
		final tick = Math.floor(params.songTime * 0.001 * frequency * getUnsafe(speedID, player));
		final seed = tick * 12.9898 + params.sourceTime * 0.017 + params.lane * 78.233 + player * 37.719;
		curPos.x += noise(seed) * (common + getUnsafe(amountIDs[1], player)) * 20;
		curPos.y += noise(seed + 19.19) * (common + getUnsafe(amountIDs[2], player)) * 20;
		curPos.z += noise(seed + 47.47) * getUnsafe(amountIDs[3], player) * 20;

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function isActive(player:Int):Bool
		return getUnsafe(amountIDs[0], player) != 0 || getUnsafe(amountIDs[1], player) != 0
			|| getUnsafe(amountIDs[2], player) != 0 || getUnsafe(amountIDs[3], player) != 0;

	override public function allowOnStraightHolds():Bool return false;
}
