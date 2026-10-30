package backend;

#if DISCORD_ALLOWED
#if windows
import hxdiscordsocial.SecureCredentialStore;
#elseif android
import lime.system.JNI;
#end

/** Platform credential storage used by the engine's optional Discord login. */
class DiscordCredentialStorage
{
	#if android
	private static final className = "com/leninasto/plusengine/DiscordCredentialStore";
	private static final availableMethod:Dynamic = JNI.createStaticMethod(className, "available", "()Z");
	private static final writeMethod:Dynamic = JNI.createStaticMethod(className, "write", "(Ljava/lang/String;Ljava/lang/String;)Z");
	private static final readMethod:Dynamic = JNI.createStaticMethod(className, "read", "(Ljava/lang/String;)Ljava/lang/String;");
	private static final removeMethod:Dynamic = JNI.createStaticMethod(className, "remove", "(Ljava/lang/String;)Z");
	#end

	public static function available():Bool
	{
		#if windows
		return SecureCredentialStore.available();
		#elseif android
		try return availableMethod() catch (_:Dynamic) return false;
		#else
		return false;
		#end
	}

	public static function write(key:String, value:String):Bool
	{
		#if windows
		return SecureCredentialStore.write(key, value);
		#elseif android
		try return writeMethod(key, value) catch (_:Dynamic) return false;
		#else
		return false;
		#end
	}

	public static function read(key:String):Null<String>
	{
		#if windows
		return SecureCredentialStore.read(key);
		#elseif android
		try return readMethod(key) catch (_:Dynamic) return null;
		#else
		return null;
		#end
	}

	public static function remove(key:String):Bool
	{
		#if windows
		return SecureCredentialStore.remove(key);
		#elseif android
		try return removeMethod(key) catch (_:Dynamic) return false;
		#else
		return false;
		#end
	}
}
#end
