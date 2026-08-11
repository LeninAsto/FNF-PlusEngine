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
		backend.VideoSpriteManager,
		objects.hxcodec.v2_5_0.MP4Handler,
		objects.hxcodec.v2_5_0.MP4Sprite,
		objects.hxcodec.v2_6_0.VideoHandler,
		objects.hxcodec.v2_6_0.VideoSprite,
		objects.hxcodec.v3_0_0.FlxVideo,
		objects.hxcodec.v3_0_0.FlxVideoSprite,
		objects.hxcodec.v3_0_0.Video
	];
	private static var warnedLegacyUsages:Map<String, Bool> = new Map();

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
		'ScriptableSubstate' => 'backend.ScriptableSubstate',
		'GameplayChangersSubstate' => 'options.GameplayChangersSubstate',
		'ResultsScreen' => 'states.ResultsState',
		'OptionsState' => 'options.OptionsState',
		'NotesColorSubState' => 'options.NotesColorSubState',
		'NoteOffsetState' => 'options.NoteOffsetState',
		'VisualsSettingsSubState' => 'options.VisualsSettingsSubState',
		'GraphicsSettingsSubState' => 'options.GraphicsSettingsSubState',
		'GameplaySettingsSubState' => 'options.GameplaySettingsSubState',
		// ===== hxCodec / hxvlc compatibility for Psych 0.6.x video scripts =====
		'vlc.MP4Handler' => 'objects.hxcodec.v2_5_0.MP4Handler',
		'vlc.MP4Sprite' => 'objects.hxcodec.v2_5_0.MP4Sprite',
		'vlc.VideoHandler' => 'objects.hxcodec.v2_6_0.VideoHandler',
		'vlc.VideoSprite' => 'objects.hxcodec.v2_6_0.VideoSprite',
		'hxcodec.MP4Handler' => 'objects.hxcodec.v2_5_0.MP4Handler',
		'hxcodec.MP4Sprite' => 'objects.hxcodec.v2_5_0.MP4Sprite',
		'hxcodec.VideoHandler' => 'objects.hxcodec.v2_6_0.VideoHandler',
		'hxcodec.VideoSprite' => 'objects.hxcodec.v2_6_0.VideoSprite',
		'hxcodec.flixel.FlxVideo' => 'objects.hxcodec.v3_0_0.FlxVideo',
		'hxcodec.flixel.FlxVideoSprite' => 'objects.hxcodec.v3_0_0.FlxVideoSprite',
		'hxcodec.flixel.Video' => 'objects.hxcodec.v3_0_0.Video'
	];

	public static final clientPrefsDataAliasMap:Map<String, String> = [
		'downScroll' => 'downScroll',
		'downscroll' => 'downScroll',
		'middleScroll' => 'middleScroll',
		'middlescroll' => 'middleScroll',
		'opponentStrums' => 'opponentStrums',
		'showFPS' => 'showFPS',
		'flashing' => 'flashing',
		'flashingLights' => 'flashing',
		'globalAntialiasing' => 'antialiasing',
		'antialiasing' => 'antialiasing',
		'noteSkin' => 'noteSkin',
		'splashSkin' => 'splashSkin',
		'splashAlpha' => 'splashAlpha',
		'lowQuality' => 'lowQuality',
		'shaders' => 'shaders',
		'shadersEnabled' => 'shaders',
		'cacheOnGPU' => 'cacheOnGPU',
		'framerate' => 'framerate',
		'camZooms' => 'camZooms',
		'cameraZoomOnBeat' => 'camZooms',
		'hideHud' => 'hideHud',
		'noteOffset' => 'noteOffset',
		'arrowHSV' => 'arrowHSV',
		'ghostTapping' => 'ghostTapping',
		'timeBarType' => 'timeBarType',
		'scoreZoom' => 'scoreZoom',
		'noReset' => 'noReset',
		'noResetButton' => 'noReset',
		'healthBarAlpha' => 'healthBarAlpha',
		'hitsoundVolume' => 'hitsoundVolume',
		'pauseMusic' => 'pauseMusic',
		'checkForUpdates' => 'checkForUpdates',
		'comboStacking' => 'comboStacking',
		'gameplaySettings' => 'gameplaySettings',
		'comboOffset' => 'comboOffset',
		'ratingOffset' => 'ratingOffset',
		'sickWindow' => 'sickWindow',
		'goodWindow' => 'goodWindow',
		'badWindow' => 'badWindow',
		'safeFrames' => 'safeFrames',
		'guitarHeroSustains' => 'guitarHeroSustains',
		'discordRPC' => 'discordRPC',
		'language' => 'language'
	];

	public static function resolveClientPrefsDataProperty(className:String, variable:String):String
	{
		if(variable == null || variable.length < 1) return variable;

		var resolvedClass:String = className;
		if(classAliasMap.exists(resolvedClass))
			resolvedClass = classAliasMap.get(resolvedClass);

		if(resolvedClass != 'backend.ClientPrefs' && resolvedClass != 'ClientPrefs')
			return variable;
		if(variable == 'data' || variable.startsWith('data.') || variable.startsWith('defaultData.'))
			return variable;

		var split:Array<String> = variable.split('.');
		if(split.length < 1 || !clientPrefsDataAliasMap.exists(split[0]))
			return variable;

		split[0] = clientPrefsDataAliasMap.get(split[0]);
		var resolvedVariable:String = 'data.' + split.join('.');
		warnLegacyLuaUsage(className + '.' + variable, 'backend.ClientPrefs.' + resolvedVariable);
		return resolvedVariable;
	}

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
				warnLegacyLuaUsage(className, newClassName);
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

	public static function warnLegacyLuaUsage(oldApi:String, newApi:String):Void
	{
		if(oldApi == null || newApi == null || oldApi == newApi) return;

		var owner:String = '';
		#if LUA_ALLOWED
		if(psychlua.FunkinLua.lastCalledScript != null)
			owner = psychlua.FunkinLua.lastCalledScript.scriptName;
		#end
		var key:String = owner + '|' + oldApi + '->' + newApi;
		if(warnedLegacyUsages.exists(key)) return;
		warnedLegacyUsages.set(key, true);

		#if LUA_ALLOWED
		if (psychlua.FunkinLua.getBool('luaDebugMode') && psychlua.FunkinLua.getBool('luaDeprecatedWarnings'))
			psychlua.FunkinLua.luaTrace('Legacy compatibility: "$oldApi" redirects to "$newApi". Use the exact Psych 1.0+ API/path or this mod may fail on vanilla Psych.', false, true, flixel.util.FlxColor.YELLOW);
		#elseif debug
		trace('[Compatibility] "$oldApi" redirects to "$newApi"');
		#end
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

