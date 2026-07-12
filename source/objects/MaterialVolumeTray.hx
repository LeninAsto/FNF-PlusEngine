package objects;

import flixel.FlxG;
import backend.ui.md3.MD3Theme;
import options.OptionsMenuTheme;
import openfl.Lib;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

class MaterialVolumeTray extends Sprite
{
	static inline var TRAY_WIDTH:Int = 286;
	static inline var TRAY_HEIGHT:Int = 58;
	static inline var TRAY_RADIUS:Int = 24;
	static inline var SHOWN_Y:Float = 18;
	static inline var HIDDEN_Y:Float = -78;
	static inline var WAVE_WIDTH:Float = 124;
	static inline var WAVE_BASE_AMPLITUDE:Float = 0.85;
	static inline var WAVE_EXTRA_AMPLITUDE:Float = 1.75;
	static inline var TAU:Float = 6.283185307179586;

	var background:Shape;
	var iconChip:Shape;
	var iconShape:Shape;
	var waveTrack:Shape;
	var waveShape:Shape;
	var valueText:TextField;
	var labelText:TextField;

	var shownVolume:Float = 0;
	var wavePhase:Float = 0;
	var displayTimer:Float = 0;
	var currentY:Float = HIDDEN_Y;
	var targetY:Float = HIDDEN_Y;
	var currentAlpha:Float = 0;
	var targetAlpha:Float = 0;
	var lastTime:Float = 0;
	var themeAccent:Int = 0;

	public function new()
	{
		super();
		mouseEnabled = false;
		mouseChildren = false;
		visible = false;
		y = HIDDEN_Y;

		background = new Shape();
		addChild(background);

		iconChip = new Shape();
		iconChip.x = 10;
		iconChip.y = 11;
		addChild(iconChip);

		waveTrack = new Shape();
		waveTrack.x = 68;
		waveTrack.y = 29;
		addChild(waveTrack);

		waveShape = new Shape();
		waveShape.x = 68;
		waveShape.y = 29;
		addChild(waveShape);

		iconShape = new Shape();
		iconShape.x = 24;
		iconShape.y = 19;
		addChild(iconShape);

		labelText = makeTextField(68, 11, 106, 11, 0x8CB89A, TextFormatAlign.LEFT, 0.82);
		addChild(labelText);

		valueText = makeTextField(216, 15, 50, 17, 0xE9FFF0, TextFormatAlign.RIGHT, 0.94, true);
		addChild(valueText);

		redrawChrome();
		updateVisuals();
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
		refreshTheme(true);
		reposition();
	}

	public function showVolume(volume:Float):Void
	{
		refreshTheme();
		shownVolume = clamp(volume, 0, 1);
		displayTimer = 1.15;
		targetY = SHOWN_Y;
		targetAlpha = 1;
		visible = true;
		updateVisuals();
		reposition();
	}

	function onEnterFrame(_:Event):Void
	{
		if (parent != null && parent.numChildren > 0 && parent.getChildIndex(this) != parent.numChildren - 1)
			parent.setChildIndex(this, parent.numChildren - 1);

		var now:Float = Lib.getTimer() / 1000;
		if (lastTime <= 0)
		{
			lastTime = now;
			return;
		}

		var elapsed:Float = now - lastTime;
		lastTime = now;
		reposition();
		refreshTheme();

		if (displayTimer > 0)
			displayTimer -= elapsed;
		else
		{
			targetY = HIDDEN_Y;
			targetAlpha = 0;
		}

		currentY = approach(currentY, targetY, elapsed * 16);
		currentAlpha = approach(currentAlpha, targetAlpha, elapsed * 18);
		y = currentY;
		alpha = currentAlpha;
		visible = currentAlpha > 0.01;

		if (visible)
		{
			wavePhase += elapsed * (4.0 + shownVolume * 5.5);
			updateVisuals();
		}
	}

	function reposition():Void
	{
		if (Lib.current == null || Lib.current.stage == null)
			return;
		x = Math.round((Lib.current.stage.stageWidth - TRAY_WIDTH) * 0.5);
	}

	function makeTextField(x:Float, y:Float, width:Float, size:Int, color:Int, align:TextFormatAlign, alpha:Float, bold:Bool = false):TextField
	{
		var field = new TextField();
		field.x = x;
		field.y = y;
		field.width = width;
		field.height = size + 12;
		field.selectable = false;
		field.mouseEnabled = false;
		field.multiline = false;
		field.defaultTextFormat = new TextFormat('_sans', size, color, bold, null, null, null, null, align);
		field.alpha = alpha;
		return field;
	}

