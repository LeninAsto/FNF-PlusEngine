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
		#if MODS_ALLOWED
		if (FileSystem.exists(path))
			return true;
		#end
		return OpenFlAssets.exists(path, type);
	}

	public static function loadText(path:String):String
	{
		#if MODS_ALLOWED
		if (FileSystem.exists(path))
			return File.getContent(path);
		#end
		if (OpenFlAssets.exists(path, TEXT))
			return Assets.getText(path);
		return null;
	}

	public static function loadBitmap(path:String):BitmapData
	{
		#if MODS_ALLOWED
		if (FileSystem.exists(path))
			return BitmapData.fromFile(path);
		#end
		if (OpenFlAssets.exists(path, IMAGE))
			return OpenFlAssets.getBitmapData(path);
		return null;
	}

	public static function loadSound(path:String):Sound
	{
		#if MODS_ALLOWED
		if (FileSystem.exists(path))
			return Sound.fromFile(path);
		#end
		if (OpenFlAssets.exists(path, SOUND))
			return OpenFlAssets.getSound(path);
		return null;
	}
}
