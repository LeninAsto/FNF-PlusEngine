package options;

import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.util.FlxSpriteUtil;
import backend.ui.md3.MaterialCheckbox;
import options.Option;
import backend.InputFormatter;
#if mobile
import mobile.backend.MobileScaleMode;
#end

class BaseOptionsMenu extends MusicBeatSubstate
{
	private static inline var OPTION_SPAWN_X:Float = -520;
	private static inline var INTRO_DURATION:Float = 0.32;
	private static inline var OUTRO_DURATION:Float = 0.26;
	private static inline var ROW_W:Float = 960;
	private static inline var ROW_H:Float = 66;
	private static inline var ROW_GAP:Float = 12;
	private static inline var ROW_SELECTED_Y:Float = 150;
	private static inline var ROW_X:Float = 160;

	private var curOption:Option = null;
	private var curSelected:Int = 0;
	private var optionsArray:Array<Option>;

	private var optionRows:FlxTypedGroup<OptionRowCard>;
	private var rowStackCache:Array<Float> = [];
	private var rowsHeightCache:Float = 0;
	private var rowsLayoutDirty:Bool = true;

	private var lastThemeSignature:String = "";
	private var titleText:FlxText;
	private var hintText:FlxText;
	private var playingIntroTransition:Bool = false;
	private var closingTransition:Bool = false;
	private var openedFromOptionsState:Bool = false;

	inline function safeOffsetX():Float
	{
		#if mobile
		return MobileScaleMode.getHorizontalOffset();
		#else
		return 0;
		#end
	}

	public var title:String;
	public var rpcTitle:String;

	public var bg:FlxSprite;

