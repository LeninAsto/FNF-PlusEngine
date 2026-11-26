package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;

class Invert extends Modifier {
	var invID = 0;
	var flpID = 0;

	public function new(pf) {
		super(pf);

		invID = findID('invert');
		flpID = findID('flip');
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		final player = params.player;
		final lane = params.lane;
		final keys = getKeyCount(player);
		final mirror = keys - 1 - lane;
		final pair = lane % 2 == 0 ? lane + 1 : lane - 1;
		if (lane < 0 || mirror < 0 || pair >= keys) return curPos;

		// Interpolate actual receptor positions, including custom spacing. Apply
		// invert after flip so that both modifiers form a permutation instead of
		// adding two independent offsets and overshooting the destination lane.
		final flippedPair = keys - 1 - pair;
		final baseX = getReceptorX(lane, player);
		final flip = getUnsafe(flpID, player);
		final invert = getUnsafe(invID, player);
		final flipDelta = getReceptorX(mirror, player) - baseX;
		final pairDelta = getReceptorX(pair, player) - baseX;
		final flippedPairDelta = getReceptorX(flippedPair, player) - getReceptorX(mirror, player);
		curPos.x += flip * flipDelta + invert * (pairDelta + flip * (flippedPairDelta - pairDelta));

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function isActive(player:Int):Bool
		return getUnsafe(invID, player) != 0 || getUnsafe(flpID, player) != 0;
}
