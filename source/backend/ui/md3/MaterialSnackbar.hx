package backend.ui.md3;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

/**
 * Material Design 3 Snackbar Component
 * Based on: https://m3.material.io/components/snackbar/guidelines
 *
 * Brief, bottom-anchored notification toast.
 * Auto-dismisses after a timeout. Optional action button.
 *
 * Usage: create once and call show() when needed.
 */
class MaterialSnackbar extends FlxSpriteGroup
{
	public var isShowing(default, null):Bool = false;
	public var onAction:Void->Void = null;

	// Visual components
	var background:FlxSprite;
	var messageText:FlxText;
	var actionButton:FlxText;
	var actionHitArea:FlxSprite;

	// Dimensions (MD3 specs)
	static inline var SNACKBAR_HEIGHT:Int = 48;
	static inline var CORNER_RADIUS:Int = 4;
	static inline var PADDING_H:Int = 16;
	static inline var ACTION_SPACING:Int = 8;
	static inline var LABEL_SIZE:Int = 14;
	static inline var ACTION_SIZE:Int = 14;

	// Layout
	var snackWidth:Float = 320;
	var _autoHideTimer:Float = 0;
	var _autoHideDuration:Float = 4.0;
	var _actionLabel:String = "";

	// Screen base position (group always stays at 0,0; children use world coords)
	var _bx:Float = 0;
	var _by:Float = 0;

	// Animation tweens
	var showTween:FlxTween;
	var hideTween:FlxTween;

	public function new(?snackWidth:Float = 320)
	{
		super(0, 0); // group always stays at (0,0); children use absolute world coords

		this.snackWidth = snackWidth;

		var w = Std.int(snackWidth);
		_bx = (FlxG.width - snackWidth) / 2;
		_by = FlxG.height - SNACKBAR_HEIGHT - 24;

		// Background pill
		background = new FlxSprite(_bx, _by);
		background.makeGraphic(w, SNACKBAR_HEIGHT, MD3Theme.inverseSurface);
		drawRoundedRect(background, w, SNACKBAR_HEIGHT, CORNER_RADIUS);
		background.color = MD3Theme.inverseSurface;
		add(background);

		// Message text — starts at screen position, re-set on each show()
		messageText = new FlxText(_bx + PADDING_H, _by, 0, "", LABEL_SIZE);
		messageText.setFormat(Paths.font('NotoSans-Medium.ttf'), LABEL_SIZE, MD3Theme.inverseOnSurface, LEFT);
		messageText.antialiasing = ClientPrefs.data.antialiasing;
		add(messageText);

		// Action button text
		actionButton = new FlxText(_bx, _by, 0, "", ACTION_SIZE);
		actionButton.setFormat(Paths.font('NotoSans-Medium.ttf'), ACTION_SIZE, MD3Theme.inversePrimary, LEFT);
		actionButton.antialiasing = ClientPrefs.data.antialiasing;
		actionButton.visible = false;
		add(actionButton);

		// Invisible hit area for action button
		actionHitArea = new FlxSprite(_bx, _by);
		actionHitArea.makeGraphic(1, SNACKBAR_HEIGHT, FlxColor.TRANSPARENT);
		actionHitArea.visible = false;
		add(actionHitArea);

		// Start hidden
		alpha = 0;
		visible = false;
		MD3Theme.addListener(_onThemeChange);
		_onThemeChange();
	}

