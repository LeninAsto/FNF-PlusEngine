package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class Transform extends Modifier {
	var xIDs:Array<Int>;
	var yIDs:Array<Int>;
	var zIDs:Array<Int>;

	var xOID = 0;
	var yOID = 0;
	var zOID = 0;

	// Per-lane IDs to avoid Std.string(lane) allocations in hot path
	var xLaneIDs:Array<Array<Int>>;
	var yLaneIDs:Array<Array<Int>>;
	var zLaneIDs:Array<Array<Int>>;

	public function new(pf) {
		super(pf);

		xIDs = [findID('x'), findID('transformX'), findID('moveX')];
		yIDs = [findID('y'), findID('transformY'), findID('moveY')];
		zIDs = [findID('z'), findID('transformZ'), findID('moveZ')];

		xOID = findID('xoffset');
		yOID = findID('yoffset');
		zOID = findID('zoffset');

		final maxKeys = 16;
		xLaneIDs = [for (id in ['x', 'transformX', 'moveX']) [for (i in 0...maxKeys) findID(id + i)]];
		yLaneIDs = [for (id in ['y', 'transformY', 'moveY']) [for (i in 0...maxKeys) findID(id + i)]];
		zLaneIDs = [for (id in ['z', 'transformZ', 'moveZ']) [for (i in 0...maxKeys) findID(id + i)]];
	}

	function getAliasValue(ids:Array<Int>, laneIDs:Array<Array<Int>>, lane:Int, player:Int):Float {
		final laneSlot = getLaneSlot(lane, laneIDs[0].length);
		for (i in 0...laneIDs.length)
			if (hasUnsafeForPlayer(laneIDs[i][laneSlot], player))
				return getUnsafe(ids[i], player) + getUnsafe(laneIDs[i][laneSlot], player);

		for (id in ids)
			if (hasUnsafeForPlayer(id, player))
				return getUnsafe(id, player);

		return 0;
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		var lane = params.lane;
		var player = params.player;

		curPos.x += getAliasValue(xIDs, xLaneIDs, lane, player) + getUnsafe(xOID, player);
		curPos.y += getAliasValue(yIDs, yLaneIDs, lane, player) + getUnsafe(yOID, player);
		curPos.z += getAliasValue(zIDs, zLaneIDs, lane, player) + getUnsafe(zOID, player);

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function isActive(player:Int):Bool {
		if (getUnsafe(xOID, player) != 0 || getUnsafe(yOID, player) != 0 || getUnsafe(zOID, player) != 0)
			return true;
		for (axis in 0...xIDs.length) {
			if (getUnsafe(xIDs[axis], player) != 0 || getUnsafe(yIDs[axis], player) != 0 || getUnsafe(zIDs[axis], player) != 0)
				return true;
			for (lane in 0...xLaneIDs[axis].length)
				if (getUnsafe(xLaneIDs[axis][lane], player) != 0 || getUnsafe(yLaneIDs[axis][lane], player) != 0
					|| getUnsafe(zLaneIDs[axis][lane], player) != 0)
					return true;
		}
		return false;
	}
}
