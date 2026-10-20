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
 * - Set `luapathRelative` to 1 to use nodes as offsets from the regular note path
 * - Set `luapathLocal` to 1 to use nodes as coordinates relative to each receptor
 * - Set `luapathLockReceptor` to 1 to move the path window while keeping its receptor anchored
 * - Animate `luapathPhase` to move through a path manually
 *
 * Modes (`luapathMode`):
 * - 0: legacy looping treadmill driven by song time
 * - 1: fixed OpenITG-like path driven only by each arrow's scroll distance
 * - 2: clamped path driven by song time * `luapathDriveSpeed`
 * - 3: ping-pong version of mode 2
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

	private static inline function pingPongToBound(value:Float, bound:Float):Float {
		if (bound <= 0)
			return 0;
		final wrapped = wrapToBound(value, bound * 2);
		return wrapped <= bound ? wrapped : bound * 2 - wrapped;
	}

	override function render(pos:Vector3, params:ModifierParameters) {
		final perc = getPercent('luapath', params.player);
		if (perc == 0)
			return pos;

		final bound = getPathBound();
		if (bound <= 0)
			return pos;

		final rawSpeed = Adapter.instance.getCurrentScrollSpeed();
		final scrollSpeed = Math.isFinite(rawSpeed) ? Math.abs(rawSpeed) : 0;
		final mode = FlxMath.bound(Std.int(Math.round(getPercent('luapathMode', params.player))), 0, 3);
		final driveSpeed = getPercent('luapathDriveSpeed', params.player);
		final manualPhase = getPercent('luapathPhase', params.player);
		final trail = Math.max(0, (Math.isFinite(params.distance) ? params.distance : 0) * scrollSpeed);
		final clock = (Math.isFinite(params.songTime) ? params.songTime : 0) * scrollSpeed;

		final base = switch (mode) {
			case 1:
				0.0;
			case 2, 3:
				clock * (Math.isFinite(driveSpeed) ? driveSpeed : 0);
			default:
				clock;
		};

		// Holds need the same distance sampling as tap notes or every body segment
		// gets pinned to the first node and the path breaks into chunks.
		final pathHead = base + (Math.isFinite(manualPhase) ? manualPhase : 0);
		final rawProgress = pathHead + trail;
		final progress = switch (mode) {
			case 0:
				wrapToBound(rawProgress, bound);
			case 3:
				pingPongToBound(rawProgress, bound);
			default:
				clampToBound(rawProgress, bound);
		};
		final originProgress = switch (mode) {
			case 0:
				wrapToBound(pathHead, bound);
			case 3:
				pingPongToBound(pathHead, bound);
			default:
				clampToBound(pathHead, bound);
		};

		final local = getPercent('luapathLocal', params.player) != 0;
		final relative = !local && getPercent('luapathRelative', params.player) != 0;
		final lockReceptor = FlxMath.bound(getPercent('luapathLockReceptor', params.player), 0, 1);
		final extraZ = relative ? 0 : pos.z - pathOffset.z;
		final anchorX = local ? getReceptorX(params.lane, params.player) + ARROW_SIZEDIV2 : 0;
		final anchorY = local ? getReceptorY(params.lane, params.player) + ARROW_SIZEDIV2 : 0;
		return computePathAt(pos, params.lane, progress, perc, relative, extraZ, originProgress, lockReceptor, local, anchorX, anchorY, 0);
	}
}
