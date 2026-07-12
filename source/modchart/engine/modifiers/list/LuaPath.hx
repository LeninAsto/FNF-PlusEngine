package modchart.engine.modifiers.list;

import flixel.math.FlxMath;
import modchart.backend.core.ModifierParameters;
import modchart.engine.PlayField;

/**
 * A path modifier whose nodes are intended to be provided at runtime (Lua/HScript).
 *
 * Usage:
 * - Add with `addModifier('luapath')`
 * - Set nodes via Lua callback `setModifierPath('luapath', nodes, field)`
 */
class LuaPath extends PathModifier {
	public function new(pf:PlayField) {
		super(pf, []);
		pathOffset.setTo(WIDTH * 0.5, HEIGHT * 0.5, 0);
	}

	private static inline function wrapToBound(value:Float, bound:Float):Float {
		if (bound <= 0)
			return 0;
		var m = value % bound;
		if (m < 0)
			m += bound;
		return m;
	}

	private static inline function clampToBound(value:Float, bound:Float):Float {
		if (bound <= 0)
			return 0;
		return FlxMath.bound(value, 0, bound);
	}

	override function render(pos:Vector3, params:ModifierParameters) {
		final perc = getPercent('luapath', params.player);
		if (perc == 0)
			return pos;

		final bound = getPathBound();
		if (bound <= 0)
			return pos;

		final scrollSpeed = Adapter.instance.getCurrentScrollSpeed();
		final mode = FlxMath.bound(Std.int(Math.round(getPercent('luapathMode', params.player))), 0, 2);
		final driveSpeed = getPercent('luapathDriveSpeed', params.player);
		final trail = Math.max(0, params.distance * scrollSpeed);

		final base = switch (mode) {
			case 1:
				0.0;
			case 2:
				params.songTime * scrollSpeed * driveSpeed;
			default:
				params.songTime * scrollSpeed;
		};

		final rawProgress = base + (params.isTapArrow ? trail : 0);
		final progress = switch (mode) {
			case 0:
				wrapToBound(rawProgress, bound);
			default:
				clampToBound(rawProgress, bound);
		};

		final driveParams:ModifierParameters = {
			songTime: params.songTime,
			hitTime: params.hitTime,
			distance: progress,
			sourceTime: params.sourceTime,
			curBeat: params.curBeat,
			lane: params.lane,
			player: params.player,
			isTapArrow: params.isTapArrow,
			straightHolds: params.straightHolds
		};

		pathOffset.z = pos.z;
		return computePath(pos, driveParams, perc);
	}
}
