package backend.ui.md3;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import openfl.display.Shape;

/**
 * Material Design 3 Checkbox Component
 * Based on: https://m3.material.io/components/checkbox/specs
 */
class MaterialCheckbox extends FlxSpriteGroup
{
	public var checked(default, set):Bool = false;
	public var enabled:Bool = true;
	public var label:String = "";
	public var onChange:Bool->Void = null;

	// Visual components
	var container:FlxSprite;
	var checkIcon:FlxSprite;
	var stateLayer:FlxSprite;
	var labelText:FlxText;

	// State layers

	// State
	var isHovered:Bool = false;
	var isPressed:Bool = false;

	// Animation tweens
	var checkTween:FlxTween;
	var hoverTween:FlxTween;
	var pressTween:FlxTween;

	inline function containerSize():Int return MD3Metrics.size(20);
	inline function checkboxRadius():Int return MD3Metrics.corner(4, containerSize(), containerSize());
	inline function stateLayerSize():Int return MD3Metrics.touch(containerSize());
	inline function iconSize():Int return MD3Metrics.size(18);
	inline function labelSpacing():Int return MD3Metrics.size(10);
	inline function labelSize():Int return MD3Metrics.text(15);

	public function new(x:Float = 0, y:Float = 0, ?label:String = "", ?checked:Bool = false, ?onChange:Bool->Void = null)
	{
		super(x, y);

		this.label = label;
		this.onChange = onChange;

		var stateSize = stateLayerSize();
		var visualSize = containerSize();
		var layerOffset = (stateSize - visualSize) / 2;
		var iconOffset = (visualSize - iconSize()) / 2;

		// Create state layer (for hover/press effects)
		stateLayer = new FlxSprite(-layerOffset, -layerOffset);
		stateLayer.antialiasing = ClientPrefs.data.antialiasing;
		MD3ShapeTools.fillCircle(stateLayer, stateSize);
		stateLayer.alpha = 0;
		add(stateLayer);

		// Create container
		container = new FlxSprite(0, 0);
		container.antialiasing = ClientPrefs.data.antialiasing;
		add(container);

		// Create check icon
		checkIcon = new FlxSprite(iconOffset, iconOffset);
		checkIcon.antialiasing = ClientPrefs.data.antialiasing;
		checkIcon.alpha = 0;
		add(checkIcon);

		// Create label text if provided
		if (label.length > 0)
		{
			labelText = new FlxText(visualSize + labelSpacing(), 0, 0, label, labelSize());
			labelText.setFormat(Paths.font('NotoSans-Medium.ttf'), labelSize(), MD3Theme.onSurfaceVariant, LEFT);
			labelText.antialiasing = ClientPrefs.data.antialiasing;
			labelText.y = (visualSize - labelText.height) / 2;
			add(labelText);
		}

		redrawCheckbox();
		this.checked = checked;

		updateAppearance();
		MD3Theme.addListener(updateAppearance);
	}

	function redrawCheckbox():Void
	{
		var size = containerSize();
		var radius = checkboxRadius();
		MD3ShapeTools.fillRoundRect(container, size, size, radius);
		drawCheckmark(checkIcon);
	}

	function drawCheckmark(sprite:FlxSprite):Void
	{
		var size = iconSize();
		sprite.makeGraphic(size, size, FlxColor.TRANSPARENT, true);
		var shape = new Shape();
		var stroke = Math.max(2.0, size / 7.0);
		shape.graphics.lineStyle(stroke, 0xFFFFFFFF, 1);
		shape.graphics.moveTo(size * 0.20, size * 0.55);
		shape.graphics.lineTo(size * 0.43, size * 0.78);
		shape.graphics.lineTo(size * 0.82, size * 0.22);
		sprite.pixels.draw(shape, null, null, null, null, true);
		sprite.dirty = true;
	}

	function updateAppearance():Void
	{
		if (container == null || checkIcon == null)
		{
			return;
		}

		redrawCheckbox();
		stateLayer.color = MD3Theme.stateLayerColor(MD3Theme.primary);

		if (!enabled)
		{
			if (checked)
			{
				MD3ShapeTools.fillRoundRect(container, containerSize(), containerSize(), checkboxRadius());
				container.color = MD3Theme.primary;
			}
			else
			{
				MD3ShapeTools.strokeRoundRect(container, containerSize(), containerSize(), checkboxRadius(), 2, MD3Theme.disabledContentColor());
				container.color = MD3Theme.surface;
			}
			container.alpha = 0.38;
			checkIcon.color = MD3Theme.disabledContentColor();
			checkIcon.alpha = checked ? 1 : 0;
			if (labelText != null)
				labelText.color = MD3Theme.disabledContentColor();
		}
		else
		{
			if (checked)
			{
				MD3ShapeTools.fillRoundRect(container, containerSize(), containerSize(), checkboxRadius());
				container.color = MD3Theme.primary;
				container.alpha = 1;
				checkIcon.color = MD3Theme.onPrimary;
				checkIcon.alpha = 1;
			}
			else
			{
				MD3ShapeTools.strokeRoundRect(container, containerSize(), containerSize(), checkboxRadius(), 2, MD3Theme.outline);
				container.color = FlxColor.TRANSPARENT;
				container.alpha = 1;
				checkIcon.color = MD3Theme.onPrimary;
				checkIcon.alpha = 0;
			}

			if (labelText != null)
				labelText.color = MD3Theme.onSurfaceVariant;
		}
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!enabled) return;

		#if FLX_MOUSE
		var offset = (stateLayerSize() - containerSize()) / 2;
		var checkboxWidth = labelText != null ? (containerSize() + labelSpacing() + labelText.width) : containerSize();
		var mousePos = FlxG.mouse.getScreenPosition();
		var isOver = mousePos.x >= x - offset && mousePos.x <= x + checkboxWidth + offset &&
			mousePos.y >= y - offset && mousePos.y <= y + containerSize() + offset;

		// Hover effect
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
		
		// Press effect
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
			var targetAlpha = isHovered ? 1.0 : 0.0;
			pressTween = FlxTween.num(stateLayer.alpha, targetAlpha, 0.1, {ease: FlxEase.cubeOut}, function(v) { stateLayer.alpha = v; });
		}

		// Click event
		if (FlxG.mouse.justReleased && isOver)
		{
			checked = !checked;
		}
		#end
	}

	function set_checked(value:Bool):Bool
	{
		var oldValue = checked;
		checked = value;

		if (checkIcon == null)
		{
			return checked;
		}

		if (checkTween != null) checkTween.cancel();

		var targetAlpha = checked ? 1.0 : 0.0;
		checkTween = FlxTween.num(checkIcon.alpha, targetAlpha, 0.15, {ease: FlxEase.cubeOut}, function(v) {
			if (checkIcon != null) checkIcon.alpha = v;
		});
		checkTween.onComplete = function(_) { updateAppearance(); };

		updateAppearance();

		if (oldValue != checked && onChange != null)
			onChange(checked);

		return checked;
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(updateAppearance);
		if (checkTween != null) checkTween.cancel();
		if (hoverTween != null) hoverTween.cancel();
		if (pressTween != null) pressTween.cancel();

		super.destroy();
	}
}
