package options;

import backend.ui.md3.MaterialBox;
import backend.ui.md3.MaterialButton;
import backend.ui.md3.MaterialButton.ButtonType;
import backend.ui.md3.MaterialCheckbox;
import backend.ui.md3.MaterialChip;
import backend.ui.md3.MaterialChip.ChipType;
import backend.ui.md3.MaterialLoadingIndicator;
import backend.ui.md3.MaterialProgressIndicator;
import backend.ui.md3.MaterialProgressIndicator.ProgressType;
import backend.ui.md3.MaterialWavyProgressIndicator;
import backend.ui.md3.MaterialWavyProgressIndicator.WavyProgressType;
import backend.ui.md3.MD3ShapeTools;
import backend.ui.md3.MD3Theme;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.shapes.FlxShapeCircle;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.math.FlxPoint;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.util.FlxGradient;
import lime.system.Clipboard;

class ThemeAccentColorSubState extends MusicBeatSubstate
{
	var onApply:Int->Void;
	var onConfirm:Void->Void;
	var onCancel:Void->Void;

	var previewBox:MaterialBox;
	var pickerBox:MaterialBox;
	var componentsBox:MaterialBox;

	var previewCard:FlxSprite;
	var previewTitle:FlxText;
	var previewMeta:FlxText;
	var previewAccent:FlxSprite;
	var accentChip:MaterialChip;
	var customChip:MaterialChip;
	var livePreviewCheck:MaterialCheckbox;
	var confirmButton:MaterialButton;
	var cancelButton:MaterialButton;
	var copyButton:MaterialButton;
	var pasteButton:MaterialButton;

	var linearDeterminate:MaterialProgressIndicator;
	var linearIndeterminate:MaterialProgressIndicator;
	var circularDeterminate:MaterialProgressIndicator;
	var circularIndeterminate:MaterialProgressIndicator;
	var wavyLinearDeterminate:MaterialWavyProgressIndicator;
	var wavyLinearIndeterminate:MaterialWavyProgressIndicator;
	var wavyCircularDeterminate:MaterialWavyProgressIndicator;
	var wavyCircularIndeterminate:MaterialWavyProgressIndicator;
	var loadingIndicator:MaterialLoadingIndicator;

	var colorGradient:FlxSprite;
	var colorGradientSelector:FlxSprite;
	var colorPalette:FlxSprite;
	var colorWheel:FlxSprite;
	var colorWheelSelector:FlxSprite;

	var controllerPointer:FlxShapeCircle;
	var _lastControllerMode:Bool = false;
	var holdingOnObj:FlxSprite;
	var storedColor:FlxColor;
	var currentColor:FlxColor;
	var originalColor:FlxColor;
	var pendingThemeColor:Null<Int> = null;
	var themeApplyTimer:Float = 0;
	var pendingPreviewRefresh:Bool = false;
	var previewRefreshTimer:Float = 0;

	static inline var THEME_APPLY_INTERVAL:Float = 1 / 12;
	static inline var PREVIEW_REFRESH_INTERVAL:Float = 1 / 20;

	public function new(initialColor:Int, onApply:Int->Void, onConfirm:Void->Void, onCancel:Void->Void)
	{
		super();
		this.onApply = onApply;
		this.onConfirm = onConfirm;
		this.onCancel = onCancel;
		originalColor = FlxColor.fromInt(0xFF000000 | (initialColor & 0x00FFFFFF));
		currentColor = originalColor;
		storedColor = currentColor;
	}

	override function create()
	{
		super.create();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence(Language.getPhrase('theme_accent_picker', 'Theme Accent Picker'), null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = OptionsMenuTheme.backdropColor();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x24FFFFFF, 0x0));
		grid.velocity.set(32, 32);
		grid.alpha = 0.65;
		add(grid);

