package backend.ui.md3;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

/**
 * Material Design 3 Dialog Component
 * Based on: https://m3.material.io/components/dialogs/guidelines
 *
 * Modal dialog with title, body text, and up to two action buttons.
 * Blocks interaction with content behind it via a scrim overlay.
 */
class MaterialDialog extends FlxSpriteGroup
{
	public var isOpen(default, null):Bool = false;
	public var onConfirm:Void->Void = null;
	public var onDismiss:Void->Void = null;

	// Visual components
	var scrim:FlxSprite;
	var panel:FlxSprite;
	var titleText:FlxText;
	var bodyText:FlxText;
	var confirmButton:MaterialButton;
	var dismissButton:MaterialButton;
	var panelWidth:Int = 0;
	var panelHeight:Int = 0;
	var buttonWidth:Int = 0;
	var buttonHeight:Int = 0;
	var confirmBaseX:Float = 0;
	var confirmBaseY:Float = 0;
	var dismissBaseX:Float = 0;
	var dismissBaseY:Float = 0;
	var focusedAction:Int = 1;

	// Animation
	var openTween:FlxTween;
	var scrimTween:FlxTween;

	inline function dialogPadding():Int return MD3Metrics.margin(20);
	inline function dialogTitleSize():Int return MD3Metrics.text(20);
	inline function dialogBodySize():Int return MD3Metrics.text(15);
	inline function dialogSpacing():Int return MD3Metrics.size(12);
	inline function dialogRadius():Int return MD3Metrics.corner(20, panelWidth, panelHeight);

