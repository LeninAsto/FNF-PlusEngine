package backend.ui.md3;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

/**
 * Material Design 3 Chip Component
 * Based on: https://m3.material.io/components/chips/guidelines
 *
 * Supports four variants:
 *   ASSIST   — suggests actions (always enabled, not togglable)
 *   FILTER   — togglable, shows checkmark when selected
 *   INPUT    — displays entered info, can show trailing delete icon
 *   SUGGESTION — read-only suggested value, triggers action
 */
class MaterialChip extends FlxSpriteGroup
{
	public var label(default, set):String = "";
	public var enabled:Bool = true;
	public var selected(default, set):Bool = false;
	public var chipType:ChipType = ASSIST;

	public var onTap:Void->Void = null;
	public var onDelete:Void->Void = null; // INPUT chips only

	// Visual components
	var container:FlxSprite;
	var outline:FlxSprite;
	var checkMark:FlxSprite;
	var labelText:FlxText;
	var deleteIcon:FlxSprite;
	var stateLayer:FlxSprite;

	// Dimensions (MD3 specs)
	public var chipWidth:Float = 0; // auto-sized if 0
	static inline var CHIP_HEIGHT:Int = 32;
	static inline var CORNER_RADIUS:Int = 8;
	static inline var PADDING_H:Int = 16;
	static inline var PADDING_H_WITH_CHECK:Int = 8;
	static inline var LABEL_SIZE:Int = 14;
	static inline var CHECK_SIZE:Int = 18;
	static inline var DELETE_SIZE:Int = 18;

	// State
	var isHovered:Bool = false;
	var isPressed:Bool = false;
	var hoverTween:FlxTween;
	var pressTween:FlxTween;

	var _calcWidth:Float = 0;

