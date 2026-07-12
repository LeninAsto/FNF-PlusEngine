package backend.ui.md3;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import openfl.display.Shape;

/**
 * Material Design 3 Slider Component
 * Based on: https://m3.material.io/components/sliders/guidelines
 */
class MaterialSlider extends FlxSpriteGroup
{
	static inline var TRACE_LAYOUT:Bool = false;

	public var value(default, set):Float = 0.5;
	public var min:Float = 0.0;
	public var max:Float = 1.0;
	public var enabled:Bool = true;
	public var allowMouseInput:Bool = true;
	public var onChange:Float->Void = null;
	
	// Visual components
	var trackInactive:FlxSprite;
	var trackActive:FlxSprite;
	var thumb:FlxSprite;
	var valueLabel:FlxSprite;
	var valueLabelText:FlxText;

	// Dimensions
	public var sliderWidth:Float = 200;

	// Animation tweens
	var thumbTween:FlxTween;
	var labelTween:FlxTween;
	var displayCenterX:Float = 0;
	var wavePhase:Float = 0;
	var currentTrackVisualHeight:Int = 0;
	var needsStaticTrackRedraw:Bool = true;

	// Interaction state
	var isDragging:Bool = false;
	var valuePulseTimer:Float = 0;

	static inline var WAVE_SPEED:Float = 1.6;
	static inline var TAU:Float = 6.283185307179586;
	static inline var VALUE_PULSE_DURATION:Float = 0.32;

	inline function trackInactiveHeight():Int return MD3Metrics.size(4);
	inline function trackActiveHeight():Int return MD3Metrics.size(6);
	inline function thumbSize():Int return MD3Metrics.size(20);
	inline function thumbPressedSize():Int return MD3Metrics.size(24);
	inline function labelHeight():Int return MD3Metrics.size(32);
	inline function labelWidth():Int return MD3Metrics.size(60);
	inline function labelTextSize():Int return MD3Metrics.text(13);
	inline function labelGap():Int return MD3Metrics.size(10);
	inline function hitHeight():Int return MD3Metrics.touch(36);
	inline function thumbCenterY():Float return thumbPressedSize() * 0.5;
	inline function trackY(height:Float):Float return thumbCenterY() - height * 0.5;

	public function new(x:Float = 0, y:Float = 0, width:Float = 200, ?value:Float = 0.5, ?min:Float = 0.0, ?max:Float = 1.0)
	{
		super(x, y);

		this.sliderWidth = width;
		this.min = min;
		this.max = max;

		// Create inactive track (full width, thin)
		trackInactive = new FlxSprite();
		trackInactive.antialiasing = ClientPrefs.data.antialiasing;
		MD3ShapeTools.fillRoundRect(trackInactive, Std.int(sliderWidth), trackInactiveHeight(), trackInactiveHeight() / 2);
		add(trackInactive);
		trackInactive.color = MD3Theme.surfaceVariant;

		// Create active track (variable width based on value, starts thin)
		trackActive = new FlxSprite();
		trackActive.antialiasing = ClientPrefs.data.antialiasing;
		add(trackActive);
		trackActive.color = MD3Theme.primary;

		// Create thumb
		thumb = new FlxSprite();
		thumb.antialiasing = ClientPrefs.data.antialiasing;
		add(thumb);
		thumb.color = MD3Theme.primary;

		// Create value label (appears on drag)
		valueLabel = new FlxSprite();
		valueLabel.antialiasing = ClientPrefs.data.antialiasing;
		MD3ShapeTools.fillRoundRect(valueLabel, labelWidth(), labelHeight(), MD3Metrics.corner(8, labelWidth(), labelHeight()));
		valueLabel.color = MD3Theme.primary;
		valueLabel.alpha = 0;
		add(valueLabel);

		valueLabelText = new FlxText(0, 0, labelWidth(), "50", labelTextSize());
		valueLabelText.setFormat(Paths.font('NotoSans-Medium.ttf'), labelTextSize(), MD3Theme.onPrimary, CENTER);
		valueLabelText.antialiasing = ClientPrefs.data.antialiasing;
		valueLabelText.alpha = 0;
		add(valueLabelText);

		// Set initial value
		displayCenterX = sliderWidth * 0.5;
		this.value = value;
		updateVisuals(false);
		MD3Theme.addListener(_onThemeChange);
		traceLayout('create');
	}

	function traceLayout(reason:String):Void
	{
		if (!TRACE_LAYOUT) return;
	}

	public function getDebugLayout():String
	{
		return 'group=(' + x + ', ' + y + ') width=' + sliderWidth
			+ ' trackInactiveLocal=(' + (trackInactive.x - x) + ', ' + (trackInactive.y - y) + ', ' + trackInactive.width + 'x' + trackInactive.height + ')'
			+ ' trackActiveLocal=(' + (trackActive.x - x) + ', ' + (trackActive.y - y) + ', ' + trackActive.width + 'x' + trackActive.height + ')'
			+ ' thumbLocal=(' + (thumb.x - x) + ', ' + (thumb.y - y) + ', ' + thumb.width + 'x' + thumb.height + ')'
			+ ' labelLocal=(' + (valueLabel.x - x) + ', ' + (valueLabel.y - y) + ', ' + valueLabel.width + 'x' + valueLabel.height + ')'
			+ ' value=' + value;
	}

