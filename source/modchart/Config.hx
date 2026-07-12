package modchart;

/**
 * Configuration settings for modchart behavior.
 *
 * This class contains various static variables that control rendering,
 * performance optimizations, and visual settings for modcharts.
 * These values are now synchronized with ClientPrefs for user customization.
 */
class Config {
	/**
	 * Enables or disables 3D cameras.
	 *
	 * Setting this to `false` will disable 3D camera functionality, which may improve performance.
	 * When disabled, all 3D-related transformations and rendering will be skipped.
	 *
	 * Synced with: `ClientPrefs.data.camera3dEnabled`
	 */
	public static var CAMERA3D_ENABLED(get, never):Bool;
	private static inline function get_CAMERA3D_ENABLED():Bool return ClientPrefs.data.camera3dEnabled;

	/**
	 * Defines the order of rotation axes.
	 *
	 * Determines the sequence in which rotations are applied around the X, Y, and Z axes.
	 * Different orders can produce different final orientations due to rotational dependency.
	 *
	 * Default: `Z_Y_X` (Rotates around the X-axis last).
	 */
	public static var ROTATION_ORDER:RotationOrder = Z_Y_X;

	/**
	 * Optimizes the rendering of hold arrows.
	 *
	 * Theoretically, this makes calculations twice as fast by reducing redundant computations.
	 * However, it is not recommended for complex modcharts, as it may cause holds to look waggy,
	 * especially when using modifiers that use rotation or complex path operations.
	 *
	 * Synced with: `ClientPrefs.data.optimizeHolds`
	 */
	public static var OPTIMIZE_HOLDS(get, never):Bool;
	private static inline function get_OPTIMIZE_HOLDS():Bool return ClientPrefs.data.optimizeHolds;

	/**
	 * Scales the Z-axis values.
	 *
	 * This value is used to multiply the Z coordinate, effectively scaling depth.
	 * A higher value increases the perceived depth, while a lower value flattens it.
	 *
	 * Synced with: `ClientPrefs.data.zScale`
	 */
	public static var Z_SCALE(get, never):Float;
	private static inline function get_Z_SCALE():Float return ClientPrefs.data.zScale;

	/**
	 * Ignores or renders the arrow path lines.
	 *
	 * When enabled, performance will be affected
	 * due to path computation.
	 * 
	 * Synced with: `ClientPrefs.data.renderArrowPaths`
	 */
	public static var RENDER_ARROW_PATHS(get, never):Bool;
	private static inline function get_RENDER_ARROW_PATHS():Bool return ClientPrefs.data.renderArrowPaths;

	/**
	 * Extra configurations for the Arrow Paths.
	 * Synced with various ClientPrefs settings.
	 */
	public static var ARROW_PATHS_CONFIG(get, never):ArrowPathConfig;
	private static function get_ARROW_PATHS_CONFIG():ArrowPathConfig {
		return {
			APPLY_COLOR: ClientPrefs.data.styledArrowPaths,
			APPLY_ALPHA: ClientPrefs.data.styledArrowPaths,
			APPLY_DEPTH: true,
			APPLY_SCALE: ClientPrefs.data.styledArrowPaths,
			RESOLUTION: 1.0,
			BASE_DIVISIONS: 60,
			LENGTH: ClientPrefs.data.arrowPathBoundary
		};
	}

	/**
	 * Scales the hold end size.
	 * 
	 * Synced with: `ClientPrefs.data.holdEndScale`
	 */
	public static var HOLD_END_SCALE(get, never):Float;
	private static inline function get_HOLD_END_SCALE():Float return ClientPrefs.data.holdEndScale;

	/**
	 * Enables or disables column-specific modifiers.
	 *
	 * Disabling this may improve performance by
	 * reducing the number of `getPercent()` calls.
	 *
	 * **WARNING**: This does **not** directly affect any modifier.
	 * It only applies to *built-in modifiers*.
	 * Custom modifiers must manually check
	 * this config value for compatibility.
	 *
	 * Synced with: `ClientPrefs.data.columnSpecificModifiers`
	 */
	public static var COLUMN_SPECIFIC_MODIFIERS(get, never):Bool;
	private static inline function get_COLUMN_SPECIFIC_MODIFIERS():Bool return ClientPrefs.data.columnSpecificModifiers;

	/**
	 * Shows the sustains behind the strums
	 * 
	 * Synced with: `ClientPrefs.data.holdsBehindStrum`
	 */
	public static var HOLDS_BEHIND_STRUM(get, never):Bool;
	private static inline function get_HOLDS_BEHIND_STRUM():Bool return ClientPrefs.data.holdsBehindStrum;
}

typedef ArrowPathConfig = {
	/**
	 * Line alpha gets affected
	 * by color/glow modifiers.
	 */
	APPLY_COLOR:Bool,

	/**
	 * Line alpha gets affected
	 * by alpha modifiers.
	 */
	APPLY_ALPHA:Bool,

	/**
	 * Thickness gets affected by Z.
	 */
	APPLY_DEPTH:Bool,

	/**
	 * Thickness gets affected by arrow scale.
	 */
	APPLY_SCALE:Bool,

	/**
	 * "Resolution" multiplier of arrow paths.
	 * Higher value = More divisions = Smoother path.
	 * **WARNING**: Can't be zero or it will CRASH.
	 */
	RESOLUTION:Float,

	/**
	 * Base division count (before RESOLUTION multiplier).
	 * Higher value = more sample points = smoother wave mods (drunk/bumpy).
	 * Default: 60 (good balance between quality and performance).
	 */
	BASE_DIVISIONS:Int,

	/**
	 * Path lines length addition.
	 */
	LENGTH:Int
}
