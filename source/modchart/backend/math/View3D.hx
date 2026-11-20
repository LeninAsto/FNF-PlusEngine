package modchart.backend.math;

import flixel.FlxG;

/**
 * Represents a perspective projection for modcharts.
 *
 * Projects modchart coordinates to screen space using the engine's legacy depth convention.
 *
 * Based on OpenGL tutorial:
 * @see https://ogldev.org/www/tutorial12/tutorial12.html
 */
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
final class View3D {
	/**
	 * Near coefficient used by the legacy depth projection.
	 */
	public var near(default, set):Float = 0;

	/**
	 * Far coefficient used by the legacy depth projection.
	 */
	public var far(default, set):Float = 1;

	/**
	 * Field of View (FOV) in radians.
	 * Defines the extent of the observable world projected onto the screen.
	 * 
	 * **NOTE:** This value defaults to 90 degrees (PI / 2).
	 */
	public var fov(default, set):Float;

	/**
	 * Distance range between the near and far clipping planes.
	 * Calculated as `near - far`.
	 */
	public var range(get, never):Float;

	/**
	 * Internal projection components.
	 */
	public var clipDistance(default, null):Float = 1;

	private var __focalScale:Float = 1;

	private var __depthRange:Float = 1;
	private var __depthScale:Float = 1;
	private var __depthOffset:Float = 0;

	/**
	 * Camera position (eye).
	 * Ignored unless `useCamera` is enabled.
	 */
	public var position:Vector3 = new Vector3(0, 0, 0);

	/**
	 * Camera target (look-at point).
	 * Ignored unless `useCamera` is enabled.
	 */
	public var target:Vector3 = new Vector3(0, 0, -1);

	/**
	 * Camera up vector.
	 * Ignored unless `useCamera` is enabled.
	 */
	public var up:Vector3 = new Vector3(0, 1, 0);

	/**
	 * Enables camera-space transformation before projection.
	 * 
	 * Defaults to `Config.CAMERA3D_ENABLED`
	 */
	public var useCamera:Bool = Config.CAMERA3D_ENABLED;

	/** Pre-allocated default screen-center origin to avoid allocation per transformVector() call. */
	private var __defaultOrigin:Vector3 = new Vector3();

	private var __forward:Vector3 = new Vector3();
	private var __right:Vector3 = new Vector3();
	private var __up:Vector3 = new Vector3();
	private var __dirtyCamera:Bool = true;
	private var __lastEye:Vector3 = new Vector3();
	private var __lastTarget:Vector3 = new Vector3();
	private var __lastUp:Vector3 = new Vector3();

	public function new() {
		fov = Math.PI / 2;
		updateProperties();
	}

	private function set_near(value:Float):Float {
		if (Math.isFinite(value) && value != far) {
			near = value;
			updateProperties();
		}
		return near;
	}

	private function set_far(value:Float):Float {
		if (Math.isFinite(value) && value != near) {
			far = value;
			updateProperties();
		}
		return far;
	}

	private function set_fov(value:Float):Float {
		if (Math.isFinite(value) && value > 0.001 && value < Math.PI - 0.001) {
			fov = value;
			updateProperties();
		}
		return fov;
	}

	private function get_range():Float {
		return near - far;
	}

	/**
	 * Updates internal projection properties based on current FOV and depth range.
	 */
	public function updateProperties():Void {
		__focalScale = 1 / Math.tan(fov * 0.5);
		__depthRange = 1 / range;
		__depthScale = (near + far) * __depthRange;
		__depthOffset = 2 * near * (far * __depthRange);
	}

	/**
	 * Sets camera parameters using a look-at model.
	 * Enables camera transformation automatically.
	 */
	public inline function lookAt(eye:Vector3, center:Vector3, up:Vector3):Void {
		position.copyFrom(eye);
		target.copyFrom(center);
		this.up.copyFrom(up);
		__dirtyCamera = true;
		useCamera = true;
	}

	private inline function updateCameraBasis():Void {
		__forward.setTo(position.x - target.x, position.y - target.y, position.z - target.z);
		if (__forward.lengthSquared < 0.00000001)
			__forward.setTo(0, 0, 1);
		else
			__forward.normalize();

		__right.setTo(up.y * __forward.z - up.z * __forward.y,
			up.z * __forward.x - up.x * __forward.z,
			up.x * __forward.y - up.y * __forward.x);
		if (__right.lengthSquared < 0.00000001) {
			if (Math.abs(__forward.y) < 0.999)
				__right.setTo(__forward.z, 0, -__forward.x);
			else
				__right.setTo(-__forward.y, __forward.x, 0);
		}
		__right.normalize();

		__up.setTo(__forward.y * __right.z - __forward.z * __right.y,
			__forward.z * __right.x - __forward.x * __right.z,
			__forward.x * __right.y - __forward.y * __right.x);

		__lastEye.copyFrom(position);
		__lastTarget.copyFrom(target);
		__lastUp.copyFrom(up);
		__dirtyCamera = false;
	}

	private inline function applyViewTransform(v:Vector3):Vector3 {
		if (__dirtyCamera || position.x != __lastEye.x || position.y != __lastEye.y || position.z != __lastEye.z
			|| target.x != __lastTarget.x || target.y != __lastTarget.y || target.z != __lastTarget.z
			|| up.x != __lastUp.x || up.y != __lastUp.y || up.z != __lastUp.z)
			updateCameraBasis();

		final px = v.x - position.x;
		final py = v.y - position.y;
		final pz = v.z - position.z;
		v.setTo(px * __right.x + py * __right.y + pz * __right.z,
			px * __up.x + py * __up.y + pz * __up.z,
			px * __forward.x + py * __forward.y + pz * __forward.z);
		return v;
	}

	/**
	 * Transforms a 3D vector into 2D screen space using perspective projection.
	 * Mutates `vector` in-place (no allocation) for the common useCamera=false path.
	 *
	 * @param vector The 3D vector to project. Modified in-place for useCamera=false.
	 * @param origin Optional origin point for transformation (defaults to screen center).
	 * @return The projected vector (same object as `vector` when useCamera=false).
	 */
	public inline function transformVector(vector:Vector3, ?origin:Null<Vector3>):Vector3 {
		if (origin == null) {
			// Reuse pre-allocated default origin to avoid a heap allocation per call
			__defaultOrigin.x = FlxG.width * 0.5;
			__defaultOrigin.y = FlxG.height * 0.5;
			__defaultOrigin.z = 0;
			origin = __defaultOrigin;
		}

		var world:Vector3;
		if (useCamera) {
			world = applyViewTransform(vector);
		} else {
			world = vector;
		}

		// Compute perspective projection in-place (no `translation = world - origin` alloc)
		var tx = world.x - origin.x;
		var ty = world.y - origin.y;
		var tz = world.z - origin.z;

		final projectedZ = __depthScale * Math.min(tz - 1, 0) + __depthOffset;
		clipDistance = ((__depthScale < 0 && __depthOffset < 0.0101) || (__depthScale > 0 && __depthOffset >= 0.0101)
			? __depthScale * (tz - 1) + __depthOffset : projectedZ) - 0.0101;

		// Guard against degenerate projection (point at or behind the near plane).
		// Sets world.z to a large sentinel (1e9) so callers (e.g. PathRenderer)
		// can detect and skip clipped segments instead of getting infinity positions.
		if (projectedZ < 0.01) {
			world.z = 1e9;
			return world;
		}

		final projectedFov = (__focalScale / projectedZ);

		world.x = tx * projectedFov + origin.x;
		world.y = ty * projectedFov + origin.y;
		world.z = projectedZ + origin.z;

		return world;
	}
}
