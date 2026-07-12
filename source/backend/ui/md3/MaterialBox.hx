package backend.ui.md3;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

/**
 * Material Design 3 Box / Panel Component
 *
 * A draggable, minimizable container panel styled with M3 surface tokens.
 * Equivalent in purpose to PsychUIBox but following Material Design 3 specs.
 *
 * Structure (top to bottom):
 *   ┌─────────────────────────────────────┐
 *   │ Title bar (44 px, surfaceContainerHigh) │
 *   ├─────────────────────────────────────┤
 *   │ content (FlxSpriteGroup)            │
 *   │ (fill with your own children)       │
 *   └─────────────────────────────────────┘
 *
 * Usage:
 *   var box = new MaterialBox(100, 60, 320, 240, "Settings");
 *   box.content.add(mySlider);
 *   box.onClose = function() { remove(box); }
 *   add(box);
 */
class MaterialBox extends FlxSpriteGroup
{
	// -----------------------------------------------------------------------
	// Public API
	// -----------------------------------------------------------------------

	/** The sprite group inside the panel where callers add their children. */
	public var content:FlxSpriteGroup;

	/** Whether the panel can be dragged by clicking the title bar. */
	public var canDrag:Bool = true;

	/** Whether the title bar double-click minimizes the panel body. */
	public var canMinimize:Bool = true;

	/** Callback fired when the close icon is clicked. Null hides the icon. */
	public var onClose:Void->Void = null;

	/** Current minimized state. Setting this animates the panel. */
	public var isMinimized(default, set):Bool = false;

	/** Read-only panel width (set with resize()). */
	public var panelWidth(default, null):Int = 0;

	/** Read-only panel height INCLUDING title bar (set with resize()). */
	public var panelHeight(default, null):Int = 0;

	// -----------------------------------------------------------------------
	// Internal visual components
	// -----------------------------------------------------------------------

	var shadow:FlxSprite;
	var panel:FlxSprite;
	var titleBar:FlxSprite;
	var titleText:FlxText;
	var closeIcon:FlxSprite;
	var divider:FlxSprite;

	// -----------------------------------------------------------------------
	// Layout constants (M3 specs)
	// -----------------------------------------------------------------------

	static inline var TITLE_BAR_HEIGHT:Int = 44;
	static inline var CORNER_RADIUS:Int    = 12;
	static inline var TITLE_FONT_SIZE:Int  = 14;
	static inline var TITLE_PADDING:Int    = 16;
	static inline var CLOSE_ICON_SIZE:Int  = 18;
	static inline var CLOSE_AREA:Int       = 40; // clickable area around close icon
	static inline var SHADOW_BLUR:Int      = 4;
	static inline var DIVIDER_HEIGHT:Int   = 1;

	// -----------------------------------------------------------------------
	// Drag state
	// -----------------------------------------------------------------------

	var _dragStart:FlxPoint;
	var _originPos:FlxPoint;
	var _dragging:Bool = false;
	var _pressed:Bool  = false;
	var _lastClickTime:Float = 999;

	var _minimizeTween:FlxTween;

	/** Unminimized content height (excluding title bar). */
	var _contentHeight:Int = 0;

