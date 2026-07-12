package backend.ui.md3;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import openfl.display.CapsStyle;
import openfl.display.JointStyle;
import openfl.display.Shape;

/**
 * Material-inspired progress indicator with a soft animated wave.
 * Supports linear and circular variants in determinate and indeterminate modes.
 */
class MaterialWavyProgressIndicator extends FlxSpriteGroup
{
	static inline var TAU:Float = 6.283185307179586;

	public var value(default, set):Float = 0;
	public var indeterminate(default, set):Bool = false;
	public var indicatorType:WavyProgressType = LINEAR;
	public var indicatorExtent:Float = 240;
	public var animationSpeed:Float = 2.6;
	public var waveUsesGradient(default, null):Bool = false;
	public var linearGapSize:Float = 4; // Pixels of separation between filled and unfilled segments.
	public var linearShowStopDot:Bool = false; // Material stop indicator on determinate linear end.
	public var linearStopDotSize:Float = 4;
	public var linearHeightScale(default, set):Float = 1.0;
	public var linearWaveThicknessScale:Float = 1.0;
	public var linearTrackThicknessScale:Float = 1.0;
	public var circularEdgeGap:Float = 0; // Radians trimmed from both ends in determinate circular mode.
	public var circularTrackRadiusOffset:Float = 0; // Pixels added to track radius (negative = inward).
	public var circularTrackThicknessScale:Float = 1; // Track thickness multiplier.

	var linearTrack:FlxSprite;
	var linearWave:FlxSprite;
	var circularTrack:FlxSprite;
	var circularWave:FlxSprite;
	var trackColor:FlxColor = 0x00000000;
	var waveStartColor:FlxColor = 0x00000000;
	var waveEndColor:FlxColor = 0x00000000;
	var useThemeTrackColor:Bool = true;
	var useThemeWaveColor:Bool = true;

	var phase:Float = 0;
	var sweepPhase:Float = 0;
	var redrawAccumulator:Float = 0;

	static inline var REDRAW_INTERVAL:Float = 1 / 30;

	inline function linearHeight():Int return Std.int(MD3Metrics.size(8) * Math.max(1, linearHeightScale));
	inline function linearCorner():Int return MD3Metrics.corner(4, indicatorExtent, linearHeight());
	inline function circularSize():Int return Std.int(indicatorExtent > 0 ? indicatorExtent : MD3Metrics.size(56));
	inline function circularThickness():Float return MD3Metrics.size(6);

	public function new(x:Float = 0, y:Float = 0, ?indicatorType:WavyProgressType = LINEAR, ?extent:Float = 240)
	{
		super(x, y);

		this.indicatorType = indicatorType;
		this.indicatorExtent = extent;

		switch (indicatorType)
		{
			case LINEAR:
				buildLinear();
			case CIRCULAR:
				buildCircular();
		}

		MD3Theme.addListener(_onThemeChange);
		applyResolvedColors();
		redrawDynamic();
	}

	public function setWaveColor(color:FlxColor):Void
	{
		useThemeWaveColor = false;
		waveUsesGradient = false;
		waveStartColor = color;
		waveEndColor = color;
		redrawDynamic();
	}

	public function setWaveGradient(startColor:FlxColor, endColor:FlxColor):Void
	{
		useThemeWaveColor = false;
		waveUsesGradient = true;
		waveStartColor = startColor;
		waveEndColor = endColor;
		redrawDynamic();
	}

	public function setTrackColor(color:FlxColor):Void
	{
		useThemeTrackColor = false;
		trackColor = color;
		applyResolvedColors();
		redrawDynamic();
	}

	public function resetThemeColors():Void
	{
		useThemeTrackColor = true;
		useThemeWaveColor = true;
		waveUsesGradient = false;
		applyResolvedColors();
		redrawDynamic();
	}

	public function getIndicatorHeight():Float
	{
		return indicatorType == LINEAR ? linearHeight() : circularSize();
	}

