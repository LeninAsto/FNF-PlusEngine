package backend.ui.md3;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

/**
 * Material Design 3 Menu Component
 * Based on: https://m3.material.io/components/menus/overview
 *
 * A dropdown list of options anchored to a trigger element.
 * Call open() / close() manually, or set a trigger button.
 */
class MaterialMenu extends FlxSpriteGroup
{
	public var items:Array<String> = [];
	public var enabled:Bool = true;
	public var onSelect:Int->String->Void = null;

	public var isOpen(default, null):Bool = false;

	// Visual components
	var panel:FlxSprite;
	var itemContainers:Array<FlxSprite> = [];
	var itemLabels:Array<FlxText> = [];
	var dividers:Array<FlxSprite> = [];
	var stateLayerIndex:Int = -1;
	var hoveredLayer:FlxSprite;

	// Dimensions
	public var menuWidth:Float = 200;

	// Animation
	var openTween:FlxTween;

	inline function itemHeight():Int return MD3Metrics.size(52);
	inline function menuRadius():Int return MD3Metrics.corner(8, menuWidth, itemHeight());
	inline function horizontalPadding():Int return MD3Metrics.size(16);
	inline function itemLabelSize():Int return MD3Metrics.text(15);

	public function new(x:Float = 0, y:Float = 0, items:Array<String>, ?width:Float = 200, ?onSelect:Int->String->Void = null)
	{
		super(x, y);

		this.items = items;
		this.menuWidth = width;
		this.onSelect = onSelect;

		var totalHeight = items.length * itemHeight();

		// Shadow / elevation simulation (offset darker rect)
		var shadow = new FlxSprite(2, 4);
		shadow.antialiasing = ClientPrefs.data.antialiasing;
		MD3ShapeTools.fillRoundRect(shadow, Std.int(menuWidth), totalHeight, menuRadius(), MD3Theme.shadowColor());
		add(shadow);

		// Panel
		panel = new FlxSprite(0, 0);
		panel.antialiasing = ClientPrefs.data.antialiasing;
		MD3ShapeTools.fillRoundRect(panel, Std.int(menuWidth), totalHeight, menuRadius());
		panel.color = MD3Theme.surfaceContainerHigh;
		add(panel);

		// Hover state layer (single reused sprite)
		hoveredLayer = new FlxSprite(0, 0);
		hoveredLayer.antialiasing = ClientPrefs.data.antialiasing;
		MD3ShapeTools.fillRoundRect(hoveredLayer, Std.int(menuWidth), itemHeight(), MD3Metrics.corner(6, menuWidth, itemHeight()));
		hoveredLayer.color = MD3Theme.stateLayerColor(MD3Theme.primary);
		hoveredLayer.alpha = 0;
		add(hoveredLayer);

		// Items
		for (i in 0...items.length)
		{
			var itemY = i * itemHeight();

			var container = new FlxSprite(0, itemY);
			container.makeGraphic(Std.int(menuWidth), itemHeight(), FlxColor.TRANSPARENT);
			itemContainers.push(container);
			add(container);

			var label = new FlxText(horizontalPadding(), itemY, menuWidth - horizontalPadding() * 2, items[i], itemLabelSize());
			label.setFormat(Paths.font('NotoSans-Medium.ttf'), itemLabelSize(), MD3Theme.onSurface, LEFT);
			label.antialiasing = ClientPrefs.data.antialiasing;
			label.y = itemY + (itemHeight() - label.height) / 2;
			itemLabels.push(label);
			add(label);

			// Divider between items (not after last)
			if (i < items.length - 1)
			{
				var divider = new FlxSprite(horizontalPadding(), itemY + itemHeight() - 1);
				divider.makeGraphic(Std.int(menuWidth - horizontalPadding() * 2), 1, MD3Theme.outlineVariant);
				dividers.push(divider);
				add(divider);
			}
		}

		// Start hidden
		visible = false;
		alpha = 0;
		MD3Theme.addListener(_onThemeChange);
	}

	function _onThemeChange():Void
	{
		if (panel != null) panel.color = MD3Theme.surfaceContainerHigh;
		if (hoveredLayer != null) hoveredLayer.color = MD3Theme.stateLayerColor(MD3Theme.primary);
		for (label in itemLabels)
			if (label != null) label.color = MD3Theme.onSurface;
		for (divider in dividers)
			if (divider != null) divider.color = MD3Theme.outlineVariant;
	}

	public function open():Void
	{
		if (isOpen) return;
		isOpen = true;
		visible = true;
		// Re-add at the end of the state's member list so the panel renders
		// above every other component (FlxTypedGroup.add() appends to the end).
		FlxG.state.remove(this, true);
		FlxG.state.add(this);
		if (openTween != null) openTween.cancel();
		openTween = FlxTween.tween(this, {alpha: 1}, 0.15, {ease: FlxEase.cubeOut});
	}

	public function close():Void
	{
		if (!isOpen) return;
		isOpen = false;
		if (openTween != null) openTween.cancel();
		openTween = FlxTween.tween(this, {alpha: 0}, 0.12, {
			ease: FlxEase.cubeIn,
			onComplete: function(_) { visible = false; }
		});
	}

	public function toggle():Void
	{
		if (isOpen) close() else open();
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!enabled || !isOpen) return;

		#if FLX_MOUSE
		var mousePos = FlxG.mouse.getScreenPosition();
		var totalHeight = items.length * itemHeight();
		var isOverMenu = mousePos.x >= x && mousePos.x <= x + menuWidth && mousePos.y >= y && mousePos.y <= y + totalHeight;

		if (isOverMenu)
		{
			var relY = mousePos.y - y;
			var hovIndex = Std.int(relY / itemHeight());

			// Update hover highlight position
			if (hovIndex >= 0 && hovIndex < items.length)
			{
				hoveredLayer.y = hovIndex * itemHeight();
				hoveredLayer.alpha = 1;

				if (FlxG.mouse.justReleased && onSelect != null)
				{
					onSelect(hovIndex, items[hovIndex]);
					close();
				}
			}
		}
		else
		{
			hoveredLayer.alpha = 0;

			// Close menu when clicking outside
			if (FlxG.mouse.justPressed)
				close();
		}
		#end
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(_onThemeChange);
		if (openTween != null) openTween.cancel();
		super.destroy();
	}
}
