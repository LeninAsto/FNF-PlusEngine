package debug;

import flixel.FlxG;
import openfl.geom.Rectangle;

/** Shared stage-space bounds for debug overlays that live above FlxGame. */
class DebugOverlayLayout
{
	public static inline final MARGIN:Float = 16;
	public static inline final FPS_MARGIN_X:Float = 6;
	public static inline final FPS_MARGIN_Y:Float = 4;

	public static function gameBounds(?result:Rectangle):Rectangle
	{
		if (result == null)
			result = new Rectangle();

		var stageWidth:Float = FlxG.stage != null ? FlxG.stage.stageWidth : FlxG.width;
		var stageHeight:Float = FlxG.stage != null ? FlxG.stage.stageHeight : FlxG.height;
		var left:Float = 0;
		var top:Float = 0;
		var width:Float = stageWidth;
		var height:Float = stageHeight;

		// MobileScaleMode owns the final letterboxed game rectangle. Reading its
		// measured size avoids transient/child-dependent DisplayObject.getBounds().
		if (FlxG.game != null && FlxG.scaleMode != null && FlxG.scaleMode.gameSize != null
			&& FlxG.scaleMode.gameSize.x > 0 && FlxG.scaleMode.gameSize.y > 0)
		{
			left = FlxG.game.x;
			top = FlxG.game.y;
			width = FlxG.scaleMode.gameSize.x;
			height = FlxG.scaleMode.gameSize.y;
		}
		else if (FlxG.game != null && FlxG.stage != null)
		{
			var measured = FlxG.game.getBounds(FlxG.stage);
			if (measured.width > 0 && measured.height > 0)
			{
				left = measured.x;
				top = measured.y;
				width = measured.width;
				height = measured.height;
			}
		}

		left = Math.max(0, Math.min(left, stageWidth));
		top = Math.max(0, Math.min(top, stageHeight));
		width = Math.max(0, Math.min(width, stageWidth - left));
		height = Math.max(0, Math.min(height, stageHeight - top));
		result.setTo(left, top, width, height);
		return result;
	}
}