	function redrawChrome():Void
	{
		var palette = OptionsMenuTheme.current();
		background.graphics.clear();
		background.graphics.beginFill(MD3Theme.surfaceContainerHigh, 0.98);
		background.graphics.drawRoundRect(0, 0, TRAY_WIDTH, TRAY_HEIGHT, TRAY_RADIUS, TRAY_RADIUS);
		background.graphics.endFill();
		background.graphics.lineStyle(1, MD3Theme.outline, 0.42);
		background.graphics.drawRoundRect(0.5, 0.5, TRAY_WIDTH - 1, TRAY_HEIGHT - 1, TRAY_RADIUS, TRAY_RADIUS);

		iconChip.graphics.clear();
		iconChip.graphics.beginFill(MD3Theme.primaryContainer, 1);
		iconChip.graphics.drawRoundRect(0, 0, 36, 34, 12, 12);
		iconChip.graphics.endFill();

		waveTrack.graphics.clear();
		waveTrack.graphics.lineStyle(2, MD3Theme.outlineVariant, 0.9, false, null, ROUND, ROUND);
		waveTrack.graphics.moveTo(0, 0);
		waveTrack.graphics.lineTo(WAVE_WIDTH, 0);

		labelText.textColor = MD3Theme.onSurfaceVariant;
		valueText.textColor = MD3Theme.onSurface;
	}

	function updateVisuals():Void
	{
		labelText.text = shownVolume <= 0.01 ? 'Muted' : 'Media volume';
		valueText.text = Std.int(Math.round(shownVolume * 100)) + '%';
		drawSpeakerIcon();
		drawWave();
	}

	function drawSpeakerIcon():Void
	{
		var palette = OptionsMenuTheme.current();
		var graphics = iconShape.graphics;
		graphics.clear();
		graphics.beginFill(MD3Theme.onPrimaryContainer, 1);
		graphics.moveTo(0, 7);
		graphics.lineTo(6, 7);
		graphics.lineTo(12, 2);
		graphics.lineTo(12, 18);
		graphics.lineTo(6, 13);
		graphics.lineTo(0, 13);
		graphics.lineTo(0, 7);
		graphics.endFill();

		if (shownVolume <= 0.01)
		{
			graphics.lineStyle(2.2, MD3Theme.onPrimaryContainer, 0.75);
			graphics.moveTo(16, 6);
			graphics.lineTo(24, 14);
			graphics.moveTo(24, 6);
			graphics.lineTo(16, 14);
			return;
		}

		var waves:Int = shownVolume > 0.66 ? 3 : (shownVolume > 0.33 ? 2 : 1);
		graphics.lineStyle(1.8, MD3Theme.onPrimaryContainer, 0.9, false, null, ROUND, ROUND);
		for (i in 0...waves)
		{
			var radius:Float = 5 + i * 4;
			var topY:Float = 10 - radius * 0.55;
			var bottomY:Float = 10 + radius * 0.55;
			var controlX:Float = 8 + radius * 0.78;
			var endX:Float = 8 + radius * 0.4;
			graphics.moveTo(endX, topY);
			graphics.curveTo(controlX, 10, endX, bottomY);
		}
	}

	function drawWave():Void
	{
		var palette = OptionsMenuTheme.current();
		var graphics = waveShape.graphics;
		graphics.clear();
		if (shownVolume <= 0.01)
		{
			graphics.lineStyle(2.4, palette.accent, 0.35, false, null, ROUND, ROUND);
			graphics.moveTo(0, 0);
			graphics.lineTo(WAVE_WIDTH * 0.2, 0);
			return;
		}

		var activeWidth:Float = Math.max(12, WAVE_WIDTH * shownVolume);
		var amplitude:Float = WAVE_BASE_AMPLITUDE + shownVolume * WAVE_EXTRA_AMPLITUDE;
		var wavelength:Float = 18.0 - shownVolume * 4.0;
		var steps:Int = 42;
		graphics.lineStyle(2.3, palette.accent, 1, false, null, ROUND, ROUND);
		for (i in 0...steps + 1)
		{
			var t:Float = i / steps;
			var px:Float = activeWidth * t;
			var py:Float = Math.sin((px / wavelength) * TAU + wavePhase) * amplitude;
			if (i == 0)
				graphics.moveTo(px, py);
			else
				graphics.lineTo(px, py);
		}
	}

	inline function approach(current:Float, target:Float, speed:Float):Float
	{
		return current + (target - current) * (1 - Math.exp(-speed));
	}

	function refreshTheme(force:Bool = false):Void
	{
		var palette = OptionsMenuTheme.current();
		if (!force && themeAccent == palette.accent)
			return;

		themeAccent = palette.accent;
		OptionsMenuTheme.syncAccent();
		redrawChrome();
		updateVisuals();
	}

	inline function clamp(value:Float, min:Float, max:Float):Float
	{
		return value < min ? min : (value > max ? max : value);
	}
}