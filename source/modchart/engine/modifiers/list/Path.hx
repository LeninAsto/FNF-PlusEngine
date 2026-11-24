package modchart.engine.modifiers.list;

import flixel.math.FlxMath;
import modchart.backend.core.ModifierParameters;
import modchart.engine.PlayField;

class Path extends PathModifier {
	public function new(pf:PlayField) {
		super(pf, []);
		pathOffset.setTo(WIDTH * 0.5, HEIGHT * 0.5, 0);
	}

	private static inline function wrap(value:Float, bound:Float):Float {
		if (bound <= 0)
			return 0;
		var out = value % bound;
		if (out < 0)
			out += bound;
		return out;
	}

	private static inline function clamp(value:Float, bound:Float):Float
		return bound <= 0 ? 0 : FlxMath.bound(value, 0, bound);

	private static inline function pingPong(value:Float, bound:Float):Float {
		if (bound <= 0)
			return 0;
		final out = wrap(value, bound * 2);
		return out <= bound ? out : bound * 2 - out;
	}

	override function render(pos:Vector3, params:ModifierParameters) {
		final perc = getPercent('path', params.player);
		if (perc == 0)
			return pos;

		final bound = getPathBound();
		if (bound <= 0)
			return pos;

		final rawSpeed = Adapter.instance.getCurrentScrollSpeed();
		final speed = Math.isFinite(rawSpeed) ? Math.abs(rawSpeed) : 0;
		final mode = FlxMath.bound(Std.int(Math.round(getPercent('pathMode', params.player))), 0, 3);
		final drive = getPercent('pathDriveSpeed', params.player);
		final phase = getPercent('pathPhase', params.player);
		final timeScaleID = findID('pathTimeScale');
		final timeScale = hasUnsafeForPlayer(timeScaleID, params.player) ? Math.max(0, getUnsafe(timeScaleID, params.player)) : speed;
		final trail = Math.max(0, (Math.isFinite(params.distance) ? getVisualDistance(params) : 0) * timeScale);
		final clock = (Math.isFinite(params.songTime) ? params.songTime : 0) * speed;
		final base = switch (mode) {
			case 1: 0.0;
			case 2, 3: clock * (Math.isFinite(drive) ? drive : 0);
			default: clock;
		};
		final head = base + (Math.isFinite(phase) ? phase : 0);
		final raw = head + trail;
		final progress = switch (mode) {
			case 0: wrap(raw, bound);
			case 3: pingPong(raw, bound);
			default: clamp(raw, bound);
		};
		final origin = switch (mode) {
			case 0: wrap(head, bound);
			case 3: pingPong(head, bound);
			default: clamp(head, bound);
		};

		final local = getPercent('pathLocal', params.player) != 0;
		final relative = !local && getPercent('pathRelative', params.player) != 0;
		final followID = findID('pathCameraFollow');
		final follow = hasUnsafeForPlayer(followID, params.player) ? getUnsafe(followID, params.player) : getPercent('pathLockReceptor', params.player);
		final lock = FlxMath.bound(follow, 0, 1);
		final extraZ = relative ? 0 : pos.z - pathOffset.z;
		var anchorX = local ? getReceptorX(params.lane, params.player) + ARROW_SIZEDIV2 : 0;
		if (local) {
			final center = FlxMath.bound(getPercent('pathCenter', params.player), 0, 1);
			if (center != 0) {
				final keys = getKeyCount(params.player);
				final first = getReceptorX(0, params.player) + ARROW_SIZEDIV2;
				final last = getReceptorX(Std.int(Math.max(keys - 1, 0)), params.player) + ARROW_SIZEDIV2;
				anchorX += (WIDTH * 0.5 - (first + last) * 0.5) * center;
			}
			if (getPercent('pathPreserveOffsets', params.player) != 0)
				anchorX += pos.x - (getReceptorX(params.lane, params.player) + ARROW_SIZEDIV2);
			final laneCenter = FlxMath.bound(getPercent('pathLaneCenter', params.player), 0, 1);
			if (laneCenter != 0) anchorX = FlxMath.lerp(anchorX, WIDTH * 0.5, laneCenter);
		}
		var anchorY = local ? getReceptorY(params.lane, params.player) + ARROW_SIZEDIV2 : 0;
		if (local) anchorY = FlxMath.lerp(anchorY, HEIGHT * 0.5, FlxMath.bound(getPercent('pathCenterY', params.player), 0, 1));
		final freezeID = findID('pathCameraFreezeX');
		final frozenX = hasUnsafeForPlayer(freezeID, params.player) ? getUnsafe(freezeID, params.player) : -1;
		final freezeYID = findID('pathCameraFreezeY');
		final freezeZID = findID('pathCameraFreezeZ');
		final frozenY = hasUnsafeForPlayer(freezeYID, params.player) ? getUnsafe(freezeYID, params.player) : -1;
		final frozenZ = hasUnsafeForPlayer(freezeZID, params.player) ? getUnsafe(freezeZID, params.player) : -1;
		return computePathAt(pos, params.lane, progress, perc, relative, extraZ, origin, lock, local, anchorX, anchorY, 0, frozenX, frozenY, frozenZ);
	}
}
