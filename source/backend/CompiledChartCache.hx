package backend;

import backend.Song.SwagSong;

#if sys
import haxe.Serializer;
import haxe.Unserializer;
import haxe.crypto.Md5;
import haxe.io.Path;
import lime.system.System as LimeSystem;
import sys.FileSystem;
import sys.io.File;
#end

/** Versioned on-disk cache for already normalized Psych charts. */
class CompiledChartCache
{
	static inline var VERSION:Int = 1;
	public static var lastHit(default, null):Bool = false;

	public static inline function resetHit():Void
		lastHit = false;

	public static function load(sourcePath:String):Null<SwagSong>
	{
		lastHit = false;
		#if sys
		var signature:String = sourceSignature(sourcePath);
		if (signature == null)
			return null;
		var path:String = cachePath(sourcePath);
		if (!FileSystem.exists(path))
			return null;

		try
		{
			var entry:Dynamic = Unserializer.run(File.getContent(path));
			if (entry == null || entry.version != VERSION || entry.signature != signature || entry.song == null)
				return null;
			lastHit = true;
			return cast entry.song;
		}
		catch (e:Dynamic)
		{
			trace('Compiled chart cache ignored: $e');
		}
		#end
		return null;
	}

	public static function save(sourcePath:String, song:SwagSong):Void
	{
		#if sys
		if (song == null)
			return;
		var signature:String = sourceSignature(sourcePath);
		if (signature == null)
			return;

		try
		{
			var folder:String = cacheFolder();
			if (!FileSystem.exists(folder))
				FileSystem.createDirectory(folder);
			File.saveContent(cachePath(sourcePath), Serializer.run({version: VERSION, signature: signature, song: song}));
		}
		catch (e:Dynamic)
		{
			trace('Could not write compiled chart cache: $e');
		}
		#end
	}

	public static function sourceVersion(sourcePath:String):String
	{
		#if sys
		var signature:String = sourceSignature(sourcePath);
		return signature == null ? '' : signature;
		#else
		return '';
		#end
	}

	#if sys
	static function sourceSignature(sourcePath:String):Null<String>
	{
		if (sourcePath == null || !FileSystem.exists(sourcePath) || FileSystem.isDirectory(sourcePath))
			return null;
		var stat = FileSystem.stat(sourcePath);
		return '${stat.size}:${stat.mtime.getTime()}';
	}

	static inline function cacheFolder():String
		return Path.join([LimeSystem.applicationStorageDirectory, 'chart-cache-v$VERSION']);

	static inline function cachePath(sourcePath:String):String
		return Path.join([cacheFolder(), Md5.encode(sourcePath.replace('\\', '/').toLowerCase()) + '.bin']);
	#end
}
