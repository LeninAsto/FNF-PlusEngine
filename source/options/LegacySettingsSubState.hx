package options;

class LegacySettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = Language.getPhrase('legacy_menu', 'Legacy Settings');
		rpcTitle = 'Legacy Settings Menu';

		var option:Option = new Option('Use Psych Score Text',
			'If checked, keeps the original Psych Engine score text format during gameplay.',
			'usePsychScoreText',
			BOOL);
		addOption(option);

		var option:Option = new Option('Vanilla Transition',
		    'If checked, uses the vanilla Psych Engine transition instead of the custom one.',
			'vanillaTransition',
			BOOL);
		addOption(option);

		var option:Option = new Option('Lower Volume When Window Loses Focus',
			'If checked, lowers the game volume while the window is not focused.',
			'lowerVolumeOnFocusLost',
			BOOL);
		addOption(option);

		var option:Option = new Option('Use Psych Freeplay',
			'If checked, uses the classic Psych Engine Freeplay state instead of the PlusEngine Freeplay.',
			'usePsychFreeplay',
			BOOL);
		addOption(option);

		#if !mobile
		var option:Option = new Option('Scriptable Custom States',
			'If checked, lets mods override states through ScriptableState and CustomState.',
			'useScriptableCustomStates',
			BOOL);
		addOption(option);
		#end

		var option:Option = new Option('Drag Character To Move',
		    'If checked, the character position can be dragged with the cursor, just like in Codename Engine.',
			'dragCharacterToMove',
			BOOL);
		option.onChange = function()
		{
			ClientPrefs.saveSettings();
		};
		addOption(option);

		var option:Option = new Option('Results State at End',
		    'If unchecked, endSong will not transition to ResultsState in Freeplay/Story Mode.',
			'resultsStateAtEnd',
			BOOL);
		addOption(option);

		super();
	}
}
