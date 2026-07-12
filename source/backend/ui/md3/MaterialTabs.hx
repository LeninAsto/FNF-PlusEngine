package backend.ui.md3;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

/**
 * Material Design 3 Tabs Component
 * Based on: https://m3.material.io/components/tabs/guidelines
 *
 * Supports Primary and Secondary variants.
 * Primary: large indicator below active tab, scrollable labels.
 * Secondary: small underline indicator, compact.
 */
class MaterialTabs extends FlxSpriteGroup
{
	public var selectedIndex(default, set):Int = 0;
	public var enabled:Bool = true;
	public var onTabChanged:Int->String->Void = null;

	public var tabType:TabType = PRIMARY;

	// Visual components
	var background:FlxSprite;
	var indicator:FlxSprite;
	var tabLabels:Array<FlxText> = [];
	var tabContainers:Array<FlxSprite> = [];
	var stateLayer:FlxSprite;

	// Tabs data
	var tabs:Array<String> = [];

	// Dimensions (MD3 specs)
	public var tabsWidth:Float = 320;
	static inline var TAB_HEIGHT:Int = 48;
	static inline var INDICATOR_HEIGHT_PRIMARY:Int = 3;
	static inline var INDICATOR_HEIGHT_SECONDARY:Int = 2;
	static inline var LABEL_SIZE_PRIMARY:Int = 14;
	static inline var LABEL_SIZE_SECONDARY:Int = 14;

	// Animation
	var indicatorTween:FlxTween;
	var tabWidth:Float = 0;

	public function new(x:Float = 0, y:Float = 0, tabs:Array<String>, ?tabType:TabType = PRIMARY, ?width:Float = 320, ?onTabChanged:Int->String->Void = null)
	{
		super(x, y);

		this.tabs = tabs;
		this.tabType = tabType;
		this.tabsWidth = width;
		this.onTabChanged = onTabChanged;
		this.tabWidth = tabsWidth / tabs.length;

		// Background
		background = new FlxSprite(0, 0);
		background.makeGraphic(Std.int(tabsWidth), TAB_HEIGHT, MD3Theme.surfaceContainerLow);
		background.color = MD3Theme.surfaceContainerLow;
		add(background);

		// Tab containers and labels
		for (i in 0...tabs.length)
		{
			var tabX = i * tabWidth;

			var container = new FlxSprite(tabX, 0);
			container.makeGraphic(Std.int(tabWidth), TAB_HEIGHT, FlxColor.TRANSPARENT);
			tabContainers.push(container);
			add(container);

			var label = new FlxText(tabX, 0, tabWidth, tabs[i], tabType == PRIMARY ? LABEL_SIZE_PRIMARY : LABEL_SIZE_SECONDARY);
			label.setFormat(Paths.font('NotoSans-Medium.ttf'), tabType == PRIMARY ? LABEL_SIZE_PRIMARY : LABEL_SIZE_SECONDARY, MD3Theme.onSurfaceVariant, CENTER);
			label.antialiasing = ClientPrefs.data.antialiasing;
			label.y = (TAB_HEIGHT - label.height) / 2;
			tabLabels.push(label);
			add(label);
		}

		// Indicator bar
		var indHeight = tabType == PRIMARY ? INDICATOR_HEIGHT_PRIMARY : INDICATOR_HEIGHT_SECONDARY;
		var indRadius = tabType == PRIMARY ? 3.0 : 0.0;
		indicator = new FlxSprite(0, TAB_HEIGHT - indHeight);
		indicator.makeGraphic(Std.int(tabWidth), indHeight, MD3Theme.primary);
		if (tabType == PRIMARY)
			drawRoundedRectTop(indicator, Std.int(tabWidth), indHeight, Std.int(indRadius));
		indicator.color = MD3Theme.primary;
		add(indicator);

		// Apply initial selection without animation
		applySelection(0, false);
		MD3Theme.addListener(_onThemeChange);
		_onThemeChange();
	}

	function drawRoundedRectTop(sprite:FlxSprite, width:Int, height:Int, radius:Int):Void
	{
		var graphics = sprite.pixels;
		graphics.fillRect(graphics.rect, FlxColor.TRANSPARENT);

		for (py in 0...height)
		{
			for (px in 0...width)
			{
				var inRect = false;
				if (px < radius && py < radius)
				{
					var dx = radius - px;
					var dy = radius - py;
					inRect = (dx * dx + dy * dy) <= radius * radius;
				}
				else if (px >= width - radius && py < radius)
				{
					var dx = px - (width - radius);
					var dy = radius - py;
					inRect = (dx * dx + dy * dy) <= radius * radius;
				}
				else
				{
					inRect = true;
				}

				if (inRect)
					graphics.setPixel32(px, py, 0xFFFFFFFF);
			}
		}
	}

	function _onThemeChange():Void
	{
		if (background != null) background.color = MD3Theme.surfaceContainerLow;
		if (indicator != null) indicator.color = MD3Theme.primary;
		for (i in 0...tabLabels.length)
			tabLabels[i].color = i == selectedIndex ? MD3Theme.primary : MD3Theme.onSurfaceVariant;
	}

	function applySelection(index:Int, animate:Bool = true):Void
	{
		for (i in 0...tabLabels.length)
		{
			tabLabels[i].color = i == index ? MD3Theme.primary : MD3Theme.onSurfaceVariant;
		}

		var targetX = x + index * tabWidth; // absolute world x = group.x + local tab offset
		if (animate)
		{
			if (indicatorTween != null) indicatorTween.cancel();
			indicatorTween = FlxTween.tween(indicator, {x: targetX}, 0.25, {ease: FlxEase.cubeOut});
		}
		else
		{
			indicator.x = targetX;
		}
	}

	function set_selectedIndex(index:Int):Int
	{
		if (index < 0 || index >= tabs.length) return selectedIndex;
		selectedIndex = index;
		applySelection(index);
		if (onTabChanged != null)
			onTabChanged(index, tabs[index]);
		return selectedIndex;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!enabled) return;

		#if FLX_MOUSE
		var mousePos = FlxG.mouse.getScreenPosition();
		var isOverBar = mousePos.x >= x && mousePos.x <= x + tabsWidth && mousePos.y >= y && mousePos.y <= y + TAB_HEIGHT;

		if (isOverBar && FlxG.mouse.justPressed)
		{
			var relX = mousePos.x - x;
			var clickedIndex = Std.int(relX / tabWidth);
			if (clickedIndex >= 0 && clickedIndex < tabs.length)
				selectedIndex = clickedIndex;
		}
		#end
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(_onThemeChange);
		if (indicatorTween != null) indicatorTween.cancel();
		super.destroy();
	}
}

enum TabType
{
	PRIMARY;
	SECONDARY;
}
