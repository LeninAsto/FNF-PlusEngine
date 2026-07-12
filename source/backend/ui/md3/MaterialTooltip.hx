package backend.ui.md3;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

/**
 * Material Design 3 Tooltip Component
 * Based on: https://m3.material.io/components/tooltips/guidelines
 *
 * Plain tooltip that appears after hovering an anchor area.
 * Rich tooltips (with title + body) are also supported.
 *
 * Usage:
 *   var tip = new MaterialTooltip("Save file");
 *   tip.attachTo(saveButton, saveButton.width, saveButton.height);
 */
class MaterialTooltip extends FlxSpriteGroup
{
	public var text:String = "";
	public var isVisible(default, null):Bool = false;

	// Visual components
	var background:FlxSprite;
	var messageText:FlxText;

	// Anchor tracking
	var anchorX:Float = 0;
	var anchorY:Float = 0;
	var anchorW:Float = 0;
	var anchorH:Float = 0;
	var hoverTimer:Float = 0;

	// Dimensions (MD3 plain tooltip specs)
	static inline var CORNER_RADIUS:Int = 4;
	static inline var PADDING_H:Int = 8;
	static inline var PADDING_V:Int = 4;
	static inline var LABEL_SIZE:Int = 12;
	static inline var HOVER_DELAY:Float = 0.5; // seconds before tooltip appears
	static inline var HIDE_DELAY:Float = 1.5;  // seconds before auto-hiding

	// State
	var _wasHovering:Bool = false;
	var _hideTimer:Float = 0;
	var showTween:FlxTween;
	var hideTween:FlxTween;

	var _tooltipW:Float = 0;
	var _tooltipH:Float = 0;

	public function new(text:String = "")
	{
		super(0, 0);

		this.text = text;

		// Measure text
		var tempText = new FlxText(0, 0, 0, text, LABEL_SIZE);
		var labelW = Std.int(tempText.width);
		var labelH = Std.int(tempText.height);
		tempText.destroy();

		var bgW = labelW + PADDING_H * 2;
		var bgH = labelH + PADDING_V * 2;
		_tooltipW = bgW;
		_tooltipH = bgH;

		// Background
		background = new FlxSprite(0, 0);
		background.makeGraphic(bgW, bgH, FlxColor.TRANSPARENT, true);
		drawRoundedRect(background, bgW, bgH, CORNER_RADIUS);
		background.color = MD3Theme.inverseSurface;
		add(background);

		// Label
		messageText = new FlxText(PADDING_H, PADDING_V, labelW + 2, text, LABEL_SIZE);
		messageText.setFormat(Paths.font('NotoSans-Medium.ttf'), LABEL_SIZE, MD3Theme.inverseOnSurface, LEFT);
		messageText.antialiasing = ClientPrefs.data.antialiasing;
		add(messageText);

		// Hidden by default
		alpha = 0;
		visible = false;
		MD3Theme.addListener(_onThemeChange);
	}

	function _onThemeChange():Void
	{
		if (background != null) background.color = MD3Theme.inverseSurface;
		if (messageText != null) messageText.color = MD3Theme.inverseOnSurface;
	}

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

	/**
	 * Set the anchor element that triggers this tooltip on hover.
	 * @param ax  Anchor X in screen coordinates.
	 * @param ay  Anchor Y in screen coordinates.
	 * @param aw  Anchor width.
	 * @param ah  Anchor height.
	 */
	public function attachTo(ax:Float, ay:Float, aw:Float, ah:Float):Void
	{
		anchorX = ax;
		anchorY = ay;
		anchorW = aw;
		anchorH = ah;
	}

	function showTooltip():Void
	{
		if (isVisible) return;
		isVisible = true;
		visible = true;
		_hideTimer = 0;

		// Position above anchor, centered
		x = anchorX + (anchorW - _tooltipW) / 2;
		y = anchorY - _tooltipH - 4;

		// Clamp inside screen
		if (x < 4) x = 4;
		if (x + _tooltipW > FlxG.width - 4) x = FlxG.width - _tooltipW - 4;
		if (y < 4) y = anchorY + anchorH + 4; // flip below if too close to top

		if (showTween != null) showTween.cancel();
		if (hideTween != null) hideTween.cancel();
		showTween = FlxTween.tween(this, {alpha: 1}, 0.15, {ease: FlxEase.cubeOut});
	}

	function hideTooltip():Void
	{
		if (!isVisible) return;
		isVisible = false;
		hoverTimer = 0;
		_hideTimer = 0;

		if (showTween != null) showTween.cancel();
		if (hideTween != null) hideTween.cancel();
		hideTween = FlxTween.tween(this, {alpha: 0}, 0.12, {
			ease: FlxEase.cubeIn,
			onComplete: function(_) { visible = false; }
		});
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		#if FLX_MOUSE
		var mousePos = FlxG.mouse.getScreenPosition();
		var isOverAnchor = mousePos.x >= anchorX && mousePos.x <= anchorX + anchorW
			&& mousePos.y >= anchorY && mousePos.y <= anchorY + anchorH;

		if (isOverAnchor)
		{
			if (!_wasHovering)
			{
				_wasHovering = true;
				hoverTimer = 0;
			}
			else
			{
				hoverTimer += elapsed;
				if (!isVisible && hoverTimer >= HOVER_DELAY)
					showTooltip();
			}

			if (isVisible)
			{
				_hideTimer += elapsed;
				if (_hideTimer >= HIDE_DELAY)
					hideTooltip();
			}
		}
		else
		{
			_wasHovering = false;
			hoverTimer = 0;
			if (isVisible) hideTooltip();
		}
		#end
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(_onThemeChange);
		if (showTween != null) showTween.cancel();
		if (hideTween != null) hideTween.cancel();
		super.destroy();
	}
}
