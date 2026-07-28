package options;

import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;

import objects.CheckboxThingie;
import objects.AttachedText;
import options.Option;
import backend.InputFormatter;

#if mobile
import mobile.backend.MobileScaleMode;
#end

class BaseOptionsMenu extends MusicBeatSubstate
{
	private static inline var OPTION_SPAWN_X:Float = -420;
	private static inline var INTRO_DURATION:Float = 0.32;
	private static inline var INTRO_DESC_DURATION:Float = 0.24;
	private static inline var OUTRO_DURATION:Float = 0.26;
	private var curOption:Option = null;
	private var curSelected:Int = 0;
	private var optionsArray:Array<Option>;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	private var grpTexts:FlxTypedGroup<AttachedText>;

	private var descBox:FlxSprite;
	private var descText:FlxText;
	private var lastThemeSignature:String = "";
	private var titleText:Alphabet;
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
		if(title == null) title = 'Options';
		if(rpcTitle == null) rpcTitle = 'Options Menu';
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence(rpcTitle, null);
		#end
		
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.alpha = OptionsMenuTheme.menuBackgroundAlpha();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		// avoids lagspikes while scrolling through menus!
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		grpTexts = new FlxTypedGroup<AttachedText>();
		add(grpTexts);

		checkboxGroup = new FlxTypedGroup<CheckboxThingie>();
		add(checkboxGroup);

		descBox = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.6;
		add(descBox);

		titleText = new Alphabet(safeOffsetX() + 75, 45, title, true);
		titleText.setScale(0.6);
		titleText.alpha = 0.4;
		add(titleText);

		descText = new FlxText(safeOffsetX() + 50, 600, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, OptionsMenuTheme.readableTextOn(OptionsMenuTheme.cardFill(false)), CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);
		refreshThemeVisuals();