	function buildLinear():Void
	{
		var width = Std.int(indicatorExtent);
		var height = linearHeight();

		linearTrack = new FlxSprite(0, 0);
		linearTrack.antialiasing = ClientPrefs.data.antialiasing;
		linearTrack.makeGraphic(width, height, FlxColor.TRANSPARENT, true);
		add(linearTrack);

		linearWave = new FlxSprite(0, 0);
		linearWave.antialiasing = ClientPrefs.data.antialiasing;
		linearWave.makeGraphic(width, height, FlxColor.TRANSPARENT, true);
		add(linearWave);
	}

	function buildCircular():Void
	{
		var size = circularSize();

		circularTrack = new FlxSprite(0, 0);
		circularTrack.antialiasing = ClientPrefs.data.antialiasing;
		circularTrack.makeGraphic(size, size, FlxColor.TRANSPARENT, true);
		add(circularTrack);

		circularWave = new FlxSprite(0, 0);
		circularWave.antialiasing = ClientPrefs.data.antialiasing;
		circularWave.makeGraphic(size, size, FlxColor.TRANSPARENT, true);
		add(circularWave);

		drawCircularTrack();
	}

	function set_value(nextValue:Float):Float
	{
		value = FlxMath.bound(nextValue, 0, 1);
		redrawDynamic();
		return value;
	}

	function set_indeterminate(nextValue:Bool):Bool
	{
		indeterminate = nextValue;
		redrawDynamic();
		return indeterminate;
	}

	function set_linearHeightScale(nextValue:Float):Float
	{
		linearHeightScale = Math.max(1.0, nextValue);
		if (indicatorType == LINEAR && linearTrack != null && linearWave != null)
		{
			var width = Std.int(indicatorExtent);
			var height = linearHeight();
			linearTrack.makeGraphic(width, height, FlxColor.TRANSPARENT, true);
			linearWave.makeGraphic(width, height, FlxColor.TRANSPARENT, true);
		}
		redrawDynamic();
		return linearHeightScale;
	}

	function _onThemeChange():Void
	{
		applyResolvedColors();
		redrawDynamic();
	}

	function applyResolvedColors():Void
	{
		if (useThemeTrackColor)
			trackColor = MD3Theme.surfaceVariant;

		if (useThemeWaveColor)
		{
			waveStartColor = MD3Theme.primary;
			waveEndColor = MD3Theme.primary;
			waveUsesGradient = false;
		}

		if (linearTrack != null)
		{
			linearTrack.color = stripAlpha(trackColor);
			linearTrack.alpha = colorAlpha(trackColor);
		}

		if (circularTrack != null)
			drawCircularTrack();
	}

	inline function stripAlpha(color:FlxColor):FlxColor
	{
		return color & 0x00FFFFFF;
	}

	inline function colorAlpha(color:FlxColor):Float
	{
		return ((color >> 24) & 0xFF) / 255;
	}

	inline function resolveWaveColor(t:Float):FlxColor
	{
		return waveUsesGradient ? FlxColor.interpolate(waveStartColor, waveEndColor, FlxMath.bound(t, 0, 1)) : waveStartColor;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (!visible || alpha <= 0) return;

		phase += elapsed * animationSpeed * TAU;
		sweepPhase += elapsed * 1.15;
		if (phase > TAU) phase -= TAU;
		if (sweepPhase > 1000) sweepPhase = 0;
		redrawAccumulator += elapsed;
		if (redrawAccumulator < REDRAW_INTERVAL) return;
		redrawAccumulator = 0;

		redrawDynamic();
	}

	function redrawDynamic():Void
	{
		switch (indicatorType)
		{
			case LINEAR:
				drawLinearWave();
			case CIRCULAR:
				drawCircularWave();
		}
	}