	// Updates _bx/_by and the background sprite position.
	// Does NOT move the group itself — children are positioned manually.
	function repositionToScreen():Void
	{
		_bx = (FlxG.width - snackWidth) / 2;
		_by = FlxG.height - SNACKBAR_HEIGHT - 24;
		background.x = _bx;
		background.y = _by;
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

	/**
	 * Show the snackbar with a message.
	 * @param message    Text to display.
	 * @param duration   Seconds before auto-dismiss (default 4s). Use 0 for persistent.
	 * @param actionLabel Optional label for action button (e.g. "UNDO").
	 * @param onAction   Callback when action button is pressed.
	 */
	public function show(message:String, ?duration:Float = 4.0, ?actionLabel:String = "", ?onAction:Void->Void = null):Void
	{
		if (isShowing) hide(false);

		this.onAction = onAction;
		this._actionLabel = actionLabel;
		this._autoHideDuration = duration;
		this._autoHideTimer = 0;

		// Refresh screen base position first
		repositionToScreen();

		messageText.text = message;

		// Action button
		var hasAction = actionLabel != null && actionLabel.length > 0;
		actionButton.visible = hasAction;
		actionHitArea.visible = hasAction;

		if (hasAction)
		{
			actionButton.text = actionLabel;
			var localActionX = snackWidth - PADDING_H - actionButton.width;
			actionButton.x = _bx + localActionX;
			actionButton.y = _by + (SNACKBAR_HEIGHT - actionButton.height) / 2;

			actionHitArea.x = _bx + localActionX - ACTION_SPACING;
			actionHitArea.y = _by;
			actionHitArea.makeGraphic(Std.int(actionButton.width + ACTION_SPACING * 2), SNACKBAR_HEIGHT, FlxColor.TRANSPARENT);

			// Position message text, leaving space for action button
			messageText.x = _bx + PADDING_H;
			messageText.y = _by + (SNACKBAR_HEIGHT - messageText.height) / 2;
			messageText.fieldWidth = Std.int(localActionX - PADDING_H - ACTION_SPACING);
		}
		else
		{
			messageText.x = _bx + PADDING_H;
			messageText.y = _by + (SNACKBAR_HEIGHT - messageText.height) / 2;
			messageText.fieldWidth = Std.int(snackWidth - PADDING_H * 2);
		}

		isShowing = true;
		visible = true;

		if (showTween != null) showTween.cancel();
		if (hideTween != null) hideTween.cancel();
		showTween = FlxTween.tween(this, {alpha: 1}, 0.2, {ease: FlxEase.cubeOut});
	}

	public function hide(?animate:Bool = true):Void
	{
		if (!isShowing) return;
		isShowing = false;
		_autoHideTimer = 0;

		if (showTween != null) showTween.cancel();
		if (hideTween != null) hideTween.cancel();

		if (animate)
		{
			hideTween = FlxTween.tween(this, {alpha: 0}, 0.2, {
				ease: FlxEase.cubeIn,
				onComplete: function(_) { visible = false; }
			});
		}
		else
		{
			alpha = 0;
			visible = false;
		}
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!isShowing) return;

		// Auto-dismiss after duration
		if (_autoHideDuration > 0)
		{
			_autoHideTimer += elapsed;
			if (_autoHideTimer >= _autoHideDuration)
				hide();
		}

		#if FLX_MOUSE
		if (FlxG.mouse.justReleased && actionButton.visible)
		{
			var mousePos = FlxG.mouse.getScreenPosition();
			// actionHitArea.x/y are already world coords (children positioned absolutely)
			var ax = actionHitArea.x;
			var ay = actionHitArea.y;
			var isOverAction = mousePos.x >= ax && mousePos.x <= ax + actionHitArea.width
				&& mousePos.y >= ay && mousePos.y <= ay + SNACKBAR_HEIGHT;

			if (isOverAction)
			{
				if (onAction != null) onAction();
				hide();
			}
		}
		#end
	}

	function _onThemeChange():Void
	{
		if (background != null) background.color = MD3Theme.inverseSurface;
		if (messageText != null) messageText.color = MD3Theme.inverseOnSurface;
		if (actionButton != null) actionButton.color = MD3Theme.inversePrimary;
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(_onThemeChange);
		if (showTween != null) showTween.cancel();
		if (hideTween != null) hideTween.cancel();
		super.destroy();
	}
}
