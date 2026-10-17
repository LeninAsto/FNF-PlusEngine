package options;

import backend.AudioTempo;
import backend.BotplayCPU;
import objects.AttachedText;
import objects.CheckboxThingie;
import options.Option.OptionType;

class GameplayChangersSubstate extends MusicBeatSubstate
{
	private var curSelected:Int = 0;
	private var optionsArray:Array<Dynamic> = [];

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	private var grpTexts:FlxTypedGroup<AttachedText>;

	private var curOption(get, never):GameplayOption;

	function get_curOption()
		return optionsArray[curSelected]; // shorter lol

	function getOptions()
	{
		var goption:GameplayOption = new GameplayOption('Scroll Type', 'scrolltype', STRING, 'multiplicative', ["multiplicative", "constant"]);
		optionsArray.push(goption);

		var option:GameplayOption = new GameplayOption('Scroll Speed', 'scrollspeed', FLOAT, 1);
		option.scrollSpeed = 2.0;
		option.minValue = 0.35;
		option.changeValue = 0.05;
		option.decimals = 2;
		if (goption.getValue() != "constant")
		{
			option.displayFormat = '%vX';
			option.maxValue = 3;
		}
		else
		{
			option.displayFormat = "%v";
			option.maxValue = 6;
		}
		optionsArray.push(option);

		#if FLX_PITCH
		var playbackRateOption:GameplayOption = new GameplayOption('Playback Rate', 'songspeed', FLOAT, 1);
		playbackRateOption.scrollSpeed = 1;
		playbackRateOption.minValue = 0.5;
		playbackRateOption.maxValue = 3.0;
		playbackRateOption.changeValue = 0.05;
		playbackRateOption.displayFormat = '%vX';
		playbackRateOption.decimals = 2;
		optionsArray.push(playbackRateOption);
		var preservePitch = new GameplayOption('Preserve Voice Pitch', 'preservepitch', BOOL, false);
		preservePitch.showCondition = function()
			return cast(playbackRateOption.getValue(), Float) <= AudioTempo.MAX_STABLE_TEMPO;
		playbackRateOption.onChange = function()
		{
			if (cast(playbackRateOption.getValue(), Float) > AudioTempo.MAX_STABLE_TEMPO && preservePitch.getValue() == true)
				preservePitch.setValue(false);
			reloadCheckboxes();
			refreshOptionAlphas();
		};
		if (!preservePitch.isSelectable() && preservePitch.getValue() == true)
			preservePitch.setValue(false);
		optionsArray.push(preservePitch);
		#end

		var option:GameplayOption = new GameplayOption('Health Gain Multiplier', 'healthgain', FLOAT, 1);
		option.scrollSpeed = 2.5;
		option.minValue = 0;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Health Loss Multiplier', 'healthloss', FLOAT, 1);
		option.scrollSpeed = 2.5;
		option.minValue = 0.5;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		optionsArray.push(option);

		optionsArray.push(new GameplayOption('Instakill on Miss', 'instakill', BOOL, false));
		optionsArray.push(new GameplayOption('Practice Mode', 'practice', BOOL, false));
		optionsArray.push(new GameplayOption('Perfect Mode', 'perfect', BOOL, false));
		optionsArray.push(new GameplayOption('Opponent Mode', 'opponentplay', BOOL, false));
		optionsArray.push(new GameplayOption('Opponent Drain', 'opponentdrain', BOOL, false));
		optionsArray.push(new GameplayOption('No Drop Penalty', 'nodroppenalty', BOOL, false));
		var botplay:GameplayOption = new GameplayOption('Botplay', 'botplay', BOOL, false);
		optionsArray.push(botplay);

		var botType:GameplayOption = new GameplayOption('Botplay Type', 'botplayType', STRING, 'Normal', ['Normal', 'CPU']);
		if (botType.options.indexOf(Std.string(botType.getValue())) < 0)
			botType.setValue('Normal');
		botType.showCondition = function() return ClientPrefs.getGameplaySetting('botplay');
		optionsArray.push(botType);

		var cpuProfile:GameplayOption = new GameplayOption('CPU Profile', 'botplayCPUProfile', STRING, 'Skilled', BotplayCPU.PROFILES.copy());
		if (cpuProfile.options.indexOf(Std.string(cpuProfile.getValue())) < 0)
			cpuProfile.setValue(BotplayCPU.normalizeProfile(cpuProfile.getValue()));
		cpuProfile.showCondition = function() return ClientPrefs.getGameplaySetting('botplay')
			&& CoolUtil.botplayType(ClientPrefs.getGameplaySetting('botplayType', 'Normal')) == 'CPU';
		optionsArray.push(cpuProfile);
	}

