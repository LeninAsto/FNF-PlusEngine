package mobile.backend;

import flixel.system.scaleModes.BaseScaleMode;
import flixel.util.FlxSignal.FlxSignal;

/**
 * @author Karim Akra, adapted for Plus Engine
 */
class MobileScaleMode extends BaseScaleMode
{
	public static var allowInfinityDisplay(default, set):Bool = true;

	public static var baseWidth(default, null):Float  = 1280;
	public static var baseHeight(default, null):Float = 720;

	public static var onGameSizeChanged(default, null):FlxSignal = new FlxSignal();

	public static inline function getBaseRatio():Float return baseWidth / baseHeight;

	public static inline function getSafeWidth():Float
	{
		if (ClientPrefs.data.infinityDisplay && allowInfinityDisplay)
			return FlxG.width;
		var s = Math.min(FlxG.width / baseWidth, FlxG.height / baseHeight);
		return baseWidth * s;
	}

	public static inline function getSafeHeight():Float
	{
		if (ClientPrefs.data.infinityDisplay && allowInfinityDisplay)
			return FlxG.height;
		var s = Math.min(FlxG.width / baseWidth, FlxG.height / baseHeight);
		return baseHeight * s;
	}

	public static inline function getHorizontalOffset():Float return (FlxG.width  - getSafeWidth())  / 2;
	public static inline function getVerticalOffset():Float   return (FlxG.height - getSafeHeight()) / 2;

	public static inline function safeX(x:Float):Float return x + getHorizontalOffset();
	public static inline function safeY(y:Float):Float return y + getVerticalOffset();

	public static inline function safeCenterX(width:Float):Float  return (FlxG.width  - width)  / 2;
	public static inline function safeCenterY(height:Float):Float return (FlxG.height - height) / 2;

	override function updateGameSize(Width:Int, Height:Int):Void
	{
		// Android can briefly report a zero-sized surface while backgrounding.
		// Dividing by that value poisons the scale mode with NaN/Infinity and the
		// resumed game keeps running behind a black renderer.
		if (Width <= 0 || Height <= 0)
			return;
		if (ClientPrefs.data.infinityDisplay && allowInfinityDisplay)
		{
			// Match the traditional Psych-style fullscreen policy: occupy the
			// entire physical screen. This deliberately keeps the canonical logical
			// resolution so Lua/mod coordinates remain compatible.
			super.updateGameSize(Width, Height);
		}
		else
		{
			var ratio:Float = baseWidth / baseHeight;
			var realRatio:Float = Width / Height;

			if (realRatio < ratio)
			{
				gameSize.x = Width;
				gameSize.y = Math.floor(gameSize.x / ratio);
			}
			else
			{
				gameSize.y = Height;
				gameSize.x = Math.floor(gameSize.y * ratio);
			}
		}

		if (!Math.isFinite(gameSize.x) || !Math.isFinite(gameSize.y) || gameSize.x <= 0 || gameSize.y <= 0)
			return;

		for (cam in FlxG.cameras.list)
			cam.setSize(Std.int(gameSize.x), Std.int(gameSize.y));

		onGameSizeChanged.dispatch();
	}

	public static function refreshAfterFocus():Void
	{
		if (FlxG.scaleMode is MobileScaleMode && FlxG.width > 0 && FlxG.height > 0)
			FlxG.scaleMode = new MobileScaleMode();
	}

	override function updateGamePosition():Void
	{
		if (ClientPrefs.data.infinityDisplay && allowInfinityDisplay)
			FlxG.game.x = FlxG.game.y = 0;
		else
			super.updateGamePosition();
	}

	@:noCompletion
	private static function set_allowInfinityDisplay(value:Bool):Bool
	{
		var changed = allowInfinityDisplay != value;
		allowInfinityDisplay = value;
		if (changed && (FlxG.scaleMode is MobileScaleMode))
			FlxG.scaleMode = new MobileScaleMode();
		return value;
	}
}
