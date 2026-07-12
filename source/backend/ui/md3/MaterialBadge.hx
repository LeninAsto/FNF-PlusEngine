package backend.ui.md3;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import backend.ui.md3.MD3Theme;

/**
 * Material Design 3 Badge Component
 * Based on: https://m3.material.io/components/badges/guidelines
 *
 * Three forms:
 *   - Small badge (dot, 6dp): no label, indicates presence of new items.
 *   - Single-digit badge (16dp): count 1-9.
 *   - Multi-digit badge (16dp+): count 1-999, shows "999+" for overflow.
 *
 * Attach to another component by setting x/y relative to its icon.
 * Typically offset to the top-right of the anchor element.
 */
class MaterialBadge extends FlxSpriteGroup
{
	public var count(default, set):Int = -1; // -1 = dot (no number)

	// Visual components
	var background:FlxSprite;
	var labelText:FlxText;

	// Dimensions (MD3)
	static inline var DOT_SIZE:Int = 6;
	static inline var BADGE_HEIGHT:Int = 16;
	static inline var BADGE_PADDING_H:Int = 4;
	static inline var LABEL_SIZE:Int = 11;
	static inline var MAX_COUNT:Int = 999;

	public function new(x:Float = 0, y:Float = 0, ?count:Int = -1)
	{
		super(x, y);

		// Will be built in set_count
		background = new FlxSprite(0, 0);
		add(background);

		labelText = new FlxText(0, 0, 0, "", LABEL_SIZE);
		labelText.setFormat(Paths.font('NotoSans-Medium.ttf'), LABEL_SIZE, MD3Theme.onError, CENTER);
		labelText.antialiasing = ClientPrefs.data.antialiasing;
		add(labelText);

		this.count = count;
		MD3Theme.addListener(rebuild);
	}

	function set_count(v:Int):Int
	{
		count = v;
		rebuild();
		return count;
	}

	function rebuild():Void
	{
		if (background == null) return;

		if (count < 0)
		{
			// Dot badge
			background.makeGraphic(DOT_SIZE, DOT_SIZE, FlxColor.TRANSPARENT, true);
			drawCircle(background, DOT_SIZE);
			background.color = MD3Theme.error;
			labelText.visible = false;
		}
		else
		{
			// Number badge
			var displayStr = count > MAX_COUNT ? (MAX_COUNT + "+") : Std.string(count);
			labelText.text = displayStr;
			labelText.visible = true;
			labelText.color = MD3Theme.onError;

			var textW = Std.int(labelText.width);
			var badgeW = Std.int(Math.max(BADGE_HEIGHT, textW + BADGE_PADDING_H * 2));

			background.makeGraphic(badgeW, BADGE_HEIGHT, FlxColor.TRANSPARENT, true);
			drawRoundedRect(background, badgeW, BADGE_HEIGHT, BADGE_HEIGHT / 2);
			background.color = MD3Theme.error;
			background.dirty = true;

			// Center label within badge using world coords (children were offset by preAdd)
			labelText.x = x + (badgeW - textW) / 2;
			labelText.y = y + (BADGE_HEIGHT - labelText.height) / 2;
		}
	}

	function drawCircle(sprite:FlxSprite, size:Int):Void
	{
		var graphics = sprite.pixels;
		graphics.fillRect(graphics.rect, FlxColor.TRANSPARENT);
		var radius = size / 2;
		var center = size / 2;

		for (py in 0...size)
		{
			for (px in 0...size)
			{
				var dx = px - center;
				var dy = py - center;
				if (dx * dx + dy * dy <= radius * radius)
					graphics.setPixel32(px, py, 0xFFFFFFFF);
			}
		}
	}

	function drawRoundedRect(sprite:FlxSprite, width:Int, height:Int, radius:Float):Void
	{
		var graphics = sprite.pixels;
		graphics.fillRect(graphics.rect, FlxColor.TRANSPARENT);

		for (py in 0...height)
		{
			for (px in 0...width)
			{
				var inRect = true;
				if (px < radius && py < radius)
				{
					var dx = radius - px; var dy = radius - py;
					inRect = (dx * dx + dy * dy) <= radius * radius;
				}
				else if (px >= width - radius && py < radius)
				{
					var dx = px - (width - radius); var dy = radius - py;
					inRect = (dx * dx + dy * dy) <= radius * radius;
				}
				else if (px < radius && py >= height - radius)
				{
					var dx = radius - px; var dy = py - (height - radius);
					inRect = (dx * dx + dy * dy) <= radius * radius;
				}
				else if (px >= width - radius && py >= height - radius)
				{
					var dx = px - (width - radius); var dy = py - (height - radius);
					inRect = (dx * dx + dy * dy) <= radius * radius;
				}

				if (inRect)
					graphics.setPixel32(px, py, 0xFFFFFFFF);
			}
		}
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(rebuild);
		super.destroy();
	}
}
