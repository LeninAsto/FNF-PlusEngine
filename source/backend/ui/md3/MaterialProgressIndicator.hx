package backend.ui.md3;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import backend.ui.md3.MD3Theme;

/**
 * Material Design 3 Progress Indicators
 * Based on: https://m3.material.io/components/progress-indicators/guidelines
 *
 * Supports:
 *   - LINEAR determinate / indeterminate
 *   - CIRCULAR determinate / indeterminate
 */
class MaterialProgressIndicator extends FlxSpriteGroup
{
	public var value(default, set):Float = 0; // 0.0 - 1.0
	public var indeterminate(default, set):Bool = false;
	public var indicatorType:ProgressType = LINEAR;

	// Linear components
	var linearTrack:FlxSprite;
	var linearFill:FlxSprite;
	var linearIndeterminate:FlxSprite;

	// Circular components
	// Drawn using BitmapData arc manually
	var circularBg:FlxSprite;
	var circularFill:FlxSprite;
	var circularCenter:FlxSprite; // hole

	// Dimensions (MD3)
	public var barWidth:Float = 240;
	static inline var LINEAR_HEIGHT:Int = 4;
	static inline var LINEAR_CORNER:Int = 2;
	static inline var CIRCULAR_SIZE:Int = 48;
	static inline var CIRCULAR_THICKNESS:Int = 5;

	// Indeterminate animation
	var indeterminateTimer:Float = 0;
	var indeterminateTween:FlxTween;
	var circleAngle:Float = 0;
	var _circleArcLen:Float = 0; // drives arc-length oscillation
	var _lastArcLen:Float = -1;  // last redrawn arc length (avoids unnecessary redraws)
	var linearIndeterminate2:FlxSprite; // trailing segment for the two-bar wavy effect

	public function new(x:Float = 0, y:Float = 0, ?indicatorType:ProgressType = LINEAR, ?width:Float = 240)
	{
		super(x, y);

		this.indicatorType = indicatorType;
		this.barWidth = width;

		if (indicatorType == LINEAR)
			buildLinear();
		else
			buildCircular();
		MD3Theme.addListener(_onThemeChange);
	}

	// -----------------------------------------------------------------------
	// BUILD
	// -----------------------------------------------------------------------

	function buildLinear():Void
	{
		var w = Std.int(barWidth);

		// Inactive track
		linearTrack = new FlxSprite(0, 0);
		linearTrack.makeGraphic(w, LINEAR_HEIGHT, MD3Theme.surfaceVariant);
		drawRoundedRect(linearTrack, w, LINEAR_HEIGHT, LINEAR_CORNER);
		linearTrack.color = MD3Theme.surfaceVariant;
		add(linearTrack);

		// Active fill
		linearFill = new FlxSprite(0, 0);
		linearFill.makeGraphic(w, LINEAR_HEIGHT, MD3Theme.primary);
		drawRoundedRect(linearFill, w, LINEAR_HEIGHT, LINEAR_CORNER);
		linearFill.color = MD3Theme.primary;
		linearFill.scale.x = 0;
		linearFill.offset.x = -(w * (1 - linearFill.scale.x)) / 2;
		add(linearFill);

		// Primary indeterminate overlay
		linearIndeterminate = new FlxSprite(0, 0);
		linearIndeterminate.makeGraphic(w, LINEAR_HEIGHT, MD3Theme.primary);
		drawRoundedRect(linearIndeterminate, w, LINEAR_HEIGHT, LINEAR_CORNER);
		linearIndeterminate.color = MD3Theme.primary;
		linearIndeterminate.visible = false;
		add(linearIndeterminate);

		// Secondary trailing segment — narrower + slightly transparent for wavy effect
		linearIndeterminate2 = new FlxSprite(0, 0);
		linearIndeterminate2.makeGraphic(w, LINEAR_HEIGHT, MD3Theme.primary);
		drawRoundedRect(linearIndeterminate2, w, LINEAR_HEIGHT, LINEAR_CORNER);
		linearIndeterminate2.color = MD3Theme.primary;
		linearIndeterminate2.alpha = 0.55;
		linearIndeterminate2.visible = false;
		add(linearIndeterminate2);

		applyValue();
	}

	function buildCircular():Void
	{
		var s = CIRCULAR_SIZE;

		circularBg = new FlxSprite(0, 0);
		circularBg.makeGraphic(s, s, FlxColor.TRANSPARENT, true);
		drawCircularTrack(circularBg, s, CIRCULAR_THICKNESS, MD3Theme.surfaceVariant);
		add(circularBg);

		circularFill = new FlxSprite(0, 0);
		circularFill.makeGraphic(s, s, FlxColor.TRANSPARENT, true);
		drawCircularArc(circularFill, s, CIRCULAR_THICKNESS, MD3Theme.primary, 0, value * 360);
		add(circularFill);
	}

