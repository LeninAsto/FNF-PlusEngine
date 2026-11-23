package modchart.engine.modifiers.list;

import flixel.math.FlxMath;
import modchart.backend.core.ModifierParameters;
import modchart.backend.core.VisualParameters;
import modchart.backend.core.TransformMode;

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
	var _suddenOffsetID:Int;
	var _hiddenID:Int;
	var _hiddenStartID:Int;
	var _hiddenEndID:Int;
	var _hiddenGlowID:Int;
	var _hiddenOffsetID:Int;
	var _noteAlphaID:Int;
	var _receptorAlphaID:Int;
	var _holdAlphaID:Int;
	var _blinkID:Int;
	var _blinkSpeedID:Int;
	var _blinkOffsetID:Int;
	var _blinkDutyID:Int;
	var _randomVanishID:Int;
	var _randomVanishStartID:Int;
	var _randomVanishEndID:Int;
	var _noteAlphaIDs:Array<Int>;
	var _receptorAlphaIDs:Array<Int>;
	var _holdAlphaIDs:Array<Int>;
	var _suddenIDs:Array<Int>;
	var _hiddenIDs:Array<Int>;
	var _suddenOffsetIDs:Array<Int>;
	var _hiddenOffsetIDs:Array<Int>;

	public function new(pf) {
		super(pf);

		setPercent('alpha', 1, -1);
		setPercent('noteAlpha', 1, -1);
		setPercent('receptorAlpha', 1, -1);
		setPercent('holdAlpha', 1, -1);
		setPercent('blinkSpeed', 10, -1);
		setPercent('blinkDuty', 0.5, -1);
		setPercent('randomVanishStart', 80, -1);
		setPercent('randomVanishEnd', 160, -1);

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
		_suddenOffsetID = findID('suddenOffset');
		_hiddenID = findID('hidden');
		_hiddenStartID = findID('hiddenStart');
		_hiddenEndID = findID('hiddenEnd');
		_hiddenGlowID = findID('hiddenGlow');
		_hiddenOffsetID = findID('hiddenOffset');
		_noteAlphaID = findID('noteAlpha');
		_receptorAlphaID = findID('receptorAlpha');
		_holdAlphaID = findID('holdAlpha');
		_blinkID = findID('blink');
		_blinkSpeedID = findID('blinkSpeed');
		_blinkOffsetID = findID('blinkOffset');
		_blinkDutyID = findID('blinkDuty');
		_randomVanishID = findID('randomVanish');
		_randomVanishStartID = findID('randomVanishStart');
		_randomVanishEndID = findID('randomVanishEnd');

		_stealthIDs = [for (i in 0...maxKeys) findID('stealth' + i)];
		_darkIDs = [for (i in 0...maxKeys) findID('dark' + i)];
		_alphaIDs = [for (i in 0...maxKeys) findID('alpha' + i)];
		_noteAlphaIDs = [for (i in 0...maxKeys) findID('noteAlpha' + i)];
		_receptorAlphaIDs = [for (i in 0...maxKeys) findID('receptorAlpha' + i)];
		_holdAlphaIDs = [for (i in 0...maxKeys) findID('holdAlpha' + i)];
		_suddenIDs = [for (i in 0...maxKeys) findID('sudden' + i)];
		_hiddenIDs = [for (i in 0...maxKeys) findID('hidden' + i)];
		_suddenOffsetIDs = [for (i in 0...maxKeys) findID('suddenOffset' + i)];
		_hiddenOffsetIDs = [for (i in 0...maxKeys) findID('hiddenOffset' + i)];
	}

	private inline function computeSudden(data:VisualParameters, params:ModifierParameters, lane:Int) {
		final player = params.player;

		final sudden = FlxMath.bound(getUnsafeLaneAdd(_suddenID, _suddenIDs[lane], player), 0, 1);

		if (sudden == 0)
			return;

		final offset = getUnsafeLaneAdd(_suddenOffsetID, _suddenOffsetIDs[lane], player) * HEIGHT * 0.5;
		final start = getUnsafe(_suddenStartID, player) * 100 + offset;
		final end = getUnsafe(_suddenEndID, player) * 100 + offset;
		final glow = getUnsafe(_suddenGlowID, player);

		final alpha = FlxMath.remapToRange(FlxMath.bound(params.distance, end, start), end, start, 1, 0);

		if (glow != 0)
		{
			// Sudden starts at alpha 0, so the old `(1 - alpha) * 2` glow
			// peaked while the arrow was still culled. A bell-shaped glow keeps
			// the flash inside the visible fade instead of revealing fragments.
			final fadeGlow = 4 * alpha * (1 - alpha);
			data.glow += fadeGlow * sudden * glow;
		}
		// Blend the fade with the modifier strength. Multiplying by `sudden`
		// made every partial value cap the whole note at that opacity.
		data.alpha *= FlxMath.lerp(1, alpha, sudden);
	}

	private inline function computeHidden(data:VisualParameters, params:ModifierParameters, lane:Int) {
		final player = params.player;

		final hidden = FlxMath.bound(getUnsafeLaneAdd(_hiddenID, _hiddenIDs[lane], player), 0, 1);

		if (hidden == 0)
			return;

		final offset = getUnsafeLaneAdd(_hiddenOffsetID, _hiddenOffsetIDs[lane], player) * HEIGHT * 0.5;
		final start = getUnsafe(_hiddenStartID, player) * 100 + offset;
		final end = getUnsafe(_hiddenEndID, player) * 100 + offset;
		final glow = getUnsafe(_hiddenGlowID, player);

		final alpha = FlxMath.remapToRange(FlxMath.bound(params.distance, end, start), end, start, 0, 1);

		if (glow != 0)
			data.glow += Math.max(0, (1 - alpha) * hidden * 2) * glow;
		data.alpha *= FlxMath.lerp(1, alpha, hidden);
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters) {
		final player = params.player;
		final lane = getLaneSlot(params.lane, _stealthIDs.length);

		// Use pre-computed IDs to avoid Std.string(lane) + string concat allocations
		final stealthVal = getUnsafeLaneAdd(_stealthID, _stealthIDs[lane], player);
		final darkVal = getUnsafeLaneAdd(_darkID, _darkIDs[lane], player);
		final stealthVisibility = FlxMath.bound(stealthVal, 0, 1);
		final darkVisibility = FlxMath.bound(darkVal, 0, 1);
		final visibility = params.isTapArrow ? stealthVisibility : darkVisibility;
		final alpha = FlxMath.bound(getUnsafe(_alphaID, player), 0, 1)
			* (hasUnsafeForPlayer(_alphaIDs[lane], player) ? FlxMath.bound(getUnsafe(_alphaIDs[lane], player), 0, 1) : 1);
		var objectAlpha = 1.0;
		if (params.isTapArrow) {
			objectAlpha = getUnsafe(_noteAlphaID, player)
				* (hasUnsafeForPlayer(_noteAlphaIDs[lane], player) ? getUnsafe(_noteAlphaIDs[lane], player) : 1);
			if (params.isHoldBody)
				objectAlpha *= getUnsafe(_holdAlphaID, player)
					* (hasUnsafeForPlayer(_holdAlphaIDs[lane], player) ? getUnsafe(_holdAlphaIDs[lane], player) : 1);
		} else {
			objectAlpha = getUnsafe(_receptorAlphaID, player)
				* (hasUnsafeForPlayer(_receptorAlphaIDs[lane], player) ? getUnsafe(_receptorAlphaIDs[lane], player) : 1);
		}
		if (params.isTapArrow && stealthVisibility != 0)
			data.glow += stealthVisibility * 2;
		data.alpha *= FlxMath.bound(alpha * objectAlpha, 0, 1) * (1 - visibility);

		// sudden & hidden
		if (params.isTapArrow) // non receptor
		{
			computeSudden(data, params, lane);
			computeHidden(data, params, lane);

			final blink = FlxMath.bound(getUnsafe(_blinkID, player), 0, 1);
			if (blink != 0) {
				final phase = (sin(params.songTime * 0.001 * getUnsafe(_blinkSpeedID, player) + getUnsafe(_blinkOffsetID, player)) + 1) * 0.5;
				final visible = phase >= FlxMath.bound(getUnsafe(_blinkDutyID, player), 0, 1) ? 1.0 : 0.0;
				data.alpha *= FlxMath.lerp(1, visible, blink);
			}

			final vanish = FlxMath.bound(getUnsafe(_randomVanishID, player), 0, 1);
			if (vanish != 0) {
				final start = Math.max(0, getUnsafe(_randomVanishStartID, player));
				final end = Math.max(start + 0.001, getUnsafe(_randomVanishEndID, player));
				final fieldDistance = Math.abs(params.distance * getScrollSpeed());
				final fromCenter = Math.abs(fieldDistance - HEIGHT * 0.5);
				final band = FlxMath.remapToRange(FlxMath.bound(fromCenter, start, end), start, end, 0, 1);
				data.alpha *= FlxMath.lerp(1, band, vanish);
			}
		}

		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function isActive(player:Int):Bool {
		if (getUnsafe(_stealthID, player) != 0 || getUnsafe(_darkID, player) != 0 || getUnsafe(_alphaID, player) != 1
			|| getUnsafe(_suddenID, player) != 0 || getUnsafe(_hiddenID, player) != 0
			|| getUnsafe(_noteAlphaID, player) != 1 || getUnsafe(_receptorAlphaID, player) != 1 || getUnsafe(_holdAlphaID, player) != 1
			|| getUnsafe(_blinkID, player) != 0 || getUnsafe(_randomVanishID, player) != 0)
			return true;
		for (lane in 0..._stealthIDs.length)
			if (getUnsafe(_stealthIDs[lane], player) != 0 || getUnsafe(_darkIDs[lane], player) != 0
				|| getUnsafe(_suddenIDs[lane], player) != 0 || getUnsafe(_hiddenIDs[lane], player) != 0
				|| (hasUnsafeForPlayer(_alphaIDs[lane], player) && getUnsafe(_alphaIDs[lane], player) != 1)
				|| (hasUnsafeForPlayer(_noteAlphaIDs[lane], player) && getUnsafe(_noteAlphaIDs[lane], player) != 1)
				|| (hasUnsafeForPlayer(_receptorAlphaIDs[lane], player) && getUnsafe(_receptorAlphaIDs[lane], player) != 1)
				|| (hasUnsafeForPlayer(_holdAlphaIDs[lane], player) && getUnsafe(_holdAlphaIDs[lane], player) != 1))
				return true;
		return false;
	}

	override public function transformMode():TransformMode
		return TransformMode.FIELD;
}
