package modchart.engine.modifiers.list;

import flixel.math.FlxAngle;
import modchart.backend.core.ModifierParameters;
import modchart.backend.core.VisualParameters;

class Skew extends Modifier {
	var xID = 0;
	var yID = 0;
	var fieldXID = 0;
	var fieldYID = 0;

	// Per-lane IDs to avoid Std.string(lane) allocations in hot path
	var xLaneIDs:Array<Int>;
	var yLaneIDs:Array<Int>;

	public function new(pf) {
		super(pf);

		xID = findID('skewX');
		yID = findID('skewY');
		fieldXID = findID('fieldSkewX');
		fieldYID = findID('fieldSkewY');

		final maxKeys = 16;
		xLaneIDs = [for (i in 0...maxKeys) findID('skewX' + i)];
		yLaneIDs = [for (i in 0...maxKeys) findID('skewY' + i)];
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		final player = params.player;
		final fieldSkewX = getUnsafe(fieldXID, player);
		final fieldSkewY = getUnsafe(fieldYID, player);

		if (fieldSkewX == 0 && fieldSkewY == 0)
			return curPos;

		final keyCount = getKeyCount(player);
		if (keyCount <= 0)
			return curPos;

		final leftX = getReceptorX(0, player);
		final originX = leftX;
		final originY = 0.0;

		final dx = curPos.x - originX;
		final dy = curPos.y - originY;
		final skewYTan = fieldSkewY != 0 ? Math.tan(fieldSkewY * FlxAngle.TO_RAD) : 0.0;
		final skewXTan = fieldSkewX != 0 ? Math.tan(fieldSkewX * FlxAngle.TO_RAD) : 0.0;

		curPos.x = originX + dx + (dy * skewXTan);
		curPos.y = originY + dy + (dx * skewYTan);

		return curPos;
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters):VisualParameters {
		final lane = params.lane;
		final player = params.player;

		data.skewX += getUnsafe(xID, player) + getUnsafe(xLaneIDs[lane], player);
		data.skewY += getUnsafe(yID, player) + getUnsafe(yLaneIDs[lane], player);

		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
