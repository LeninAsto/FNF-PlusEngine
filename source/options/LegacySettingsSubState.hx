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

		var option:Option = new Option('Legacy Memory Management',
			'If checked, keeps more cached assets around like older Psych versions. Safer for old mods, heavier on RAM.',
			'legacyMemoryManagement',
			BOOL);
		addOption(option);

		var option:Option = new Option('Legacy File System Access',
			'If checked, prefers raw filesystem reads for directory scans and old mod layouts.',
			'legacyFileSystemAccess',
			BOOL);
		addOption(option);

		var option:Option = new Option('Legacy Shader Init',
			'If checked, keeps shader setup closer to old Psych behavior instead of auto-adapting shader code.',
			'legacyShaderInit',
			BOOL);
		addOption(option);

		#if !mobile
		var option:Option = new Option('Scriptable Custom States',
			'If checked, lets mods override states through ScriptableState and CustomState.',
			'useScriptableCustomStates',
			BOOL);
		addOption(option);
		#end

		super();
	}
}
