package modchart.engine.modifiers.list;

class Drunk extends Modifier {
	var dID:Int;

	var dXID:Int;
	var dYID:Int;
	var dZID:Int;

	var dS:Int;
	var dP:Int;
	var dO:Int;
	var amountLaneIDs:Array<Array<Int>>;
	var speedIDs:Array<Int>;
	var periodIDs:Array<Int>;
	var offsetIDs:Array<Int>;

	public function new(pf) {
		super(pf);

		dID = findID('drunk');

		dXID = findID('drunkx');
		dYID = findID('drunky');
		dZID = findID('drunkz');

		dS = findID('drunkSpeed');
		dP = findID('drunkPeriod');
		dO = findID('drunkOffset');
		amountLaneIDs = [
			[for (lane in 0...16) findID('drunk' + lane)],
			[for (lane in 0...16) findID('drunkY' + lane)],
			[for (lane in 0...16) findID('drunkZ' + lane)]
		];
		speedIDs = [findID('drunkXSpeed'), findID('drunkYSpeed'), findID('drunkZSpeed')];
		periodIDs = [findID('drunkXPeriod'), findID('drunkYPeriod'), findID('drunkZPeriod')];
		offsetIDs = [findID('drunkXOffset'), findID('drunkYOffset'), findID('drunkZOffset')];
	}

	inline function axisShift(params:ModifierParameters, axis:Int, amount:Float):Float {
		if (amount == 0) return 0;
		final player = params.player;
		final speed = hasUnsafeForPlayer(speedIDs[axis], player) ? getUnsafe(speedIDs[axis], player) : getUnsafe(dS, player);
		final period = hasUnsafeForPlayer(periodIDs[axis], player) ? getUnsafe(periodIDs[axis], player) : getUnsafe(dP, player);
		final offset = hasUnsafeForPlayer(offsetIDs[axis], player) ? getUnsafe(offsetIDs[axis], player) : getUnsafe(dO, player);
		final phase = params.songTime * 0.001 * (1 + speed) + params.lane * ((offset * 0.2) + 0.2)
			+ params.distance * ((period * 10) + 10) / HEIGHT;
		return cos(phase) * ARROW_SIZE * 0.5 * amount;
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		final player = params.player;

		final lane = getLaneSlot(params.lane, amountLaneIDs[0].length);
		final xVal = getUnsafe(dID, player) + getUnsafe(dXID, player) + getUnsafe(amountLaneIDs[0][lane], player);
		final yVal = getUnsafe(dYID, player) + getUnsafe(amountLaneIDs[1][lane], player);
		final zVal = getUnsafe(dZID, player) + getUnsafe(amountLaneIDs[2][lane], player);

		if (xVal == 0 && yVal == 0 && zVal == 0)
			return curPos;

		curPos.x += axisShift(params, 0, xVal);
		curPos.y += axisShift(params, 1, yVal);
		curPos.z += axisShift(params, 2, zVal);

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function isActive(player:Int):Bool
	{
		if (getUnsafe(dID, player) != 0 || getUnsafe(dXID, player) != 0 || getUnsafe(dYID, player) != 0 || getUnsafe(dZID, player) != 0) return true;
		for (axis in amountLaneIDs) for (id in axis) if (getUnsafe(id, player) != 0) return true;
		return false;
	}

	override public function allowOnStraightHolds():Bool
		return false;
}