	public function new(x:Float = 0, y:Float = 0, width:Int = 300, height:Int = 200, title:String = "")
	{
		super(x, y);

		// Shadow (offset slightly for elevation-2 feel)
		shadow = new FlxSprite(SHADOW_BLUR, SHADOW_BLUR);
		shadow.makeGraphic(width + SHADOW_BLUR * 2, height + SHADOW_BLUR * 2, FlxColor.TRANSPARENT, true);
		add(shadow);

		// Panel background
		panel = new FlxSprite(0, 0);
		panel.makeGraphic(width, height, MD3Theme.surfaceContainerLow);
		drawRoundedRect(panel, width, height, CORNER_RADIUS, MD3Theme.surfaceContainerLow);
		add(panel);

		// Title bar (top strip)
		titleBar = new FlxSprite(0, 0);
		titleBar.makeGraphic(width, TITLE_BAR_HEIGHT, MD3Theme.surfaceContainerHigh);
		drawTitleBar(titleBar, width, TITLE_BAR_HEIGHT, CORNER_RADIUS);
		add(titleBar);

		// Divider line below title bar
		divider = new FlxSprite(0, TITLE_BAR_HEIGHT);
		divider.makeGraphic(width, DIVIDER_HEIGHT, MD3Theme.outlineVariant);
		divider.color = MD3Theme.outlineVariant;
		add(divider);

		// Title text
		titleText = new FlxText(TITLE_PADDING, 0, width - TITLE_PADDING * 2 - CLOSE_AREA, title, TITLE_FONT_SIZE);
		titleText.setFormat(Paths.font('NotoSans-Medium.ttf'), TITLE_FONT_SIZE, MD3Theme.onSurface, LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		titleText.y = (TITLE_BAR_HEIGHT - titleText.height) / 2;
		add(titleText);

		// Close icon (drawn as an X)
		closeIcon = new FlxSprite(width - CLOSE_AREA + (CLOSE_AREA - CLOSE_ICON_SIZE) / 2, (TITLE_BAR_HEIGHT - CLOSE_ICON_SIZE) / 2);
		closeIcon.makeGraphic(CLOSE_ICON_SIZE, CLOSE_ICON_SIZE, FlxColor.TRANSPARENT, true);
		drawCloseIcon(closeIcon, CLOSE_ICON_SIZE, MD3Theme.onSurfaceVariant);
		closeIcon.visible = (onClose != null);
		add(closeIcon);

		// Content group (positioned below title bar + divider)
		content = new FlxSpriteGroup(0, TITLE_BAR_HEIGHT + DIVIDER_HEIGHT);
		add(content);

		// Draw shadow graphic
		drawShadow(shadow, width + SHADOW_BLUR * 2, height + SHADOW_BLUR * 2, CORNER_RADIUS + SHADOW_BLUR);

		panelWidth = width;
		panelHeight = height;
		_contentHeight = height - TITLE_BAR_HEIGHT - DIVIDER_HEIGHT;

		MD3Theme.addListener(_onThemeChange);
	}

	// -----------------------------------------------------------------------
	// Update — drag + click handling
	// -----------------------------------------------------------------------

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		_lastClickTime += elapsed;

		#if FLX_MOUSE
		var mouse = FlxG.mouse.getScreenPosition();

		// Check if mouse is over the title bar
		var overTitle = (mouse.x >= x && mouse.x <= x + panelWidth
			&& mouse.y >= y && mouse.y <= y + TITLE_BAR_HEIGHT);

		// Check if mouse is over the close icon area
		var closeX = x + panelWidth - CLOSE_AREA;
		var overClose = onClose != null
			&& mouse.x >= closeX && mouse.x <= x + panelWidth
			&& mouse.y >= y && mouse.y <= y + TITLE_BAR_HEIGHT;

		if (FlxG.mouse.justPressed && overTitle)
		{
			_pressed = true;
			if (overClose)
			{
				// Close button click — handled on release
			}
		}

		if (_dragging && canDrag)
		{
			if (!FlxG.mouse.released)
			{
				var newMouse = FlxG.mouse.getScreenPosition();
				setPosition(
					_originPos.x + (newMouse.x - _dragStart.x),
					_originPos.y + (newMouse.y - _dragStart.y)
				);
			}
			else
			{
				_dragging = false;
				_pressed = false;
			}
		}
		else if (_pressed && canDrag && FlxG.mouse.pressed
			&& (Math.abs(FlxG.mouse.deltaScreenX) > 1 || Math.abs(FlxG.mouse.deltaScreenY) > 1)
			&& !overClose)
		{
			_dragging = true;
			_dragStart  = FlxG.mouse.getScreenPosition();
			_originPos  = FlxPoint.get(x, y);
		}

		if (FlxG.mouse.justReleased && _pressed)
		{
			if (overClose && onClose != null)
			{
				onClose();
			}
			else if (overTitle && !_dragging && canMinimize && _lastClickTime < 0.20)
			{
				// Double-click on title to minimize/maximize
				isMinimized = !isMinimized;
				_lastClickTime = 999;
			}
			else if (overTitle && !_dragging)
			{
				_lastClickTime = 0;
			}
			_pressed  = false;
			_dragging = false;
		}

		mouse.put();
		#end
	}

	// -----------------------------------------------------------------------
	// Public methods
	// -----------------------------------------------------------------------

