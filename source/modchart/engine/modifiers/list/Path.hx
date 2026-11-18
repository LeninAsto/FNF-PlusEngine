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
		final trail = Math.max(0, (Math.isFinite(params.distance) ? params.distance : 0) * speed);
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
		final lock = FlxMath.bound(getPercent('pathLockReceptor', params.player), 0, 1);
		final extraZ = relative ? 0 : pos.z - pathOffset.z;
		final anchorX = local ? getReceptorX(params.lane, params.player) + ARROW_SIZEDIV2 : 0;
		final anchorY = local ? getReceptorY(params.lane, params.player) + ARROW_SIZEDIV2 : 0;
		return computePathAt(pos, params.lane, progress, perc, relative, extraZ, origin, lock, local, anchorX, anchorY, 0);
	}
}