		for (i in 0...optionsArray.length)
		{
			var optionText:Alphabet = new Alphabet(safeOffsetX() + 220, 260, optionsArray[i].name, false);
			optionText.isMenuItem = true;
			/*optionText.forceX = 300;
			optionText.yMult = 90;*/
			optionText.targetY = i;
			grpOptions.add(optionText);

			if(optionsArray[i].type == BOOL)
			{
				var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, Std.string(optionsArray[i].getValue()) == 'true');
				checkbox.sprTracker = optionText;
				checkbox.ID = i;
				if (openedFromOptionsState) checkbox.alpha = 0;
				checkboxGroup.add(checkbox);
			}
			else
			{
				optionText.x -= 80;
				optionText.startPosition.x -= 80;
				//optionText.xAdd -= 80;
				var valueText:AttachedText = new AttachedText('' + optionsArray[i].getValue(), optionText.width + 60);
				valueText.sprTracker = optionText;
				valueText.copyAlpha = true;
				valueText.ID = i;
				if (openedFromOptionsState) valueText.alpha = 0;
				grpTexts.add(valueText);
				optionsArray[i].child = valueText;
			}
			updateTextFrom(optionsArray[i]);
		}

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

	public function addOption(option:Option) {
		if(optionsArray == null || optionsArray.length < 1) optionsArray = [];
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
			if (option == null) continue;
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
	var bindingText:Alphabet;
	var bindingText2:Alphabet;
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (lastThemeSignature != OptionsMenuTheme.signature())
			refreshThemeVisuals();

		if(bindingKey)
		{
			bindingKeyUpdate(elapsed);
			return;
		}

		if (playingIntroTransition || closingTransition)
			return;

		if (curOption != null && !curOption.selectable)
			changeSelection(0);

		if (controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
		}

		if (controls.BACK) {
			var backStop = callOnCompanionScript('onOptionsBack', [getCurrentOption(), curSelected]);
			if (backStop == Function_Stop)
				return;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			startCloseTransition();
			return;
		}

		if(nextAccept <= 0 && curOption != null && curOption.selectable)
		{
			switch(curOption.type)
			{
				case BOOL:
					if(controls.ACCEPT)
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
					if(controls.ACCEPT)
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
	
						bindingText = new Alphabet(FlxG.width / 2, 160, Language.getPhrase('controls_rebinding', 'Rebinding {1}', [curOption.name]), false);
						bindingText.alignment = CENTERED;
						add(bindingText);

						final escape:String = (controls.mobileC) ? "B" : "ESC";
						final backspace:String = (controls.mobileC) ? "C" : "Backspace";
						
						bindingText2 = new Alphabet(FlxG.width / 2, 340, Language.getPhrase('controls_rebinding2', 'Hold {1} to Cancel\nHold {2} to Delete', [escape, backspace]), true);
						bindingText2.alignment = CENTERED;
						add(bindingText2);
	
						bindingKey = true;
						holdingEsc = 0;
						ClientPrefs.toggleVolumeKeys(false);
						FlxG.sound.play(Paths.sound('scrollMenu'));
					}

				default:
					if(controls.UI_LEFT || controls.UI_RIGHT)
					{
						var pressed = (controls.UI_LEFT_P || controls.UI_RIGHT_P);
						if(holdTime > 0.5 || pressed)
						{
							if(pressed)
							{
								var add:Dynamic = null;
								if(curOption.type != STRING)
									add = controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue;
		
								switch(curOption.type)
								{
									case INT, FLOAT, PERCENT:
										holdValue = curOption.getValue() + add;
										if(holdValue < curOption.minValue) holdValue = curOption.minValue;
										else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;
		
										if(curOption.type == INT)
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
										var num:Int = curOption.curOption; //lol
										if(controls.UI_LEFT_P) --num;
										else num++;
		
										if(num < 0)
											num = curOption.options.length - 1;
										else if(num >= curOption.options.length)
											num = 0;
		
										curOption.curOption = num;
										curOption.setValue(curOption.options[num]);
										//trace(curOption.options[num]);

									default:
								}
								updateTextFrom(curOption);
								curOption.change();
								FlxG.sound.play(Paths.sound('scrollMenu'));
							}
							else if(curOption.type != STRING)
							{
								holdValue += curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1);
								if(holdValue < curOption.minValue) holdValue = curOption.minValue;
								else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;
		
								switch(curOption.type)
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
		
						if(curOption.type != STRING)
							holdTime += elapsed;
					}
					else if(controls.UI_LEFT_R || controls.UI_RIGHT_R)
					{
						if(holdTime > 0.5) FlxG.sound.play(Paths.sound('scrollMenu'));
						holdTime = 0;
					}
			}

			if(controls.RESET || touchPad.buttonC.justPressed)
			{
				var leOption:Option = optionsArray[curSelected];
				if(leOption.type != KEYBIND)
				{
					leOption.setValue(leOption.defaultValue);
					if(leOption.type != BOOL)
					{
						if(leOption.type == STRING) leOption.curOption = leOption.options.indexOf(leOption.getValue());
						updateTextFrom(leOption);
					}
				}
				else
				{
					leOption.setValue(!Controls.instance.controllerMode ? leOption.defaultKeys.keyboard : leOption.defaultKeys.gamepad);
					updateBind(leOption);
				}
				leOption.change();
				FlxG.sound.play(Paths.sound('cancelMenu'));
				reloadCheckboxes();
			}
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}
	}

	function refreshThemeVisuals():Void
	{
		lastThemeSignature = OptionsMenuTheme.signature();
		if (bg != null)
		{
			bg.alpha = OptionsMenuTheme.menuBackgroundAlpha();
		}
		if (descBox != null)
		{
			descBox.color = OptionsMenuTheme.cardFill(false);
			descBox.alpha = 0.84;
		}
		if (descText != null)
			descText.color = OptionsMenuTheme.readableTextOn(OptionsMenuTheme.cardFill(false));
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

		for (item in grpOptions.members)
		{
			if (item == null) continue;
			var targetX:Float = item.x;
			item.x = Math.min(OPTION_SPAWN_X, -item.width - 140);
			item.alpha = 0;
			FlxTween.tween(item, {x: targetX}, INTRO_DURATION, {ease: FlxEase.cubeInOut, startDelay: 0.02 * Math.max(0, item.targetY + 1)});
			FlxTween.tween(item, {alpha: item.targetY == curSelected ? 1 : 0.6}, INTRO_DURATION, {ease: FlxEase.cubeInOut, startDelay: 0.02 * Math.max(0, item.targetY + 1)});
		}

		for (text in grpTexts.members)
		{
			if (text == null) continue;
			text.alpha = 0;
			FlxTween.tween(text, {alpha: text.ID == curSelected ? 1 : 0.6}, INTRO_DURATION, {ease: FlxEase.cubeInOut, startDelay: 0.02 * Math.max(0, text.ID + 1)});
		}

		for (checkbox in checkboxGroup.members)
		{
			if (checkbox == null) continue;
			checkbox.alpha = 0;
			FlxTween.tween(checkbox, {alpha: checkbox.ID == curSelected ? 1 : 0.6}, INTRO_DURATION, {ease: FlxEase.cubeInOut, startDelay: 0.02 * Math.max(0, checkbox.ID + 1)});
		}

		if (descBox != null)
		{
			descBox.alpha = 0;
			FlxTween.tween(descBox, {alpha: 0.84}, INTRO_DESC_DURATION, {ease: FlxEase.cubeInOut, startDelay: 0.08});
		}

		if (descText != null)
		{
			descText.alpha = 0;
			FlxTween.tween(descText, {alpha: 1}, INTRO_DESC_DURATION, {ease: FlxEase.cubeInOut, startDelay: 0.1});
		}

		new FlxTimer().start(0.4, function(_) playingIntroTransition = false);
	}

	function startCloseTransition():Void
	{
		if (closingTransition)
			return;

		closingTransition = true;

		for (item in grpOptions.members)
		{
			if (item == null) continue;
			FlxTween.cancelTweensOf(item);
			FlxTween.tween(item, {x: Math.min(OPTION_SPAWN_X, -item.width - 140), alpha: 0}, OUTRO_DURATION, {ease: FlxEase.cubeInOut});
		}

		for (text in grpTexts.members)
		{
			if (text == null) continue;
			FlxTween.cancelTweensOf(text);
			FlxTween.tween(text, {alpha: 0}, OUTRO_DURATION - 0.04, {ease: FlxEase.cubeInOut});
		}

		for (checkbox in checkboxGroup.members)
		{
			if (checkbox == null) continue;
			FlxTween.cancelTweensOf(checkbox);
			FlxTween.tween(checkbox, {alpha: 0}, OUTRO_DURATION - 0.04, {ease: FlxEase.cubeInOut});
		}

		if (descBox != null)
		{
			FlxTween.cancelTweensOf(descBox);
			FlxTween.tween(descBox, {alpha: 0}, OUTRO_DURATION - 0.08, {ease: FlxEase.cubeInOut});
		}

		if (descText != null)
		{
			FlxTween.cancelTweensOf(descText);
			FlxTween.tween(descText, {alpha: 0}, OUTRO_DURATION - 0.08, {ease: FlxEase.cubeInOut});
		}

		new FlxTimer().start(OUTRO_DURATION + 0.04, function(_)
		{
			closingTransition = false;
			close();
		});
	}

	function bindingKeyUpdate(elapsed:Float)
	{
		if(touchPad.buttonB.pressed || FlxG.keys.pressed.ESCAPE || FlxG.gamepads.anyPressed(B))
		{
			holdingEsc += elapsed;
			if(holdingEsc > 0.5)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				closeBinding();
			}
		}
		else if (touchPad.buttonC.pressed || FlxG.keys.pressed.BACKSPACE || FlxG.gamepads.anyPressed(BACK))
		{
			holdingEsc += elapsed;
			if(holdingEsc > 0.5)
			{
				if (!controls.controllerMode) curOption.keys.keyboard = NONE;
				else curOption.keys.gamepad = NONE;
				updateBind(!controls.controllerMode ? InputFormatter.getKeyName(NONE) : InputFormatter.getGamepadName(NONE));
				FlxG.sound.play(Paths.sound('cancelMenu'));
				closeBinding();
			}
		}
		else
		{
			holdingEsc = 0;
			var changed:Bool = false;
			if(!controls.controllerMode)
			{
				if(FlxG.keys.justPressed.ANY || FlxG.keys.justReleased.ANY)
				{
					var keyPressed:FlxKey = cast (FlxG.keys.firstJustPressed(), FlxKey);
					var keyReleased:FlxKey = cast (FlxG.keys.firstJustReleased(), FlxKey);

					if(keyPressed != NONE && keyPressed != ESCAPE && keyPressed != BACKSPACE)
					{
						changed = true;
						curOption.keys.keyboard = keyPressed;
					}
					else if(keyReleased != NONE && (keyReleased == ESCAPE || keyReleased == BACKSPACE))
					{
						changed = true;
						curOption.keys.keyboard = keyReleased;
					}
				}
			}
			else if(FlxG.gamepads.anyJustPressed(ANY) || FlxG.gamepads.anyJustPressed(LEFT_TRIGGER) || FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER) || FlxG.gamepads.anyJustReleased(ANY))
			{
				var keyPressed:FlxGamepadInputID = NONE;
				var keyReleased:FlxGamepadInputID = NONE;
				if(FlxG.gamepads.anyJustPressed(LEFT_TRIGGER))
					keyPressed = LEFT_TRIGGER; //it wasnt working for some reason
				else if(FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER))
					keyPressed = RIGHT_TRIGGER; //it wasnt working for some reason
				else
				{
					for (i in 0...FlxG.gamepads.numActiveGamepads)
					{
						var gamepad:FlxGamepad = FlxG.gamepads.getByID(i);
						if(gamepad != null)
						{
							keyPressed = gamepad.firstJustPressedID();
							keyReleased = gamepad.firstJustReleasedID();
							if(keyPressed != NONE || keyReleased != NONE) break;
						}
					}
				}

				if(keyPressed != NONE && keyPressed != FlxGamepadInputID.BACK && keyPressed != FlxGamepadInputID.B)
				{
					changed = true;
					curOption.keys.gamepad = keyPressed;
				}
				else if(keyReleased != NONE && (keyReleased == FlxGamepadInputID.BACK || keyReleased == FlxGamepadInputID.B))
				{
					changed = true;
					curOption.keys.gamepad = keyReleased;
				}
			}

			if(changed)
			{
				var key:String = null;
				if(!controls.controllerMode)
				{
					if(curOption.keys.keyboard == null) curOption.keys.keyboard = 'NONE';
					curOption.setValue(curOption.keys.keyboard);
					key = InputFormatter.getKeyName(FlxKey.fromString(curOption.keys.keyboard));
				}
				else
				{
					if(curOption.keys.gamepad == null) curOption.keys.gamepad = 'NONE';
					curOption.setValue(curOption.keys.gamepad);
					key = InputFormatter.getGamepadName(FlxGamepadInputID.fromString(curOption.keys.gamepad));
				}
				updateBind(key);
				FlxG.sound.play(Paths.sound('confirmMenu'));
				closeBinding();
			}
		}
	}

	final MAX_KEYBIND_WIDTH = 320;
	function updateBind(?text:String = null, ?option:Option = null)
	{
		if(option == null) option = curOption;
		if(text == null)
		{
			text = option.getValue();
			if(text == null) text = 'NONE';

			if(!controls.controllerMode)
				text = InputFormatter.getKeyName(FlxKey.fromString(text));
			else
				text = InputFormatter.getGamepadName(FlxGamepadInputID.fromString(text));
		}

		var bind:AttachedText = cast option.child;
		var attach:AttachedText = new AttachedText(text, bind.offsetX);
		attach.sprTracker = bind.sprTracker;
		attach.copyAlpha = true;
		attach.ID = bind.ID;
		playstationCheck(attach);
		attach.scaleX = Math.min(1, MAX_KEYBIND_WIDTH / attach.width);
		attach.x = bind.x;
		attach.y = bind.y;

		option.child = attach;
		grpTexts.insert(grpTexts.members.indexOf(bind), attach);
		grpTexts.remove(bind);
		bind.destroy();
	}

	function playstationCheck(alpha:Alphabet)
	{
		if(!controls.controllerMode) return;

		var gamepad:FlxGamepad = FlxG.gamepads.firstActive;
		var model:FlxGamepadModel = gamepad != null ? gamepad.detectedModel : UNKNOWN;
		var letter = alpha.letters[0];
		if(model == PS4)
		{
			switch(alpha.text)
			{
				case '[', ']': //Square and Triangle respectively
					letter.image = 'alphabet_playstation';
					letter.updateHitbox();
					
					letter.offset.x += 4;
					letter.offset.y -= 5;
			}
		}
	}

	function closeBinding()
	{
		bindingKey = false;
		bindingBlack.destroy();
		remove(bindingBlack);

		bindingText.destroy();
		remove(bindingText);

		bindingText2.destroy();
		remove(bindingText2);
		ClientPrefs.toggleVolumeKeys(true);
	}

	function updateTextFrom(option:Option) {
		if(option.type == KEYBIND)
		{
			updateBind(option);
			return;
		}

		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();
		if(option.type == PERCENT) val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);
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
			if (optionsArray[index] != null && optionsArray[index].selectable)
			{
				found = index;
				break;
			}
		}

		if (found == -1)
			found = Std.int(FlxMath.bound(curSelected, 0, optionsArray.length - 1));

		curSelected = found;

		descText.text = optionsArray[curSelected].description;
		descText.screenCenter(Y);
		descText.y += 270;

		for (num => item in grpOptions.members)
		{
			item.targetY = num - curSelected;
			item.alpha = (optionsArray[num] != null && !optionsArray[num].selectable) ? 0.35 : 0.6;
			if (item.targetY == 0 && (optionsArray[num] == null || optionsArray[num].selectable)) item.alpha = 1;
		}
		for (text in grpTexts)
		{
			text.alpha = (optionsArray[text.ID] != null && !optionsArray[text.ID].selectable) ? 0.35 : 0.6;
			if(text.ID == curSelected && (optionsArray[text.ID] == null || optionsArray[text.ID].selectable)) text.alpha = 1;
		}

		descBox.setPosition(descText.x - 10, descText.y - 10);
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();

		curOption = optionsArray[curSelected]; //shorter lol
		callOnCompanionScript('onOptionSelectionChange', [curSelected, getCurrentOption()]);
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function reloadCheckboxes()
		for (checkbox in checkboxGroup)
			checkbox.daValue = Std.string(optionsArray[checkbox.ID].getValue()) == 'true'; //Do not take off the Std.string() from this, it will break a thing in Mod Settings Menu

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
		if (optionsArray == null || name == null) return null;
		for (option in optionsArray)
		{
			if (option == null) continue;
			if (option.name == name || option.variable == name)
				return option;
		}
		return null;
	}

	public function selectOption(index:Int):Void
	{
		if (optionsArray == null || optionsArray.length < 1) return;
		curSelected = FlxMath.wrap(index, 0, optionsArray.length - 1);
		changeSelection(0);
	}

	public function rebuildOptionsVisuals():Void
	{
		if (optionsArray == null)
			optionsArray = [];

		for (i in 0...grpOptions.members.length)
		{
			var item = grpOptions.members[0];
			item.kill();
			grpOptions.remove(item, true);
			item.destroy();
		}
		for (i in 0...grpTexts.members.length)
		{
			var text = grpTexts.members[0];
			text.kill();
			grpTexts.remove(text, true);
			text.destroy();
		}
		for (i in 0...checkboxGroup.members.length)
		{
			var checkbox = checkboxGroup.members[0];
			checkbox.kill();
			checkboxGroup.remove(checkbox, true);
			checkbox.destroy();
		}

		for (i in 0...optionsArray.length)
		{
			var optionText:Alphabet = new Alphabet(safeOffsetX() + 220, 260, optionsArray[i].name, false);
			optionText.isMenuItem = true;
			optionText.targetY = i;
			grpOptions.add(optionText);

			if(optionsArray[i].type == BOOL)
			{
				var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, Std.string(optionsArray[i].getValue()) == 'true');
				checkbox.sprTracker = optionText;
				checkbox.ID = i;
				checkboxGroup.add(checkbox);
			}
			else
			{
				optionText.x -= 80;
				optionText.startPosition.x -= 80;
				var valueText:AttachedText = new AttachedText('' + optionsArray[i].getValue(), optionText.width + 60);
				valueText.sprTracker = optionText;
				valueText.copyAlpha = true;
				valueText.ID = i;
				grpTexts.add(valueText);
				optionsArray[i].child = valueText;
			}
			updateTextFrom(optionsArray[i]);
		}

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
			descText.text = '';
			descBox.setGraphicSize(1, 1);
			descBox.updateHitbox();
		}
		callOnCompanionScript('onRebuildOptionsVisuals', [getOptionsCopy()]);
	}
}
