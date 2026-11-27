package options;

class LegacySettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = Language.getPhrase('options.menus.legacy.title', Language.getPhrase('legacy_menu', 'Legacy Settings'));
		rpcTitle = Language.getPhrase('options.menus.legacy.presence', 'Legacy Settings Menu');

		var option:Option = new Option('FPS Rainbow Color', 'Cycles the FPS counter through rainbow colors.', 'fpsRainbowColor', BOOL);
		option.onChange = function() { if (ClientPrefs.data.fpsRainbowColor) ClientPrefs.data.fpsInterpolateColor = false; };
		addOption(option);

		var option:Option = new Option('FPS Interpolate Color', 'Colors the FPS counter green, orange or red based on performance.', 'fpsInterpolateColor', BOOL);
		option.onChange = function() { if (ClientPrefs.data.fpsInterpolateColor) ClientPrefs.data.fpsRainbowColor = false; };
		addOption(option);

		var option:Option = new Option('Use Psych Score Text', 'If checked, keeps the original Psych Engine score text format during gameplay.',
			'psychScoreText', BOOL);
		addOption(option);

		var option:Option = new Option('Vanilla Transition', 'If checked, uses the vanilla Psych Engine transition instead of the custom one.',
			'vanillaTransition', BOOL);
		addOption(option);

		var option:Option = new Option('Sticker Transition', 'If unchecked, stickers are won\'t show when exit',
		    'stickerTransition', BOOL);
		addOption(option);


        #if (cpp && windows)
		var option:Option = new Option('Instant Window Close', 'If checked, closing the game exits instantly instead of fading the window out.',
			'instantWindowClose', BOOL);
		addOption(option);
		#end

		var option:Option = new Option('Main Menu Style', 'Selects the standard layout or the Plus layout. Plus is opt-in.',
			'mainMenuStyle', STRING, ['Normal', 'Plus']);
		addOption(option);

		var option:Option = new Option('Freeplay Menu Style', 'Selects the classic Freeplay or the Plus layout. Plus is opt-in.',
			'freeplayMenuStyle', STRING, ['Normal', 'Plus']);
		addOption(option);

		var option:Option = new Option('Script Deprecation Warnings',
			'If checked, deprecated Lua/HScript compatibility APIs will print warnings to the debug console. Disable to silence noisy mods.',
			'scriptWarns', BOOL);
		addOption(option);

		var option:Option = new Option('Drag Character',
			'If checked, holding a character with mouse/touch screen will move the position, just like in Codename Engine.', 'cneStyleDragCharacter', BOOL);
		option.onChange = function()
		{
			ClientPrefs.saveSettings();
		};
		addOption(option);

		var option:Option = new Option('Drag Stage Camera',
		    'If unchecked, stage camera cannot be dragged with mouse/touch screen.\nUncheck this if you prefer old Psych style.', 'canDragCameraStage', BOOL);
		option.onChange = function()
		{
			ClientPrefs.saveSettings();
		};
		addOption(option);

		var option:Option = new Option('Results State at End', 'If unchecked, endSong will not transition to ResultsState in Freeplay/Story Mode.',
			'resultsStateAtEnd', BOOL);
		addOption(option);

		super();
	}
}

