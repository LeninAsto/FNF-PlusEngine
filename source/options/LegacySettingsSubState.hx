package options;

class LegacySettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = Language.getPhrase('legacy_menu', 'Legacy Settings');
		rpcTitle = 'Legacy Settings Menu';

		var option:Option = new Option('Use Psych Score Text', 'If checked, keeps the original Psych Engine score text format during gameplay.',
			'usePsychScoreText', BOOL);
		addOption(option);

		var option:Option = new Option('Vanilla Transition', 'If checked, uses the vanilla Psych Engine transition instead of the custom one.',
			'vanillaTransition', BOOL);
		addOption(option);

		var option:Option = new Option('Instant Window Close', 'If checked, closing the game exits instantly instead of fading the window out.',
			'instantWindowClose', BOOL);
		addOption(option);

		var option:Option = new Option('Use Psych Freeplay', 'If checked, uses the classic Psych Engine Freeplay state instead of the PlusEngine Freeplay.',
			'usePsychFreeplay', BOOL);
		addOption(option);

		var option:Option = new Option('Script Deprecation Warnings',
			'If checked, deprecated Lua/HScript compatibility APIs will print warnings to the debug console. Disable to silence noisy mods.',
			'scriptDeprecationWarnings', BOOL);
		addOption(option);

		#if MODS_ALLOWED
		var option:Option = new Option('Mod Security',
			'If checked, scans mod Lua/HScript and skips scripts from mods with untrusted sensitive APIs.', 'modSecurityEnabled', BOOL);
		option.onChange = function()
		{
			ClientPrefs.saveSettings();
			backend.ModSecurity.rescanAll();
		};
		addOption(option);
		#end

		var option:Option = new Option('Results State at End', 'If unchecked, endSong will not transition to ResultsState in Freeplay/Story Mode.',
			'resultsStateAtEnd', BOOL);
		addOption(option);

		super();
	}
}