	public function new()
	{
		controls.isInSubstate = true;

		super();
		if (title == null)
			title = 'Options';
		if (rpcTitle == null)
			rpcTitle = 'Options Menu';
		if (optionsArray == null)
			optionsArray = [];

		#if DISCORD_ALLOWED
		DiscordClient.changePresence(rpcTitle, null);
		#end

		OptionsMenuTheme.syncAccent();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.alpha = OptionsMenuTheme.menuBackgroundAlpha();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		titleText = new FlxText(safeOffsetX() + 64, 38, 700, title, 34);
		titleText.setFormat(Paths.font("vcr.ttf"), 34, OptionsMenuTheme.titleColor(), LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 1.5;
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		hintText = new FlxText(safeOffsetX() + 66, 80, 780, Language.getPhrase('options_substate_hint', 'LEFT/RIGHT changes values. ACCEPT toggles or edits binds.'), 16);
		hintText.setFormat(Paths.font("vcr.ttf"), 16, OptionsMenuTheme.bodyTextColor(), LEFT);
		hintText.antialiasing = ClientPrefs.data.antialiasing;
		add(hintText);

		optionRows = new FlxTypedGroup<OptionRowCard>();
		add(optionRows);

		rebuildOptionsVisuals(false);
		changeSelection();
		reloadCheckboxes();
		setupIntroTransition();

		addTouchPad('LEFT_FULL', 'A_B_C');
	}

	override function create()
	{
		super.create();
		callOnCompanionScript('onOptionsMenuCreatePost', [getOptionsCopy()]);
	}

	public function addOption(option:Option)
	{
		if (optionsArray == null || optionsArray.length < 1)
			optionsArray = [];
		optionsArray.push(option);
		return option;
	}

	public function setOptionsList(newOptions:Array<Option>):Void
	{
		optionsArray = (newOptions != null) ? newOptions.copy() : [];
		if (curSelected >= optionsArray.length)
			curSelected = Std.int(Math.max(0, optionsArray.length - 1));
		rebuildOptionsVisuals();
	}

	public function removeOptionAt(index:Int):Option
	{
		if (optionsArray == null || index < 0 || index >= optionsArray.length)
			return null;

		var removed = optionsArray.splice(index, 1);
		if (curSelected >= optionsArray.length)
			curSelected = Std.int(Math.max(0, optionsArray.length - 1));
		rebuildOptionsVisuals();
		return removed.length > 0 ? removed[0] : null;
	}

	public function removeOptionByName(name:String):Option
	{
		if (optionsArray == null || name == null)
			return null;

		for (i in 0...optionsArray.length)
		{
			var option = optionsArray[i];
			if (option == null)
				continue;
			if (option.name == name || option.variable == name)
				return removeOptionAt(i);
		}
		return null;
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;

	var bindingKey:Bool = false;
	var holdingEsc:Float = 0;
	var bindingBlack:FlxSprite;
	var bindingText:FlxText;
	var bindingText2:FlxText;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (lastThemeSignature != OptionsMenuTheme.signature())
			refreshThemeVisuals();

		if (bindingKey)
		{
			bindingKeyUpdate(elapsed);
			return;
		}

		if (playingIntroTransition || closingTransition)
			return;

		layoutRows(elapsed);

		if (curOption != null && !isOptionSelectable(curOption))
			changeSelection(0);

		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (controls.BACK)
		{
			var backStop = callOnCompanionScript('onOptionsBack', [getCurrentOption(), curSelected]);
			if (backStop == Function_Stop)
				return;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			startCloseTransition();
			return;
		}

		if (nextAccept <= 0 && curOption != null && isOptionSelectable(curOption))
		{
			switch (curOption.type)
			{
				case BOOL:
					if (controls.ACCEPT)
					{
						var acceptStop = callOnCompanionScript('onOptionAccept', [getCurrentOption(), curSelected]);
						if (acceptStop == Function_Stop)
							return;
						FlxG.sound.play(Paths.sound('scrollMenu'));
						curOption.setValue((curOption.getValue() == true) ? false : true);
						curOption.change();
						if (curOption.variable == 'judgementCounter')
							ClientPrefs.judgementCounter = ClientPrefs.data.judgementCounter;
						reloadCheckboxes();
					}

				case KEYBIND:
					if (controls.ACCEPT)
					{
						var keybindStop = callOnCompanionScript('onOptionAccept', [getCurrentOption(), curSelected]);
						if (keybindStop == Function_Stop)
							return;

						bindingBlack = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
						bindingBlack.scale.set(FlxG.width, FlxG.height);
						bindingBlack.updateHitbox();
						bindingBlack.alpha = 0;
						FlxTween.tween(bindingBlack, {alpha: 0.6}, 0.35, {ease: FlxEase.linear});
						add(bindingBlack);

						bindingText = new FlxText(0, 160, FlxG.width, Language.getPhrase('controls_rebinding', 'Rebinding {1}', [curOption.name]), 34);
						bindingText.setFormat(Paths.font("vcr.ttf"), 34, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
						bindingText.borderSize = 2;
						add(bindingText);

						final escape:String = (controls.mobileC) ? "B" : "ESC";
						final backspace:String = (controls.mobileC) ? "C" : "Backspace";

						bindingText2 = new FlxText(0, 334, FlxG.width,
							Language.getPhrase('controls_rebinding2', 'Hold {1} to Cancel\nHold {2} to Delete', [escape, backspace]), 24);
						bindingText2.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
						bindingText2.borderSize = 1.5;
						add(bindingText2);

						bindingKey = true;
						holdingEsc = 0;
						ClientPrefs.toggleVolumeKeys(false);
						FlxG.sound.play(Paths.sound('scrollMenu'));
					}

				default:
					if (controls.UI_LEFT || controls.UI_RIGHT)
					{
						var pressed = (controls.UI_LEFT_P || controls.UI_RIGHT_P);
						if (holdTime > 0.5 || pressed)
						{
							if (pressed)
							{
								var add:Dynamic = null;
								if (curOption.type != STRING)
									add = controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue;

								switch (curOption.type)
								{
									case INT, FLOAT, PERCENT:
										holdValue = curOption.getValue() + add;
										if (holdValue < curOption.minValue)
											holdValue = curOption.minValue;
										else if (holdValue > curOption.maxValue)
											holdValue = curOption.maxValue;

										if (curOption.type == INT)
										{
											holdValue = Math.round(holdValue);
											curOption.setValue(holdValue);
										}
										else
										{
											holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
											curOption.setValue(holdValue);
										}

									case STRING:
										var num:Int = curOption.curOption;
										if (controls.UI_LEFT_P)
											--num;
										else
											num++;

										if (num < 0)
											num = curOption.options.length - 1;
										else if (num >= curOption.options.length)
											num = 0;

										curOption.curOption = num;
										curOption.setValue(curOption.options[num]);

									default:
								}
								updateTextFrom(curOption);
								curOption.change();
								FlxG.sound.play(Paths.sound('scrollMenu'));
							}
							else if (curOption.type != STRING)
							{
								holdValue += curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1);
								if (holdValue < curOption.minValue)
									holdValue = curOption.minValue;
								else if (holdValue > curOption.maxValue)
									holdValue = curOption.maxValue;

								switch (curOption.type)
								{
									case INT:
										curOption.setValue(Math.round(holdValue));

									case PERCENT:
										curOption.setValue(FlxMath.roundDecimal(holdValue, curOption.decimals));

									default:
								}
								updateTextFrom(curOption);
								curOption.change();
							}
						}

						if (curOption.type != STRING)
							holdTime += elapsed;
					}
					else if (controls.UI_LEFT_R || controls.UI_RIGHT_R)
					{
						if (holdTime > 0.5)
							FlxG.sound.play(Paths.sound('scrollMenu'));
						holdTime = 0;
					}
			}

			if (controls.RESET || touchPad.buttonC.justPressed)
			{
				var leOption:Option = optionsArray[curSelected];
				if (leOption.type != KEYBIND)
				{
					leOption.setValue(leOption.defaultValue);
					if (leOption.type != BOOL)
					{
						if (leOption.type == STRING)
							leOption.curOption = leOption.options.indexOf(leOption.getValue());
						updateTextFrom(leOption);
					}
				}
				else
				{
					leOption.setValue(!Controls.instance.controllerMode ? leOption.defaultKeys.keyboard : leOption.defaultKeys.gamepad);
					updateBind(null, leOption);
				}
				leOption.change();
				FlxG.sound.play(Paths.sound('cancelMenu'));
				reloadCheckboxes();
			}
		}

		if (nextAccept > 0)
			nextAccept -= 1;
	}

	function refreshThemeVisuals():Void
	{
		lastThemeSignature = OptionsMenuTheme.signature();
		OptionsMenuTheme.syncAccent();
		if (bg != null)
		{
			bg.alpha = OptionsMenuTheme.menuBackgroundAlpha();
			bg.color = OptionsMenuTheme.current().accent;
		}
		if (titleText != null)
			titleText.color = OptionsMenuTheme.titleColor();
		if (hintText != null)
			hintText.color = OptionsMenuTheme.bodyTextColor();
		if (optionRows != null)
			for (row in optionRows.members)
				if (row != null)
					row.applyTheme(row.index == curSelected, true);
	}

	function setupIntroTransition():Void
	{
		openedFromOptionsState = Std.isOfType(FlxG.state, OptionsState) && OptionsState.substateVisualActive;
		if (!openedFromOptionsState)
			return;

		playingIntroTransition = true;

		if (titleText != null)
		{
			titleText.visible = false;
			titleText.active = false;
			titleText.alpha = 0;
		}
		if (hintText != null)
		{
			hintText.visible = false;
			hintText.active = false;
			hintText.alpha = 0;
		}

		for (row in optionRows.members)
		{
			if (row == null)
				continue;
			var targetX:Float = row.x;
			row.x = Math.min(OPTION_SPAWN_X, -row.rowWidth - 140);
			row.alpha = 0;
			FlxTween.tween(row, {x: targetX}, INTRO_DURATION, {ease: FlxEase.cubeInOut, startDelay: 0.02 * Math.max(0, row.index + 1)});
			FlxTween.tween(row, {alpha: row.index == curSelected ? 1 : 0.6}, INTRO_DURATION,
				{ease: FlxEase.cubeInOut, startDelay: 0.02 * Math.max(0, row.index + 1)});
		}

		new FlxTimer().start(0.4, function(_) playingIntroTransition = false);
	}

	function startCloseTransition():Void
	{
		if (closingTransition)
			return;

		closingTransition = true;

		for (row in optionRows.members)
		{
			if (row == null)
				continue;
			FlxTween.cancelTweensOf(row);
			FlxTween.tween(row, {x: Math.min(OPTION_SPAWN_X, -row.rowWidth - 140), alpha: 0}, OUTRO_DURATION, {ease: FlxEase.cubeInOut});
		}

		new FlxTimer().start(OUTRO_DURATION + 0.04, function(_)
		{
			closingTransition = false;
			close();
		});
	}

	function bindingKeyUpdate(elapsed:Float)
	{
		if (touchPad.buttonB.pressed || FlxG.keys.pressed.ESCAPE || FlxG.gamepads.anyPressed(B))
		{
			holdingEsc += elapsed;
			if (holdingEsc > 0.5)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				closeBinding();
			}
		}
		else if (touchPad.buttonC.pressed || FlxG.keys.pressed.BACKSPACE || FlxG.gamepads.anyPressed(BACK))
		{
			holdingEsc += elapsed;
			if (holdingEsc > 0.5)
			{
				if (!controls.controllerMode)
					curOption.keys.keyboard = 'NONE';
				else
					curOption.keys.gamepad = 'NONE';
				updateBind(!controls.controllerMode ? InputFormatter.getKeyName(NONE) : InputFormatter.getGamepadName(NONE));
				FlxG.sound.play(Paths.sound('cancelMenu'));
				closeBinding();
			}
		}
		else
		{
			holdingEsc = 0;
			var changed:Bool = false;
			if (!controls.controllerMode)
			{
				if (FlxG.keys.justPressed.ANY || FlxG.keys.justReleased.ANY)
				{
					var keyPressed:FlxKey = cast(FlxG.keys.firstJustPressed(), FlxKey);
					var keyReleased:FlxKey = cast(FlxG.keys.firstJustReleased(), FlxKey);

					if (keyPressed != NONE && keyPressed != ESCAPE && keyPressed != BACKSPACE)
					{
						changed = true;
						curOption.keys.keyboard = keyPressed;
					}
					else if (keyReleased != NONE && (keyReleased == ESCAPE || keyReleased == BACKSPACE))
					{
						changed = true;
						curOption.keys.keyboard = keyReleased;
					}
				}
			}
			else if (FlxG.gamepads.anyJustPressed(ANY)
				|| FlxG.gamepads.anyJustPressed(LEFT_TRIGGER)
				|| FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER)
				|| FlxG.gamepads.anyJustReleased(ANY))
			{
				var keyPressed:FlxGamepadInputID = NONE;
				var keyReleased:FlxGamepadInputID = NONE;
				if (FlxG.gamepads.anyJustPressed(LEFT_TRIGGER))
					keyPressed = LEFT_TRIGGER;
				else if (FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER))
					keyPressed = RIGHT_TRIGGER;
				else
				{
					for (i in 0...FlxG.gamepads.numActiveGamepads)
					{
						var gamepad:FlxGamepad = FlxG.gamepads.getByID(i);
						if (gamepad != null)
						{
							keyPressed = gamepad.firstJustPressedID();
							keyReleased = gamepad.firstJustReleasedID();
							if (keyPressed != NONE || keyReleased != NONE)
								break;
						}
					}
				}

				if (keyPressed != NONE && keyPressed != FlxGamepadInputID.BACK && keyPressed != FlxGamepadInputID.B)
				{
					changed = true;
					curOption.keys.gamepad = keyPressed;
				}
				else if (keyReleased != NONE && (keyReleased == FlxGamepadInputID.BACK || keyReleased == FlxGamepadInputID.B))
				{
					changed = true;
					curOption.keys.gamepad = keyReleased;
				}
			}

