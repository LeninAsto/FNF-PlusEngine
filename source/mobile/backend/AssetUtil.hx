package mobile.backend;

import backend.AssetLoader;
import flash.media.Sound;
import openfl.display.BitmapData;

class AssetUtil
{
	public static inline function getBitmap(path:String):BitmapData
	{
		return AssetLoader.loadBitmap(path);
	}

	public static inline function getSound(path:String):Sound
	{
		return AssetLoader.loadSound(path);
	}
}
