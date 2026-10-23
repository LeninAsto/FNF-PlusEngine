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
	static inline var VERSION:Int = 2;
	static inline var MAX_SOURCE_BYTES:Int = 2 * 1024 * 1024;
	public static var lastHit(default, null):Bool = false;
	static var pendingSaves:Array<Dynamic> = [];

	public static inline function resetHit():Void
		lastHit = false;

	public static function load(sourcePath:String):Null<SwagSong>
	{
		lastHit = false;
		#if sys
		if (!isCacheableSource(sourcePath))
			return null;
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
		if (song == null || !isCacheableSource(sourcePath))
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

	public static function queueSave(sourcePath:String, song:SwagSong):Void
	{
		if (sourcePath == null || song == null)
			return;
		#if sys
		if (!isCacheableSource(sourcePath))
			return;
		#end
		for (entry in pendingSaves)
			if (entry.sourcePath == sourcePath)
			{
				entry.song = song;
				return;
			}
		pendingSaves.push({sourcePath: sourcePath, song: song});
		while (pendingSaves.length > 2)
			pendingSaves.shift();
	}

	/** Drops both queued and on-disk data after the source chart is edited. */
	public static function invalidate(sourcePath:String):Void
	{
		if (sourcePath == null || sourcePath.length == 0)
			return;

		var normalized:String = sourcePath.replace('\\', '/').toLowerCase();
		pendingSaves = pendingSaves.filter(function(entry:Dynamic)
		{
			return entry == null || entry.sourcePath == null
				|| Std.string(entry.sourcePath).replace('\\', '/').toLowerCase() != normalized;
		});

		#if sys
		var path:String = cachePath(sourcePath);
		try
		{
			if (FileSystem.exists(path) && !FileSystem.isDirectory(path))
				FileSystem.deleteFile(path);
		}
		catch (e:Dynamic)
			trace('Could not invalidate compiled chart cache: $e');
		#end
	}

	public static function flushPending():Void
	{
		var saves:Array<Dynamic> = pendingSaves;
		pendingSaves = [];
		for (entry in saves)
			save(entry.sourcePath, entry.song);
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
	static function isCacheableSource(sourcePath:String):Bool
	{
		return sourcePath != null && FileSystem.exists(sourcePath) && !FileSystem.isDirectory(sourcePath)
			&& FileSystem.stat(sourcePath).size <= MAX_SOURCE_BYTES;
	}

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