	public function getOptionByName(name:String)
	{
		for (i in optionsArray)
		{
			var opt:GameplayOption = i;
			// Match against localized display name, internal name or variable identifier
			if (opt.name == name || opt.internalName == name || opt.variableName == name)
				return opt;
		}
		return null;
	}

	public function getOptionsCopy():Array<GameplayOption>
	{
		var result:Array<GameplayOption> = [];
		for (option in optionsArray)
		{
			if (option != null)
				result.push(cast option);
		}
		return result;
	}

	public function new()
	{
		controls.isInSubstate = true;

		super();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		// avoids lagspikes while scrolling through menus!
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		grpTexts = new FlxTypedGroup<AttachedText>();
		add(grpTexts);

		checkboxGroup = new FlxTypedGroup<CheckboxThingie>();
		add(checkboxGroup);

		getOptions();

		for (i in 0...optionsArray.length)
		{
			var optionText:Alphabet = new Alphabet(150, 360, optionsArray[i].name, true);
			optionText.isMenuItem = true;
			optionText.setScale(0.8);
			optionText.targetY = i;
			grpOptions.add(optionText);

			if (optionsArray[i].type == BOOL)
			{
				optionText.x += 60;
				optionText.startPosition.x += 60;
				optionText.snapToPosition();
				var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, optionsArray[i].getValue() == true);
				checkbox.sprTracker = optionText;
				checkbox.offsetX -= 20;
				checkbox.offsetY = -52;
				checkbox.ID = i;
				checkboxGroup.add(checkbox);
			}
			else
			{
				optionText.snapToPosition();
				var valueText:AttachedText = new AttachedText(Std.string(optionsArray[i].getValue()), optionText.width + 40, 0, true, 0.8);
				valueText.sprTracker = optionText;
				valueText.copyAlpha = true;
				valueText.ID = i;
				grpTexts.add(valueText);
				optionsArray[i].setChild(valueText);
			}
			updateTextFrom(optionsArray[i]);
		}

		addTouchPad('LEFT_FULL', 'A_B_C');
		addTouchPadCamera();