	public function new(x:Float = 0, y:Float = 0, label:String = "Chip", ?chipType:ChipType = ASSIST, ?selected:Bool = false,
		?onTap:Void->Void = null, ?onDelete:Void->Void = null)
	{
		super(x, y);

		this.chipType = chipType;
		this.onTap = onTap;
		this.onDelete = onDelete;

		// Measure label first to set width
		var tempLabel = new FlxText(0, 0, 0, label, LABEL_SIZE);
		var labelW = tempLabel.width;
		tempLabel.destroy();

		var hasCheck = chipType == FILTER && selected;
		var hasDelete = chipType == INPUT;
		var leftPad = hasCheck ? PADDING_H_WITH_CHECK : PADDING_H;
		var rightPad = hasDelete ? CHECK_SIZE + 4 + PADDING_H_WITH_CHECK : PADDING_H;
		_calcWidth = leftPad + (hasCheck ? CHECK_SIZE + 8 : 0) + labelW + rightPad;

		var w = Std.int(_calcWidth);

		// Container background
		container = new FlxSprite(0, 0);
		container.makeGraphic(w, CHIP_HEIGHT, MD3Theme.surface);
		drawRoundedRect(container, w, CHIP_HEIGHT, CORNER_RADIUS);
		add(container);

		// Outline
		outline = new FlxSprite(0, 0);
		outline.makeGraphic(w, CHIP_HEIGHT, FlxColor.TRANSPARENT, true);
		drawOutline(outline, w, CHIP_HEIGHT, CORNER_RADIUS);
		add(outline);

		// State layer
		stateLayer = new FlxSprite(0, 0);
		stateLayer.makeGraphic(w, CHIP_HEIGHT, FlxColor.TRANSPARENT);
		drawRoundedRect(stateLayer, w, CHIP_HEIGHT, CORNER_RADIUS);
		stateLayer.alpha = 0;
		add(stateLayer);

		// Check/select mark (FILTER only)
		checkMark = new FlxSprite(PADDING_H_WITH_CHECK, (CHIP_HEIGHT - CHECK_SIZE) / 2);
		checkMark.makeGraphic(CHECK_SIZE, CHECK_SIZE, FlxColor.TRANSPARENT, true);
		drawCheckmark(checkMark, CHECK_SIZE);
		checkMark.color = MD3Theme.primary;
		checkMark.visible = false;
		add(checkMark);

		// Label text
		var labelOffsetX:Float = leftPad + (hasCheck ? CHECK_SIZE + 8 : 0);
		labelText = new FlxText(labelOffsetX, 0, labelW + 2, label, LABEL_SIZE);
		labelText.setFormat(Paths.font('NotoSans-Medium.ttf'), LABEL_SIZE, MD3Theme.onSurfaceVariant, LEFT);
		labelText.antialiasing = ClientPrefs.data.antialiasing;
		labelText.y = (CHIP_HEIGHT - labelText.height) / 2;
		add(labelText);

		// Delete icon (INPUT chips)
		if (chipType == INPUT)
		{
			deleteIcon = new FlxSprite(w - PADDING_H_WITH_CHECK - DELETE_SIZE, (CHIP_HEIGHT - DELETE_SIZE) / 2);
			deleteIcon.makeGraphic(DELETE_SIZE, DELETE_SIZE, FlxColor.TRANSPARENT, true);
			drawXIcon(deleteIcon, DELETE_SIZE);
			deleteIcon.color = MD3Theme.primary;
			add(deleteIcon);
		}

		@:bypassAccessor this.label = label;
		this.selected = selected;
		updateAppearance();
		MD3Theme.addListener(updateAppearance);
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

	function drawOutline(sprite:FlxSprite, width:Int, height:Int, radius:Int):Void
	{
		if (sprite == null || sprite.pixels == null) return;
		var graphics = sprite.pixels;
		graphics.fillRect(graphics.rect, FlxColor.TRANSPARENT);
		var col:Int = MD3Theme.outline;

		for (px in radius...(width - radius))
		{
			graphics.setPixel32(px, 0, col);
			graphics.setPixel32(px, height - 1, col);
		}
		for (py in radius...(height - radius))
		{
			graphics.setPixel32(0, py, col);
			graphics.setPixel32(width - 1, py, col);
		}

		var corners = [
			{cx: radius, cy: radius, off: 2},
			{cx: width - radius, cy: radius, off: 3},
			{cx: radius, cy: height - radius, off: 1},
			{cx: width - radius, cy: height - radius, off: 0}
		];
		for (c in corners)
		{
			for (angle in 0...90)
			{
				var rad = angle * Math.PI / 180 + c.off * Math.PI / 2;
				var px = Std.int(c.cx + Math.cos(rad) * (radius - 1));
				var py = Std.int(c.cy + Math.sin(rad) * (radius - 1));
				if (px >= 0 && px < width && py >= 0 && py < height)
					graphics.setPixel32(px, py, col);
			}
		}
	}

	function drawCheckmark(sprite:FlxSprite, size:Int):Void
	{
		var graphics = sprite.pixels;
		graphics.fillRect(graphics.rect, FlxColor.TRANSPARENT);
		var col = 0xFFFFFFFF;
		// Simple tick: two line segments
		var pts = [{x: 2, y: size / 2}, {x: size / 2 - 2, y: size - 4}, {x: size - 2, y: 3}];
		for (i in 0...pts.length - 1)
		{
			var x0 = pts[i].x; var y0 = pts[i].y;
			var x1 = pts[i + 1].x; var y1 = pts[i + 1].y;
			var steps = Std.int(Math.max(Math.abs(x1 - x0), Math.abs(y1 - y0)));
			for (s in 0...steps + 1)
			{
				var t = steps > 0 ? s / steps : 0.0;
				var px = Std.int(x0 + (x1 - x0) * t);
				var py = Std.int(y0 + (y1 - y0) * t);
				if (px >= 0 && px < size && py >= 0 && py < size)
					graphics.setPixel32(px, py, col);
			}
		}
	}

	function drawXIcon(sprite:FlxSprite, size:Int):Void
	{
		var graphics = sprite.pixels;
		graphics.fillRect(graphics.rect, FlxColor.TRANSPARENT);
		var col = 0xFFFFFFFF;
		var margin = 4;

		for (i in 0...(size - margin * 2))
		{
			var t = (size - margin * 2) > 0 ? i / (size - margin * 2 - 1) : 0.0;
			var px1 = Std.int(margin + i);
			var py1 = Std.int(margin + i);
			var px2 = Std.int(size - margin - 1 - i);
			var py2 = Std.int(margin + i);
			if (px1 >= 0 && px1 < size && py1 >= 0 && py1 < size) graphics.setPixel32(px1, py1, col);
			if (px2 >= 0 && px2 < size && py2 >= 0 && py2 < size) graphics.setPixel32(px2, py2, col);
		}
	}

	// -----------------------------------------------------------------------
	// APPEARANCE
	// -----------------------------------------------------------------------

	function updateAppearance():Void
	{
		if (container == null) return;

		if (!enabled)
		{
			container.color = MD3Theme.disabledContainerColor();
			outline.visible = false;
			labelText.color = MD3Theme.disabledContentColor();
			if (deleteIcon != null) deleteIcon.color = MD3Theme.disabledContentColor();
			if (checkMark != null) checkMark.visible = false;
			return;
		}

		if (chipType == FILTER && selected)
		{
			container.color = MD3Theme.secondaryContainer;
			outline.visible = false;
			labelText.color = MD3Theme.onSecondaryContainer;
			if (checkMark != null)
			{
				checkMark.color = MD3Theme.onSecondaryContainer;
				checkMark.visible = true;
			}
		}
		else
		{
			container.color = MD3Theme.surface;
			outline.visible = true;
			drawOutline(outline, Std.int(_calcWidth), CHIP_HEIGHT, CORNER_RADIUS);
			labelText.color = MD3Theme.onSurfaceVariant;
			if (checkMark != null)
			{
				checkMark.color = MD3Theme.primary;
				checkMark.visible = false;
			}
		}

		if (deleteIcon != null)
			deleteIcon.color = selected ? MD3Theme.onSecondaryContainer : MD3Theme.primary;
	}

	// -----------------------------------------------------------------------
	// SETTERS
	// -----------------------------------------------------------------------

	function set_label(v:String):String
	{
		label = v;
		if (labelText != null) labelText.text = v;
		return label;
	}

	function set_selected(v:Bool):Bool
	{
		selected = v;
		updateAppearance();
		return selected;
	}

	// -----------------------------------------------------------------------
	// UPDATE
	// -----------------------------------------------------------------------

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!enabled) return;

		#if FLX_MOUSE
		var mousePos = FlxG.mouse.getScreenPosition();
		var w = _calcWidth;
		var isOver = mousePos.x >= x && mousePos.x <= x + w && mousePos.y >= y && mousePos.y <= y + CHIP_HEIGHT;

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

		if (FlxG.mouse.justReleased && isOver)
		{
			// Check if clicking delete icon (INPUT chip)
			if (chipType == INPUT && deleteIcon != null && onDelete != null)
			{
				var delX = x + deleteIcon.x;
				var delY = y + deleteIcon.y;
				var isOverDel = mousePos.x >= delX && mousePos.x <= delX + DELETE_SIZE && mousePos.y >= delY && mousePos.y <= delY + DELETE_SIZE;
				if (isOverDel)
				{
					onDelete();
					return;
				}
			}

			if (chipType == FILTER)
				selected = !selected;

			if (onTap != null) onTap();
		}
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

enum ChipType
{
	ASSIST;
	FILTER;
	INPUT;
	SUGGESTION;
}