			if (changed)
			{
				var key:String = null;
				if (!controls.controllerMode)
				{
					if (curOption.keys.keyboard == null)
						curOption.keys.keyboard = 'NONE';
					curOption.setValue(curOption.keys.keyboard);
					key = InputFormatter.getKeyName(FlxKey.fromString(curOption.keys.keyboard));
				}
				else
				{
					if (curOption.keys.gamepad == null)
						curOption.keys.gamepad = 'NONE';
					curOption.setValue(curOption.keys.gamepad);
					key = InputFormatter.getGamepadName(FlxGamepadInputID.fromString(curOption.keys.gamepad));
				}
				updateBind(key);
				FlxG.sound.play(Paths.sound('confirmMenu'));
				closeBinding();
			}
		}
	}

	function updateBind(?text:String = null, ?option:Option = null)
	{
		if (option == null)
			option = curOption;
		if (option == null)
			return;
		if (text == null)
		{
			text = option.getValue();
			if (text == null)
				text = 'NONE';

			if (!controls.controllerMode)
				text = InputFormatter.getKeyName(FlxKey.fromString(text));
			else
				text = InputFormatter.getGamepadName(FlxGamepadInputID.fromString(text));
		}

		option.text = text;
		var row:OptionRowCard = cast option.child;
		if (row != null)
			row.setValueLabel(text);
	}

	function closeBinding()
	{
		bindingKey = false;
		if (bindingBlack != null)
		{
			bindingBlack.destroy();
			remove(bindingBlack);
			bindingBlack = null;
		}

		if (bindingText != null)
		{
			bindingText.destroy();
			remove(bindingText);
			bindingText = null;
		}

		if (bindingText2 != null)
		{
			bindingText2.destroy();
			remove(bindingText2);
			bindingText2 = null;
		}
		ClientPrefs.toggleVolumeKeys(true);
	}

	function updateTextFrom(option:Option)
	{
		if (option == null)
			return;

		if (option.type == BOOL)
		{
			var boolRow:OptionRowCard = cast option.child;
			if (boolRow != null)
			{
				boolRow.refreshFromOption();
				if (boolRow.consumeHeightChanged())
					markRowsLayoutDirty();
			}
			return;
		}

		if (option.type == KEYBIND)
		{
			updateBind(null, option);
			return;
		}

		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();
		if (option.type == PERCENT)
			val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);

		var row:OptionRowCard = cast option.child;
		if (row != null)
		{
			row.refreshFromOption();
			if (row.consumeHeightChanged())
				markRowsLayoutDirty();
		}
	}

	function changeSelection(change:Int = 0)
	{
		if (optionsArray == null || optionsArray.length == 0)
			return;

		var direction:Int = change < 0 ? -1 : 1;
		var target:Int = curSelected + change;
		var found:Int = -1;
		for (step in 0...optionsArray.length)
		{
			var index:Int = FlxMath.wrap(target + (step * direction), 0, optionsArray.length - 1);
			if (isOptionSelectable(optionsArray[index]))
			{
				found = index;
				break;
			}
		}

		if (found == -1)
			found = Std.int(FlxMath.bound(curSelected, 0, optionsArray.length - 1));

		curSelected = found;
		curOption = optionsArray[curSelected];

		refreshOptionAlphas();
		layoutRows(FlxG.elapsed);

		callOnCompanionScript('onOptionSelectionChange', [curSelected, getCurrentOption()]);
		if (change != 0)
			FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function reloadCheckboxes()
	{
		if (optionRows == null)
			return;
		for (row in optionRows.members)
		{
			if (row == null)
				continue;
			row.refreshFromOption();
			row.applyTheme(row.index == curSelected, true);
			row.alpha = optionAlpha(row.index, row.index == curSelected);
		}
	}

	function isOptionSelectable(option:Option):Bool
	{
		return option != null && option.isSelectable();
	}

	function optionAlpha(index:Int, selected:Bool):Float
	{
		var option:Option = getOptionAt(index);
		if (!isOptionSelectable(option))
			return 0.35;
		return selected ? 1 : 0.62;
	}

	function refreshOptionAlphas():Void
	{
		if (optionsArray == null || optionRows == null)
			return;

		for (row in optionRows.members)
		{
			if (row == null)
				continue;
			var selected:Bool = row.index == curSelected;
			row.alpha = optionAlpha(row.index, selected);
			row.applyTheme(selected);
		}
	}

	function layoutRows(elapsed:Float, instant:Bool = false):Void
	{
		if (optionRows == null)
			return;

		ensureRowsLayoutCache();
		var moveLerp:Float = elapsed <= 0 ? 0 : Math.exp(-elapsed * 12);
		for (row in optionRows.members)
		{
			if (row == null)
				continue;
			var offset:Int = row.index - curSelected;
			var selected:Bool = offset == 0;
			var targetX:Float = safeOffsetX() + ROW_X + (selected ? 0 : 18);
			var targetY:Float = rowTargetY(row.index);
			var targetScale:Float = 1;
			var newX:Float = targetX;
			var newY:Float = targetY;
			var newScale:Float = targetScale;

			if (instant)
			{
				newX = targetX;
				newY = targetY;
				newScale = targetScale;
			}
			else
			{
				newX = FlxMath.lerp(targetX, row.x, moveLerp);
				newY = FlxMath.lerp(targetY, row.y, moveLerp);
				newScale = FlxMath.lerp(targetScale, row.scale.x, moveLerp);
			}

			var onScreen:Bool = newY + row.rowHeight >= -90 && newY <= FlxG.height + 90;
			row.visible = onScreen;
			row.active = onScreen;
			if (!onScreen && !instant)
			{
				row.x = newX;
				row.y = newY;
				row.scale.set(newScale, newScale);
				row.syncLayout();
				continue;
			}

			if (instant || Math.abs(row.x - newX) > 0.05 || Math.abs(row.y - newY) > 0.05 || Math.abs(row.scale.x - newScale) > 0.001)
			{
				row.x = newX;
				row.y = newY;
				row.scale.set(newScale, newScale);
				row.syncLayout();
			}
		}
	}

	function rowTargetY(index:Int):Float
	{
		if (optionRows == null)
			return ROW_SELECTED_Y;

		var desiredScroll:Float = rowStackY(curSelected);
		var maxScroll:Float = Math.max(0, rowsTotalHeight() + ROW_SELECTED_Y - (FlxG.height - 40));
		var scroll:Float = FlxMath.bound(desiredScroll, 0, maxScroll);
		return ROW_SELECTED_Y + rowStackY(index) - scroll;
	}

	function rowStackY(index:Int):Float
	{
		ensureRowsLayoutCache();
		return (index >= 0 && index < rowStackCache.length) ? rowStackCache[index] : 0;
	}

	function rowsTotalHeight():Float
	{
		ensureRowsLayoutCache();
		return rowsHeightCache;
	}

	function markRowsLayoutDirty():Void
	{
		rowsLayoutDirty = true;
	}

	function ensureRowsLayoutCache():Void
	{
		if (!rowsLayoutDirty)
			return;
		rowsLayoutDirty = false;
		rowStackCache.resize(0);
		rowsHeightCache = 0;
		if (optionRows == null || optionRows.members.length == 0)
			return;

		var total:Float = 0;
		for (i in 0...optionRows.members.length)
		{
			rowStackCache.push(total);
			var row = getRowAt(i);
			total += (row != null ? row.rowHeight : ROW_H);
			if (i < optionRows.members.length - 1)
				total += ROW_GAP;
		}
		rowsHeightCache = total;
	}

	function getRowAt(index:Int):OptionRowCard
	{
		return (optionRows != null && index >= 0 && index < optionRows.members.length) ? optionRows.members[index] : null;
	}

	public function getOptionsCopy():Array<Option>
		return optionsArray != null ? optionsArray.copy() : [];

	public function getCurrentOption():Option
		return curOption;

	public function getCurrentOptionIndex():Int
		return curSelected;

	public function getOptionAt(index:Int):Option
		return (optionsArray != null && index >= 0 && index < optionsArray.length) ? optionsArray[index] : null;

	public function getOptionByName(name:String):Option
	{
		if (optionsArray == null || name == null)
			return null;
		for (option in optionsArray)
		{
			if (option == null)
				continue;
			if (option.name == name || option.variable == name)
				return option;
		}
		return null;
	}

	public function selectOption(index:Int):Void
	{
		if (optionsArray == null || optionsArray.length < 1)
			return;
		curSelected = FlxMath.wrap(index, 0, optionsArray.length - 1);
		changeSelection(0);
	}

	public function rebuildOptionsVisuals(?notifyCompanion:Bool = true):Void
	{
		if (optionRows == null)
			return;
		if (optionsArray == null)
			optionsArray = [];

		while (optionRows.members.length > 0)
		{
			var row = optionRows.members[0];
			if (row != null)
			{
				row.kill();
				optionRows.remove(row, true);
				row.destroy();
			}
			else
				optionRows.members.shift();
		}

		for (i in 0...optionsArray.length)
		{
			var row:OptionRowCard = new OptionRowCard(i, optionsArray[i], ROW_W, ROW_H);
			optionRows.add(row);
			optionsArray[i].child = row;
			updateTextFrom(optionsArray[i]);
		}
		markRowsLayoutDirty();

		if (optionsArray.length > 0)
		{
			curSelected = Std.int(FlxMath.bound(curSelected, 0, optionsArray.length - 1));
			changeSelection(0);
			reloadCheckboxes();
		}
		else
		{
			curSelected = 0;
			curOption = null;
		}

		if (notifyCompanion)
			callOnCompanionScript('onRebuildOptionsVisuals', [getOptionsCopy()]);
	}
}

