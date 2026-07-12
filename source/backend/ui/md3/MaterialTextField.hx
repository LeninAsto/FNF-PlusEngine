package backend.ui.md3;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.input.keyboard.FlxKey;
import flash.events.KeyboardEvent;
import backend.ui.md3.MD3Theme;

/**
 * Material Design 3 Outlined Text Field Component
 * Based on: https://m3.material.io/components/text-fields/guidelines
 */
class MaterialTextField extends FlxSpriteGroup
{
	public var text(default, set):String = "";
	public var passwordMask(default, set):Bool = false;
	public var label:String = "Label";
	public var helperText:String = "";
	public var errorText:String = "";
	public var hasError(default, set):Bool = false;
	public var enabled:Bool = true;
	public var maxLength:Int = 0; // 0 = unlimited
	
	public var onChange:String->Void = null;
	public var onFocus:Void->Void = null;
	public var onBlur:Void->Void = null;

	/** True while this field has keyboard focus. Check this to gate navigation input. */
	public var focused(get, never):Bool;
	inline function get_focused():Bool return isFocused;
	
	// Visual components
	var container:FlxSprite;
	var outline:FlxSprite;
	var labelText:FlxText;
	var inputText:FlxText;
	var supportingText:FlxText;
	var cursor:FlxSprite;
	
	// Dimensions
	public var fieldWidth:Float = 280;
	static inline var FIELD_HEIGHT:Int = 56;
	static inline var OUTLINE_WIDTH:Int = 1;
	static inline var OUTLINE_WIDTH_FOCUSED:Int = 2;
	static inline var PADDING_HORIZONTAL:Int = 16;
	static inline var PADDING_TOP:Int = 8;
	static inline var LABEL_Y_NORMAL:Int = 20; // Label position when unfocused
	static inline var LABEL_Y_FLOATING:Int = 8; // Label position when floating
	static inline var LABEL_SCALE_SMALL:Float = 0.75;
	
	// State
	var isFocused:Bool = false;
	var isHovered:Bool = false;
	var cursorVisible:Bool = false;
	var cursorTimer:Float = 0;
	var labelFloating:Bool = false;
	var labelYPos:Float = 0; // Track label Y position for animation
	
	// Tweens
	var labelTween:FlxTween;
	var labelScaleTween:FlxTween;
	var outlineTween:FlxTween;
	
	public function new(x:Float = 0, y:Float = 0, width:Float = 280, ?label:String = "Label")
	{
		super(x, y);
		
		this.fieldWidth = width;
		this.label = label;
		
		// Create outline container (relative position)
		outline = new FlxSprite(0, 0);
		outline.makeGraphic(Std.int(fieldWidth), FIELD_HEIGHT, FlxColor.TRANSPARENT, true);
		drawOutline(outline, Std.int(fieldWidth), FIELD_HEIGHT, OUTLINE_WIDTH, false);
		add(outline);
		
		// Create label text (relative to group)
		labelYPos = LABEL_Y_NORMAL;
		labelText = new FlxText(PADDING_HORIZONTAL, 0, fieldWidth - PADDING_HORIZONTAL * 2, this.label, 16);
		labelText.setFormat(Paths.font('NotoSans-Medium.ttf'), 16, MD3Theme.onSurfaceVariant, LEFT);
		labelText.antialiasing = ClientPrefs.data.antialiasing;
		labelText.offset.y = -labelYPos; // Use negative offset to position downward
		add(labelText);
		
		// Create input text (relative to group)
		inputText = new FlxText(PADDING_HORIZONTAL, 28, fieldWidth - PADDING_HORIZONTAL * 2, "", 16);
		inputText.setFormat(Paths.font('NotoSans-Medium.ttf'), 16, MD3Theme.onSurface, LEFT);
		inputText.antialiasing = ClientPrefs.data.antialiasing;
		inputText.alpha = 0;
		add(inputText);
		
		// Create cursor (relative to group)
		cursor = new FlxSprite(0, 28);
		cursor.makeGraphic(2, 20, MD3Theme.primary);
		cursor.alpha = 0;
		cursor.offset.x = -PADDING_HORIZONTAL;
		add(cursor);
		
		// Create supporting text (relative to group)
		supportingText = new FlxText(PADDING_HORIZONTAL, FIELD_HEIGHT + 4, fieldWidth - PADDING_HORIZONTAL * 2, "", 12);
		supportingText.setFormat(Paths.font('NotoSans-Medium.ttf'), 12, MD3Theme.onSurfaceVariant, LEFT);
		supportingText.antialiasing = ClientPrefs.data.antialiasing;
		add(supportingText);
		
		updateSupportingText();
		
		// Listen to keyboard events
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		MD3Theme.addListener(_onThemeChange);
	}
	
