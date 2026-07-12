package objects;

import flixel.FlxG;
import openfl.Lib;
import openfl.display.CapsStyle;
import openfl.display.JointStyle;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Rectangle;
import options.OptionsMenuTheme;

class GlobalLoadingOverlay
{
	static var display:GlobalLoadingOverlayDisplay;
	static var initialized:Bool = false;

	public static function pulse(?holdTime:Float = 0.32):Void
	{
		ensureDisplay();
		display.show(false, holdTime);
	}

	public static function showPersistent():Void
	{
		ensureDisplay();
		display.show(true, 0);
	}

	public static function hide(?immediate:Bool = false):Void
	{
		if (display != null)
			display.hide(immediate);
	}

	public static function stateReady():Void
	{
		hide();
	}

	static function ensureDisplay():Void
	{
		if (display == null)
			display = new GlobalLoadingOverlayDisplay();

		if (!initialized)
		{
			initialized = true;
			FlxG.signals.preStateSwitch.add(onPreStateSwitch);
			FlxG.signals.postStateSwitch.add(onPostStateSwitch);
			FlxG.signals.gameResized.add(onGameResized);
			FlxG.signals.focusGained.add(onFocusGained);
		}

		display.attach();
	}

	static function onPreStateSwitch():Void
	{
		if (display != null)
			display.prepareForStateSwitch();
	}

	static function onPostStateSwitch():Void
	{
		if (display != null)
			display.reattachAfterStateSwitch();
	}

	static function onGameResized(_:Int, _:Int):Void
	{
		if (display != null)
			display.handleExternalResize();
	}

	static function onFocusGained():Void
	{
		if (display != null)
			display.resetFrameClock();
	}
}

private class GlobalLoadingOverlayDisplay extends Sprite
{
	static inline var PANEL_WIDTH:Float = 112;
	static inline var PANEL_HEIGHT:Float = 56;
	static inline var PANEL_RADIUS:Float = 28;
	static inline var TOP_MARGIN:Float = 12;
	static inline var HIDDEN_OFFSET:Float = -84;
	static inline var ICON_SIZE:Float = 34;
	static inline var TRACK_ALPHA:Float = 0.22;
	static inline var WAVE_ALPHA:Float = 1.0;
	static inline var WAVE_SPEED:Float = 2.6;
	static inline var SWEEP_SPEED:Float = 1.15;
	static inline var TAU:Float = 6.283185307179586;

	var container:Sprite;
	var shadow:Shape;
	var panel:Shape;
	var outline:Shape;
	var iconHolder:Sprite;
	var iconTrack:Shape;
	var iconWave:Shape;

	var currentY:Float = HIDDEN_OFFSET;
	var targetY:Float = HIDDEN_OFFSET;
	var currentAlpha:Float = 0;
	var targetAlpha:Float = 0;
	var hideDeadline:Float = -1;
	var persistent:Bool = false;
	var wavePhase:Float = 0;
	var sweepPhase:Float = 0;
	var lastTime:Float = 0;
	var lastThemeSignature:String = null;