private class OptionRowCard extends FlxSpriteGroup
{
	static inline var MAX_DESCRIPTION_CHARS:Int = 220;
	static inline var MAX_ROW_HEIGHT:Float = 128;
	static inline var DOT_W:Float = 14;
	static inline var DOT_H:Float = 34;
	static inline var DOT_X:Float = 18;
	static inline var CONTENT_X:Float = 46;
	static inline var TITLE_Y:Float = 11;
	static inline var DESCRIPTION_Y:Float = 39;
	static inline var TEXT_CONTROL_GAP:Float = 28;
	static inline var CONTROL_MARGIN:Float = 34;
	static inline var CHECKBOX_SIZE:Float = 20;
	static inline var VALUE_CONTROL_W:Float = 292;
	static inline var VALUE_CONTROL_H:Float = 44;

	public var index(default, null):Int;
	public var rowWidth(default, null):Float;
	public var rowHeight(default, null):Float;
	public var text(get, set):String;

	var option:Option;
	var minRowHeight:Float;
	var bg:FlxSprite;
	var title:FlxText;
	var description:FlxText;
	var valueControl:OptionValueControl;
	var checkBox:MaterialCheckbox;
	var lastSelected:Null<Bool> = null;
	var lastTheme:String = "";
	var valueLabel:String = "";
	var lastName:String = null;
	var lastDescription:String = null;
	var heightChanged:Bool = false;

