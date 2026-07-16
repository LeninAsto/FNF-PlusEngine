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
		for (aliasLaneIDs in laneIDs)
			if (hasUnsafe(aliasLaneIDs[lane]))
				return getUnsafe(aliasLaneIDs[lane], player);

		for (id in ids)
			if (hasUnsafe(id))
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
}
