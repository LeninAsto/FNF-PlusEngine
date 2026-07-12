package options;

class GameplaySettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = Language.getPhrase('gameplay_menu', 'Gameplay Settings');
		rpcTitle = 'Gameplay Settings Menu'; //for Discord Rich Presence

		//I'd suggest using "Downscroll" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Downscroll', //Name
			'If checked, notes go Down instead of Up, simple enough.', //Description
			'downScroll', //Save data variable name
			BOOL); //Variable type
		addOption(option);

		var option:Option = new Option('Middlescroll',
			'If checked, your notes get centered.',
			'middleScroll',
			BOOL);
		addOption(option);

		var option:Option = new Option('Opponent Notes',
			'If unchecked, opponent notes get hidden.',
			'opponentStrums',
			BOOL);
		addOption(option);

		var option:Option = new Option('Ghost Tapping',
			"If checked, you won't get misses from pressing keys\nwhile there are no notes able to be hit.",
			'ghostTapping',
			BOOL);
		addOption(option);
		
		var option:Option = new Option('Bad and Shit Break Combo',
			"If checked, hitting Bad or Shit notes will break your combo\nand count as Combo Breaks instead of just Misses.",
			'badShitBreakCombo',
			BOOL);
		addOption(option);
		
		var option:Option = new Option('Auto Pause',
			"If checked, the game automatically pauses if the screen isn't on focus.",
			'autoPause',
			BOOL);
		addOption(option);
		option.onChange = onChangeAutoPause;

		var option:Option = new Option('Pop Up Score',
			"If unchecked, hitting notes won't make \"sick\", \"good\".. and combo popups\n(Useful for low end " + Main.platform + ").",
			'popUpRating',
			BOOL);
		addOption(option);

		var option:Option = new Option('Disable Reset Button',
			"If checked, pressing Reset won't do anything.",
			'noReset',
			BOOL);
		addOption(option);

		#if mobile
		var option:Option = new Option('Game Over Vibration',
			"If checked, your device will vibrate at game over.",
			'gameOverVibration',
			BOOL);
		addOption(option);
		option.onChange = onChangeVibration;
		#end
		
		var option:Option = new Option('Sustains as One Note',
			"If checked, Hold Notes can't be pressed if you miss,\nand count as a single Hit/Miss.\nUncheck this if you prefer the old Input System.",
			'guitarHeroSustains',
			BOOL);
		addOption(option);

		var option:Option = new Option('Hitsound in what way',
			'If checked, note and keys do a hitsound when pressed!, else just when notes are hit!',
			'hitsoundType',
			STRING,
			['None', 'Keys', 'Notes']);
		addOption(option);
		
		var option:Option = new Option('Hitsound Volume',
			'Funny notes does \"Tick!\" when you hit them.',
			'hitsoundVolume',
			PERCENT);
		addOption(option);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = onChangeHitsoundVolume;

		var option:Option = new Option('Hitsound',
			'Funny notes does \"Any Sound\" when you hit them.',
			'hitSounds',
			STRING,
			['None', 'quaver', 'osu', 'clap', 'camellia', 'stepmania', '21st century humor', 'vine boom', 'sexus']);
		addOption(option);
		option.onChange = onChangeHitsound;

		var option:Option = new Option('Rating Offset',
			'Changes how late/early you have to hit for a "flawless!!"\nHigher values mean you have to hit later.',
			'ratingOffset',
			INT);
		option.displayFormat = '%vms';
		option.scrollSpeed = 20;
		option.minValue = -30;
		option.maxValue = 30;
		addOption(option);

		var option:Option = new Option('Flawless!! Hit Window',
			'Changes the amount of time you have\nfor hitting a "Flawless!!" in milliseconds.',
			'flawlessWindow',
			FLOAT);
		option.displayFormat = '%vms';
		option.scrollSpeed = 5;
		option.minValue = 15.0;
		option.maxValue = 25.0;
		option.changeValue = 0.1;
		addOption(option);

		var option:Option = new Option('Sick! Hit Window',
			'Changes the amount of time you have\nfor hitting a "Sick!" in milliseconds.',
			'sickWindow',
			FLOAT);
		option.displayFormat = '%vms';
		option.scrollSpeed = 15;
		option.minValue = 15.0;
		option.maxValue = 45.0;
		option.changeValue = 0.1;
		addOption(option);

		var option:Option = new Option('Good Hit Window',
			'Changes the amount of time you have\nfor hitting a "Good" in milliseconds.',
			'goodWindow',
			FLOAT);
		option.displayFormat = '%vms';
		option.scrollSpeed = 30;
		option.minValue = 15.0;
		option.maxValue = 90.0;
		option.changeValue = 0.1;
		addOption(option);

		var option:Option = new Option('Bad Hit Window',
			'Changes the amount of time you have\nfor hitting a "Bad" in milliseconds.',
			'badWindow',
			FLOAT);
		option.displayFormat = '%vms';
		option.scrollSpeed = 60;
		option.minValue = 15.0;
		option.maxValue = 135.0;
		option.changeValue = 0.1;
		addOption(option);

		var option:Option = new Option('Safe Frames',
			'Changes how many frames you have for\nhitting a note earlier or late.',
			'safeFrames',
			FLOAT);
		option.scrollSpeed = 5;
		option.minValue = 2;
		option.maxValue = 10;
		option.changeValue = 0.1;
		addOption(option);

		var option:Option = new Option('Accuracy System',
			"Choose the accuracy calculation system:\nWife3 - StepMania precision timing\nPsych - Rating mod based\nSimple - Basic hits/total\nosu!mania - Weighted judgement system\nDJMAX - Combo bonus system\nITG - Dance Points system\n\n",
			'accuracySystem',
			STRING,
			['Wife3', 'Psych', 'Simple', 'osu!mania', 'DJMAX', 'ITG']);
		addOption(option);

		var option:Option = new Option('System Score Multiplier',
			"Choose the scoring system for note hits",
			'systemScoreMultiplier',
			STRING,
			['Psych', 'Codename']); // No V-Slice here :frowning_face:
		addOption(option);

		super();
	}

	var daHitSound:FlxSound = new FlxSound();

	function onChangeHitsound()
	{
		if (ClientPrefs.data.hitSounds != "None" && ClientPrefs.data.hitsoundVolume != 0)
		{
			daHitSound.loadEmbedded(Paths.sound('hitsounds/${ClientPrefs.data.hitSounds}'));
			daHitSound.volume = ClientPrefs.data.hitsoundVolume;
			daHitSound.play();
		}
	}

	function onChangeHitsoundVolume()
	{
		if (ClientPrefs.data.hitSounds != "None")
		{
			daHitSound.loadEmbedded(Paths.sound('hitsounds/${ClientPrefs.data.hitSounds}'));
			daHitSound.volume = ClientPrefs.data.hitsoundVolume;
			daHitSound.play();
		}
		else
			FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.data.hitsoundVolume);
	}

	function onChangeAutoPause()
		FlxG.autoPause = ClientPrefs.data.autoPause;

	function onChangeVibration()
	{
		if(ClientPrefs.data.gameOverVibration)
			lime.ui.Haptic.vibrate(0, 500);
	}
}
