package backend.ui.md3;

import flixel.FlxG;

class MD3Metrics
{
	public static inline var BASE_WIDTH:Float = 1280.0;
	public static inline var BASE_HEIGHT:Float = 720.0;
	public static inline var MIN_TOUCH_TARGET:Float = 48.0;

	inline static function clamp(value:Float, minValue:Float, maxValue:Float):Float
	{
		return Math.max(minValue, Math.min(maxValue, value));
	}

	public static function uiScale():Float
	{
		var widthScale = FlxG.width / BASE_WIDTH;
		var heightScale = FlxG.height / BASE_HEIGHT;
		return clamp(Math.min(widthScale, heightScale), 0.90, 1.20);
	}

	public static function size(value:Float):Int
	{
		return Std.int(Math.max(1, Math.round(value * uiScale())));
	}

	public static function text(value:Float):Int
	{
		return Std.int(Math.max(12, Math.round(value * uiScale())));
	}

	public static function touch(value:Float):Int
	{
		return Std.int(Math.max(size(value), size(MIN_TOUCH_TARGET)));
	}

	public static function corner(value:Float, width:Float, height:Float):Int
	{
		var maxCorner = Math.floor(Math.min(width, height) / 2);
		return Std.int(Math.max(0, Math.min(size(value), maxCorner)));
	}

	public static function dialogWidth(preferredWidth:Float, screenWidth:Float):Int
	{
		var margin = size(24);
		var fluidWidth = Math.floor(screenWidth * 0.72);
		var maxWidth = Math.min(size(preferredWidth), screenWidth - margin * 2);
		return Std.int(Math.max(size(280), Math.min(fluidWidth, maxWidth)));
	}

	public static function margin(value:Float):Int
	{
		return size(value);
	}
}