	public function new(index:Int, option:Option, w:Float, h:Float)
	{
		super();
		this.index = index;
		this.option = option;
		rowWidth = w;
		minRowHeight = h;
		rowHeight = h;

		bg = new FlxSprite().makeGraphic(Std.int(rowWidth), Std.int(rowHeight), FlxColor.TRANSPARENT, true);
		add(bg);

		title = new FlxText(0, 0, textColumnWidth(), option.name, 21);
		title.setFormat(Paths.font("vcr.ttf"), 21, FlxColor.WHITE, LEFT);
		title.antialiasing = ClientPrefs.data.antialiasing;
		add(title);

		description = new FlxText(0, 0, textColumnWidth(), formatDescription(option.description), 15);
		description.setFormat(Paths.font("vcr.ttf"), 15, FlxColor.WHITE, LEFT);
		description.antialiasing = ClientPrefs.data.antialiasing;
		add(description);

		valueControl = new OptionValueControl(VALUE_CONTROL_W, VALUE_CONTROL_H);
		add(valueControl);

		checkBox = new MaterialCheckbox(0, 0, "", false);
		checkBox.allowMouseInput = false;
		add(checkBox);

		resizeToContent();
		refreshFromOption();
		applyTheme(false, true);
	}

	public function refreshFromOption():Void
	{
		if (option == null)
			return;

		var formattedDescription:String = formatDescription(option.description);
		if (lastName != option.name || lastDescription != formattedDescription)
		{
			lastName = option.name;
			lastDescription = formattedDescription;
			title.text = option.name;
			description.text = formattedDescription;
			if (resizeToContent())
				heightChanged = true;
		}

		switch (option.type)
		{
			case BOOL:
				valueLabel = "";
				if (valueControl != null)
				{
					valueControl.showArrows = false;
					valueControl.setText("");
					setValueControlVisible(false);
				}
				if (checkBox != null)
				{
					setCheckboxVisible(true);
					checkBox.syncChecked(boolValue(option.getValue()));
				}
				syncLayout();

			case KEYBIND:
				if (checkBox != null)
				{
					checkBox.syncChecked(false);
					setCheckboxVisible(false);
				}
				if (valueControl != null)
				{
					valueControl.showArrows = false;
					setValueControlVisible(true);
				}
				valueLabel = option.text != null ? option.text : Std.string(option.getValue());
				valueControl.setText(valueLabel);
				compactValueText();

			default:
				if (checkBox != null)
				{
					checkBox.syncChecked(false);
					setCheckboxVisible(false);
				}
				if (valueControl != null)
				{
					valueControl.showArrows = true;
					setValueControlVisible(true);
				}
				valueLabel = option.text != null ? option.text : Std.string(option.getValue());
				valueControl.setText(valueLabel);
				compactValueText();
		}
	}