	public function new(?title:String = "Dialog", ?body:String = "", ?confirmLabel:String = "Confirm", ?dismissLabel:String = "Cancel",
		?onConfirm:Void->Void = null, ?onDismiss:Void->Void = null)
	{
		super(0, 0);

		this.onConfirm = onConfirm;
		this.onDismiss = onDismiss;

		var screenW = FlxG.width;
		var screenH = FlxG.height;
		var padding = dialogPadding();
		var spacing = dialogSpacing();
		var titleSize = dialogTitleSize();
		var bodySize = dialogBodySize();
		buttonHeight = MD3Metrics.size(44);
		panelWidth = MD3Metrics.dialogWidth(420, screenW);

		// Compute panel height dynamically based on body text.
		var bodyTextTemp = new FlxText(0, 0, panelWidth - padding * 2, body, bodySize);
		var bodyHeight = Std.int(bodyTextTemp.height);
		panelHeight = padding + titleSize + spacing + bodyHeight + spacing + buttonHeight + padding;
		bodyTextTemp.destroy();
		var minMargin = MD3Metrics.margin(24);
		var panelX = Std.int((screenW - panelWidth) / 2);
		var panelY = Std.int(Math.max(minMargin, (screenH - panelHeight) / 2));

		// Scrim (full-screen overlay)
		scrim = new FlxSprite(0, 0);
		scrim.makeGraphic(screenW, screenH, MD3Theme.scrimColor());
		scrim.alpha = 0;
		add(scrim);

		// Panel
		panel = new FlxSprite(panelX, panelY);
		panel.antialiasing = ClientPrefs.data.antialiasing;
		MD3ShapeTools.fillRoundRect(panel, panelWidth, panelHeight, dialogRadius());
		panel.color = MD3Theme.surfaceContainerHigh;
		panel.alpha = 0;
		add(panel);

		// Title
		var titleY = panelY + padding;
		titleText = new FlxText(panelX + padding, titleY, panelWidth - padding * 2, title, titleSize);
		titleText.setFormat(Paths.font('NotoSans-Medium.ttf'), titleSize, MD3Theme.onSurface, LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		titleText.alpha = 0;
		add(titleText);

		// Body text
		var bodyY = titleY + titleSize + spacing;
		bodyText = new FlxText(panelX + padding, bodyY, panelWidth - padding * 2, body, bodySize);
		bodyText.setFormat(Paths.font('NotoSans-Medium.ttf'), bodySize, MD3Theme.onSurfaceVariant, LEFT);
		bodyText.antialiasing = ClientPrefs.data.antialiasing;
		bodyText.alpha = 0;
		add(bodyText);

		// Buttons row (bottom-right aligned)
		var buttonSpacing = MD3Metrics.size(8);
		buttonWidth = Std.int(Math.min(MD3Metrics.size(140), (panelWidth - padding * 2 - buttonSpacing) / 2));
		var buttonRowY = panelY + panelHeight - padding - buttonHeight;
		dismissBaseX = panelX + panelWidth - padding - buttonWidth * 2 - buttonSpacing;
		dismissBaseY = buttonRowY;
		confirmBaseX = panelX + panelWidth - padding - buttonWidth;
		confirmBaseY = buttonRowY;

		dismissButton = new MaterialButton(
			dismissBaseX,
			buttonRowY, dismissLabel, TEXT, buttonWidth,
			function()
			{
				close();
				if (this.onDismiss != null) this.onDismiss();
			}
		);
		dismissButton.alpha = 0;
		add(dismissButton);

		confirmButton = new MaterialButton(
			confirmBaseX,
			buttonRowY, confirmLabel, FILLED, buttonWidth,
			function()
			{
				close();
				if (this.onConfirm != null) this.onConfirm();
			}
		);
		confirmButton.alpha = 0;
		add(confirmButton);

		// Start hidden
		visible = false;
		MD3Theme.addListener(_onThemeChange);
		refreshActionFocus();
	}

	function _onThemeChange():Void
	{
		if (scrim != null) scrim.makeGraphic(FlxG.width, FlxG.height, MD3Theme.scrimColor());
		if (panel != null) panel.color = MD3Theme.surfaceContainerHigh;
		if (titleText != null) titleText.color = MD3Theme.onSurface;
		if (bodyText != null) bodyText.color = MD3Theme.onSurfaceVariant;
		if (confirmButton != null) confirmButton.refreshTheme();
		if (dismissButton != null) dismissButton.refreshTheme();
	}

	public function open():Void
	{
		if (isOpen) return;
		isOpen = true;
		visible = true;
		focusedAction = 1;
		refreshActionFocus();

		if (openTween != null) openTween.cancel();
		if (scrimTween != null) scrimTween.cancel();

		scrimTween = FlxTween.tween(scrim, {alpha: 1}, 0.2, {ease: FlxEase.cubeOut});
		openTween = FlxTween.tween(panel, {alpha: 1}, 0.2, {ease: FlxEase.cubeOut});
		FlxTween.tween(titleText, {alpha: 1}, 0.2, {ease: FlxEase.cubeOut});
		FlxTween.tween(bodyText, {alpha: 1}, 0.2, {ease: FlxEase.cubeOut});
		FlxTween.tween(confirmButton, {alpha: 1}, 0.2, {ease: FlxEase.cubeOut});
		FlxTween.tween(dismissButton, {alpha: 1}, 0.2, {ease: FlxEase.cubeOut});
	}

	public function close():Void
	{
		if (!isOpen) return;
		isOpen = false;

		if (openTween != null) openTween.cancel();
		if (scrimTween != null) scrimTween.cancel();

		scrimTween = FlxTween.tween(scrim, {alpha: 0}, 0.15, {ease: FlxEase.cubeIn});
		openTween = FlxTween.tween(panel, {alpha: 0}, 0.15, {
			ease: FlxEase.cubeIn,
			onComplete: function(_) { visible = false; }
		});
		FlxTween.tween(titleText, {alpha: 0}, 0.15, {ease: FlxEase.cubeIn});
		FlxTween.tween(bodyText, {alpha: 0}, 0.15, {ease: FlxEase.cubeIn});
		FlxTween.tween(confirmButton, {alpha: 0}, 0.15, {ease: FlxEase.cubeIn});
		FlxTween.tween(dismissButton, {alpha: 0}, 0.15, {ease: FlxEase.cubeIn});
	}

	public function focusConfirm():Void
	{
		focusedAction = 1;
		refreshActionFocus();
	}

	public function focusDismiss():Void
	{
		focusedAction = 0;
		refreshActionFocus();
	}

	public function moveFocus(direction:Int):Void
	{
		if (direction == 0) return;
		focusedAction = focusedAction == 1 ? 0 : 1;
		refreshActionFocus();
	}

	public function activateFocused():Void
	{
		if (focusedAction == 1)
		{
			if (confirmButton.onClick != null) confirmButton.onClick();
		}
		else if (dismissButton.onClick != null)
		{
			dismissButton.onClick();
		}
	}

	public function handlePointerTap(screenX:Float, screenY:Float):Bool
	{
		if (!isOpen) return false;

		if (isPointInsideButton(confirmButton, screenX, screenY))
		{
			if (confirmButton.onClick != null) confirmButton.onClick();
			return true;
		}

		if (isPointInsideButton(dismissButton, screenX, screenY))
		{
			if (dismissButton.onClick != null) dismissButton.onClick();
			return true;
		}

		if (!containsPoint(screenX, screenY))
		{
			close();
			if (onDismiss != null) onDismiss();
			return true;
		}

		return false;
	}

	public function containsPoint(screenX:Float, screenY:Float):Bool
	{
		return screenX >= panel.x && screenX <= panel.x + panelWidth && screenY >= panel.y && screenY <= panel.y + panelHeight;
	}

	inline function isPointInsideButton(button:MaterialButton, screenX:Float, screenY:Float):Bool
	{
		if (button == null) return false;

		var buttonWidthScaled:Float = buttonWidth * button.scale.x;
		var buttonHeightScaled:Float = buttonHeight * button.scale.y;
		return screenX >= button.x && screenX <= button.x + buttonWidthScaled && screenY >= button.y && screenY <= button.y + buttonHeightScaled;
	}

	function refreshActionFocus():Void
	{
		if (confirmButton == null || dismissButton == null) return;

		applyButtonFocus(confirmButton, focusedAction == 1, confirmBaseX, confirmBaseY);
		applyButtonFocus(dismissButton, focusedAction == 0, dismissBaseX, dismissBaseY);
	}

	function applyButtonFocus(button:MaterialButton, isFocused:Bool, baseX:Float, baseY:Float):Void
	{
		var scaleValue:Float = isFocused ? 1.05 : 1.0;
		button.keyboardFocused = isFocused;
		button.scale.set(scaleValue, scaleValue);
		button.alpha = isFocused ? 1.0 : 0.72;
		var scaledWidth:Float = buttonWidth * scaleValue;
		var scaledHeight:Float = buttonHeight * scaleValue;
		button.x = baseX - (scaledWidth - buttonWidth) * 0.5;
		button.y = baseY - (scaledHeight - buttonHeight) * 0.5;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!isOpen) return;

		#if FLX_MOUSE
		// Click on scrim to dismiss
		if (FlxG.mouse.justPressed)
		{
			var mousePos = FlxG.mouse.getScreenPosition();
			var panelX = panel.x;
			var panelY = panel.y;
			var isOverPanel = mousePos.x >= panelX && mousePos.x <= panelX + panelWidth
				&& mousePos.y >= panelY && mousePos.y <= panelY + panelHeight;

			if (!isOverPanel)
			{
				close();
				if (onDismiss != null) onDismiss();
			}
		}
		#end
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(_onThemeChange);
		if (openTween != null) openTween.cancel();
		if (scrimTween != null) scrimTween.cancel();
		super.destroy();
	}
}
