package modchart.backend.core;

/**
 * Bitmask that identifies which transform family a modifier can affect.
 *
 * The default is `ALL`, which preserves current behavior until a modifier
 * opts into a narrower scope.
 */
enum abstract TransformMode(Int) from Int to Int {
	public var NONE = 0;
	public var FIELD = 1;
	public var NOTE = 2;
	public var RECEPTOR = 4;
	public var SPLASH = 8;
	public var ALL = FIELD | NOTE | RECEPTOR | SPLASH;

	public inline function has(mode:TransformMode):Bool {
		return (this & mode) != 0;
	}
}