		changeSelection();
		reloadCheckboxes();
	}

	override function create()
	{
		super.create();
		callOnCompanionScript('onGameplayChangerCreatePost', [getOptionsCopy()]);
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;

	override function update(elapsed:Float)
	{
		if (controls.UI_UP_P || (touchPad != null && touchPad.buttonUp.justPressed))
			changeSelection(-1);

		if (controls.UI_DOWN_P || (touchPad != null && touchPad.buttonDown.justPressed))
			changeSelection(1);

		if (controls.BACK || (touchPad != null && touchPad.buttonB.justPressed))
		{
			var backStop = callOnCompanionScript('onGameplayChangerBack', [curSelected, curOption]);
			if (backStop == Function_Stop)
				return;
			close();
			ClientPrefs.saveSettings();
			controls.isInSubstate = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if (nextAccept <= 0)
		{
			if (curOption == null)
			{
				// Allow scripted menus to temporarily clear the list without crashing update logic.
			}
			else
			{
				var usesCheckbox:Bool = (curOption.type == BOOL);
				if (usesCheckbox)
				{
					if (controls.ACCEPT || (touchPad != null && touchPad.buttonA.justPressed))
					{
						var acceptStop = callOnCompanionScript('onGameplayChangerAccept', [curSelected, curOption]);
						if (acceptStop == Function_Stop)
							return;
						FlxG.sound.play(Paths.sound('scrollMenu'));
						curOption.setValue((curOption.getValue() == true) ? false : true);
						curOption.change();
						reloadCheckboxes();
					}
				}
				else
				{
					if (controls.UI_LEFT
						|| controls.UI_RIGHT
						|| (touchPad != null && (touchPad.buttonLeft.pressed || touchPad.buttonRight.pressed)))
					{
						var pressed = (controls.UI_LEFT_P
							|| controls.UI_RIGHT_P
							|| (touchPad != null && (touchPad.buttonLeft.justPressed || touchPad.buttonRight.justPressed)));
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

										switch (curOption.type)
										{
											case INT:
												holdValue = Math.round(holdValue);
												curOption.setValue(holdValue);

											case FLOAT, PERCENT:
												holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
												curOption.setValue(holdValue);

											default:
										}

									case STRING:
										var num:Int = curOption.curOption; // lol
										if (controls.UI_LEFT_P)
											--num;
										else
											num++;

										if (num < 0)
											num = curOption.options.length - 1;
										else if (num >= curOption.options.length)
											num = 0;

										curOption.curOption = num;
										curOption.setValue(curOption.options[num]); // lol

										if (curOption.variableName == "scrolltype" || curOption.internalName == "Scroll Type")
										{
											var oOption:GameplayOption = getOptionByName("scrollspeed");
											if (oOption != null)
											{
												if (curOption.getValue() == "constant")
												{
													oOption.displayFormat = "%v";
													oOption.maxValue = 6;
												}
												else
												{
													oOption.displayFormat = "%vX";
													oOption.maxValue = 3;
													if (oOption.getValue() > 3)
														oOption.setValue(3);
												}
												updateTextFrom(oOption);
											}
										}

									default:
								}
								updateTextFrom(curOption);
								curOption.change();
								FlxG.sound.play(Paths.sound('scrollMenu'));
							}
							else if (curOption.type != STRING)
							{
								holdValue = Math.max(curOption.minValue,
									Math.min(curOption.maxValue, holdValue + curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1)));

								switch (curOption.type)
								{
									case INT:
										curOption.setValue(Math.round(holdValue));

									case FLOAT, PERCENT:
										var blah:Float = Math.max(curOption.minValue,
											Math.min(curOption.maxValue, holdValue + curOption.changeValue - (holdValue % curOption.changeValue)));
										curOption.setValue(FlxMath.roundDecimal(blah, curOption.decimals));

									default:
								}
								updateTextFrom(curOption);
								curOption.change();
							}
						}

						if (curOption.type != STRING)
							holdTime += elapsed;
					}
					else if (controls.UI_LEFT_R
						|| controls.UI_RIGHT_R
						|| (touchPad != null && (touchPad.buttonLeft.justReleased || touchPad.buttonRight.justReleased)))
						clearHold();
				}

				if (controls.RESET || (touchPad != null && touchPad.buttonC.justPressed))
				{
					var resetStop = callOnCompanionScript('onGameplayChangerReset', [curSelected, curOption]);
					if (resetStop == Function_Stop)
						return;
					for (i in 0...optionsArray.length)
					{
						var leOption:GameplayOption = optionsArray[i];
						leOption.setValue(leOption.defaultValue);
						if (leOption.type != BOOL)
						{
							if (leOption.type == STRING)
								leOption.curOption = leOption.options.indexOf(leOption.getValue());

							updateTextFrom(leOption);
						}

						if (leOption.variableName == 'scrollspeed' || leOption.internalName == 'Scroll Speed')
						{
							leOption.displayFormat = "%vX";
							leOption.maxValue = 3;
							if (leOption.getValue() > 3)
								leOption.setValue(3);

							updateTextFrom(leOption);
						}
						leOption.change();
					}
					FlxG.sound.play(Paths.sound('cancelMenu'));
					reloadCheckboxes();
				}
			}
		}

		if (nextAccept > 0)
		{
			nextAccept -= 1;
		}

		if (touchPad == null)
		{ // sometimes it dosent add the tpad, hopefully this fixes it
			addTouchPad('LEFT_FULL', 'A_B_C');
			addTouchPadCamera();
		}
		super.update(elapsed);
	}

	function updateTextFrom(option:GameplayOption)
	{
		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();
		if (option.type == PERCENT)
			val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);
	}

	function clearHold()
	{
		if (holdTime > 0.5)
			FlxG.sound.play(Paths.sound('scrollMenu'));

		holdTime = 0;
	}

	function changeSelection(change:Int = 0)
	{
		if (optionsArray == null || optionsArray.length == 0)
			return;

		curSelected = wrapSelectable(curSelected + change, change < 0 ? -1 : 1);
		refreshOptionAlphas();
		callOnCompanionScript('onGameplayChangerSelectionChange', [curSelected, curOption]);
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function refreshOptionAlphas():Void
	{
		if (grpOptions == null || grpTexts == null || checkboxGroup == null)
			return;

		for (num => item in grpOptions.members)
		{
			if (item == null)
				continue;

			item.targetY = num - curSelected;
			item.alpha = optionAlpha(num, item.targetY == 0);
		}
		for (text in grpTexts)
		{
			text.alpha = optionAlpha(text.ID, text.ID == curSelected);
		}
		for (checkbox in checkboxGroup)
		{
			checkbox.alpha = optionAlpha(checkbox.ID, checkbox.ID == curSelected);
		}
	}

	function reloadCheckboxes()
	{
		for (checkbox in checkboxGroup)
		{
			checkbox.daValue = (optionsArray[checkbox.ID].getValue() == true);
		}
	}

	public function getCurrentOption():GameplayOption
		return curOption;

	public function getCurrentOptionIndex():Int
		return curSelected;

	public function getOptionAt(index:Int):GameplayOption
		return (index >= 0 && index < optionsArray.length) ? cast optionsArray[index] : null;

	public function selectOption(index:Int):Void
	{
		if (optionsArray == null || optionsArray.length < 1)
			return;
		curSelected = wrapSelectable(index);
		changeSelection(0);
	}

	public function addGameplayOption(option:GameplayOption):GameplayOption
	{
		if (option == null)
			return null;
		optionsArray.push(option);
		rebuildOptionsVisuals();
		return option;
	}

	public function removeGameplayOption(name:String):GameplayOption
	{
		if (name == null)
			return null;
		for (i in 0...optionsArray.length)
		{
			var option:GameplayOption = cast optionsArray[i];
			if (option == null)
				continue;
			if (option.name == name || option.internalName == name || option.variableName == name)
			{
				var removed = optionsArray.splice(i, 1);
				if (curSelected >= optionsArray.length)
					curSelected = Std.int(Math.max(0, optionsArray.length - 1));
				rebuildOptionsVisuals();
				return removed.length > 0 ? cast removed[0] : null;
			}
		}
		return null;
	}

	public function rebuildOptionsVisuals():Void
	{
		if (grpOptions == null || grpTexts == null || checkboxGroup == null)
			return;

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
			var option:GameplayOption = cast optionsArray[i];
			var optionText:Alphabet = new Alphabet(150, 360, option.name, true);
			optionText.isMenuItem = true;
			optionText.setScale(0.8);
			optionText.targetY = i;
			grpOptions.add(optionText);

			if (option.type == BOOL)
			{
				optionText.x += 60;
				optionText.startPosition.x += 60;
				optionText.snapToPosition();
				var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, option.getValue() == true);
				checkbox.sprTracker = optionText;
				checkbox.offsetX -= 20;
				checkbox.offsetY = -52;
				checkbox.ID = i;
				checkboxGroup.add(checkbox);
			}
			else
			{
				optionText.snapToPosition();
				var valueText:AttachedText = new AttachedText(Std.string(option.getValue()), optionText.width + 40, 0, true, 0.8);
				valueText.sprTracker = optionText;
				valueText.copyAlpha = true;
				valueText.ID = i;
				grpTexts.add(valueText);
				option.setChild(valueText);
			}
			updateTextFrom(option);
		}

		if (optionsArray.length > 0)
		{
			curSelected = wrapSelectable(curSelected);
			changeSelection(0);
			reloadCheckboxes();
		}
		else
		{
			curSelected = 0;
		}

		callOnCompanionScript('onGameplayChangerRebuild', [getOptionsCopy()]);
	}

	function wrapSelectable(index:Int, direction:Int = 1):Int
	{
		if (optionsArray == null || optionsArray.length == 0)
			return 0;

		direction = direction < 0 ? -1 : 1;
		var idx:Int = FlxMath.wrap(index, 0, optionsArray.length - 1);
		for (i in 0...optionsArray.length)
		{
			var check:Int = FlxMath.wrap(idx + (i * direction), 0, optionsArray.length - 1);
			if (optionsArray[check].isSelectable())
				return check;
		}
		return 0;
	}

	function optionAlpha(index:Int, selected:Bool):Float
	{
		var option:GameplayOption = getOptionAt(index);
		if (option == null)
			return 0.6;
		if (!option.isSelectable())
			return 0.32;
		return selected ? 1 : 0.6;
	}
}

