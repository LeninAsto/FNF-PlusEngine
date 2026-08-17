package backend;

import openfl.display.BitmapData;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import flash.media.Sound;
import lime.utils.Assets;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

/**
 * Raw asset I/O for filesystem and bundled assets.
 * Inspired by the loader separation used in P-Slice.
 */
class AssetLoader
{
	public static function exists(path:String, type:AssetType):Bool
	{
		if (path == null || path.length == 0)
			return false;

		#if MODS_ALLOWED
		try
		{
			if (FileSystem.exists(path))
				return true;
		}
		catch (_:Dynamic)
		{
		}
		#end
		try
		{
			return OpenFlAssets.exists(path, type);
		}
		catch (_:Dynamic)
		{
		}
		return false;
	}

	public static function loadText(path:String):String
	{
		if (path == null || path.length == 0)
			return null;

		#if MODS_ALLOWED
		try
		{
			if (FileSystem.exists(path))
				return File.getContent(path);
		}
		catch (_:Dynamic)
		{
		}
		#end
		try
		{
			if (OpenFlAssets.exists(path, TEXT))
				return Assets.getText(path);
		}
		catch (_:Dynamic)
		{
		}
		return null;
	}

	public static function loadBitmap(path:String):BitmapData
	{
		if (path == null || path.length == 0)
			return null;

		#if MODS_ALLOWED
		try
		{
			if (FileSystem.exists(path))
				return BitmapData.fromFile(path);
		}
		catch (_:Dynamic)
		{
		}
		#end
		try
		{
			if (OpenFlAssets.exists(path, IMAGE))
				return OpenFlAssets.getBitmapData(path);
		}
		catch (_:Dynamic)
		{
		}
		return null;
	}

	public static function loadSound(path:String):Sound
	{
		if (path == null || path.length == 0)
			return null;

		#if MODS_ALLOWED
		try
		{
			if (FileSystem.exists(path))
				return Sound.fromFile(path);
		}
		catch (_:Dynamic)
		{
		}
		#end
		try
		{
			if (OpenFlAssets.exists(path, SOUND))
				return OpenFlAssets.getSound(path);
		}
		catch (_:Dynamic)
		{
		}
		return null;
	}
}