	public function consumeHeightChanged():Bool
	{
		var changed:Bool = heightChanged;
		heightChanged = false;
		return changed;
	}

	function resizeToContent():Bool
	{
		if (description != null)
			description.updateHitbox();

		var oldHeight:Float = rowHeight;
		var descBottom:Float = description != null ? DESCRIPTION_Y + description.height : 54;
		rowHeight = FlxMath.bound(descBottom + 14, minRowHeight, MAX_ROW_HEIGHT);

		syncLayout();

		lastTheme = "";
		return Math.abs(rowHeight - oldHeight) > 0.1;
	}

	public function syncLayout():Void
	{
		if (bg != null)
			bg.setPosition(x, y);
		if (title != null)
		{
			title.x = x + CONTENT_X;
			title.y = y + TITLE_Y;
			title.fieldWidth = textColumnWidth();
		}
		if (description != null)
		{
			description.x = x + CONTENT_X;
			description.y = y + DESCRIPTION_Y;
			description.fieldWidth = textColumnWidth();
		}

		var rowCenter:Float = y + rowHeight * 0.5;
		var controlX:Float = x + rowWidth - CONTROL_MARGIN - CHECKBOX_SIZE;
		if (checkBox != null)
		{
			checkBox.x = controlX;
			checkBox.y = centeredY(CHECKBOX_SIZE, rowCenter);
		}

		if (valueControl != null)
		{
			valueControl.x = x + rowWidth - CONTROL_MARGIN - VALUE_CONTROL_W;
			valueControl.y = centeredY(VALUE_CONTROL_H, rowCenter);
			valueControl.syncLayout();
		}
	}