	function drawOutline(sprite:FlxSprite, width:Int, height:Int, thickness:Int, focused:Bool):Void
	{
		var graphics = sprite.pixels;
		graphics.fillRect(graphics.rect, FlxColor.TRANSPARENT);
		
		var color = hasError ? MD3Theme.error : (focused ? MD3Theme.primary : MD3Theme.outline);
		var cornerRadius = 4;
		
		// Draw outline using rectangles for each side
		for (i in 0...thickness)
		{
			// Top
			for (x in cornerRadius...(width - cornerRadius))
				graphics.setPixel32(x, i, color);
			
			// Bottom
			for (x in cornerRadius...(width - cornerRadius))
				graphics.setPixel32(x, height - 1 - i, color);
			
			// Left
			for (y in cornerRadius...(height - cornerRadius))
				graphics.setPixel32(i, y, color);
			
			// Right
			for (y in cornerRadius...(height - cornerRadius))
				graphics.setPixel32(width - 1 - i, y, color);
		}
		
		// Draw rounded corners
		drawCorner(graphics, cornerRadius, cornerRadius, cornerRadius, color, thickness, 0); // Top-left
		drawCorner(graphics, width - cornerRadius, cornerRadius, cornerRadius, color, thickness, 1); // Top-right
		drawCorner(graphics, cornerRadius, height - cornerRadius, cornerRadius, color, thickness, 2); // Bottom-left
		drawCorner(graphics, width - cornerRadius, height - cornerRadius, cornerRadius, color, thickness, 3); // Bottom-right
	}
	
	function drawCorner(graphics:openfl.display.BitmapData, cx:Int, cy:Int, radius:Int, color:FlxColor, thickness:Int, corner:Int):Void
	{
		for (angle in 0...90)
		{
			var rad = angle * Math.PI / 180 + corner * Math.PI / 2;
			for (r in (radius - thickness)...radius)
			{
				var x = Std.int(cx + Math.cos(rad) * r);
				var y = Std.int(cy + Math.sin(rad) * r);
				if (x >= 0 && x < graphics.width && y >= 0 && y < graphics.height)
					graphics.setPixel32(x, y, color);
			}
		}
	}
	
	function floatLabel():Void
	{
		if (labelFloating) return;
		labelFloating = true;
		
		if (labelTween != null) labelTween.cancel();
		if (labelScaleTween != null) labelScaleTween.cancel();
		
		var targetY = LABEL_Y_FLOATING;
		var targetScale = LABEL_SCALE_SMALL;
		
		// Animate position using tracked variable
		labelTween = FlxTween.tween(this, {labelYPos: targetY}, 0.2, {
			ease: FlxEase.cubeOut,
			onUpdate: function(_) {
				labelText.offset.y = -labelYPos;
			}
		});
		labelScaleTween = FlxTween.tween(labelText.scale, {x: targetScale, y: targetScale}, 0.2, {
			ease: FlxEase.cubeOut
		});
		
		inputText.alpha = 1;
	}
	
	function sinkLabel():Void
	{
		if (!labelFloating || text.length > 0) return;
		labelFloating = false;
		
		if (labelTween != null) labelTween.cancel();
		if (labelScaleTween != null) labelScaleTween.cancel();
		
		// Animate position using tracked variable
		labelTween = FlxTween.tween(this, {labelYPos: LABEL_Y_NORMAL}, 0.2, {
			ease: FlxEase.cubeOut,
			onUpdate: function(_) {
				labelText.offset.y = -labelYPos;
			}
		});
		labelScaleTween = FlxTween.tween(labelText.scale, {x: 1, y: 1}, 0.2, {
			ease: FlxEase.cubeOut
		});
		
		if (text.length == 0)
			inputText.alpha = 0;
	}
	
	function updateOutline():Void
	{
		var thickness = isFocused ? OUTLINE_WIDTH_FOCUSED : OUTLINE_WIDTH;
		outline.makeGraphic(Std.int(fieldWidth), FIELD_HEIGHT, FlxColor.TRANSPARENT, true);
		drawOutline(outline, Std.int(fieldWidth), FIELD_HEIGHT, thickness, isFocused);
		
		// Update label color
		labelText.color = hasError ? MD3Theme.error : (isFocused ? MD3Theme.primary : MD3Theme.onSurfaceVariant);
	}
	
