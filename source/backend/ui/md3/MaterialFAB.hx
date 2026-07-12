package backend.ui.md3;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

/**
 * Material Design 3 Floating Action Button
 * Based on: https://m3.material.io/components/floating-action-button/guidelines
 *            https://m3.material.io/components/extended-fab/guidelines
 *
 * Supports three size variants: SMALL (40dp), REGULAR (56dp), LARGE (96dp).
 * Supports Extended variant by passing a non-empty label (Extended FAB).
 *
 * Icon is loaded via `iconSprite.loadGraphic()` after creation.
 */
class MaterialFAB extends FlxSpriteGroup
{
	public var enabled:Bool = true;
	public var onClick:Void->Void = null;
	public var fabSize:FABSize = REGULAR;

	// Visual components
	var container:FlxSprite;
	var shadow:FlxSprite;
	var stateLayer:FlxSprite;
	public var iconSprite:FlxSprite;
	var labelText:FlxText; // Extended FAB only

	// Dimensions (MD3)
	static var SIZE_MAP:Map<String, Int> = ["SMALL" => 40, "REGULAR" => 56, "LARGE" => 96];
	static var ICON_MAP:Map<String, Int> = ["SMALL" => 24, "REGULAR" => 24, "LARGE" => 36];
	static var CORNER_MAP:Map<String, Int> = ["SMALL" => 12, "REGULAR" => 16, "LARGE" => 28];
	static inline var EXTENDED_HEIGHT:Int = 56;
	static inline var EXTENDED_CORNER:Int = 16;
	static inline var EXTENDED_PADDING_H:Int = 16;
	static inline var LABEL_SIZE:Int = 14;

	// Extended FAB
	var isExtended:Bool = false;
	var _label:String = "";
	var _containerWidth:Float = 0;

	// State interaction
	var isHovered:Bool = false;
	var isPressed:Bool = false;
	var hoverTween:FlxTween;
	var pressTween:FlxTween;

	public function new(x:Float = 0, y:Float = 0, ?fabSize:FABSize = REGULAR, ?label:String = "", ?onClick:Void->Void = null)
	{
		super(x, y);

		this.fabSize = fabSize;
		this._label = label;
		this.onClick = onClick;
		this.isExtended = label != null && label.length > 0;

		var sizeKey = Std.string(fabSize);
		var containerSize = SIZE_MAP.exists(sizeKey) ? SIZE_MAP.get(sizeKey) : 56;
		var iconSize = ICON_MAP.exists(sizeKey) ? ICON_MAP.get(sizeKey) : 24;
		var cornerRadius = CORNER_MAP.exists(sizeKey) ? CORNER_MAP.get(sizeKey) : 16;

		var containerW:Int;
		var containerH:Int;

		if (isExtended)
		{
			// Extended FAB: measure label and build a pill-shaped container
			var tempLabel = new FlxText(0, 0, 0, label, LABEL_SIZE);
			var labelW = Std.int(tempLabel.width);
			tempLabel.destroy();
			containerW = EXTENDED_PADDING_H + iconSize + 8 + labelW + EXTENDED_PADDING_H;
			containerH = EXTENDED_HEIGHT;
			cornerRadius = EXTENDED_CORNER;
		}
		else
		{
			containerW = containerSize;
			containerH = containerSize;
		}

		_containerWidth = containerW;

		// Shadow (elevation simulation)
		shadow = new FlxSprite(3, 5);
		shadow.makeGraphic(containerW, containerH, FlxColor.TRANSPARENT, true);
		drawRoundedRect(shadow, containerW, containerH, cornerRadius);
		shadow.color = MD3Theme.shadowColor();
		add(shadow);

		// Container
		container = new FlxSprite(0, 0);
		container.makeGraphic(containerW, containerH, MD3Theme.tertiaryContainer);
		drawRoundedRect(container, containerW, containerH, cornerRadius);
		container.color = MD3Theme.tertiaryContainer;
		add(container);

		// State layer
		stateLayer = new FlxSprite(0, 0);
		stateLayer.makeGraphic(containerW, containerH, FlxColor.TRANSPARENT);
		drawRoundedRect(stateLayer, containerW, containerH, cornerRadius);
		stateLayer.alpha = 0;
		add(stateLayer);

		// Icon
		var iconOffsetX:Float = isExtended ? EXTENDED_PADDING_H : (containerW - iconSize) / 2;
		var iconOffsetY:Float = (containerH - iconSize) / 2;
		iconSprite = new FlxSprite(iconOffsetX, iconOffsetY);
		iconSprite.makeGraphic(iconSize, iconSize, FlxColor.TRANSPARENT);
		iconSprite.color = MD3Theme.onTertiaryContainer;
		add(iconSprite);

		// Label (Extended FAB only)
		if (isExtended)
		{
			labelText = new FlxText(EXTENDED_PADDING_H + iconSize + 8, 0, 0, label, LABEL_SIZE);
			labelText.setFormat(Paths.font("inter.otf"), LABEL_SIZE, MD3Theme.onTertiaryContainer, LEFT);
			labelText.antialiasing = ClientPrefs.data.antialiasing;
			labelText.y = (containerH - labelText.height) / 2;
			add(labelText);
		}
		MD3Theme.addListener(_onThemeChange);
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

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!enabled) return;

		#if FLX_MOUSE
		var sizeKey = Std.string(fabSize);
		var containerH = isExtended ? EXTENDED_HEIGHT : (SIZE_MAP.exists(sizeKey) ? SIZE_MAP.get(sizeKey) : 56);
		var mousePos = FlxG.mouse.getScreenPosition();
		var isOver = mousePos.x >= x && mousePos.x <= x + _containerWidth && mousePos.y >= y && mousePos.y <= y + containerH;

		if (isOver && !isHovered)
		{
			isHovered = true;
			if (hoverTween != null) hoverTween.cancel();
			stateLayer.color = MD3Theme.stateLayerColor(MD3Theme.onTertiaryContainer);
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
			stateLayer.color = MD3Theme.stateLayerColor(MD3Theme.onTertiaryContainer, true);
			pressTween = FlxTween.num(stateLayer.alpha, 1, 0.1, {ease: FlxEase.cubeOut}, function(v) { stateLayer.alpha = v; });
		}
		else if (!FlxG.mouse.pressed && isPressed)
		{
			isPressed = false;
			if (pressTween != null) pressTween.cancel();
				stateLayer.color = isHovered ? MD3Theme.stateLayerColor(MD3Theme.onTertiaryContainer) : FlxColor.TRANSPARENT;
			pressTween = FlxTween.num(stateLayer.alpha, isHovered ? 1.0 : 0.0, 0.1, {ease: FlxEase.cubeOut}, function(v) { stateLayer.alpha = v; });
		}

		if (FlxG.mouse.justReleased && isOver && onClick != null)
			onClick();
		#end
	}

	function _onThemeChange():Void
	{
		if (shadow != null) shadow.color = MD3Theme.shadowColor();
		if (container != null) container.color = MD3Theme.tertiaryContainer;
		if (iconSprite != null) iconSprite.color = MD3Theme.onTertiaryContainer;
		if (labelText != null) labelText.color = MD3Theme.onTertiaryContainer;
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(_onThemeChange);
		if (hoverTween != null) hoverTween.cancel();
		if (pressTween != null) pressTween.cancel();
		super.destroy();
	}
}

enum FABSize
{
	SMALL;
	REGULAR;
	LARGE;
}