class GameplayOption
{
	private var child:Alphabet;

	public var text(get, set):String;
	public var onChange:Void->Void = null; // Pressed enter (on Bool type options) or pressed/held left/right (on other types)
	public var type:OptionType = BOOL;

	public var showBoyfriend:Bool = false;
	public var showCondition:Void->Bool = null;
	public var scrollSpeed:Float = 50; // Only works on int/float, defines how fast it scrolls per second while holding left/right

	private var variable:String = null; // Variable from ClientPrefs.hx's gameplaySettings

	public var defaultValue:Dynamic = null;

	public var curOption:Int = 0; // Don't change this
	public var options:Array<String> = null; // Only used in string type
	public var changeValue:Dynamic = 1; // Only used in int/float/percent type, how much is changed when you PRESS
	public var minValue:Dynamic = null; // Only used in int/float/percent type
	public var maxValue:Dynamic = null; // Only used in int/float/percent type
	public var decimals:Int = 1; // Only used in float/percent type

	public var displayFormat:String = '%v'; // How String/Float/Percent/Int values are shown, %v = Current value, %d = Default value
	public var name:String = 'Unknown';

	public function new(name:String, variable:String, type:OptionType, defaultValue:Dynamic = 'null variable value', ?options:Array<String> = null)
	{
		_name = name;
		this.variable = variable;
		var key = Option.normalizeTranslationKey(variable);
		this.name = Language.getPhrase('options.gameplay_changers.$key.name', Language.getPhrase('setting_$name', name));
		this.type = type;
		this.defaultValue = defaultValue;
		this.options = options;

		if (defaultValue == 'null variable value')
		{
			switch (type)
			{
				case BOOL:
					defaultValue = false;
				case INT, FLOAT:
					defaultValue = 0;
				case PERCENT:
					defaultValue = 1;
				case STRING:
					defaultValue = '';
					if (options.length > 0)
						defaultValue = options[0];

				default:
			}
		}

		if (getValue() == null)
			setValue(defaultValue);

		switch (type)
		{
			case STRING:
				var num:Int = options.indexOf(getValue());
				if (num > -1)
					curOption = num;

			case PERCENT:
				displayFormat = '%v%';
				changeValue = 0.01;
				minValue = 0;
				maxValue = 1;
				scrollSpeed = 0.5;
				decimals = 2;

			default:
		}
	}

	public function change()
	{
		// nothing lol
		if (onChange != null)
			onChange();
	}

	public function getValue():Dynamic
		return ClientPrefs.data.gameplaySettings.get(variable);

	public function setValue(value:Dynamic)
		ClientPrefs.data.gameplaySettings.set(variable, value);

	public function setChild(child:Alphabet)
		this.child = child;

	public function isSelectable():Bool
		return showCondition == null || showCondition();

	// Expose internal name and variable identifier via read-only properties
	public var internalName(get, never):String;

	private function get_internalName():String
		return _name;

	public var variableName(get, never):String;

	private function get_variableName():String
		return variable;

	var _name:String = null;
	var _text:String = null;

	private function get_text()
		return _text;

	private function set_text(newValue:String = '')
	{
		if (child != null)
		{
			_text = newValue;
			var key = Option.normalizeTranslationKey(variable);
			var valueKey = Option.normalizeTranslationKey(_text);
			child.text = Language.getPhrase('options.gameplay_changers.$key.values.$valueKey',
				Language.getPhrase('setting_$_name-$_text', _text));
			return _text;
		}
		return null;
	}
}

