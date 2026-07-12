package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class Transform extends Modifier {
	var xID = 0;
	var yID = 0;
	var zID = 0;

	var xOID = 0;
	var yOID = 0;
	var zOID = 0;

	// Per-lane IDs to avoid Std.string(lane) allocations in hot path
	var xLaneIDs:Array<Int>;
	var yLaneIDs:Array<Int>;
	var zLaneIDs:Array<Int>;

	public function new(pf) {
		super(pf);

		xID = findID('x');
		yID = findID('y');
		zID = findID('z');

		xOID = findID('xoffset');
		yOID = findID('yoffset');
		zOID = findID('zoffset');

		final maxKeys = 16;
		xLaneIDs = [for (i in 0...maxKeys) findID('x' + i)];
		yLaneIDs = [for (i in 0...maxKeys) findID('y' + i)];
		zLaneIDs = [for (i in 0...maxKeys) findID('z' + i)];
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		var lane = params.lane;
		var player = params.player;

		curPos.x += getUnsafe(xID, player) + getUnsafe(xOID, player) + getUnsafe(xLaneIDs[lane], player);
		curPos.y += getUnsafe(yID, player) + getUnsafe(yOID, player) + getUnsafe(yLaneIDs[lane], player);
		curPos.z += getUnsafe(zID, player) + getUnsafe(zOID, player) + getUnsafe(zLaneIDs[lane], player);

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