	// -----------------------------------------------------------------------
	// DRAWING HELPERS
	// -----------------------------------------------------------------------

	function drawRoundedRect(sprite:FlxSprite, width:Int, height:Int, radius:Int):Void
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

	function drawCircularTrack(sprite:FlxSprite, size:Int, thickness:Int, color:FlxColor):Void
	{
		var graphics = sprite.pixels;
		graphics.fillRect(graphics.rect, FlxColor.TRANSPARENT);

		var cx = size / 2;
		var cy = size / 2;
		var outerR = size / 2 - 1;
		var innerR = outerR - thickness;

		for (py in 0...size)
		{
			for (px in 0...size)
			{
				var dx = px - cx;
				var dy = py - cy;
				var dist = Math.sqrt(dx * dx + dy * dy);
				if (dist <= outerR && dist >= innerR)
					graphics.setPixel32(px, py, color);
			}
		}
	}

	function drawCircularArc(sprite:FlxSprite, size:Int, thickness:Int, color:FlxColor, startDeg:Float, endDeg:Float):Void
	{
		var graphics = sprite.pixels;
		graphics.fillRect(graphics.rect, FlxColor.TRANSPARENT);

		var cx = size / 2;
		var cy = size / 2;
		var outerR = size / 2 - 1;
		var innerR = outerR - thickness;

		// Normalize angles
		var startRad = (startDeg - 90) * Math.PI / 180;
		var endRad = (endDeg - 90) * Math.PI / 180 + startRad;

		var steps = 720;
		var stepAngle = (endDeg / 360) * 2 * Math.PI / steps;
		var baseAngle = startRad;

		for (step in 0...steps)
		{
			var angle = baseAngle + step * stepAngle;
			for (r in Std.int(innerR)...Std.int(outerR) + 1)
			{
				var px = Std.int(cx + Math.cos(angle) * r);
				var py = Std.int(cy + Math.sin(angle) * r);
				if (px >= 0 && px < size && py >= 0 && py < size)
					graphics.setPixel32(px, py, color);
			}
		}
	}

	// -----------------------------------------------------------------------
	// VALUE & STATE
	// -----------------------------------------------------------------------

	function applyValue():Void
	{
		if (indicatorType == LINEAR)
		{
			if (linearFill == null) return;
			var w = barWidth;
			linearFill.scale.x = Math.max(0.001, value);
			// Positive offset anchors the scaled sprite to its LEFT edge
			linearFill.offset.x = (w * (1.0 - value)) / 2;
		}
		else
		{
			if (circularFill == null) return;
			var s = CIRCULAR_SIZE;
			circularFill.pixels.fillRect(circularFill.pixels.rect, FlxColor.TRANSPARENT);
				drawCircularArc(circularFill, s, CIRCULAR_THICKNESS, MD3Theme.primary, 0, value * 360);
			circularFill.dirty = true;
		}
	}

	function set_value(v:Float):Float
	{
		value = Math.max(0, Math.min(1, v));
		if (!indeterminate) applyValue();
		return value;
	}

	function set_indeterminate(v:Bool):Bool
	{
		indeterminate = v;

		if (indicatorType == LINEAR)
		{
			if (linearFill == null || linearIndeterminate == null) return v;
			linearFill.visible = !v;
			linearIndeterminate.visible = v;
			if (linearIndeterminate2 != null) linearIndeterminate2.visible = v;

			if (v)
			{
				// Cancel any legacy tween; animation is update-driven
				if (indeterminateTween != null) { indeterminateTween.cancel(); indeterminateTween = null; }
				indeterminateTimer = 0;
				linearIndeterminate.scale.x = 0.01;
				linearIndeterminate.offset.x = (barWidth * 0.99) / 2;
				linearIndeterminate.x = linearTrack.x;
				if (linearIndeterminate2 != null)
				{
					linearIndeterminate2.scale.x = 0.01;
					linearIndeterminate2.offset.x = (barWidth * 0.99) / 2;
					linearIndeterminate2.x = linearTrack.x;
				}
			}
			else
			{
				if (indeterminateTween != null) { indeterminateTween.cancel(); indeterminateTween = null; }
				linearIndeterminate.x = linearTrack.x;
				linearIndeterminate.scale.x = 1;
				linearIndeterminate.offset.x = 0;
				if (linearIndeterminate2 != null)
				{
					linearIndeterminate2.x = linearTrack.x;
					linearIndeterminate2.scale.x = 1;
					linearIndeterminate2.offset.x = 0;
				}
			}
		}

		return v;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!indeterminate) return;