	/**
	 * Resize the panel. Content group is repositioned automatically.
	 * @param width   New total width in pixels.
	 * @param height  New total height in pixels (including the title bar).
	 */
	public function resize(width:Int, height:Int):Void
	{
		panelWidth  = width;
		panelHeight = height;
		_contentHeight = height - TITLE_BAR_HEIGHT - DIVIDER_HEIGHT;

		panel.makeGraphic(width, height, MD3Theme.surfaceContainerLow);
		drawRoundedRect(panel, width, height, CORNER_RADIUS, MD3Theme.surfaceContainerLow);

		titleBar.makeGraphic(width, TITLE_BAR_HEIGHT, MD3Theme.surfaceContainerHigh);
		drawTitleBar(titleBar, width, TITLE_BAR_HEIGHT, CORNER_RADIUS);

		divider.makeGraphic(width, DIVIDER_HEIGHT, MD3Theme.outlineVariant);
		divider.color = MD3Theme.outlineVariant;

		titleText.fieldWidth = width - TITLE_PADDING * 2 - CLOSE_AREA;

		closeIcon.x = width - CLOSE_AREA + (CLOSE_AREA - CLOSE_ICON_SIZE) / 2;
		drawCloseIcon(closeIcon, CLOSE_ICON_SIZE, MD3Theme.onSurfaceVariant);

		shadow.setPosition(SHADOW_BLUR, SHADOW_BLUR);
		shadow.makeGraphic(width + SHADOW_BLUR * 2, height + SHADOW_BLUR * 2, FlxColor.TRANSPARENT, true);
		drawShadow(shadow, width + SHADOW_BLUR * 2, height + SHADOW_BLUR * 2, CORNER_RADIUS + SHADOW_BLUR);
	}

	// -----------------------------------------------------------------------
	// Theme
	// -----------------------------------------------------------------------

	function _onThemeChange():Void
	{
		if (panel == null) return;

		drawRoundedRect(panel, panelWidth, panelHeight, CORNER_RADIUS, MD3Theme.surfaceContainerLow);
		drawTitleBar(titleBar, panelWidth, TITLE_BAR_HEIGHT, CORNER_RADIUS);

		if (divider != null) divider.color = MD3Theme.outlineVariant;
		if (titleText != null) titleText.color = MD3Theme.onSurface;
		if (closeIcon != null)
			drawCloseIcon(closeIcon, CLOSE_ICON_SIZE, MD3Theme.onSurfaceVariant);
		if (shadow != null)
			drawShadow(shadow, panelWidth + SHADOW_BLUR * 2, panelHeight + SHADOW_BLUR * 2, CORNER_RADIUS + SHADOW_BLUR);
	}

	// -----------------------------------------------------------------------
	// Minimize setter
	// -----------------------------------------------------------------------

	function set_isMinimized(v:Bool):Bool
	{
		if (v == isMinimized) return v;
		isMinimized = v;

		if (_minimizeTween != null) _minimizeTween.cancel();

		var targetH:Float = v ? 0 : _contentHeight;
		var dur = v ? 0.15 : 0.22;
		var ease = v ? FlxEase.cubeIn : FlxEase.cubeOut;

		// Tween content scale and panel height visually
		_minimizeTween = FlxTween.num(content.scale.y, v ? 0 : 1, dur, {ease: ease}, function(sv)
		{
			content.scale.y = sv;
			content.alpha   = sv;
			// Shrink panel height by scaling
			panel.scale.y   = v ? (TITLE_BAR_HEIGHT + DIVIDER_HEIGHT + targetH * (1 - sv)) / panelHeight
			                     : (TITLE_BAR_HEIGHT + DIVIDER_HEIGHT + _contentHeight * sv) / panelHeight;
		});

		return v;
	}

	// -----------------------------------------------------------------------
	// Drawing helpers
	// -----------------------------------------------------------------------