	function drawLinearWave():Void
	{
		if (linearWave == null) return;
		drawLinearTrack();

		var bitmap = linearWave.pixels;
		bitmap.fillRect(bitmap.rect, FlxColor.TRANSPARENT);

		var width = indicatorExtent;
		var height = linearHeight();
		var stroke = height * 0.72 * linearWaveThicknessScale;
		var centerY = height * 0.5;
		var amplitude = Math.max(1.0, height * 0.18);
		var maxAmplitude = Math.max(0.0, ((height - stroke) * 0.5) - 1);
		amplitude = Math.min(amplitude, maxAmplitude);
		var waveLength = Math.max(MD3Metrics.size(36), height * 3.0);
		var availableWidth = Math.max(0.0, width - stroke);

		var startOffset = 0.0;
		var endOffset = availableWidth * value;
		if (indeterminate)
		{
			var segmentWidth = availableWidth * 0.34;
			var travel = availableWidth + segmentWidth;
			var segmentT = (sweepPhase % 1.1) / 1.1;
			var head = segmentT * travel - segmentWidth;
			startOffset = Math.max(0.0, head);
			endOffset = Math.min(availableWidth, head + segmentWidth);
		}

		var startX = stroke * 0.5 + startOffset;
		var endX = stroke * 0.5 + endOffset;
		if (!indeterminate)
		{
			var gap = FlxMath.bound(linearGapSize, 0, availableWidth * 0.5);
			endX -= gap * 0.5;
		}
		if (endX - startX <= 0.5)
		{
			linearWave.dirty = true;
			return;
		}

		var shape = new Shape();
		var graphics = shape.graphics;
		var steps = Std.int(Math.max(16, Math.ceil((endX - startX) / 4.0)));
		var previousX:Null<Float> = null;
		var previousY:Null<Float> = null;

		for (i in 0...steps + 1)
		{
			var t = i / steps;
			var px = FlxMath.lerp(startX, endX, t);
			var py = centerY + Math.sin((px / waveLength) * TAU + phase) * amplitude;
			if (previousX != null && previousY != null)
			{
				var color = resolveWaveColor((i - 0.5) / steps);
				graphics.lineStyle(stroke, stripAlpha(color), colorAlpha(color), false, null, ROUND, ROUND);
				graphics.moveTo(previousX, previousY);
				graphics.lineTo(px, py);
			}
			previousX = px;
			previousY = py;
		}

		bitmap.draw(shape);

		if (!indeterminate && linearShowStopDot)
		{
			var dotRadius = Math.max(1.0, linearStopDotSize * 0.5);
			var dotColor = resolveWaveColor(1);
			var dotShape = new Shape();
			dotShape.graphics.beginFill(stripAlpha(dotColor), colorAlpha(dotColor));
			dotShape.graphics.drawCircle(width - dotRadius, centerY, dotRadius);
			dotShape.graphics.endFill();
			bitmap.draw(dotShape);
		}
		linearWave.dirty = true;
	}

	function drawLinearTrack():Void
	{
		if (linearTrack == null) return;

		var bitmap = linearTrack.pixels;
		bitmap.fillRect(bitmap.rect, FlxColor.TRANSPARENT);

		var width = indicatorExtent;
		var height = linearHeight();
		var stroke = height * 0.72 * linearTrackThicknessScale;
		var centerY = height * 0.5;
		var availableWidth = Math.max(0.0, width - stroke);

		var startOffset = 0.0;
		var endOffset = availableWidth * value;
		if (indeterminate)
		{
			startOffset = 0;
			endOffset = availableWidth;
		}

		var gap = indeterminate ? 0.0 : FlxMath.bound(linearGapSize, 0, availableWidth * 0.5);
		var startX = stroke * 0.5 + endOffset + gap * 0.5;
		var endX = stroke * 0.5 + availableWidth;

		if (endX - startX <= 0.5)
		{
			linearTrack.dirty = true;
			return;
		}

		var shape = new Shape();
		var graphics = shape.graphics;
		graphics.lineStyle(stroke, stripAlpha(trackColor), colorAlpha(trackColor), false, null, ROUND, ROUND);
		graphics.moveTo(startX, centerY);
		graphics.lineTo(endX, centerY);

		bitmap.draw(shape);
		linearTrack.dirty = true;
	}