	inline function centeredY(h:Float, center:Float):Float
	{
		return Math.ffloor(center - h * 0.5);
	}

	inline function textColumnWidth():Float
	{
		return rowWidth - CONTENT_X - CONTROL_MARGIN - VALUE_CONTROL_W - TEXT_CONTROL_GAP;
	}

	function formatDescription(value:String):String
	{
		if (value == null)
			return '';

		var text:String = value.trim();
		if (text.length <= MAX_DESCRIPTION_CHARS)
			return text;

		return text.substr(0, MAX_DESCRIPTION_CHARS - 3).trim() + '...';
	}

	public function setValueLabel(value:String):Void
	{
		if (option != null && option.type == BOOL)
		{
			valueLabel = "";
			if (valueControl != null)
			{
				valueControl.showArrows = false;
				valueControl.setText("");
				setValueControlVisible(false);
			}
			if (checkBox != null)
			{
				setCheckboxVisible(true);
				checkBox.syncChecked(boolValue(option.getValue()));
			}
			syncLayout();
			return;
		}

		var nextValue:String = value != null ? value : '';
		if (valueLabel == nextValue)
			return;
		valueLabel = nextValue;
		if (valueControl != null)
			valueControl.setText(valueLabel);
		compactValueText();
	}

	function boolValue(value:Dynamic):Bool
	{
		if (Std.isOfType(value, Bool))
			return value;
		return Std.string(value).toLowerCase() == 'true';
	}

	function compactValueText():Void
	{
		if (valueControl != null)
			valueControl.compactText();
		syncLayout();
	}

	function setCheckboxVisible(value:Bool):Void
	{
		if (checkBox == null)
			return;
		checkBox.setDisplayEnabled(value);
	}

	function setValueControlVisible(value:Bool):Void
	{
		if (valueControl == null)
			return;
		valueControl.setDisplayEnabled(value);
	}

	public function applyTheme(selected:Bool, force:Bool = false):Void
	{
		var signature = OptionsMenuTheme.signature();
		if (!force && lastSelected == selected && lastTheme == signature)
			return;
		lastSelected = selected;
		lastTheme = signature;

		var fill:Int = selected ? OptionsMenuTheme.difficultyCardFill(OptionsMenuTheme.current().accent, true) : OptionsMenuTheme.cardFill(false);
		var stroke:Int = selected ? OptionsMenuTheme.current().accent : OptionsMenuTheme.panelOutlineColor();
		bg.makeGraphic(Std.int(rowWidth), Std.int(rowHeight), FlxColor.TRANSPARENT, true);
		bg.setPosition(x, y);
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, rowWidth, rowHeight, 8, 8, fill);
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, rowWidth, rowHeight, 8, 8, FlxColor.TRANSPARENT, {thickness: selected ? 2 : 1, color: stroke});
		FlxSpriteUtil.drawRoundRect(bg, DOT_X, (rowHeight - DOT_H) * 0.5, DOT_W, DOT_H, DOT_W * 0.5, DOT_W * 0.5,
			selected ? OptionsMenuTheme.current().accent : OptionsMenuTheme.cardAccent(false));

		title.color = OptionsMenuTheme.cardTitleColor(selected);
		description.color = OptionsMenuTheme.cardDescriptionColor(selected);
		if (valueControl != null)
			valueControl.applyTheme(selected);
		syncLayout();
	}

	function get_text():String
		return valueLabel;

	function set_text(value:String):String
	{
		setValueLabel(value);
		return valueLabel;
	}
}

private class OptionValueControl extends FlxSpriteGroup
{
	static inline var BUTTON_W:Float = 44;
	static inline var VALUE_PAD:Float = 6;

	public var controlWidth(default, null):Float;
	public var controlHeight(default, null):Float;
	public var showArrows(default, set):Bool = true;

	var bg:FlxSprite;
	var leftState:FlxSprite;
	var rightState:FlxSprite;
	var leftDivider:FlxSprite;
	var rightDivider:FlxSprite;
	var leftArrow:FlxText;
	var rightArrow:FlxText;
	var valueText:FlxText;
	var rawText:String = "";

	public function new(w:Float, h:Float)
	{
		super();
		controlWidth = w;
		controlHeight = h;

		bg = new FlxSprite();
		add(bg);

		leftState = new FlxSprite();
		add(leftState);

		rightState = new FlxSprite();
		add(rightState);

		leftDivider = new FlxSprite();
		add(leftDivider);

		rightDivider = new FlxSprite();
		add(rightDivider);

		leftArrow = new FlxText(0, 0, BUTTON_W, "<", 22);
		leftArrow.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, CENTER);
		leftArrow.antialiasing = ClientPrefs.data.antialiasing;
		add(leftArrow);

