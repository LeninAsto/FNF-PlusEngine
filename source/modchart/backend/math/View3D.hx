package modchart.backend.math;

import flixel.FlxG;

/**
 * Represents a perspective projection for modcharts.
 *
 * This class provides a basic perspective transformation based on OpenGL principles.
 * It allows transforming 3D world coordinates into 2D screen space, taking into account
 * field of view (FOV), aspect ratio, and depth scaling.
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
	 * Distance to the near clipping plane.
	 * Objects closer than this distance will not be rendered.
	 */
	public var near(default, set):Float = 0;

	/**
	 * Distance to the far clipping plane.
	 * Objects farther than this distance will not be rendered.
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
	private var __tanHalfFov:Float = 0;

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

	public function new() {
		fov = Math.PI / 2;
		updateProperties();
	}

	private function set_near(value:Float):Float {
		updateProperties();
		return near = value;
	}

	private function set_far(value:Float):Float {
		updateProperties();
		return far = value;
	}

	private function set_fov(value:Float):Float {
		updateProperties();
		return fov = value;
	}

	private function get_range():Float {
		return near - far;
	}

	/**
	 * Updates internal projection properties based on current FOV and depth range.
	 */
	public function updateProperties():Void {
		__tanHalfFov = Math.tan(fov * 0.5);
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
		// pendejada mas pendeja alaverga
		__forward = position - target;
		__forward.normalize();

		__right = up.crossProduct(__forward);
		__right.normalize();

		__up = __forward.crossProduct(__right);

		__dirtyCamera = false;
	}

	private inline function applyViewTransform(v:Vector3):Vector3 {
		if (__dirtyCamera)
			updateCameraBasis();

		var p = v - position;
		return new Vector3(p.dotProduct(__right), p.dotProduct(__up), p.dotProduct(__forward));
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
			world = applyViewTransform(vector); // allocates, but camera mode is rarely used
		} else {
			world = vector;
		}

		// Compute perspective projection in-place (no `translation = world - origin` alloc)
		var tx = world.x - origin.x;
		var ty = world.y - origin.y;
		var tz = world.z - origin.z;

		final projectedZ = __depthScale * Math.min(tz - 1, 0) + __depthOffset;

		// Guard against degenerate projection (point at or behind the near plane).
		// Sets world.z to a large sentinel (1e9) so callers (e.g. PathRenderer)
		// can detect and skip clipped segments instead of getting infinity positions.
		if (projectedZ < 0.01) {
			world.z = 1e9;
			return world;
		}

		final projectedFov = (__tanHalfFov / projectedZ);

		world.x = tx * projectedFov + origin.x;
		world.y = ty * projectedFov + origin.y;
		world.z = projectedZ + origin.z;

		return world;
	}
}