	function updateSupportingText():Void
	{
		if (hasError && errorText.length > 0)
		{
			supportingText.text = errorText;
			supportingText.color = MD3Theme.error;
		}
		else if (helperText.length > 0)
		{
			supportingText.text = helperText;
			supportingText.color = MD3Theme.onSurfaceVariant;
		}
		else
		{
			supportingText.text = "";
		}
	}
	
	public function focus():Void
	{
		if (!enabled || isFocused) return;
		
		isFocused = true;
		floatLabel();
		updateOutline();
		cursor.alpha = 1;
		cursorVisible = true;
		cursor.offset.x = -(PADDING_HORIZONTAL + (inputText.textField != null ? inputText.textField.textWidth : 0) + 2);
		
		if (onFocus != null)
			onFocus();
	}
	
	public function blur():Void
	{
		if (!isFocused) return;
		
		isFocused = false;
		sinkLabel();
		updateOutline();
		cursor.alpha = 0;
		cursorVisible = false;
		
		if (onBlur != null)
			onBlur();
	}
	
	function onKeyDown(e:KeyboardEvent):Void
	{
		if (!isFocused || !enabled) return;
		
		var keyCode:Int = e.keyCode;
		var charCode:Int = e.charCode;
		var flxKey:FlxKey = cast keyCode;
		
		// Handle special keys
		switch(flxKey)
		{
			case BACKSPACE:
				if (text.length > 0)
					text = text.substr(0, text.length - 1);
				return;
				
			case ENTER:
				blur();
				return;
				
			case ESCAPE:
				blur();
				return;
				
			default:
		}
		
		// Handle character input
		if (charCode > 0 && (maxLength == 0 || text.length < maxLength))
		{
			var char = String.fromCharCode(charCode);
			text += char;
		}
	}
	
	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		if (!enabled) return;
		
		// Cursor blinking
		if (isFocused)
		{
			cursorTimer += elapsed;
			if (cursorTimer >= 0.5)
			{
				cursorVisible = !cursorVisible;
				cursor.alpha = cursorVisible ? 1 : 0;
				cursorTimer = 0;
			}
			
			// Update cursor position
			if (inputText.textField != null)
				cursor.offset.x = -(PADDING_HORIZONTAL + inputText.textField.textWidth + 2);
		}
		
		#if FLX_MOUSE
		var mousePos = FlxG.mouse.getScreenPosition();
		var isOver = mousePos.x >= x && mousePos.x <= x + fieldWidth &&
		             mousePos.y >= y && mousePos.y <= y + FIELD_HEIGHT;
		
		if (FlxG.mouse.justPressed && isOver)
		{
			focus();
		}
		else if (FlxG.mouse.justPressed && !isOver && isFocused)
		{
			blur();
		}
		#end
	}
	
	function set_text(value:String):String
	{
		text = value;
		refreshDisplayedText();
		
		if (text.length > 0 && !labelFloating)
		{
			floatLabel();
		}
		
		if (onChange != null)
			onChange(text);
		
		return text;
	}

	function set_passwordMask(value:Bool):Bool
	{
		passwordMask = value;
		refreshDisplayedText();
		return passwordMask;
	}

	inline function getDisplayedText():String
	{
		if (!passwordMask)
			return text;

		var len = text.length;
		if (len <= 0)
			return "";

		var masked = "";
		for (i in 0...len)
			masked += "*";
		return masked;
	}

	function refreshDisplayedText():Void
	{
		if (inputText != null)
			inputText.text = getDisplayedText();
	}
	
	function set_hasError(value:Bool):Bool
	{
		hasError = value;
		updateOutline();
		updateSupportingText();
		return hasError;
	}
	
	function _onThemeChange():Void
	{
		if (cursor != null) cursor.color = MD3Theme.primary;
		if (inputText != null) inputText.color = MD3Theme.onSurface;
		updateOutline();
		updateSupportingText();
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(_onThemeChange);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		
		if (labelTween != null) labelTween.cancel();
		if (labelScaleTween != null) labelScaleTween.cancel();
		if (outlineTween != null) outlineTween.cancel();
		
		onChange = null;
		onFocus = null;
		onBlur = null;
		
		super.destroy();
	}
}
