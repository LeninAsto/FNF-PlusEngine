package modchart.engine.modifiers.list;

import flixel.math.FlxMath;
import modchart.backend.core.ModifierParameters;
import modchart.backend.core.VisualParameters;

class Stealth extends Modifier {
	// Pre-computed hashed IDs to avoid Std.string(lane) allocations in hot path.
	var _stealthID:Int;
	var _darkID:Int;
	var _alphaID:Int;
	var _stealthIDs:Array<Int>;
	var _darkIDs:Array<Int>;
	var _alphaIDs:Array<Int>;
	var _suddenID:Int;
	var _suddenStartID:Int;
	var _suddenEndID:Int;
	var _suddenGlowID:Int;
	var _hiddenID:Int;
	var _hiddenStartID:Int;
	var _hiddenEndID:Int;
	var _hiddenGlowID:Int;

	public function new(pf) {
		super(pf);

		setPercent('alpha', 1, -1);

		setPercent('suddenStart', 5, -1);
		setPercent('suddenEnd', 3, -1);
		setPercent('suddenGlow', 1, -1);

		setPercent('hiddenStart', 5, -1);
		setPercent('hiddenEnd', 3, -1);
		setPercent('hiddenGlow', 1, -1);

		final maxKeys = 16;
		_stealthID = findID('stealth');
		_darkID = findID('dark');
		_alphaID = findID('alpha');
		_suddenID = findID('sudden');
		_suddenStartID = findID('suddenStart');
		_suddenEndID = findID('suddenEnd');
		_suddenGlowID = findID('suddenGlow');
		_hiddenID = findID('hidden');
		_hiddenStartID = findID('hiddenStart');
		_hiddenEndID = findID('hiddenEnd');
		_hiddenGlowID = findID('hiddenGlow');

		_stealthIDs = [for (i in 0...maxKeys) findID('stealth' + i)];
		_darkIDs = [for (i in 0...maxKeys) findID('dark' + i)];
		_alphaIDs = [for (i in 0...maxKeys) findID('alpha' + i)];
	}

	private inline function computeSudden(data:VisualParameters, params:ModifierParameters) {
		final player = params.player;

		final sudden = getUnsafe(_suddenID, player);

		if (sudden == 0)
			return;

		final start = getUnsafe(_suddenStartID, player) * 100;
		final end = getUnsafe(_suddenEndID, player) * 100;
		final glow = getUnsafe(_suddenGlowID, player);

		final alpha = FlxMath.remapToRange(FlxMath.bound(params.distance, end, start), end, start, 1, 0);

		if (glow != 0)
			data.glow += Math.max(0, (1 - alpha) * sudden * 2) * glow;
		data.alpha *= alpha * sudden;
	}

	private inline function computeHidden(data:VisualParameters, params:ModifierParameters) {
		final player = params.player;

		final hidden = getUnsafe(_hiddenID, player);

		if (hidden == 0)
			return;

		final start = getUnsafe(_hiddenStartID, player) * 100;
		final end = getUnsafe(_hiddenEndID, player) * 100;
		final glow = getUnsafe(_hiddenGlowID, player);

		final alpha = FlxMath.remapToRange(FlxMath.bound(params.distance, end, start), end, start, 0, 1);

		if (glow != 0)
			data.glow += Math.max(0, (1 - alpha) * hidden * 2) * glow;
		data.alpha *= alpha * hidden;
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters) {
		final player = params.player;
		final lane = params.lane;

		// Use pre-computed IDs to avoid Std.string(lane) + string concat allocations
		final stealthVal = getUnsafe(_stealthID, player) + getUnsafe(_stealthIDs[lane], player);
		final darkVal = getUnsafe(_darkID, player) + getUnsafe(_darkIDs[lane], player);
		final visibility = params.isTapArrow ? stealthVal : darkVal;
		data.alpha = ((getUnsafe(_alphaID, player) + getUnsafe(_alphaIDs[lane], player)) * (1 - ((Math.max(0.5, visibility) - 0.5) * 2)));
		data.glow += visibility * 2;

		// sudden & hidden
		if (params.isTapArrow) // non receptor
		{
			computeSudden(data, params);
			computeHidden(data, params);
		}

		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