	public function new()
	{
		super();
		mouseEnabled = false;
		mouseChildren = false;
		visible = false;

		container = new Sprite();
		addChild(container);

		shadow = new Shape();
		container.addChild(shadow);

		panel = new Shape();
		container.addChild(panel);

		outline = new Shape();
		container.addChild(outline);

		iconHolder = new Sprite();
		iconHolder.scrollRect = new Rectangle(0, 0, ICON_SIZE, ICON_SIZE);
		iconHolder.x = (PANEL_WIDTH - ICON_SIZE) * 0.5;
		iconHolder.y = (PANEL_HEIGHT - ICON_SIZE) * 0.5;
		container.addChild(iconHolder);

		iconTrack = new Shape();
		iconHolder.addChild(iconTrack);

		iconWave = new Shape();
		iconHolder.addChild(iconWave);

		refreshThemeIfNeeded(true);
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	public function attach():Void
	{
		refreshThemeIfNeeded();

		if (Lib.current == null || Lib.current.stage == null)
			return;

		if (FlxG.game != null)
		{
			var gameHost:Sprite = cast FlxG.game;
			if (parent != gameHost)
			{
				if (parent != null)
					parent.removeChild(this);
				gameHost.addChild(this);
			}
			else
			{
				gameHost.setChildIndex(this, gameHost.numChildren - 1);
			}
		}
		else
		{
			var stageHost:Dynamic = Lib.current.stage;
			if (parent != stageHost)
			{
				if (parent != null)
					parent.removeChild(this);
				stageHost.addChild(this);
			}
			else
			{
				stageHost.setChildIndex(this, stageHost.numChildren - 1);
			}
		}

		resize();
		resetFrameClock();
	}

	public function prepareForStateSwitch():Void
	{
		if (parent != null)
			parent.setChildIndex(this, parent.numChildren - 1);
		resetFrameClock();
	}

	public function reattachAfterStateSwitch():Void
	{
		attach();
	}

	public function handleExternalResize():Void
	{
		resize();
		if (iconHolder != null)
			iconHolder.scrollRect = new Rectangle(0, 0, ICON_SIZE, ICON_SIZE);
	}

	public function resetFrameClock():Void
	{
		lastTime = 0;
	}

	public function show(keepVisible:Bool, holdTime:Float):Void
	{
		refreshThemeIfNeeded();
		attach();
		persistent = keepVisible;
		hideDeadline = keepVisible ? -1 : (nowSeconds() + holdTime);
		targetY = TOP_MARGIN;
		targetAlpha = 1;
		visible = true;
	}

	public function hide(?immediate:Bool = false):Void
	{
		persistent = false;
		hideDeadline = -1;

		if (immediate)
		{
			currentY = HIDDEN_OFFSET;
			targetY = HIDDEN_OFFSET;
			currentAlpha = 0;
			targetAlpha = 0;
			alpha = 0;
			visible = false;
			return;
		}

		targetY = HIDDEN_OFFSET;
		targetAlpha = 0;
	}

	function onEnterFrame(_:Event):Void
	{
		if (stage == null)
			return;

		refreshThemeIfNeeded();

		var now = nowSeconds();
		if (lastTime <= 0)
		{
			lastTime = now;
			redrawIndicator();
			return;
		}
		var elapsed = now - lastTime;
		lastTime = now;
		elapsed = Math.min(elapsed, 1 / 15);

		resize();

		if (!persistent && hideDeadline > 0 && now >= hideDeadline)
			hide();

		currentY = approach(currentY, targetY, elapsed * 14);
		currentAlpha = approach(currentAlpha, targetAlpha, elapsed * 16);
		alpha = currentAlpha;
		visible = currentAlpha > 0.01;
		container.y = currentY;

		wavePhase += elapsed * WAVE_SPEED * TAU;
		sweepPhase += elapsed * SWEEP_SPEED;
		if (wavePhase > TAU) wavePhase -= TAU;
		if (sweepPhase > 1000) sweepPhase = 0;
		redrawIndicator();
	}

	function resize():Void
	{
		if (stage == null)
			return;
		if (FlxG.game != null && parent == FlxG.game)
			x = Math.round(((stage.stageWidth - PANEL_WIDTH) * 0.5) - FlxG.game.x);
		else
			x = Math.round((stage.stageWidth - PANEL_WIDTH) * 0.5);
		y = 0;
	}

	function redrawChrome():Void
	{
		shadow.graphics.clear();
		shadow.graphics.beginFill(0x000000, 0.18);
		shadow.graphics.drawRoundRect(0, 4, PANEL_WIDTH, PANEL_HEIGHT, PANEL_RADIUS, PANEL_RADIUS);
		shadow.graphics.endFill();

		panel.graphics.clear();
		panel.graphics.beginFill(OptionsMenuTheme.loadingOverlayPanelColor(), 0.96);
		panel.graphics.drawRoundRect(0, 0, PANEL_WIDTH, PANEL_HEIGHT, PANEL_RADIUS, PANEL_RADIUS);
		panel.graphics.endFill();

		outline.graphics.clear();
		outline.graphics.lineStyle(1, OptionsMenuTheme.loadingOverlayOutlineColor(), OptionsMenuTheme.isDark() ? 0.28 : 0.18);
		outline.graphics.drawRoundRect(0.5, 0.5, PANEL_WIDTH - 1, PANEL_HEIGHT - 1, PANEL_RADIUS, PANEL_RADIUS);
	}

	function redrawIndicatorTrack():Void
	{
		if (iconTrack == null)
			return;

		var size:Float = ICON_SIZE;
		var thickness:Float = Math.max(4.0, size * 0.12);
		var center:Float = size * 0.5;
		var radius:Float = (size - thickness) * 0.5 - 1;

		iconTrack.graphics.clear();
		iconTrack.graphics.lineStyle(thickness, OptionsMenuTheme.loadingOverlayTrackColor(), TRACK_ALPHA, false, null, CapsStyle.ROUND, JointStyle.ROUND);
		iconTrack.graphics.drawCircle(center, center, radius);
	}

	function redrawIndicator():Void
	{
		if (iconWave == null)
			return;

		var size:Float = ICON_SIZE;
		var thickness:Float = Math.max(4.0, size * 0.12);
		var center:Float = size * 0.5;
		var baseRadius:Float = (size - thickness) * 0.5 - 1;
		var amplitude:Float = Math.max(1.0, thickness * 0.35);
		var waveTurns:Float = 6.0;
		var startAngle:Float = -Math.PI / 2 + sweepPhase * 2.4;
		var pulse:Float = (Math.sin(sweepPhase * 1.9) + 1) * 0.5;
		var sweep:Float = TAU * lerp(0.18, 0.34, pulse);

		iconWave.graphics.clear();
		if (sweep <= 0.01)
			return;

		iconWave.graphics.lineStyle(thickness, OptionsMenuTheme.loadingOverlayWaveColor(), WAVE_ALPHA, false, null, CapsStyle.ROUND, JointStyle.ROUND);

		var steps:Int = Std.int(Math.max(36, Math.ceil((sweep * baseRadius) / 3.0)));
		for (i in 0...steps + 1)
		{
			var t:Float = i / steps;
			var angle:Float = startAngle + sweep * t;
			var radius:Float = baseRadius + Math.sin(angle * waveTurns + wavePhase) * amplitude;
			var px:Float = center + Math.cos(angle) * radius;
			var py:Float = center + Math.sin(angle) * radius;

			if (i == 0)
				iconWave.graphics.moveTo(px, py);
			else
				iconWave.graphics.lineTo(px, py);
		}
	}

	inline function approach(current:Float, target:Float, speed:Float):Float
	{
		return current + (target - current) * (1 - Math.exp(-speed));
	}

	inline function lerp(a:Float, b:Float, t:Float):Float
	{
		return a + (b - a) * t;
	}

	inline function nowSeconds():Float
	{
		return Lib.getTimer() / 1000;
	}

	function refreshThemeIfNeeded(?force:Bool = false):Void
	{
		var themeSignature = OptionsMenuTheme.signature();
		if (!force && lastThemeSignature == themeSignature)
			return;

		lastThemeSignature = themeSignature;
		redrawChrome();
		redrawIndicatorTrack();
	}
}