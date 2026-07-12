package backend.ui.md3;

import flixel.FlxSprite;
import flixel.util.FlxColor;

/**
 * Material Design 3 Divider Component
 * Based on: https://m3.material.io/components/divider/guidelines
 *
 * A simple 1dp horizontal or vertical hairline separator.
 * Full-width or inset (indented) variants.
 */
class MaterialDivider extends FlxSprite
{
	var dividerLength:Int = 0;
	var isVertical:Bool = false;
	var dividerInsetStart:Float = 0;
	var dividerInsetEnd:Float = 0;

	/**
	 * @param x          Position X.
	 * @param y          Position Y.
	 * @param length     Length of the divider in pixels.
	 * @param vertical   If true, draws a vertical divider instead of horizontal.
	 * @param insetStart Left/top inset in pixels (default 0 = full-width).
	 * @param insetEnd   Right/bottom inset in pixels (default 0).
	 */
	public function new(x:Float = 0, y:Float = 0, length:Float = 240, ?vertical:Bool = false, ?insetStart:Float = 0, ?insetEnd:Float = 0)
	{
		super(x, y);
		dividerLength = Std.int(length);
		isVertical = vertical;
		dividerInsetStart = insetStart;
		dividerInsetEnd = insetEnd;
		antialiasing = false;
		rebuild();
		MD3Theme.addListener(rebuild);
	}

	function rebuild():Void
	{
		var insetedLength = Std.int(dividerLength - dividerInsetStart - dividerInsetEnd);
		if (insetedLength < 1) insetedLength = 1;

		if (!isVertical)
		{
			makeGraphic(dividerLength, 1, FlxColor.TRANSPARENT, true);
			for (px in Std.int(dividerInsetStart)...Std.int(dividerInsetStart + insetedLength))
				pixels.setPixel32(px, 0, MD3Theme.dividerColor());
		}
		else
		{
			makeGraphic(1, dividerLength, FlxColor.TRANSPARENT, true);
			for (py in Std.int(dividerInsetStart)...Std.int(dividerInsetStart + insetedLength))
				pixels.setPixel32(0, py, MD3Theme.dividerColor());
		}

		dirty = true;
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(rebuild);
		super.destroy();
	}
}