	function drawCircularTrack():Void
	{
		if (circularTrack == null) return;

		var bitmap = circularTrack.pixels;
		bitmap.fillRect(bitmap.rect, FlxColor.TRANSPARENT);

		var size = circularSize();
		var thickness = circularThickness() * circularTrackThicknessScale;
		var radius = (size - circularThickness()) * 0.5 - 1 + circularTrackRadiusOffset;
		radius = Math.max(1, radius);
		var center = size * 0.5;

		var shape = new Shape();
		var graphics = shape.graphics;
		graphics.lineStyle(thickness, stripAlpha(trackColor), colorAlpha(trackColor), false, null, ROUND, ROUND);

		// Determinate circular: draw only the remaining (unfilled) arc, not a full background ring.
		if (!indeterminate)
		{
			var startAngle = -Math.PI / 2;
			var waveSweep = TAU * value;
			var gap = FlxMath.bound(circularEdgeGap, 0, Math.PI / 4);
			var trackStart = startAngle + waveSweep + gap;
			var trackSweep = TAU - waveSweep - (gap * 2);
			if (trackSweep > 0.01)
			{
				var steps = Std.int(Math.max(36, Math.ceil((trackSweep * radius) / 3.0)));
				for (i in 0...steps + 1)
				{
					var t = i / steps;
					var angle = trackStart + trackSweep * t;
					var px = center + Math.cos(angle) * radius;
					var py = center + Math.sin(angle) * radius;
					if (i == 0) graphics.moveTo(px, py); else graphics.lineTo(px, py);
				}
			}
		}
		else
		{
			graphics.drawCircle(center, center, radius);
		}

		bitmap.draw(shape);
		circularTrack.dirty = true;
	}

	function drawCircularWave():Void
	{
		if (circularWave == null) return;
		drawCircularTrack();

		var bitmap = circularWave.pixels;
		bitmap.fillRect(bitmap.rect, FlxColor.TRANSPARENT);

		var size = circularSize();
		var thickness = circularThickness();
		var center = size * 0.5;
		var baseRadius = (size - thickness) * 0.5 - 1;
		var amplitude = Math.max(1.0, thickness * 0.35);
		var waveTurns = 6.0;

		var startAngle = -Math.PI / 2;
		var sweep = TAU * value;
		if (indeterminate)
		{
			startAngle += sweepPhase * 2.4;
			var pulse = (Math.sin(sweepPhase * 1.9) + 1) * 0.5;
			sweep = TAU * FlxMath.lerp(0.18, 0.34, pulse);
		}
		else
		{
			var gap = FlxMath.bound(circularEdgeGap, 0, Math.PI / 4);
			if (gap > 0)
			{
				if (sweep > gap * 2)
				{
					startAngle += gap;
					sweep -= gap * 2;
				}
				else
				{
					sweep = 0;
				}
			}
		}

		if (sweep <= 0.01)
		{
			circularWave.dirty = true;
			return;
		}

		var shape = new Shape();
		var graphics = shape.graphics;

		var steps = Std.int(Math.max(36, Math.ceil((sweep * baseRadius) / 3.0)));
		var previousX:Null<Float> = null;
		var previousY:Null<Float> = null;
		for (i in 0...steps + 1)
		{
			var t = i / steps;
			var angle = startAngle + sweep * t;
			var radius = baseRadius + Math.sin(angle * waveTurns + phase) * amplitude;
			var px = center + Math.cos(angle) * radius;
			var py = center + Math.sin(angle) * radius;
			if (previousX != null && previousY != null)
			{
				var color = resolveWaveColor((i - 0.5) / steps);
				graphics.lineStyle(thickness, stripAlpha(color), colorAlpha(color), false, null, ROUND, ROUND);
				graphics.moveTo(previousX, previousY);
				graphics.lineTo(px, py);
			}
			previousX = px;
			previousY = py;
		}

		bitmap.draw(shape);
		circularWave.dirty = true;
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(_onThemeChange);
		super.destroy();
	}
}

enum WavyProgressType
{
	LINEAR;
	CIRCULAR;
}
