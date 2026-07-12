package backend;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import flash.media.Sound;

@:access(openfl.display.BitmapData)
class AssetCache
{
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];
	public static var localTrackedAssets:Array<String> = [];
	public static var missingBitmapCache:Map<String, Bool> = [];

	public static function remember(key:String):Void
	{
		if (key != null)
			localTrackedAssets.push(key);
	}

	public static function resetLocalTracking():Void
	{
		localTrackedAssets = [];
		missingBitmapCache = [];
	}

	public static function cacheBitmap(cacheKey:String, bitmap:BitmapData, allowGPU:Bool):FlxGraphic
	{
		if (bitmap == null)
			return null;

		if (allowGPU && ClientPrefs.data.cacheOnGPU && bitmap.image != null)
		{
			bitmap.lock();
			if (bitmap.__texture == null)
			{
				bitmap.image.premultiplied = true;
				bitmap.getTexture(FlxG.stage.context3D);
			}
			bitmap.getSurface();
			bitmap.disposeImage();
			bitmap.image.data = null;
			bitmap.image = null;
			bitmap.readable = true;
		}
		#if android
		else
		{
			bitmap = backend.TextureOptimizer.optimize(bitmap);
		}
		#end

		var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, cacheKey);
		graphic.persist = true;
		graphic.destroyOnNoUse = false;
		currentTrackedAssets.set(cacheKey, graphic);
		remember(cacheKey);
		return graphic;
	}

	public static function cacheSound(cacheKey:String, sound:Sound):Sound
	{
		if (sound != null)
			currentTrackedSounds.set(cacheKey, sound);
		remember(cacheKey);
		return currentTrackedSounds.get(cacheKey);
	}

	public static function destroyGraphic(graphic:FlxGraphic):Bool
	{
		if (graphic == null)
			return false;

		if (graphic.useCount > 0)
			return false;

		if (ClientPrefs.data.legacyMemoryManagement)
		{
			@:privateAccess
			openfl.Assets.cache.removeBitmapData(graphic.key);
			FlxG.bitmap.remove(graphic);
			graphic.persist = false;
			graphic.destroyOnNoUse = true;
			graphic.destroy();
		}
		else
		{
			if (graphic.bitmap != null && graphic.bitmap.__texture != null)
				graphic.bitmap.__texture.dispose();
			FlxG.bitmap.remove(graphic);
		}

		return true;
	}
}
