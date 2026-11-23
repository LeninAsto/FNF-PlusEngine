package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class XMode extends Modifier {
	var amountID:Int;
	var laneIDs:Array<Int>;

	public function new(pf) {
		super(pf);
		amountID = findID('xmode');
		laneIDs = [for (lane in 0...16) findID('xmode' + lane)];
	}

	override public function render(pos:Vector3, params:ModifierParameters) {
		final lane = getLaneSlot(params.lane, laneIDs.length);
		final amount = getUnsafeLaneAdd(amountID, laneIDs[lane], params.player);
		if (amount != 0) {
			final side = params.player == 0 ? -1 : 1;
			pos.x += params.distance * getScrollSpeed() * side * amount;
		}
		return pos;
	}

	override public function shouldRun(params:ModifierParameters):Bool return true;
	override public function isActive(player:Int):Bool {
		if (getUnsafe(amountID, player) != 0) return true;
		for (id in laneIDs) if (getUnsafe(id, player) != 0) return true;
		return false;
	}
	override public function allowOnStraightHolds():Bool return false;
}
