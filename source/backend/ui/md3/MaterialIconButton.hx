package backend.ui.md3;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

/**
 * Material Design 3 Icon Button Component
 * Based on: https://m3.material.io/components/icon-buttons/guidelines
 *
 * Supports four variants: STANDARD, FILLED, FILLED_TONAL, OUTLINED.
 * Icon is supplied via a FlxSprite — set iconSprite.loadGraphic() after creation.
 */
class MaterialIconButton extends FlxSpriteGroup
{
	public var enabled:Bool = true;
	public var onClick:Void->Void = null;
	public var buttonType:IconButtonType = STANDARD;

	// Visual components
	var container:FlxSprite;
	var outline:FlxSprite;
	var stateLayer:FlxSprite;

	/** Exposed so callers can load their icon graphic here. */
	public var iconSprite:FlxSprite;

	// Dimensions (MD3 specs — 40dp container, 24dp icon)
	static inline var BUTTON_SIZE:Int = 40;
	static inline var ICON_SIZE:Int = 24;
	static inline var CORNER_RADIUS:Int = 20; // fully circular

	// State
	var isHovered:Bool = false;
	var isPressed:Bool = false;
	var hoverTween:FlxTween;
	var pressTween:FlxTween;

	public function new(x:Float = 0, y:Float = 0, ?buttonType:IconButtonType = STANDARD, ?onClick:Void->Void = null)
	{
		super(x, y);

		this.buttonType = buttonType;
		this.onClick = onClick;

		// Container background
		container = new FlxSprite(0, 0);
		container.makeGraphic(BUTTON_SIZE, BUTTON_SIZE, FlxColor.TRANSPARENT);
		drawCircle(container, BUTTON_SIZE);
		add(container);

		// Outline (OUTLINED only)
		outline = new FlxSprite(0, 0);
		outline.makeGraphic(BUTTON_SIZE, BUTTON_SIZE, FlxColor.TRANSPARENT, true);
		if (buttonType == OUTLINED)
			drawCircleOutline(outline, BUTTON_SIZE, MD3Theme.outline);
		outline.visible = (buttonType == OUTLINED);
		add(outline);

		// State layer
		stateLayer = new FlxSprite(0, 0);
		stateLayer.makeGraphic(BUTTON_SIZE, BUTTON_SIZE, FlxColor.TRANSPARENT);
		drawCircle(stateLayer, BUTTON_SIZE);
		stateLayer.alpha = 0;
		add(stateLayer);

		// Icon (centered, caller populates)
		var iconOffset = (BUTTON_SIZE - ICON_SIZE) / 2;
		iconSprite = new FlxSprite(iconOffset, iconOffset);
		iconSprite.makeGraphic(ICON_SIZE, ICON_SIZE, FlxColor.TRANSPARENT);
		add(iconSprite);

		updateAppearance();
		MD3Theme.addListener(updateAppearance);
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

	function drawCircleOutline(sprite:FlxSprite, size:Int, color:FlxColor):Void
	{
		var graphics = sprite.pixels;
		graphics.fillRect(graphics.rect, FlxColor.TRANSPARENT);
		var outerR = size / 2 - 1;
		var innerR = outerR - 1;
		var center = size / 2;

		for (py in 0...size)
		{
			for (px in 0...size)
			{
				var dx = px - center;
				var dy = py - center;
				var dist = Math.sqrt(dx * dx + dy * dy);
				if (dist <= outerR && dist >= innerR)
					graphics.setPixel32(px, py, color);
			}
		}
	}

	function updateAppearance():Void
	{
		if (container == null) return;

		if (!enabled)
		{
			container.color = MD3Theme.disabledContainerColor();
			container.alpha = 0.12;
			container.visible = buttonType != STANDARD && buttonType != OUTLINED;
			outline.visible = false;
			iconSprite.color = MD3Theme.disabledContentColor();
			iconSprite.alpha = 0.38;
			return;
		}

		container.alpha = 1;
		iconSprite.alpha = 1;

		switch (buttonType)
		{
			case STANDARD:
				container.visible = false;
				outline.visible = false;
				iconSprite.color = MD3Theme.primary;
				stateLayer.color = MD3Theme.stateLayerColor(MD3Theme.primary);
			case FILLED:
				container.visible = true;
				container.color = MD3Theme.primary;
				outline.visible = false;
				iconSprite.color = MD3Theme.onPrimary;
				stateLayer.color = MD3Theme.stateLayerColor(MD3Theme.onPrimary);
			case FILLED_TONAL:
				container.visible = true;
				container.color = MD3Theme.secondaryContainer;
				outline.visible = false;
				iconSprite.color = MD3Theme.onSecondaryContainer;
				stateLayer.color = MD3Theme.stateLayerColor(MD3Theme.onSecondaryContainer);
			case OUTLINED:
				container.visible = false;
				outline.visible = true;
				drawCircleOutline(outline, BUTTON_SIZE, MD3Theme.outline);
				iconSprite.color = MD3Theme.primary;
				stateLayer.color = MD3Theme.stateLayerColor(MD3Theme.primary);
		}
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!enabled) return;

		#if FLX_MOUSE
		var mousePos = FlxG.mouse.getScreenPosition();
		var cx = x + BUTTON_SIZE / 2;
		var cy = y + BUTTON_SIZE / 2;
		var dx = mousePos.x - cx;
		var dy = mousePos.y - cy;
		var isOver = (dx * dx + dy * dy) <= (BUTTON_SIZE / 2) * (BUTTON_SIZE / 2);

		if (isOver && !isHovered)
		{
			isHovered = true;
			if (hoverTween != null) hoverTween.cancel();
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
			stateLayer.color = MD3Theme.stateLayerColor(
				buttonType == FILLED ? MD3Theme.onPrimary : (buttonType == FILLED_TONAL ? MD3Theme.onSecondaryContainer : MD3Theme.primary),
				true
			);
			pressTween = FlxTween.num(stateLayer.alpha, 1, 0.1, {ease: FlxEase.cubeOut}, function(v) { stateLayer.alpha = v; });
		}
		else if (!FlxG.mouse.pressed && isPressed)
		{
			isPressed = false;
			if (pressTween != null) pressTween.cancel();
				stateLayer.color = isHovered ? MD3Theme.stateLayerColor(
					buttonType == FILLED ? MD3Theme.onPrimary : (buttonType == FILLED_TONAL ? MD3Theme.onSecondaryContainer : MD3Theme.primary)
				) : FlxColor.TRANSPARENT;
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

enum IconButtonType
{
	STANDARD;
	FILLED;
	FILLED_TONAL;
	OUTLINED;
}
