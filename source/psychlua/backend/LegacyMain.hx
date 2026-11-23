package psychlua.backend;

/**
 * Narrow compatibility view of the historic root `Main` class.
 *
 * Old Psych mods commonly use Main.fpsVar to hide or read the FPS counter.
 * Exposing the real boot class would also expose native/debug internals, so
 * HScript and Lua receive this facade through ClassResolver instead.
 */
class LegacyMain
{
	public static var fpsVar(get, never):LegacyFPSCounter;

	static final fpsCounter:LegacyFPSCounter = new LegacyFPSCounter();

	static inline function get_fpsVar():LegacyFPSCounter
		return fpsCounter;
}

class LegacyFPSCounter
{
	public var visible(get, set):Bool;
	public var currentFPS(get, never):Float;

	public function new() {}

	inline function get_visible():Bool
		return Main.fpsVar != null && Main.fpsVar.visible;

	inline function set_visible(value:Bool):Bool
	{
		if (Main.fpsVar != null)
			Main.fpsVar.visible = value;
		return value;
	}

	inline function get_currentFPS():Float
		return Main.fpsVar != null ? Main.fpsVar.currentFPS : 0;
}
