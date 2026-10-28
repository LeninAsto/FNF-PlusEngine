package backend.native;

/** Entry point and capability check for optional batched native kernels. */
class NativeBackend
{
	public static final available:Bool = #if cpp true #else false #end;
	public static var apiVersion(default, null):Int = 0;
	static var initialized:Bool = false;

	public static function init():Void
	{
		if (initialized)
			return;

		initialized = true;
		apiVersion = NativeMath.apiVersion();
	}
}