	function redrawThumb(size:Int):Void
	{
		MD3ShapeTools.fillCircle(thumb, size);
	}

	function redrawStaticActiveTrack(width:Int, height:Int):Void
	{
		var drawWidth = Std.int(Math.max(height, width));
		MD3ShapeTools.fillRoundRect(trackActive, drawWidth, height, height * 0.5);
		needsStaticTrackRedraw = false;
	}

	function redrawActiveTrack(width:Int, height:Int, pressed:Bool):Void
	{
		var drawWidth = Std.int(Math.max(height, width));
		var stroke = Math.max(2, height);
		var amplitude = Math.max(2.0, height * (pressed ? 0.75 : 0.55));
		var verticalPadding = Std.int(Math.ceil(amplitude + stroke * 0.5 + 1));
		var drawHeight = Std.int(Math.max(1, height + verticalPadding * 2));
		trackActive.makeGraphic(drawWidth, drawHeight, FlxColor.TRANSPARENT, true);

		var centerY = drawHeight * 0.5;
		var wavelength = Math.max(MD3Metrics.size(34), height * (pressed ? 7.0 : 8.5));
		var startX = stroke * 0.5;
		var endX = Math.max(startX, drawWidth - stroke * 0.5);

		var shape = new Shape();
		var graphics = shape.graphics;
		graphics.lineStyle(stroke, MD3Theme.primary, 1, false, null, ROUND, ROUND);

		var steps = Std.int(Math.max(10, Math.ceil((endX - startX) / 4.0)));
		for (i in 0...steps + 1)
		{
			var t = i / steps;
			var px = FlxMath.lerp(startX, endX, t);
			var py = centerY + Math.sin((px / wavelength) * TAU + wavePhase) * amplitude;
			if (i == 0)
				graphics.moveTo(px, py);
			else
				graphics.lineTo(px, py);
		}

		trackActive.pixels.draw(shape, null, null, null, null, true);
		trackActive.dirty = true;
	}

	function _onThemeChange():Void
	{
		trackInactive.color = MD3Theme.surfaceVariant;
		trackActive.color = MD3Theme.primary;
		thumb.color = MD3Theme.primary;
		valueLabel.color = MD3Theme.primary;
		valueLabelText.color = MD3Theme.onPrimary;
		needsStaticTrackRedraw = true;
		layoutComponents(isDragging);
	}

	function updateVisuals(animate:Bool = true):Void
	{
		var duration = animate ? 0.24 : 0;
		var range = max - min;
		var normalizedValue = range == 0 ? 0 : (value - min) / range;
		var targetCenterX = sliderWidth * normalizedValue;
		if (animate && thumbTween != null) thumbTween.cancel();

		if (animate)
		{
			thumbTween = FlxTween.tween(this, {displayCenterX: targetCenterX}, duration, {
				ease: FlxEase.cubeOut,
				onUpdate: function(_) {
					layoutComponents(isDragging);
				}
			});
		}
		else
		{
			displayCenterX = targetCenterX;
		}

		layoutComponents(isDragging);
		updateLabelPosition();
		updateLabelText();
		traceLayout(animate ? 'updateVisuals(animated)' : 'updateVisuals(static)');
	}

	function layoutComponents(pressed:Bool):Void
	{
		var currentThumbSize = pressed ? thumbPressedSize() : thumbSize();
		var currentTrackHeight = pressed ? trackActiveHeight() : trackInactiveHeight();
		var activeTrackWidth = Std.int(Math.max(currentTrackHeight, displayCenterX));
		currentTrackVisualHeight = currentTrackHeight;

		trackInactive.x = x;
		trackInactive.y = y + trackY(trackInactiveHeight());
		updateInactiveTrackClip();
		if (pressed)
		{
			redrawActiveTrack(activeTrackWidth, currentTrackHeight, true);
			needsStaticTrackRedraw = true;
		}
		else if (needsStaticTrackRedraw || trackActive.frameWidth != activeTrackWidth || trackActive.frameHeight != currentTrackHeight)
		{
			redrawStaticActiveTrack(activeTrackWidth, currentTrackHeight);
		}
		trackActive.x = x;
		trackActive.y = y + thumbCenterY() - trackActive.height * 0.5;

		redrawThumb(currentThumbSize);
		thumb.x = x + displayCenterX - thumb.width * 0.5;
		thumb.y = y + thumbCenterY() - thumb.height * 0.5;
	}