		var title:FlxText = new FlxText(72, 42, 1136, Language.getPhrase('theme_accent_color_title', 'Theme Accent Color'), 30);
		title.setFormat(Paths.font("vcr.ttf"), 30, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		title.borderSize = 2;
		add(title);

		var hint:FlxText = new FlxText(72, 82, 1136, Language.getPhrase('theme_accent_color_hint', 'Preview real MD3 widgets while you drag the picker. ENTER confirms, BACK cancels.'), 16);
		hint.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		hint.borderSize = 1.5;
		hint.alpha = 0.8;
		add(hint);

		buildPanels();
		buildPicker();
		buildPreview();
		buildComponentsPreview();

		controllerPointer = new FlxShapeCircle(0, 0, 18, {thickness: 0}, FlxColor.WHITE);
		controllerPointer.offset.set(18, 18);
		controllerPointer.alpha = 0.6;
		controllerPointer.visible = controls.controllerMode;
		controllerPointer.screenCenter();
		add(controllerPointer);
		_lastControllerMode = controls.controllerMode;
		FlxG.mouse.visible = !controls.controllerMode;

		addTouchPad('NONE', 'A_B');
		updatePreview();
	}

	function buildPanels():Void
	{
		previewBox = new MaterialBox(36, 124, 420, 556, Language.getPhrase('theme_preview_box', 'Theme Preview'));
		add(previewBox);

		pickerBox = new MaterialBox(472, 124, 360, 556, Language.getPhrase('accent_picker_box', 'Accent Picker'));
		add(pickerBox);

		componentsBox = new MaterialBox(848, 124, 396, 556, Language.getPhrase('md3_components_preview_box', 'MD3 Components Preview'));
		add(componentsBox);
	}

	function buildPicker():Void
	{
		var pickerHint:FlxText = new FlxText(18, 10, 320, Language.getPhrase('theme_accent_picker_hint', 'Wheel + luminance strip + palette, without turning into visual soup.'), 16);
		pickerHint.setFormat(Paths.font("vcr.ttf"), 16, MD3Theme.onSurfaceVariant, LEFT);
		pickerBox.content.add(pickerHint);

		colorGradient = FlxGradient.createGradientFlxSprite(54, 268, [FlxColor.WHITE, FlxColor.BLACK]);
		colorGradient.setPosition(748, 236);
		add(colorGradient);

		colorGradientSelector = new FlxSprite(740, 236).makeGraphic(78, 10, FlxColor.WHITE);
		colorGradientSelector.offset.y = 5;
		add(colorGradientSelector);

		colorPalette = new FlxSprite(566, 530).loadGraphic(Paths.image('noteColorMenu/palette', false));
		colorPalette.scale.set(12, 12);
		colorPalette.updateHitbox();
		colorPalette.antialiasing = false;
		add(colorPalette);

		colorWheel = new FlxSprite(520, 236).loadGraphic(Paths.image('noteColorMenu/colorWheel'));
		colorWheel.setGraphicSize(208, 208);
		colorWheel.updateHitbox();
		add(colorWheel);

		colorWheelSelector = new FlxShapeCircle(0, 0, 8, {thickness: 0}, FlxColor.WHITE);
		colorWheelSelector.offset.set(8, 8);
		colorWheelSelector.alpha = 0.7;
		add(colorWheelSelector);
	}

