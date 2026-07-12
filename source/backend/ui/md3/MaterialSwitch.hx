package backend.ui.md3;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import backend.ui.md3.MD3Theme;

/**
 * Material Design 3 Switch Component
 * Based on: https://m3.material.io/components/switch/guidelines
 */
class MaterialSwitch extends FlxSpriteGroup
{
	static inline var TRACE_LAYOUT:Bool = false;

	public var checked(default, set):Bool = false;
	public var enabled:Bool = true;
	public var allowMouseInput:Bool = true;
	public var onChange:Bool->Void = null;

	// Visual components
	var track:FlxSprite;
	var thumb:FlxSprite;
	var thumbIcon:FlxSprite;

	// Animation tweens
	var thumbTween:FlxTween;
	var thumbScaleTween:FlxTween;
	var thumbCenterX:Float = 0;
	var thumbVisualScale:Float = 1;

	inline function trackWidth():Int return MD3Metrics.size(52);
	inline function trackHeight():Int return MD3Metrics.size(32);
	inline function thumbSize():Int return MD3Metrics.size(24);
	inline function pressedThumbSize():Int return MD3Metrics.size(28);
	inline function iconSize():Int return MD3Metrics.size(14);
	inline function switchRadius():Int return MD3Metrics.corner(16, trackWidth(), trackHeight());
	inline function hitHeight():Int return MD3Metrics.touch(trackHeight());

	public function new(x:Float = 0, y:Float = 0, ?checked:Bool = false)
	{
		super(x, y);

		// Create track (background pill shape)
		track = new FlxSprite();
		track.antialiasing = ClientPrefs.data.antialiasing;
		MD3ShapeTools.fillRoundRect(track, trackWidth(), trackHeight(), switchRadius());
		add(track);

		// Create thumb (sliding circle)
		thumb = new FlxSprite();
		thumb.antialiasing = ClientPrefs.data.antialiasing;
		MD3ShapeTools.fillCircle(thumb, thumbSize());
		add(thumb);

		// Create thumb icon (centered inside thumb)
		thumbIcon = new FlxSprite();
		thumbIcon.antialiasing = ClientPrefs.data.antialiasing;
		add(thumbIcon);

		@:bypassAccessor this.checked = checked;
		thumbCenterX = getThumbCenter(this.checked);

		// Set initial state without animation
		updateVisuals(false);
		MD3Theme.addListener(_onThemeChange);
		traceLayout('create');
	}

	inline function getThumbCenter(isChecked:Bool):Float
	{
		var margin = MD3Metrics.size(4);
		var radius = thumbSize() * 0.5;
		return isChecked ? trackWidth() - margin - radius : margin + radius;
	}

	function layoutThumb():Void
	{
		thumb.scale.set(thumbVisualScale, thumbVisualScale);
		thumb.updateHitbox();
		thumb.x = x + thumbCenterX - thumb.width * 0.5;
		thumb.y = y + trackHeight() * 0.5 - thumb.height * 0.5;
		updateIconPosition();
	}

	function traceLayout(reason:String):Void
	{
		if (!TRACE_LAYOUT) return;
	}

	public function getDebugLayout():String
	{
		return 'group=(' + x + ', ' + y + ')'
			+ ' checked=' + checked
			+ ' trackLocal=(' + (track.x - x) + ', ' + (track.y - y) + ', ' + track.width + 'x' + track.height + ')'
			+ ' thumbLocal=(' + (thumb.x - x) + ', ' + (thumb.y - y) + ', ' + thumb.width + 'x' + thumb.height + ')'
			+ ' iconLocal=(' + (thumbIcon.x - x) + ', ' + (thumbIcon.y - y) + ', ' + thumbIcon.width + 'x' + thumbIcon.height + ')';
	}

	function drawIcon(sprite:FlxSprite, isCheck:Bool):Void
	{
		var iconW = iconSize();
		sprite.makeGraphic(iconW, iconW, FlxColor.TRANSPARENT, true);
		var graphics = sprite.pixels;
		graphics.fillRect(graphics.rect, FlxColor.TRANSPARENT);

		var lineWidth = 2;

		if (isCheck)
		{
			var startX = 3;
			var startY = 8;
			var midX = 6;
			var midY = 11;
			var endX = 13;
			var endY = 4;

			drawLine(graphics, startX, startY, midX, midY, lineWidth);
			drawLine(graphics, midX, midY, endX, endY, lineWidth);
		}
		else
		{
			var padding = 4;
			drawLine(graphics, padding, padding, iconW - padding, iconW - padding, lineWidth);
			drawLine(graphics, iconW - padding, padding, padding, iconW - padding, lineWidth);
		}
	}