	function updateInactiveTrackClip():Void
	{
		var clipStart = FlxMath.bound(displayCenterX, 0, sliderWidth);
		var visibleWidth = sliderWidth - clipStart;
		if (visibleWidth <= 0.5)
		{
			trackInactive.visible = false;
			trackInactive.clipRect = null;
			return;
		}

		trackInactive.visible = true;
		trackInactive.clipRect = new FlxRect(clipStart, 0, visibleWidth, trackInactive.frameHeight);
	}

	function updateLabelPosition():Void
	{
		valueLabel.x = x + displayCenterX - labelWidth() * 0.5;
		valueLabel.y = thumb.y - labelHeight() - labelGap();
		valueLabelText.x = valueLabel.x;
		valueLabelText.y = valueLabel.y + (labelHeight() - valueLabelText.height) / 2;
	}

	function updateLabelText():Void
	{
		var displayValue:String;
		if (max - min >= 10)
			displayValue = Std.string(Std.int(value));
		else
			displayValue = Std.string(Math.round(value * 100) / 100);

		valueLabelText.text = displayValue;
		valueLabelText.y = valueLabel.y + (labelHeight() - valueLabelText.height) / 2;
	}

	function setLabelAlpha(value:Float):Void
	{
		valueLabel.alpha = value;
		valueLabelText.alpha = value;
	}

	function showValueLabel():Void
	{
		if (labelTween != null) labelTween.cancel();
		labelTween = FlxTween.num(valueLabel.alpha, 1, 0.15, {ease: FlxEase.cubeOut}, function(v) {
			setLabelAlpha(v);
		});
	}

	function hideValueLabel():Void
	{
		if (labelTween != null) labelTween.cancel();
		labelTween = FlxTween.num(valueLabel.alpha, 0, 0.15, {ease: FlxEase.cubeOut}, function(v) {
			setLabelAlpha(v);
		});
	}

	function startValuePulse():Void
	{
		valuePulseTimer = VALUE_PULSE_DURATION;
		wavePhase = 0;
		showValueLabel();
		layoutComponents(true);
		updateLabelPosition();
		updateLabelText();
	}

	function updateValuePulse(elapsed:Float):Void
	{
		if (valuePulseTimer <= 0 || isDragging)
			return;

		valuePulseTimer -= elapsed;
		wavePhase += elapsed * WAVE_SPEED * TAU;
		if (wavePhase > TAU) wavePhase -= TAU;
		layoutComponents(true);
		updateLabelPosition();
		updateLabelText();

		if (valuePulseTimer <= 0)
		{
			valuePulseTimer = 0;
			layoutComponents(false);
			hideValueLabel();
		}
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!enabled) return;
		updateValuePulse(elapsed);
		if (!allowMouseInput)
		{
			if (isDragging)
			{
				isDragging = false;
				hideValueLabel();
				layoutComponents(false);
			}
			return;
		}

		#if FLX_MOUSE
		var mousePos = FlxG.mouse.getScreenPosition();
		var hitPadY = Std.int(Math.max(0, (hitHeight() - thumbPressedSize()) / 2));
		var hitPadX = thumbPressedSize() / 2;
		var isOverSlider = mousePos.x >= x - hitPadX && mousePos.x <= x + sliderWidth + hitPadX
			&& mousePos.y >= y - hitPadY && mousePos.y <= y + thumbPressedSize() + hitPadY;

		// Start dragging
		if (FlxG.mouse.justPressed && isOverSlider)
		{
			isDragging = true;
			showValueLabel();
			layoutComponents(true);
		}

		// Update value while dragging
		if (isDragging && FlxG.mouse.pressed)
		{
			var localX = mousePos.x - x;
			var normalizedValue = FlxMath.bound(localX / sliderWidth, 0, 1);
			var newValue = min + normalizedValue * (max - min);

			if (max - min <= 100)
			{
				newValue = Math.round(newValue * 100) / 100;
			}

			if (newValue != value)
			{
				this.value = newValue;

				if (onChange != null)
					onChange(value);
			}
		}

		// Stop dragging
		if (isDragging && FlxG.mouse.justReleased)
		{
			isDragging = false;
			hideValueLabel();
			layoutComponents(false);
		}

		// Update label position if dragging
		if (isDragging)
		{
			wavePhase += elapsed * WAVE_SPEED * TAU;
			if (wavePhase > TAU) wavePhase -= TAU;
			layoutComponents(true);
			updateLabelPosition();
			updateLabelText();
		}
		#end
	}

	function set_value(newValue:Float):Float
	{
		var previousValue = value;
		value = FlxMath.bound(newValue, min, max);
		if (Math.abs(previousValue - value) > 0.0001 && !isDragging)
			startValuePulse();
		updateVisuals(!isDragging);
		return value;
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(_onThemeChange);
		if (thumbTween != null) thumbTween.cancel();
		if (labelTween != null) labelTween.cancel();

		onChange = null;

		super.destroy();
	}
}
