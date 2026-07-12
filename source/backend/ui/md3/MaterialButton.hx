package backend.ui.md3;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

/**
 * Material Design 3 Button Component
 * Based on: https://m3.material.io/components/buttons/specs
 *
 * Supports three variants: Filled, Outlined, and Text
 */
class MaterialButton extends FlxSpriteGroup
{
	public var label(default, set):String = "";
	public var enabled:Bool = true;
	public var allowMouseInput:Bool = true;
	public var keyboardFocused(default, set):Bool = false;
	public var onClick:Void->Void = null;

	public var buttonType:ButtonType = FILLED;

	// Visual components
	var container:FlxSprite;
	var outline:FlxSprite;
	var stateLayer:FlxSprite;
	var labelText:FlxText;

	// Dimensions
	public var buttonWidth:Float = 120;
	static inline var OUTLINE_WIDTH:Int = 1;

	// State
	var isHovered:Bool = false;
	var isPressed:Bool = false;

	// Animation tweens
	var hoverTween:FlxTween;
	var pressTween:FlxTween;

	inline function stateLayerBaseColor():FlxColor
		return buttonType == FILLED ? MD3Theme.onPrimary : MD3Theme.primary;

	inline function stateLayerTargetAlpha(?pressed:Bool = false):Float
		return pressed ? 0.12 : 0.08;

	inline function buttonHeight():Int return MD3Metrics.size(44);
	inline function labelSize():Int return MD3Metrics.text(15);
	inline function cornerRadius():Int return MD3Metrics.corner(16, buttonWidth, buttonHeight());
	inline function minHitHeight():Int return MD3Metrics.touch(buttonHeight());

	public function new(x:Float = 0, y:Float = 0, label:String = "Button", ?buttonType:ButtonType = FILLED, ?width:Float = 120, ?onClick:Void->Void = null)
	{
		super(x, y);

		this.label = label;
		this.buttonType = buttonType;
		this.buttonWidth = width;
		this.onClick = onClick;

		var height = buttonHeight();

		// Create container background
		container = new FlxSprite(0, 0);
		container.antialiasing = ClientPrefs.data.antialiasing;
		add(container);

		// Create state layer (for hover/press effects)
		stateLayer = new FlxSprite(0, 0);
		stateLayer.antialiasing = ClientPrefs.data.antialiasing;
		stateLayer.alpha = 0;
		add(stateLayer);

		// Create outline (for outlined variant)
		outline = new FlxSprite(0, 0);
		outline.antialiasing = ClientPrefs.data.antialiasing;
		add(outline);

		// Create label text
		labelText = new FlxText(0, 0, buttonWidth, this.label, labelSize());
		labelText.setFormat(Paths.font('NotoSans-Medium.ttf'), labelSize(), MD3Theme.onPrimary, CENTER);
		labelText.antialiasing = ClientPrefs.data.antialiasing;
		labelText.y = (height - labelText.height) / 2;
		add(labelText);

		redrawGeometry();
		updateAppearance();
		MD3Theme.addListener(updateAppearance);
	}

	function redrawGeometry():Void
	{
		var width = Std.int(buttonWidth);
		var height = buttonHeight();
		var radius = cornerRadius();
		MD3ShapeTools.fillRoundRect(container, width, height, radius);
		MD3ShapeTools.fillRoundRect(stateLayer, width, height, radius);
		MD3ShapeTools.strokeRoundRect(outline, width, height, radius, OUTLINE_WIDTH);
	}

