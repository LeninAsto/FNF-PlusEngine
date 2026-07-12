package backend.ui.md3;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

/**
 * Material Design 3 Radio Button Component
 * Based on: https://m3.material.io/components/radio-button/specs
 */
class MaterialRadioButton extends FlxSpriteGroup
{
	public var selected(default, set):Bool = false;
	public var enabled:Bool = true;
	public var label:String = "";
	public var value:String = "";
	public var groupName:String = "";
	public var onChange:String->Void = null;
	
	// Visual components
	var outerCircle:FlxSprite;
	var innerCircle:FlxSprite;
	var stateLayer:FlxSprite;
	var labelText:FlxText;
	
	// Dimensions (MD3 specs)
	static inline var ICON_SIZE:Int = 20;
	static inline var INNER_CIRCLE_SIZE:Int = 10;
	static inline var STATE_LAYER_SIZE:Int = 40;
	static inline var LABEL_SPACING:Int = 8;
	
	// State
	var isHovered:Bool = false;
	var isPressed:Bool = false;
	
	// Animation tweens
	var selectTween:FlxTween;
	var hoverTween:FlxTween;
	var pressTween:FlxTween;
	
	// Static group registry for radio button groups
	static var radioGroups:Map<String, Array<MaterialRadioButton>> = new Map();
	
	public function new(x:Float = 0, y:Float = 0, ?label:String = "", ?value:String = "", ?groupName:String = "default", ?selected:Bool = false, ?onChange:String->Void = null)
	{
		super(x, y);
		
		this.label = label;
		this.value = value.length > 0 ? value : label;
		this.groupName = groupName;
		this.onChange = onChange;
		
		// Register this radio button in its group
		if (!radioGroups.exists(groupName))
			radioGroups.set(groupName, []);
		radioGroups.get(groupName).push(this);
		
		// Create state layer (for hover/press effects)
		var layerOffset = (STATE_LAYER_SIZE - ICON_SIZE) / 2;
		stateLayer = new FlxSprite(-layerOffset, -layerOffset);
		stateLayer.makeGraphic(STATE_LAYER_SIZE, STATE_LAYER_SIZE, FlxColor.TRANSPARENT);
		drawCircle(stateLayer, STATE_LAYER_SIZE / 2, STATE_LAYER_SIZE / 2, STATE_LAYER_SIZE / 2);
		stateLayer.alpha = 0;
		add(stateLayer);
		
		// Create outer circle
		outerCircle = new FlxSprite(0, 0);
		outerCircle.makeGraphic(ICON_SIZE, ICON_SIZE, FlxColor.TRANSPARENT, true);
		add(outerCircle);
		
		// Create inner circle (selected indicator)
		var innerOffset = (ICON_SIZE - INNER_CIRCLE_SIZE) / 2;
		innerCircle = new FlxSprite(innerOffset, innerOffset);
		innerCircle.makeGraphic(INNER_CIRCLE_SIZE, INNER_CIRCLE_SIZE, FlxColor.TRANSPARENT);
		drawCircle(innerCircle, INNER_CIRCLE_SIZE / 2, INNER_CIRCLE_SIZE / 2, INNER_CIRCLE_SIZE / 2);
		innerCircle.alpha = 0;
		add(innerCircle);
		
		// Create label text if provided
		if (label.length > 0)
		{
			labelText = new FlxText(ICON_SIZE + LABEL_SPACING, 0, 0, label, 14);
			labelText.setFormat(Paths.font('NotoSans-Medium.ttf'), 14, MD3Theme.onSurfaceVariant, LEFT);
			labelText.antialiasing = ClientPrefs.data.antialiasing;
			labelText.y = (ICON_SIZE - labelText.height) / 2;
			add(labelText);
		}
		
		updateAppearance();
		
		// Set selected after all components are created
		if (selected)
		{
			selectThis();
		}
		MD3Theme.addListener(updateAppearance);
	}
	
	function drawCircle(sprite:FlxSprite, cx:Float, cy:Float, radius:Float):Void
	{
		if (sprite == null || sprite.pixels == null) return;
		var graphics = sprite.pixels;
		var w:Int = Std.int(graphics.width);
		var h:Int = Std.int(graphics.height);
		for (y in 0...h)
		{
			for (x in 0...w)
			{
				var dx = x - cx;
				var dy = y - cy;
				if (dx * dx + dy * dy <= radius * radius)
					graphics.setPixel32(x, y, 0xFFFFFFFF);
			}
		}
	}
	
