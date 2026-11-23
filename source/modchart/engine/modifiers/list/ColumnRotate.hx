package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;
import modchart.backend.util.ModchartUtil;

class ColumnRotate extends Modifier {
	var xIDs:Array<Int>;
	var yIDs:Array<Int>;
	var zIDs:Array<Int>;
	final origin:Vector3 = new Vector3();

	public function new(pf) {
		super(pf);
		xIDs = [for (lane in 0...16) findID(lane + 'rotateX')];
		yIDs = [for (lane in 0...16) findID(lane + 'rotateY')];
		zIDs = [for (lane in 0...16) findID(lane + 'rotateZ')];
	}

	override public function render(pos:Vector3, params:ModifierParameters) {
		final lane = getLaneSlot(params.lane, xIDs.length);
		final x = getUnsafe(xIDs[lane], params.player);
		final y = getUnsafe(yIDs[lane], params.player);
		final z = getUnsafe(zIDs[lane], params.player);
		if (x == 0 && y == 0 && z == 0) return pos;
		origin.setTo(getReceptorX(params.lane, params.player) + ARROW_SIZEDIV2, HEIGHT * 0.5, 0);
		pos -= origin;
		ModchartUtil.rotate3DVectorInto(pos, x, y, z, pos);
		pos += origin;
		return pos;
	}

	override public function shouldRun(params:ModifierParameters):Bool return true;
	override public function isActive(player:Int):Bool {
		for (lane in 0...xIDs.length)
			if (getUnsafe(xIDs[lane], player) != 0 || getUnsafe(yIDs[lane], player) != 0 || getUnsafe(zIDs[lane], player) != 0) return true;
		return false;
	}
	override public function allowOnStraightHolds():Bool return false;
}
