package states.play;

#if mobile
import mobile.backend.MobileScaleMode;
#end

class HudSafeZone
{
	public static inline function x():Float
	{
		#if mobile
		return MobileScaleMode.getHorizontalOffset();
		#else
		return 0;
		#end
	}

	public static inline function y():Float
	{
		#if mobile
		return MobileScaleMode.getVerticalOffset();
		#else
		return 0;
		#end
	}

	public static inline function width():Float
	{
		#if mobile
		return MobileScaleMode.getSafeWidth();
		#else
		return FlxG.width;
		#end
	}

	public static inline function height():Float
	{
		#if mobile
		return MobileScaleMode.getSafeHeight();
		#else
		return FlxG.height;
		#end
	}
}