	function drawCircleOutline(sprite:FlxSprite, cx:Float, cy:Float, radius:Float, thickness:Int, color:FlxColor):Void
	{
		if (sprite == null || sprite.pixels == null) return;
		var graphics = sprite.pixels;
		graphics.fillRect(graphics.rect, FlxColor.TRANSPARENT);
		
		var w:Int = Std.int(graphics.width);
		var h:Int = Std.int(graphics.height);
		for (y in 0...h)
		{
			for (x in 0...w)
			{
				var dx = x - cx;
				var dy = y - cy;
				var dist = Math.sqrt(dx * dx + dy * dy);
				
				if (dist <= radius && dist >= radius - thickness)
					graphics.setPixel32(x, y, color);
			}
		}
	}
	
	function updateAppearance():Void
	{
		if (outerCircle == null || innerCircle == null)
		{
			return;
		}
		
		if (!enabled)
		{
			drawCircleOutline(outerCircle, ICON_SIZE / 2, ICON_SIZE / 2, ICON_SIZE / 2, 2, MD3Theme.disabledContentColor());
			innerCircle.color = MD3Theme.disabledContentColor();
			innerCircle.alpha = selected ? 0.38 : 0;
			if (labelText != null)
				labelText.color = MD3Theme.disabledContentColor();
		}
		else
		{
			if (selected)
			{
				drawCircleOutline(outerCircle, ICON_SIZE / 2, ICON_SIZE / 2, ICON_SIZE / 2, 2, MD3Theme.primary);
				innerCircle.color = MD3Theme.primary;
				innerCircle.alpha = 1;
			}
			else
			{
				drawCircleOutline(outerCircle, ICON_SIZE / 2, ICON_SIZE / 2, ICON_SIZE / 2, 2, MD3Theme.onSurfaceVariant);
				innerCircle.alpha = 0;
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
		var radioWidth = labelText != null ? (ICON_SIZE + LABEL_SPACING + labelText.width) : ICON_SIZE;
		var mousePos = FlxG.mouse.getScreenPosition();
		var isOver = mousePos.x >= x && mousePos.x <= x + radioWidth &&
		             mousePos.y >= y && mousePos.y <= y + ICON_SIZE;
		
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
		if (FlxG.mouse.justReleased && isOver && !selected)
		{
			selectThis();
		}
		#end
	}
	
	public function selectThis():Void
	{
		// Deselect all other radio buttons in this group
		if (radioGroups.exists(groupName))
		{
			for (radio in radioGroups.get(groupName))
			{
				if (radio != this && radio.selected)
					radio.selected = false;
			}
		}
		
		selected = true;
	}
	
	function set_selected(value:Bool):Bool
	{
		var oldValue = selected;
		selected = value;
		
		if (innerCircle == null)
		{
			return selected;
		}
		
		if (selectTween != null) selectTween.cancel();
		
		if (selected)
		{
			// Scale animation for inner circle appearing
			innerCircle.scale.set(0, 0);
			innerCircle.alpha = 1;
			selectTween = FlxTween.tween(innerCircle.scale, {x: 1, y: 1}, 0.15, {
				ease: FlxEase.cubeOut,
				onComplete: function(_) {
					updateAppearance();
				}
			});
		}
		else
		{
			selectTween = FlxTween.tween(innerCircle.scale, {x: 0, y: 0}, 0.15, {
				ease: FlxEase.cubeOut,
				onComplete: function(_) {
					innerCircle.alpha = 0;
					innerCircle.scale.set(1, 1);
					updateAppearance();
				}
			});
		}
		
		updateAppearance();
		
		if (oldValue != selected && selected && onChange != null)
			onChange(this.value);
		
		return selected;
	}
	
	override function destroy():Void
	{
		MD3Theme.removeListener(updateAppearance);
		// Unregister from group
		if (radioGroups.exists(groupName))
		{
			radioGroups.get(groupName).remove(this);
			if (radioGroups.get(groupName).length == 0)
				radioGroups.remove(groupName);
		}
		
		if (selectTween != null) selectTween.cancel();
		if (hoverTween != null) hoverTween.cancel();
		if (pressTween != null) pressTween.cancel();
		
		super.destroy();
	}
	
	public static function getSelectedValue(groupName:String):String
	{
		if (radioGroups.exists(groupName))
		{
			for (radio in radioGroups.get(groupName))
			{
				if (radio.selected)
					return radio.value;
			}
		}
		return "";
	}
}