	function drawRoundedRect(sprite:FlxSprite, width:Int, height:Int, radius:Int, color:FlxColor):Void
	{
		if (sprite == null || sprite.pixels == null) return;
		var g = sprite.pixels;
		g.fillRect(g.rect, FlxColor.TRANSPARENT);

		for (py in 0...height)
		{
			for (px in 0...width)
			{
				var inside = true;
				if (px < radius && py < radius)
				{
					var dx = radius - px; var dy = radius - py;
					inside = (dx * dx + dy * dy) <= radius * radius;
				}
				else if (px >= width - radius && py < radius)
				{
					var dx = px - (width - radius); var dy = radius - py;
					inside = (dx * dx + dy * dy) <= radius * radius;
				}
				else if (px < radius && py >= height - radius)
				{
					var dx = radius - px; var dy = py - (height - radius);
					inside = (dx * dx + dy * dy) <= radius * radius;
				}
				else if (px >= width - radius && py >= height - radius)
				{
					var dx = px - (width - radius); var dy = py - (height - radius);
					inside = (dx * dx + dy * dy) <= radius * radius;
				}
				if (inside) g.setPixel32(px, py, color);
			}
		}
	}

	/** Title bar: only top corners are rounded (bottom corners are square). */
	function drawTitleBar(sprite:FlxSprite, width:Int, height:Int, radius:Int):Void
	{
		if (sprite == null || sprite.pixels == null) return;
		var g = sprite.pixels;
		g.fillRect(g.rect, FlxColor.TRANSPARENT);
		var color:Int = MD3Theme.surfaceContainerHigh;

		for (py in 0...height)
		{
			for (px in 0...width)
			{
				var inside = true;
				if (px < radius && py < radius)
				{
					var dx = radius - px; var dy = radius - py;
					inside = (dx * dx + dy * dy) <= radius * radius;
				}
				else if (px >= width - radius && py < radius)
				{
					var dx = px - (width - radius); var dy = radius - py;
					inside = (dx * dx + dy * dy) <= radius * radius;
				}
				if (inside) g.setPixel32(px, py, color);
			}
		}
	}

	/** Circular gradient shadow — approximated with concentric alpha rings. */
	function drawShadow(sprite:FlxSprite, width:Int, height:Int, radius:Int):Void
	{
		if (sprite == null || sprite.pixels == null) return;
		var g = sprite.pixels;
		g.fillRect(g.rect, FlxColor.TRANSPARENT);
		var shadowColor = MD3Theme.shadowColor();
		var shadowRgb = shadowColor & 0x00FFFFFF;
		var maxAlpha = Std.int(shadowColor.alphaFloat * 255);

		for (py in 0...height)
		{
			for (px in 0...width)
			{
				var inside = true;
				var edge = SHADOW_BLUR;
				if (px < radius && py < radius) { var dx = radius - px; var dy = radius - py; inside = (dx*dx+dy*dy) <= radius * radius; }
				else if (px >= width - radius && py < radius) { var dx = px-(width-radius); var dy = radius-py; inside = (dx*dx+dy*dy) <= radius*radius; }
				else if (px < radius && py >= height - radius) { var dx = radius-px; var dy = py-(height-radius); inside = (dx*dx+dy*dy) <= radius*radius; }
				else if (px >= width - radius && py >= height - radius) { var dx = px-(width-radius); var dy = py-(height-radius); inside = (dx*dx+dy*dy) <= radius*radius; }
				
				if (inside)
				{
					// Compute distance to the nearest edge (for alpha falloff)
					var distToEdge = Std.int(Math.min(Math.min(px, width - px - 1), Math.min(py, height - py - 1)));
					var alpha = distToEdge < edge ? Std.int(maxAlpha * distToEdge / edge) : 0;
					if (alpha > 0)
						g.setPixel32(px, py, (alpha << 24) | shadowRgb);
				}
			}
		}
		sprite.dirty = true;
	}

	/** Draw a simple × icon. */
	function drawCloseIcon(sprite:FlxSprite, size:Int, color:FlxColor):Void
	{
		if (sprite == null || sprite.pixels == null) return;
		var g = sprite.pixels;
		g.fillRect(g.rect, FlxColor.TRANSPARENT);
		var col:Int = color;
		for (i in 0...size)
		{
			g.setPixel32(i, i, col);
			if (i > 0) g.setPixel32(i - 1, i, col);
			if (i < size - 1) g.setPixel32(i + 1, i, col);
			g.setPixel32(size - 1 - i, i, col);
			if (i > 0) g.setPixel32(size - i, i, col);
			if (size - 2 - i >= 0) g.setPixel32(size - 2 - i, i, col);
		}
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(_onThemeChange);
		if (_minimizeTween != null) _minimizeTween.cancel();
		if (_dragStart != null) _dragStart.put();
		if (_originPos != null) _originPos.put();
		super.destroy();
	}
}