		if (indicatorType == LINEAR && linearIndeterminate != null)
		{
			// Material-style: each bar sweeps linearly across the track.
			// The visible width grows organically as the bar enters and shrinks as it exits —
			// no explicit width formula needed, just clamp the bar to [0,1].
			indeterminateTimer += elapsed;

			// Bar 1: period 1.35 s, natural width 55 % of track
			var BAR1_W:Float = 0.55;
			var t1     = (indeterminateTimer % 1.35) / 1.35;
			var lead1  = t1 * (1.0 + BAR1_W) - BAR1_W; // -BAR1_W → 1.0 over [0,1]
			var trail1 = lead1 + BAR1_W;
			var vs1    = Math.max(0.0, lead1);
			var ve1    = Math.min(1.0, trail1);
			var s1     = Math.max(0.005, ve1 - vs1);
			linearIndeterminate.scale.x  = s1;
			linearIndeterminate.offset.x = (barWidth * (1.0 - s1)) / 2;
			linearIndeterminate.x        = linearTrack.x + vs1 * barWidth;

			// Bar 2: period 0.90 s, narrower (35 %), half-period out of phase
			if (linearIndeterminate2 != null && linearIndeterminate2.visible)
			{
				var BAR2_W:Float = 0.35;
				var t2     = ((indeterminateTimer + 0.45) % 0.90) / 0.90;
				var lead2  = t2 * (1.0 + BAR2_W) - BAR2_W;
				var trail2 = lead2 + BAR2_W;
				var vs2    = Math.max(0.0, lead2);
				var ve2    = Math.min(1.0, trail2);
				var s2     = Math.max(0.005, ve2 - vs2);
				linearIndeterminate2.scale.x  = s2;
				linearIndeterminate2.offset.x = (barWidth * (1.0 - s2)) / 2;
				linearIndeterminate2.x        = linearTrack.x + vs2 * barWidth;
			}
		}
		else if (indicatorType == CIRCULAR && circularFill != null)
		{
			// Spin at a consistent pace
			circleAngle += elapsed * 280;
			if (circleAngle >= 360) circleAngle -= 360;

			// Arc: grows 55 % of cycle (ease-out cubic), shrinks 45 % (smoothstep = ease-in-out).
			// Using ease-in-out for the shrink avoids the abrupt &quot;snap&quot; of plain ease-in.
			_circleArcLen += elapsed;
			var cycleT     = (_circleArcLen % 1.5) / 1.5;
			var newArcLen:Float;
			if (cycleT < 0.55)
			{
				var growT = cycleT / 0.55;
				newArcLen = 30.0 + 240.0 * (1.0 - Math.pow(1.0 - growT, 3)); // ease-out cubic
			}
			else
			{
				var shrinkT = (cycleT - 0.55) / 0.45;
				var ease    = shrinkT * shrinkT * (3.0 - 2.0 * shrinkT); // smoothstep
				newArcLen = 270.0 - 240.0 * ease; // ease-in-out: smooth collapse
			}

			if (Math.abs(newArcLen - _lastArcLen) > 2)
			{
				_lastArcLen = newArcLen;
				circularFill.pixels.fillRect(circularFill.pixels.rect, FlxColor.TRANSPARENT);
				drawCircularArc(circularFill, CIRCULAR_SIZE, CIRCULAR_THICKNESS, MD3Theme.primary, 0, newArcLen);
				circularFill.dirty = true;
			}
			circularFill.angle = circleAngle;
		}
	}

	function _onThemeChange():Void
	{
		if (indicatorType == LINEAR)
		{
			if (linearTrack != null) linearTrack.color = MD3Theme.surfaceVariant;
			if (linearFill != null) linearFill.color = MD3Theme.primary;
			if (linearIndeterminate != null) linearIndeterminate.color = MD3Theme.primary;
			if (linearIndeterminate2 != null) linearIndeterminate2.color = MD3Theme.primary;
		}
		else
		{
			if (circularBg != null)
			{
				circularBg.pixels.fillRect(circularBg.pixels.rect, FlxColor.TRANSPARENT);
				drawCircularTrack(circularBg, CIRCULAR_SIZE, CIRCULAR_THICKNESS, MD3Theme.surfaceVariant);
				circularBg.dirty = true;
			}
			if (circularFill != null)
			{
				_lastArcLen = -1; // force redraw on next update
				applyValue();
			}
		}
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(_onThemeChange);
		if (indeterminateTween != null) indeterminateTween.cancel();
		super.destroy();
	}
}

enum ProgressType
{
	LINEAR;
	CIRCULAR;
}