	function updateAppearance():Void
	{
		if (container == null || labelText == null || outline == null || stateLayer == null)
		{
			return;
		}

		outline.color = enabled ? MD3Theme.outline : MD3Theme.disabledContentColor();

		if (!enabled)
		{
			switch (buttonType)
			{
				case FILLED:
					container.visible = true;
					container.color = MD3Theme.disabledContainerColor();
					container.alpha = 1;
					outline.visible = false;
					stateLayer.visible = true;
					labelText.color = MD3Theme.disabledContentColor();
				case OUTLINED:
					container.visible = false;
					outline.visible = true;
					stateLayer.visible = true;
					labelText.color = MD3Theme.disabledContentColor();
				case TEXT:
					container.visible = false;
					outline.visible = false;
					stateLayer.visible = true;
					labelText.color = MD3Theme.disabledContentColor();
			}
		}
		else
		{
			stateLayer.color = stateLayerBaseColor();
			switch (buttonType)
			{
				case FILLED:
					container.visible = true;
					container.color = MD3Theme.primary;
					container.alpha = 1;
					outline.visible = false;
					stateLayer.visible = true;
					labelText.color = MD3Theme.onPrimary;
				case OUTLINED:
					container.visible = false;
					outline.visible = true;
					stateLayer.visible = true;
					labelText.color = MD3Theme.primary;
				case TEXT:
					container.visible = false;
					outline.visible = false;
					stateLayer.visible = true;
					labelText.color = MD3Theme.primary;
			}
		}

		if (!isHovered && !isPressed)
			stateLayer.alpha = keyboardFocused && enabled ? stateLayerTargetAlpha(false) : 0;
	}

	public function refreshTheme():Void
	{
		updateAppearance();
	}

	function set_keyboardFocused(value:Bool):Bool
	{
		keyboardFocused = value;
		if (stateLayer != null && enabled && !isHovered && !isPressed)
		{
			stateLayer.color = stateLayerBaseColor();
			stateLayer.alpha = keyboardFocused ? stateLayerTargetAlpha(false) : 0;
		}
		return keyboardFocused;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!enabled) return;
		if (!allowMouseInput)
		{
			isHovered = false;
			isPressed = false;
			stateLayer.color = stateLayerBaseColor();
			stateLayer.alpha = keyboardFocused ? stateLayerTargetAlpha(false) : 0;
			return;
		}

		#if FLX_MOUSE
		var mousePos = FlxG.mouse.getScreenPosition();
		var hitPadX = MD3Metrics.size(4);
		var hitPadY = Std.int(Math.max(0, (minHitHeight() - buttonHeight()) / 2));
		var isOver = mousePos.x >= x - hitPadX && mousePos.x <= x + buttonWidth + hitPadX &&
			mousePos.y >= y - hitPadY && mousePos.y <= y + buttonHeight() + hitPadY;

		// Hover effect
		if (isOver && !isHovered)
		{
			isHovered = true;
			if (hoverTween != null) hoverTween.cancel();
			stateLayer.color = stateLayerBaseColor();
			hoverTween = FlxTween.num(stateLayer.alpha, stateLayerTargetAlpha(false), 0.15, {ease: FlxEase.cubeOut}, function(v) { stateLayer.alpha = v; });
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
			stateLayer.color = stateLayerBaseColor();
			pressTween = FlxTween.num(stateLayer.alpha, stateLayerTargetAlpha(true), 0.1, {ease: FlxEase.cubeOut}, function(v) { stateLayer.alpha = v; });
		}
		else if (!FlxG.mouse.pressed && isPressed)
		{
			isPressed = false;
			if (pressTween != null) pressTween.cancel();
			stateLayer.color = stateLayerBaseColor();
			var targetAlpha = isHovered ? stateLayerTargetAlpha(false) : 0.0;
			pressTween = FlxTween.num(stateLayer.alpha, targetAlpha, 0.1, {ease: FlxEase.cubeOut}, function(v) { stateLayer.alpha = v; });
		}

		// Click event
		if (FlxG.mouse.justReleased && isOver && onClick != null)
		{
			onClick();
		}
		#end
	}

	function set_label(value:String):String
	{
		label = value;
		if (labelText != null)
		{
			// Keep label anchored to button group offset when text changes.
			labelText.x = x;
			labelText.fieldWidth = buttonWidth;
			labelText.alignment = CENTER;
			labelText.wordWrap = false;
			labelText.text = value;
			labelText.y = y + (buttonHeight() - labelText.height) / 2;
		}
		return label;
	}

	public function getDebugLayout():String
	{
		return 'group=(' + x + ', ' + y + ') width=' + buttonWidth
			+ ' labelTextLocal=(' + (labelText.x - x) + ', ' + (labelText.y - y) + ', ' + labelText.width + 'x' + labelText.height + ')'
			+ ' label="' + label + '"';
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(updateAppearance);
		if (hoverTween != null) hoverTween.cancel();
		if (pressTween != null) pressTween.cancel();

		super.destroy();
	}
}

enum ButtonType
{
	FILLED;
	OUTLINED;
	TEXT;
}
