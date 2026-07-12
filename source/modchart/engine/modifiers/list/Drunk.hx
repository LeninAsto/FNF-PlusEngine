package modchart.engine.modifiers.list;

class Drunk extends Modifier {
	var dID:Int;

	var dXID:Int;
	var dYID:Int;
	var dZID:Int;

	var dS:Int;
	var dP:Int;
	var dO:Int;

	public function new(pf) {
		super(pf);

		dID = findID('drunk');

		dXID = findID('drunkx');
		dYID = findID('drunky');
		dZID = findID('drunkz');

		dS = findID('drunkSpeed');
		dP = findID('drunkPeriod');
		dO = findID('drunkOffset');
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		var player = params.player;

		var xVal = getUnsafe(dID, player) + getUnsafe(dXID, player);
		var yVal = getUnsafe(dYID, player);
		var zVal = getUnsafe(dZID, player);

		if (xVal == 0 && yVal == 0 && zVal == 0)
			return curPos;

		var speed = getUnsafe(dS, player);
		var period = getUnsafe(dP, player);
		var offset = getUnsafe(dO, player);

		var shift = params.songTime * 0.001 * (1 + speed) + params.lane * ((offset * 0.2) + 0.2) + params.distance * ((period * 10) + 10) / HEIGHT;
		var drunk = (cos(shift) * ARROW_SIZE * 0.5);

		curPos.x += drunk * xVal;
		curPos.y += drunk * yVal;
		curPos.z += drunk * zVal;

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function allowOnStraightHolds():Bool
		return false;
}
