package backend;

/**
 * Compatibility mapping for old Psych Engine class paths.
 * This allows old mods to work without modification by redirecting old class paths to the current PlusEngine paths.
 * Supports Psych Engine 0.6.3 -> 0.7.3 -> 1.0.4 -> FNF PlusEngine
 */
class StructurePsychOld
{
	// Keep reflection-only compatibility classes from being removed by DCE.
	private static final _compatClassRefs:Array<Class<Dynamic>> = [
		backend.VideoSpriteManager
	];

	/**
	 * Compatibility map for Psych Engine 0.6.3 and older script paths.
	 */
	public static final classAliasMap:Map<String, String> = [
		// ===== Psych 0.6.x / 0.7.x compatibility =====
		'Conductor' => 'backend.Conductor',
		'ClientPrefs' => 'backend.ClientPrefs',
		'Paths' => 'backend.Paths',
		'CoolUtil' => 'backend.CoolUtil',
		'Difficulty' => 'backend.Difficulty',
		'Mods' => 'backend.Mods',
		'Highscore' => 'backend.Highscore',
		'Achievements' => 'backend.Achievements',
		'MusicBeatState' => 'backend.MusicBeatState',
		'MusicBeatSubstate' => 'backend.MusicBeatSubstate',
		'BaseStage' => 'backend.BaseStage',
		'StageData' => 'backend.StageData',
		'WeekData' => 'backend.WeekData',
		'Song' => 'backend.Song',
		'Rating' => 'backend.Rating',
		'Controls' => 'backend.Controls',
		'Discord' => 'backend.DiscordClient',
		'DiscordClient' => 'backend.DiscordClient',
		'Language' => 'backend.Language',
		'Native' => 'backend.Native',
		'PsychCamera' => 'backend.PsychCamera',
		'CustomFadeTransition' => 'backend.CustomFadeTransition',
		'FlxGUtils' => 'backend.FlxGUtils',
		'ALSoftConfig' => 'backend.ALSoftConfig',
		'CrashHandler' => 'backend.CrashHandler',
		'InputFormatter' => 'backend.InputFormatter',
		'NoteTypesConfig' => 'backend.NoteTypesConfig',
		'PlayState' => 'states.PlayState',
		'MainMenuState' => 'states.MainMenuState',
		'FreeplayState' => 'states.FreeplayState',
		'StoryMenuState' => 'states.StoryMenuState',
		'TitleState' => 'states.TitleState',
		'LoadingState' => 'states.LoadingState',
		'CreditsState' => 'states.CreditsState',
		'ModsMenuState' => 'states.ModsMenuState',
		'MasterEditorMenu' => 'states.editors.MasterEditorMenu',
		'CharacterEditorState' => 'states.editors.CharacterEditorState',
		'ChartingState' => 'states.editors.ChartingState',
		'NoteSplashEditorState' => 'states.editors.NoteSplashEditorState',
		'StageEditorState' => 'states.editors.StageEditorState',
		'WeekEditorState' => 'states.editors.WeekEditorState',
		'MenuCharacterEditorState' => 'states.editors.MenuCharacterEditorState',
		'DialogueCharacterEditorState' => 'states.editors.DialogueCharacterEditorState',
		'Alphabet' => 'objects.Alphabet',
		'Character' => 'objects.Character',
		'Note' => 'objects.Note',
		'NoteSplash' => 'objects.NoteSplash',
		'StrumNote' => 'objects.StrumNote',
		'HealthIcon' => 'objects.HealthIcon',
		'BGSprite' => 'objects.BGSprite',
		'AttachedSprite' => 'objects.AttachedSprite',
		'AttachedText' => 'objects.AttachedText',
		'MenuCharacter' => 'objects.MenuCharacter',
		'GameOverSubstate' => 'substates.GameOverSubstate',
		'PauseSubState' => 'substates.PauseSubState',
		'CustomSubstate' => 'psychlua.CustomSubstate',
		'GameplayChangersSubstate' => 'options.GameplayChangersSubstate',
		'ResultsScreen' => 'states.ResultsState',
		'OptionsState' => 'options.OptionsState',
		'NotesColorSubState' => 'options.NotesColorSubState',
		'NoteOffsetState' => 'options.NoteOffsetState',
		'VisualsSettingsSubState' => 'options.VisualsSettingsSubState',
		'GraphicsSettingsSubState' => 'options.GraphicsSettingsSubState',
		'GameplaySettingsSubState' => 'options.GameplaySettingsSubState'
	];

	/**
	 * Resolves a class by name with backwards compatibility support.
	 * @param className The full class path to resolve
	 * @return The resolved class or null if not found
	 */
	public static function resolveClass(className:String):Class<Dynamic>
	{
		var myClass:Dynamic = Type.resolveClass(className);

		// If class not found, try aliases for backwards compatibility
		if (myClass == null && classAliasMap.exists(className))
		{
			var newClassName = classAliasMap.get(className);
			myClass = Type.resolveClass(newClassName);
			if (myClass != null)
			{
				#if debug
				trace('[Compatibility] Redirected "$className" to "$newClassName"');
				#end
			}
			else
			{
				#if debug
				trace('[Compatibility] WARNING: Alias "$className" -> "$newClassName" exists, but target class not found!');
				#end
			}
		}
		else if (myClass == null)
		{
			#if debug
			if (!_warnedClasses.exists(className))
			{
				trace('[Compatibility] WARNING: Class "$className" not found and no alias exists. This may break old mods.');
				trace('[Compatibility] If this is a common class, consider adding it to StructurePsychOld.classAliasMap');
				_warnedClasses.set(className, true);
			}
			#end
		}

		return myClass;
	}

	#if debug
	// Track warned classes to avoid spam
	private static var _warnedClasses:Map<String, Bool> = new Map();

	/**
	 * Get list of all classes that failed to resolve (for debugging)
	 */
	public static function getWarningLog():Array<String>
	{
		var log:Array<String> = [];
		for (className in _warnedClasses.keys())
		{
			log.push(className);
		}
		return log;
	}

	/**
	 * Clear warning log
	 */
	public static function clearWarningLog():Void
	{
		_warnedClasses.clear();
	}
	#end
}

