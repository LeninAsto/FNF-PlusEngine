package options;

import options.Option.OptionType;

class GameplayChangersSubstate extends BaseOptionsMenu
{
	var gameplayOptions:Array<Option> = [];
	var scrollTypeOption:Option;
	var scrollSpeedOption:Option;

	public function new()
	{
		title = Language.getPhrase('gameplay_changers_menu', 'Gameplay Changers');
		rpcTitle = 'Gameplay Changers Menu';
		controls.isInSubstate = true;

		buildGameplayOptions();
		super();
	}

	function buildGameplayOptions():Void
	{
		scrollTypeOption = addGameplayOptionCard('Scroll Type', 'Changes how scroll speed is interpreted.', 'scrolltype', STRING, 'multiplicative',
			["multiplicative", "constant"]);

		scrollSpeedOption = addGameplayOptionCard('Scroll Speed', 'Changes chart scroll speed.', 'scrollspeed', FLOAT, 1);
		scrollSpeedOption.scrollSpeed = 2.0;
		scrollSpeedOption.minValue = 0.35;
		scrollSpeedOption.changeValue = 0.05;
		scrollSpeedOption.decimals = 2;
		configureScrollSpeedOption();

		#if FLX_PITCH
		var option:Option = addGameplayOptionCard('Playback Rate', 'Changes song playback speed.', 'songspeed', FLOAT, 1);
		option.scrollSpeed = 1;
		option.minValue = 0.5;
		option.maxValue = 3.0;
		option.changeValue = 0.05;
		option.displayFormat = '%vX';
		option.decimals = 2;
		#end

		var option:Option = addGameplayOptionCard('Health Gain Multiplier', 'Changes how much health you gain on hits.', 'healthgain', FLOAT, 1);
		option.scrollSpeed = 2.5;
		option.minValue = 0;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';

		option = addGameplayOptionCard('Health Loss Multiplier', 'Changes how much health you lose on misses.', 'healthloss', FLOAT, 1);
		option.scrollSpeed = 2.5;
		option.minValue = 0.5;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';

		addGameplayOptionCard('Instakill on Miss', 'If checked, missing any note instantly kills you.', 'instakill', BOOL, false);
		addGameplayOptionCard('Practice Mode', 'Disables death for practice runs.', 'practice', BOOL, false);
		addGameplayOptionCard('Perfect Mode', 'If checked, any judgement below Sick kills you.', 'perfect', BOOL, false);
		addGameplayOptionCard('Opponent Mode', 'Play the opponent side.', 'opponentplay', BOOL, false);
		addGameplayOptionCard('Opponent Drain', 'Opponent note hits drain player health.', 'opponentdrain', BOOL, false);
		addGameplayOptionCard('No Drop Penalty', "Hold drops don't cause misses.", 'nodroppenalty', BOOL, false);
		addGameplayOptionCard('Botplay', 'Lets the engine play for you.', 'botplay', BOOL, false);
	}

	function addGameplayOptionCard(name:String, description:String, variable:String, type:OptionType, defaultValue:Dynamic, ?values:Array<String>):Option
	{
		var option:Option = new Option(name, description, variable, type, values);
		option.defaultValue = defaultValue;
		option.getValue = function():Dynamic
		{
			return ClientPrefs.data.gameplaySettings.get(variable);
		}
		option.setValue = function(value:Dynamic):Dynamic
		{
			ClientPrefs.data.gameplaySettings.set(variable, value);
			return value;
		}

		if (option.getValue() == null)
			option.setValue(defaultValue);

		if (type == STRING && values != null)
		{
			option.curOption = values.indexOf(option.getValue());
			if (option.curOption < 0)
			{
				option.curOption = 0;
				if (values.length > 0)
					option.setValue(values[0]);
			}
		}

		option.onChange = function()
		{
			if (variable == 'scrolltype')
				configureScrollSpeedOption();
			ClientPrefs.saveSettings();
		}

		gameplayOptions.push(option);
		addOption(option);
		return option;
	}

	function configureScrollSpeedOption():Void
	{
		if (scrollSpeedOption == null || scrollTypeOption == null)
			return;

		if (scrollTypeOption.getValue() == "constant")
		{
			scrollSpeedOption.displayFormat = "%v";
			scrollSpeedOption.maxValue = 6;
		}
		else
		{
			scrollSpeedOption.displayFormat = "%vX";
			scrollSpeedOption.maxValue = 3;
			if (scrollSpeedOption.getValue() > 3)
				scrollSpeedOption.setValue(3);
		}

		if (scrollSpeedOption.child != null)
			updateTextFrom(scrollSpeedOption);
	}

	override function create()
	{
		super.create();
		callOnCompanionScript('onGameplayChangerCreatePost', [getOptionsCopy()]);
	}

	override public function getOptionByName(name:String):Option
	{
		for (option in gameplayOptions)
			if (option != null && (option.name == name || option.variable == name))
				return option;
		return null;
	}

	public function getCurrentGameplayOption():Option
		return getCurrentOption();

	public function getGameplayOptionAt(index:Int):Option
		return (index >= 0 && index < gameplayOptions.length) ? gameplayOptions[index] : null;

	public function addGameplayOption(option:Option):Option
	{
		if (option == null)
			return null;
		gameplayOptions.push(option);
		addOption(option);
		rebuildOptionsVisuals();
		return option;
	}

	public function removeGameplayOption(name:String):Option
	{
		var option = getOptionByName(name);
		if (option == null)
			return null;
		gameplayOptions.remove(option);
		removeOptionByName(option.variable);
		return option;
	}
}