	function drawLine(graphics:openfl.display.BitmapData, x1:Int, y1:Int, x2:Int, y2:Int, thickness:Int):Void
	{
		var dx = Math.abs(x2 - x1);
		var dy = Math.abs(y2 - y1);
		var sx = x1 < x2 ? 1 : -1;
		var sy = y1 < y2 ? 1 : -1;
		var err = dx - dy;
		
		var x = x1;
		var y = y1;

		while (true)
		{
			for (ty in -Std.int(thickness/2)...Std.int(thickness/2) + 1)
			{
				for (tx in -Std.int(thickness/2)...Std.int(thickness/2) + 1)
				{
					var px = x + tx;
					var py = y + ty;
					if (px >= 0 && px < iconSize() && py >= 0 && py < iconSize())
						graphics.setPixel32(px, py, 0xFFFFFFFF);
				}
			}

			if (x == x2 && y == y2) break;

			var e2 = 2 * err;
			if (e2 > -dy)
			{
				err -= dy;
				x += sx;
			}
			if (e2 < dx)
			{
				err += dx;
				y += sy;
			}
		}
	}

	function updateVisuals(animate:Bool = true):Void
	{
		var duration = animate ? 0.2 : 0;

		// Cancel existing tweens
		if (thumbTween != null) thumbTween.cancel();

		var targetCenter = getThumbCenter(checked);
		drawIcon(thumbIcon, checked);

		if (animate)
		{
			thumbTween = FlxTween.tween(this, {thumbCenterX: targetCenter}, duration, {
				ease: FlxEase.cubeOut,
				onUpdate: function(_) {
					layoutThumb();
				}
			});
		}
		else
		{
			thumbCenterX = targetCenter;
			layoutThumb();
		}

		var targetTrackColor:FlxColor = checked ? MD3Theme.primary : MD3Theme.surfaceVariant;
		var targetThumbColor:FlxColor = checked ? MD3Theme.onPrimary : MD3Theme.outline;
		var targetIconColor:FlxColor = checked ? MD3Theme.primary : MD3Theme.onSurfaceVariant;

		if (!enabled)
		{
			targetTrackColor = MD3Theme.disabledContainerColor();
			targetThumbColor = MD3Theme.disabledContentColor();
			targetIconColor = MD3Theme.disabledContentColor();
		}

		if (animate)
		{
			animateColor(track, track.color, targetTrackColor, duration);
			animateColor(thumb, thumb.color, targetThumbColor, duration);
			animateColor(thumbIcon, thumbIcon.color, targetIconColor, duration);
		}
		else
		{
			track.color = targetTrackColor;
			thumb.color = targetThumbColor;
			thumbIcon.color = targetIconColor;
		}

		traceLayout(animate ? 'updateVisuals(animated)' : 'updateVisuals(static)');
	}

	function animateColor(sprite:FlxSprite, fromColor:FlxColor, toColor:FlxColor, duration:Float):Void
	{
		var startR = fromColor.red;
		var startG = fromColor.green;
		var startB = fromColor.blue;

		var endR = toColor.red;
		var endG = toColor.green;
		var endB = toColor.blue;

		FlxTween.num(0, 1, duration, {ease: FlxEase.cubeOut}, function(t:Float) {
			var r = Std.int(FlxMath.lerp(startR, endR, t));
			var g = Std.int(FlxMath.lerp(startG, endG, t));
			var b = Std.int(FlxMath.lerp(startB, endB, t));
			sprite.color = FlxColor.fromRGB(r, g, b);
		});
	}

	function updateIconPosition():Void
	{
		thumbIcon.x = thumb.x + (thumb.width - iconSize()) * 0.5;
		thumbIcon.y = thumb.y + (thumb.height - iconSize()) * 0.5;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		updateIconPosition();

		#if FLX_MOUSE
		if (enabled && allowMouseInput && FlxG.mouse.justPressed)
		{
			var mousePos = FlxG.mouse.getScreenPosition();
			var hitPadY = Std.int(Math.max(0, (hitHeight() - trackHeight()) / 2));
			var isOver = mousePos.x >= x && mousePos.x <= x + trackWidth()
				&& mousePos.y >= y - hitPadY && mousePos.y <= y + trackHeight() + hitPadY;
			if (isOver)
			{
				toggle();
			}
		}
		#end
	}

	public function toggle():Void
	{
		if (!enabled) return;

		checked = !checked;
		traceLayout('toggle');

		if (onChange != null)
			onChange(checked);
	}

	function _onThemeChange():Void
	{
		updateVisuals(false);
	}

	function set_checked(value:Bool):Bool
	{
		if (checked != value)
		{
			checked = value;
			updateVisuals(true);
		}
		return checked;
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(_onThemeChange);
		if (thumbTween != null) thumbTween.cancel();
		if (thumbScaleTween != null) thumbScaleTween.cancel();

		onChange = null;

		super.destroy();
	}
}
