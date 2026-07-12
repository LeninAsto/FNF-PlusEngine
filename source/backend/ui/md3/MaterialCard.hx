package backend.ui.md3;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

/**
 * Material Design 3 Card Component
 * Based on: https://m3.material.io/components/cards/guidelines
 *
 * Supports three variants: Elevated, Filled, Outlined.
 * Acts as a container — add children with addContent().
 */
class MaterialCard extends FlxSpriteGroup
{
	public var enabled:Bool = true;
	public var onClick:Void->Void = null;
	public var cardType:CardType = ELEVATED;

	// Visual components
	var background:FlxSprite;
	var shadow:FlxSprite;
	var outline:FlxSprite;
	var stateLayer:FlxSprite;

	// Content group (children go here)
	public var content:FlxSpriteGroup;

	// Dimensions (MD3 specs)
	public var cardWidth:Float = 280;
	public var cardHeight:Float = 140;
	static inline var CORNER_RADIUS:Int = 12;
	static inline var OUTLINE_WIDTH:Int = 1;

	// State
	var isHovered:Bool = false;
	var isPressed:Bool = false;
	var hoverTween:FlxTween;
	var pressTween:FlxTween;

	public function new(x:Float = 0, y:Float = 0, ?cardType:CardType = ELEVATED, ?width:Float = 280, ?height:Float = 140, ?onClick:Void->Void = null)
	{
		super(x, y);

		this.cardType = cardType;
		this.cardWidth = width;
		this.cardHeight = height;
		this.onClick = onClick;

		var w = Std.int(cardWidth);
		var h = Std.int(cardHeight);

		// Shadow (only for elevated)
		shadow = new FlxSprite(3, 5);
		shadow.makeGraphic(w, h, FlxColor.TRANSPARENT, true);
		drawRoundedRect(shadow, w, h, CORNER_RADIUS);
		shadow.color = MD3Theme.shadowColor();
		shadow.visible = cardType == ELEVATED;
		add(shadow);

		// Background
		background = new FlxSprite(0, 0);
		background.makeGraphic(w, h, MD3Theme.surfaceContainerLow);
		drawRoundedRect(background, w, h, CORNER_RADIUS);
		add(background);

		// Outline (only for outlined)
		outline = new FlxSprite(0, 0);
		outline.makeGraphic(w, h, FlxColor.TRANSPARENT, true);
		if (cardType == OUTLINED)
			drawOutline(outline, w, h, CORNER_RADIUS);
		outline.visible = cardType == OUTLINED;
		add(outline);

		// State layer (hover / press) — unique bitmap so coloring doesn't bleed
		stateLayer = new FlxSprite(0, 0);
		stateLayer.makeGraphic(w, h, FlxColor.TRANSPARENT, true);
		drawRoundedRect(stateLayer, w, h, CORNER_RADIUS);
		stateLayer.alpha = 0;
		add(stateLayer);

		// Content group — positioned relative to this group's origin
		content = new FlxSpriteGroup(0, 0);
		add(content);

		updateAppearance();
		MD3Theme.addListener(updateAppearance);
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

	function drawOutline(sprite:FlxSprite, width:Int, height:Int, radius:Int):Void
	{
		if (sprite == null || sprite.pixels == null) return;
		var graphics = sprite.pixels;
		graphics.fillRect(graphics.rect, FlxColor.TRANSPARENT);
		var col:Int = MD3Theme.outlineVariant;

		for (i in 0...OUTLINE_WIDTH)
		{
			for (px in radius...(width - radius))
			{
				graphics.setPixel32(px, i, col);
				graphics.setPixel32(px, height - 1 - i, col);
			}
			for (py in radius...(height - radius))
			{
				graphics.setPixel32(i, py, col);
				graphics.setPixel32(width - 1 - i, py, col);
			}
		}

		// Approximate corner outlines
		for (angle in 0...90)
		{
			var cornerConfigs = [
				{cx: radius, cy: radius, offset: 2},
				{cx: width - radius, cy: radius, offset: 3},
				{cx: radius, cy: height - radius, offset: 1},
				{cx: width - radius, cy: height - radius, offset: 0}
			];
			for (cfg in cornerConfigs)
			{
				var rad = angle * Math.PI / 180 + cfg.offset * Math.PI / 2;
				for (r in (radius - OUTLINE_WIDTH)...radius)
				{
					var px = Std.int(cfg.cx + Math.cos(rad) * r);
					var py = Std.int(cfg.cy + Math.sin(rad) * r);
					if (px >= 0 && px < width && py >= 0 && py < height)
						graphics.setPixel32(px, py, col);
				}
			}
		}
	}

	function updateAppearance():Void
	{
		switch (cardType)
		{
			case ELEVATED:
				background.color = MD3Theme.surfaceContainerLow;
				shadow.color = MD3Theme.shadowColor();
				shadow.visible = true;
				outline.visible = false;
			case FILLED:
				background.color = MD3Theme.surfaceContainerHighest;
				shadow.visible = false;
				outline.visible = false;
			case OUTLINED:
				background.color = MD3Theme.surface;
				shadow.visible = false;
				outline.visible = true;
		}
	}

	/** Add a sprite as card content */
	public function addContent(child:FlxSprite):Void
	{
		content.add(child);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!enabled || onClick == null) return;

		#if FLX_MOUSE
		var mousePos = FlxG.mouse.getScreenPosition();
		var isOver = mousePos.x >= x && mousePos.x <= x + cardWidth && mousePos.y >= y && mousePos.y <= y + cardHeight;

		if (isOver && !isHovered)
		{
			isHovered = true;
			if (hoverTween != null) hoverTween.cancel();
			stateLayer.color = MD3Theme.stateLayerColor(MD3Theme.primary);
			hoverTween = FlxTween.num(stateLayer.alpha, 1, 0.15, {ease: FlxEase.cubeOut}, function(v) { stateLayer.alpha = v; });
		}
		else if (!isOver && isHovered)
		{
			isHovered = false;
			if (hoverTween != null) hoverTween.cancel();
			hoverTween = FlxTween.num(stateLayer.alpha, 0, 0.15, {ease: FlxEase.cubeOut}, function(v) { stateLayer.alpha = v; });
		}

		if (FlxG.mouse.pressed && isOver && !isPressed)
		{
			isPressed = true;
			if (pressTween != null) pressTween.cancel();
			stateLayer.color = MD3Theme.stateLayerColor(MD3Theme.primary, true);
			pressTween = FlxTween.num(stateLayer.alpha, 1, 0.1, {ease: FlxEase.cubeOut}, function(v) { stateLayer.alpha = v; });
		}
		else if (!FlxG.mouse.pressed && isPressed)
		{
			isPressed = false;
			if (pressTween != null) pressTween.cancel();
				stateLayer.color = isHovered ? MD3Theme.stateLayerColor(MD3Theme.primary) : FlxColor.TRANSPARENT;
			pressTween = FlxTween.num(stateLayer.alpha, isHovered ? 1.0 : 0.0, 0.1, {ease: FlxEase.cubeOut}, function(v) { stateLayer.alpha = v; });
		}

		if (FlxG.mouse.justReleased && isOver && onClick != null)
			onClick();
		#end
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(updateAppearance);
		if (hoverTween != null) hoverTween.cancel();
		if (pressTween != null) pressTween.cancel();
		super.destroy();
	}
}

enum CardType
{
	ELEVATED;
	FILLED;
	OUTLINED;
}
