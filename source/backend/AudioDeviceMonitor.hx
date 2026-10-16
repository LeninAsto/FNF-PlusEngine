package backend;

#if (cpp && lime_openal)
import lime._internal.backend.native.AudioDeviceLock;
import lime.media.openal.ALC;
#end

/** Polls OpenAL Soft device state from the game's main update thread. */
class AudioDeviceMonitor
{
	#if (cpp && lime_openal)
	private static var elapsed:Int = 0;
	private static var retry:Int = 0;
	private static var defaultName:String;

	/** Returns true once when OpenAL successfully switches to a new output. */
	public static function update(deltaTime:Int):Bool
	{
		elapsed += deltaTime;
		if (retry > 0) retry -= deltaTime;
		if (elapsed < 1000 || retry > 0) return false;
		elapsed = 0;

		var context = ALC.getCurrentContext();
		if (context == null) return false;
		var device = ALC.getContextsDevice(context);
		if (device == null) return false;
		var nextName = ALC.getString(null, ALC.DEFAULT_ALL_DEVICES_SPECIFIER);
		if (nextName == null) nextName = ALC.getString(null, ALC.DEFAULT_DEVICE_SPECIFIER);
		if (defaultName == null) defaultName = nextName;

		var connected = ALC.getIntegerv(device, ALC.CONNECTED, 1);
		var disconnected = connected != null && connected.length > 0 && connected[0] == ALC.FALSE;
		if (!disconnected && nextName == defaultName) return false;

		AudioDeviceLock.acquire();
		var reopened = false;
		try reopened = ALC.reopenDevice(device) catch (_:Dynamic) {}
		AudioDeviceLock.release();
		if (reopened) defaultName = nextName;
		else retry = 3000;
		return reopened;
	}
	#else
	public static inline function update(deltaTime:Int):Bool return false;
	#end
}
