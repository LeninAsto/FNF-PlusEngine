package mobile.backend;

import flixel.system.scaleModes.BaseScaleMode;
import flixel.util.FlxSignal.FlxSignal;

/**
 * @author Karim Akra, adapted for Plus Engine
 */
class MobileScaleMode extends BaseScaleMode
{
	public static var allowInfinityDisplay(default, set):Bool = true;

	public static var onGameSizeChanged(default, null):FlxSignal = new FlxSignal();

	public static inline function getSafeWidth():Float return FlxG.width;
	public static inline function getSafeHeight():Float return FlxG.height;
	public static inline function getScreenWidth():Float return FlxG.width;
	public static inline function getScreenHeight():Float return FlxG.height;
	public static inline function getHorizontalOffset():Float return 0;
	public static inline function getVerticalOffset():Float return 0;
	public static inline function safeX(x:Float):Float return x;
	public static inline function safeY(y:Float):Float return y;

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
			super.updateGameSize(Width, Height);
		else
		{
			var ratio:Float = FlxG.width / FlxG.height;
			var realRatio:Float = Width / Height;

			var scaleY:Bool = realRatio < ratio;
			if (scaleY)
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