	function buildPreview():Void
	{
		previewCard = new FlxSprite(24, 34);
		previewBox.content.add(previewCard);

		previewAccent = new FlxSprite(38, 50).makeGraphic(8, 78, currentColor);
		previewBox.content.add(previewAccent);

		previewTitle = new FlxText(64, 68, 300, Language.getPhrase('theme_accent_preview_title', 'FREEPLAY SAMPLE'), 28);
		previewTitle.setFormat(Paths.font("vcr.ttf"), 30, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		previewTitle.borderSize = 2;
		previewBox.content.add(previewTitle);

		previewMeta = new FlxText(64, 110, 300, Language.getPhrase('theme_accent_preview_meta', 'Custom Accent Preview'), 18);
		previewMeta.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		previewMeta.borderSize = 1.5;
		previewBox.content.add(previewMeta);

		accentChip = new MaterialChip(24, 170, Language.getPhrase('theme_accent_chip_active', 'Accent active'), ChipType.FILTER, true);
		previewBox.content.add(accentChip);

		customChip = new MaterialChip(180, 170, Language.getPhrase('theme_accent_chip_custom', 'Custom token'), ChipType.ASSIST, false);
		previewBox.content.add(customChip);

		livePreviewCheck = new MaterialCheckbox(24, 220, Language.getPhrase('theme_accent_live_preview', 'Live preview enabled'), true);
		previewBox.content.add(livePreviewCheck);

		copyButton = new MaterialButton(24, 278, Language.getPhrase('theme_accent_copy_hex', 'Copy HEX'), ButtonType.OUTLINED, 140, function()
		{
			Clipboard.text = currentColor.toHexString(false, false);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		});
		previewBox.content.add(copyButton);

		pasteButton = new MaterialButton(176, 278, Language.getPhrase('theme_accent_paste_hex', 'Paste HEX'), ButtonType.OUTLINED, 140, function()
		{
			var formattedText = Clipboard.text.trim().toUpperCase().replace('#', '').replace('0x', '');
			var newColor:Null<FlxColor> = FlxColor.fromString('#' + formattedText);
			if (newColor != null && formattedText.length == 6)
			{
				applyColor(newColor);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			}
			else FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
		});
		previewBox.content.add(pasteButton);

		confirmButton = new MaterialButton(24, 344, Language.getPhrase('theme_accent_apply', 'Apply'), ButtonType.FILLED, 140, function()
		{
			confirmSelection();
		});
		previewBox.content.add(confirmButton);

		cancelButton = new MaterialButton(176, 344, Language.getPhrase('theme_accent_cancel', 'Cancel'), ButtonType.OUTLINED, 140, function()
		{
			cancelSelection();
		});
		previewBox.content.add(cancelButton);

		var miniHint:FlxText = new FlxText(24, 416, 350, Language.getPhrase('theme_accent_mini_hint', 'The right side shows stock engine widgets tinted with your accent. If it looks cursed here, it would look cursed in menus too.'), 16);
		miniHint.setFormat(Paths.font("vcr.ttf"), 16, OptionsMenuTheme.bodyTextColor(), LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		miniHint.borderSize = 1.25;
		miniHint.alpha = 0.95;
		previewBox.content.add(miniHint);
	}

	function buildComponentsPreview():Void
	{
		var section1:FlxText = new FlxText(20, 16, 340, Language.getPhrase('theme_accent_section_standard', 'Standard Progress'), 20);
		section1.setFormat(Paths.font("vcr.ttf"), 20, MD3Theme.onSurface, LEFT);
		componentsBox.content.add(section1);

		linearDeterminate = new MaterialProgressIndicator(20, 54, ProgressType.LINEAR, 160);
		componentsBox.content.add(linearDeterminate);

		linearIndeterminate = new MaterialProgressIndicator(198, 54, ProgressType.LINEAR, 160);
		linearIndeterminate.indeterminate = true;
		componentsBox.content.add(linearIndeterminate);

		circularDeterminate = new MaterialProgressIndicator(72, 96, ProgressType.CIRCULAR, 48);
		componentsBox.content.add(circularDeterminate);

		circularIndeterminate = new MaterialProgressIndicator(250, 96, ProgressType.CIRCULAR, 48);
		circularIndeterminate.indeterminate = true;
		componentsBox.content.add(circularIndeterminate);

		var section2:FlxText = new FlxText(20, 182, 340, Language.getPhrase('theme_accent_section_wavy', 'Wavy Progress'), 20);
		section2.setFormat(Paths.font("vcr.ttf"), 20, MD3Theme.onSurface, LEFT);
		componentsBox.content.add(section2);

		wavyLinearDeterminate = new MaterialWavyProgressIndicator(20, 220, WavyProgressType.LINEAR, 160);
		componentsBox.content.add(wavyLinearDeterminate);

		wavyLinearIndeterminate = new MaterialWavyProgressIndicator(198, 220, WavyProgressType.LINEAR, 160);
		wavyLinearIndeterminate.indeterminate = true;
		componentsBox.content.add(wavyLinearIndeterminate);

		wavyCircularDeterminate = new MaterialWavyProgressIndicator(68, 262, WavyProgressType.CIRCULAR, 56);
		componentsBox.content.add(wavyCircularDeterminate);

		wavyCircularIndeterminate = new MaterialWavyProgressIndicator(244, 262, WavyProgressType.CIRCULAR, 56);
		wavyCircularIndeterminate.indeterminate = true;
		componentsBox.content.add(wavyCircularIndeterminate);

		var section3:FlxText = new FlxText(20, 350, 340, Language.getPhrase('theme_accent_section_widgets', 'Other Engine Widgets'), 20);
		section3.setFormat(Paths.font("vcr.ttf"), 20, MD3Theme.onSurface, LEFT);
		componentsBox.content.add(section3);

		loadingIndicator = new MaterialLoadingIndicator(24, 390, 44, true);
		componentsBox.content.add(loadingIndicator);

		var infoChip = new MaterialChip(90, 396, Language.getPhrase('theme_accent_chip_preset_safe', 'Preset-safe'), ChipType.SUGGESTION, false);
		componentsBox.content.add(infoChip);

		var filterChip = new MaterialChip(230, 396, Language.getPhrase('theme_accent_chip_selected', 'Selected'), ChipType.FILTER, true);
		componentsBox.content.add(filterChip);

		var inputChip = new MaterialChip(90, 434, Language.getPhrase('theme_accent_chip_hex', 'HEX token'), ChipType.INPUT, false, null, function()
		{
			Clipboard.text = currentColor.toHexString(false, false);
		});
		componentsBox.content.add(inputChip);

		var componentCheck = new MaterialCheckbox(24, 486, Language.getPhrase('theme_accent_use_custom', 'Use custom accent'), true);
		componentsBox.content.add(componentCheck);

		var outlineButton = new MaterialButton(196, 478, Language.getPhrase('theme_accent_preview', 'Preview'), ButtonType.OUTLINED, 84);
		outlineButton.allowMouseInput = false;
		componentsBox.content.add(outlineButton);

		var filledButton = new MaterialButton(292, 478, Language.getPhrase('theme_accent_accent', 'Accent'), ButtonType.FILLED, 84);
		filledButton.allowMouseInput = false;
		componentsBox.content.add(filledButton);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		themeApplyTimer += elapsed;
		previewRefreshTimer += elapsed;

		if (FlxG.gamepads.anyJustPressed(ANY)) controls.controllerMode = true;
		else if (FlxG.mouse.justPressed || FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0) controls.controllerMode = false;
		if (controls.controllerMode != _lastControllerMode)
		{
			FlxG.mouse.visible = !controls.controllerMode;
			controllerPointer.visible = controls.controllerMode;
			_lastControllerMode = controls.controllerMode;
		}
		updateControllerPointer(elapsed);

		if (controls.BACK || touchPad.buttonB.justPressed)
		{
			cancelSelection();
			return;
		}

		if (controls.ACCEPT || touchPad.buttonA.justPressed)
		{
			confirmSelection();
			return;
		}

		var generalPressed:Bool = FlxG.mouse.justPressed || (controls.controllerMode && controls.ACCEPT);
		if (generalPressed)
		{
			if (pointerOverlaps(colorWheel))
			{
				storedColor = currentColor;
				holdingOnObj = colorWheel;
				setPreviewAnimationsEnabled(false);
			}
			else if (pointerOverlaps(colorGradient))
			{
				storedColor = currentColor;
				holdingOnObj = colorGradient;
				setPreviewAnimationsEnabled(false);
			}
			else if (pointerOverlaps(colorPalette))
			{
				var sampled = colorPalette.pixels.getPixel32(
					Std.int((pointerX() - colorPalette.x) / colorPalette.scale.x),
					Std.int((pointerY() - colorPalette.y) / colorPalette.scale.y)
				);
				applyColor(sampled);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			}
			else holdingOnObj = null;
		}

		if (holdingOnObj != null)
		{
			if (FlxG.mouse.justReleased || (controls.controllerMode && controls.justReleased('accept')))
			{
				holdingOnObj = null;
				storedColor = currentColor;
				flushPendingThemeColor();
				updatePreview(true);
				setPreviewAnimationsEnabled(true);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			}
			else if (holdingOnObj == colorGradient)
			{
				var newBrightness = 1 - FlxMath.bound((pointerY() - colorGradient.y) / colorGradient.height, 0, 1);
				if (storedColor.brightness == 0)
					applyColor(FlxColor.fromRGBFloat(newBrightness, newBrightness, newBrightness));
				else
					applyColor(FlxColor.fromHSB(storedColor.hue, storedColor.saturation, newBrightness));
			}
			else if (holdingOnObj == colorWheel)
			{
				var center:FlxPoint = new FlxPoint(colorWheel.x + colorWheel.width / 2, colorWheel.y + colorWheel.height / 2);
				var pointer:FlxPoint = pointerFlxPoint();
				var hue:Float = FlxMath.wrap(FlxMath.wrap(Std.int(pointer.degreesTo(center)), 0, 360) - 90, 0, 360);
				var sat:Float = FlxMath.bound(pointer.dist(center) / colorWheel.width * 2, 0, 1);
				if (sat != 0)
					applyColor(FlxColor.fromHSB(hue, sat, storedColor.brightness));
				else
					applyColor(FlxColor.fromRGBFloat(storedColor.brightness, storedColor.brightness, storedColor.brightness));
			}
		}

		if (pendingThemeColor != null && themeApplyTimer >= THEME_APPLY_INTERVAL)
			flushPendingThemeColor();
		if (pendingPreviewRefresh && previewRefreshTimer >= PREVIEW_REFRESH_INTERVAL)
			flushPendingPreviewRefresh();
	}

	function confirmSelection():Void
	{
		flushPendingThemeColor();
		flushPendingPreviewRefresh();
		if (onConfirm != null) onConfirm();
		close();
	}

	function cancelSelection():Void
	{
		applyColor(originalColor, true);
		setPreviewAnimationsEnabled(true);
		if (onCancel != null) onCancel();
		close();
	}

	function applyColor(color:Int, ?forceThemeApply:Bool = false):Void
	{
		var normalizedColor = FlxColor.fromInt(0xFF000000 | (color & 0x00FFFFFF));
		if (normalizedColor == currentColor && !forceThemeApply)
			return;

		currentColor = normalizedColor;
		if (forceThemeApply || holdingOnObj == null)
			commitThemeColor(currentColor);
		else
			pendingThemeColor = currentColor;
		if (forceThemeApply || holdingOnObj == null)
			updatePreview(true);
		else
		{
			updatePreview(false);
			pendingPreviewRefresh = true;
		}
	}

	function commitThemeColor(color:Int):Void
	{
		pendingThemeColor = null;
		themeApplyTimer = 0;
		if (onApply != null) onApply(color);
	}

	function flushPendingThemeColor():Void
	{
		if (pendingThemeColor == null) return;
		commitThemeColor(pendingThemeColor);
	}

	function flushPendingPreviewRefresh():Void
	{
		pendingPreviewRefresh = false;
		previewRefreshTimer = 0;
		updatePreview(true);
	}

	function updatePreview(?fullRefresh:Bool = true):Void
	{
		customChip.label = Language.getPhrase('theme_accent_hex_label', 'HEX {1}', [currentColor.toHexString(false, false)]);
		updatePickerVisuals();
		if (!fullRefresh) return;

		MD3ShapeTools.fillAndStrokeRoundRect(previewCard, 360, 110, 22, 3, OptionsMenuTheme.cardFill(true), OptionsMenuTheme.cardStroke(true));
		previewAccent.color = OptionsMenuTheme.cardAccent(true);
		previewTitle.color = OptionsMenuTheme.optionTitleColor(true);
		previewMeta.color = OptionsMenuTheme.optionDescriptionColor(true);
		accentChip.selected = true;
		livePreviewCheck.checked = true;

		var hueRatio:Float = FlxMath.bound(currentColor.hue / 360, 0, 1);
		var satRatio:Float = FlxMath.bound(currentColor.saturation, 0, 1);
		var brightRatio:Float = FlxMath.bound(currentColor.brightness, 0, 1);
		var comboRatio:Float = FlxMath.bound((hueRatio * 0.4) + (satRatio * 0.35) + (brightRatio * 0.25), 0, 1);

		linearDeterminate.value = satRatio;
		circularDeterminate.value = brightRatio;
		wavyLinearDeterminate.value = hueRatio;
		wavyCircularDeterminate.value = comboRatio;

		applyWavyColors(wavyLinearDeterminate);
		applyWavyColors(wavyLinearIndeterminate);
		applyWavyColors(wavyCircularDeterminate);
		applyWavyColors(wavyCircularIndeterminate);
	}

	function updatePickerVisuals():Void
	{
		colorWheel.color = FlxColor.fromHSB(0, 0, currentColor.brightness);
		colorWheelSelector.setPosition(colorWheel.x + colorWheel.width / 2, colorWheel.y + colorWheel.height / 2);
		if (currentColor.saturation != 0)
		{
			var hueWrap = currentColor.hue * Math.PI / 180;
			colorWheelSelector.x += Math.sin(hueWrap) * colorWheel.width / 2 * currentColor.saturation;
			colorWheelSelector.y -= Math.cos(hueWrap) * colorWheel.height / 2 * currentColor.saturation;
		}
		colorGradientSelector.y = colorGradient.y + colorGradient.height * (1 - currentColor.brightness);
	}

	function setPreviewAnimationsEnabled(enabled:Bool):Void
	{
		if (linearIndeterminate != null) linearIndeterminate.active = enabled;
		if (circularIndeterminate != null) circularIndeterminate.active = enabled;
		if (wavyLinearDeterminate != null) wavyLinearDeterminate.active = enabled;
		if (wavyLinearIndeterminate != null) wavyLinearIndeterminate.active = enabled;
		if (wavyCircularDeterminate != null) wavyCircularDeterminate.active = enabled;
		if (wavyCircularIndeterminate != null) wavyCircularIndeterminate.active = enabled;
		if (loadingIndicator != null) loadingIndicator.active = enabled;
	}

	function applyWavyColors(indicator:MaterialWavyProgressIndicator):Void
	{
		if (indicator == null) return;
		var waveStart:Int = 0xFF000000 | (currentColor & 0x00FFFFFF);
		var waveEnd:Int = FlxColor.interpolate(waveStart, 0xFFFFFFFF, 0.45);
		var track:Int = FlxColor.interpolate(OptionsMenuTheme.cardFill(false), waveStart, 0.18);
		indicator.setWaveGradient(waveStart, waveEnd);
		indicator.setTrackColor(track);
	}

	function updateControllerPointer(elapsed:Float):Void
	{
		if (!controls.controllerMode)
			return;

		var analogX:Float = 0;
		var analogY:Float = 0;
		for (gamepad in FlxG.gamepads.getActiveGamepads())
		{
			analogX = gamepad.getXAxis(LEFT_ANALOG_STICK);
			analogY = gamepad.getYAxis(LEFT_ANALOG_STICK);
			if (analogX != 0 || analogY != 0)
				break;
		}
		controllerPointer.x = Math.max(0, Math.min(FlxG.width, controllerPointer.x + analogX * 1000 * elapsed));
		controllerPointer.y = Math.max(0, Math.min(FlxG.height, controllerPointer.y + analogY * 1000 * elapsed));
	}

	function pointerOverlaps(obj:Dynamic):Bool
	{
		if (!controls.controllerMode) return FlxG.mouse.overlaps(obj);
		return FlxG.overlap(controllerPointer, obj);
	}

	function pointerX():Float
	{
		return !controls.controllerMode ? FlxG.mouse.x : controllerPointer.x;
	}

	function pointerY():Float
	{
		return !controls.controllerMode ? FlxG.mouse.y : controllerPointer.y;
	}

	function pointerFlxPoint():FlxPoint
	{
		return !controls.controllerMode ? FlxG.mouse.getScreenPosition() : controllerPointer.getScreenPosition();
	}
}