		rightArrow = new FlxText(0, 0, BUTTON_W, ">", 22);
		rightArrow.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, CENTER);
		rightArrow.antialiasing = ClientPrefs.data.antialiasing;
		add(rightArrow);

		valueText = new FlxText(BUTTON_W + VALUE_PAD, 0, controlWidth - BUTTON_W * 2 - VALUE_PAD * 2, "", 18);
		valueText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER);
		valueText.antialiasing = ClientPrefs.data.antialiasing;
		add(valueText);

		layoutChildren();
		applyTheme(false);
	}

	public function setDisplayEnabled(value:Bool):Void
	{
		visible = value;
		active = value;
		exists = value;
		applyChildVisibility();
	}

	public function setText(value:String):Void
	{
		var nextText:String = value != null ? value : "";
		if (rawText == nextText)
			return;
		rawText = nextText;
		valueText.text = rawText;
		compactText();
	}

	public function compactText():Void
	{
		valueText.scale.set(1, 1);
		valueText.updateHitbox();
		var maxTextW:Float = controlWidth - BUTTON_W * 2 - VALUE_PAD * 2;
		if (valueText.width > maxTextW)
		{
			var scale:Float = Math.max(0.70, maxTextW / valueText.width);
			valueText.scale.set(scale, scale);
		}
		layoutChildren();
	}

	public function syncLayout():Void
	{
		layoutChildren();
	}

	function layoutChildren():Void
	{
		bg.setPosition(x, y);

		leftState.setPosition(x, y);
		rightState.setPosition(x + controlWidth - BUTTON_W, y);

		leftDivider.setPosition(x + BUTTON_W, y + 8);
		rightDivider.setPosition(x + controlWidth - BUTTON_W - 1, y + 8);

		leftArrow.x = x;
		rightArrow.x = x + controlWidth - BUTTON_W;
		valueText.x = x + BUTTON_W + VALUE_PAD;
		valueText.fieldWidth = controlWidth - BUTTON_W * 2 - VALUE_PAD * 2;

		centerText(leftArrow);
		centerText(rightArrow);
		centerText(valueText);
		applyChildVisibility();
	}

	function centerText(text:FlxText):Void
	{
		if (text == null)
			return;
		text.updateHitbox();
		text.y = y + Math.ffloor((controlHeight - text.height * text.scale.y) * 0.5 - 1);
	}

	public function applyTheme(selected:Bool):Void
	{
		var fill:Int = OptionsMenuTheme.interactiveFill(false, selected);
		var stroke:Int = selected ? OptionsMenuTheme.current().accent : OptionsMenuTheme.neutralOutlineColor();
		bg.makeGraphic(Std.int(controlWidth), Std.int(controlHeight), FlxColor.TRANSPARENT, true);
		bg.setPosition(x, y);
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, controlWidth, controlHeight, 8, 8, fill);
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, controlWidth, controlHeight, 8, 8, FlxColor.TRANSPARENT, {thickness: selected ? 1.6 : 1, color: stroke});

		leftState.makeGraphic(Std.int(BUTTON_W), Std.int(controlHeight), FlxColor.TRANSPARENT, true);
		rightState.makeGraphic(Std.int(BUTTON_W), Std.int(controlHeight), FlxColor.TRANSPARENT, true);
		layoutChildren();
		FlxSpriteUtil.drawRoundRect(leftState, 0, 0, BUTTON_W, controlHeight, 8, 8, OptionsMenuTheme.interactiveFill(false, selected));
		FlxSpriteUtil.drawRoundRect(rightState, 0, 0, BUTTON_W, controlHeight, 8, 8, OptionsMenuTheme.interactiveFill(false, selected));

		leftDivider.makeGraphic(1, Std.int(controlHeight - 16), OptionsMenuTheme.neutralOutlineColor());
		rightDivider.makeGraphic(1, Std.int(controlHeight - 16), OptionsMenuTheme.neutralOutlineColor());

		leftArrow.color = selected ? OptionsMenuTheme.current().accent : OptionsMenuTheme.footerTextColor();
		rightArrow.color = leftArrow.color;
		valueText.color = OptionsMenuTheme.cardValueColor(selected);
	}

	function set_showArrows(value:Bool):Bool
	{
		showArrows = value;
		applyChildVisibility();
		return showArrows;
	}

	function applyChildVisibility():Void
	{
		var enabled:Bool = visible && exists;
		if (bg != null)
		{
			bg.visible = enabled;
			bg.active = enabled;
			bg.exists = enabled;
		}
		if (valueText != null)
		{
			valueText.visible = enabled;
			valueText.active = enabled;
			valueText.exists = enabled;
		}

		var arrowsEnabled:Bool = enabled && showArrows;
		if (leftArrow != null)
		{
			leftArrow.visible = arrowsEnabled;
			leftArrow.active = arrowsEnabled;
			leftArrow.exists = arrowsEnabled;
		}
		if (rightArrow != null)
		{
			rightArrow.visible = arrowsEnabled;
			rightArrow.active = arrowsEnabled;
			rightArrow.exists = arrowsEnabled;
		}
		if (leftDivider != null)
		{
			leftDivider.visible = arrowsEnabled;
			leftDivider.active = arrowsEnabled;
			leftDivider.exists = arrowsEnabled;
		}
		if (rightDivider != null)
		{
			rightDivider.visible = arrowsEnabled;
			rightDivider.active = arrowsEnabled;
			rightDivider.exists = arrowsEnabled;
		}
		if (leftState != null)
		{
			leftState.visible = arrowsEnabled;
			leftState.active = arrowsEnabled;
			leftState.exists = arrowsEnabled;
		}
		if (rightState != null)
		{
			rightState.visible = arrowsEnabled;
			rightState.active = arrowsEnabled;
			rightState.exists = arrowsEnabled;
		}
	}
}
