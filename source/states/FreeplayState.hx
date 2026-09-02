package states;

import backend.StageData;
import backend.AssetLoader;
import backend.WeekData;
import backend.Highscore;
import backend.Song;
import objects.HealthIcon;
import objects.MusicPlayer;
import options.GameplayChangersSubstate;
import options.OptionsMenuTheme;
import substates.ResetScoreSubState;
import backend.ui.md3.MD3ShapeTools;
import backend.ui.md3.MaterialTextField;
import backend.ui.md3.MaterialWavyProgressIndicator;
import backend.ui.md3.MaterialWavyProgressIndicator.WavyProgressType;
import flixel.math.FlxMath;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxDestroyUtil;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.utils.AssetType;
import openfl.utils.Assets;
#if funkin.vis
import funkin.vis.dsp.SpectralAnalyzer;
#end
#if (target.threaded && sys)
import sys.thread.Mutex;
import backend.ThreadUtil;
#end
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
#end
#if mobile
import mobile.backend.StorageUtil;
#end
import haxe.Json;

class FreeplayState extends MusicBeatState
{
	public static var instance:FreeplayState;

	public var songs:Array<SongMetadata> = [];

	public var selector:FlxText;
	public var pendingSong:String = null;

	public static var curSelected:Int = 0;

	public var lerpSelected:Float = 0;
	public var curDifficulty:Int = -1;

	private static var lastDifficultyName:String = Difficulty.getDefault();

	// scoreText eliminado - ahora se muestra debajo de cada dificultad
	public var lerpScore:Int = 0;
	public var lerpRating:Float = 0;
	public var intendedScore:Int = 0;
	public var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<FlxText>;
	private var songTextArray:Array<FlxText> = [];
	private var cardGroup:FlxTypedGroup<FlxSprite>;
	private var cardAccentGroup:FlxTypedGroup<FlxSprite>;
	private var iconGroup:FlxTypedGroup<HealthIcon>;
	private var modTextGroup:FlxTypedGroup<FlxText>;
	private var curPlaying:Bool = false;
	private var searchField:MaterialTextField;
	private var songSearchQuery:String = "";
	private var songInfoCardBg:FlxSprite;
	private var songInfoAlbumBg:FlxSprite;
	private var songInfoCardCover:FlxSprite;
	private var songInfoCardTitle:FlxText;
	private var songInfoCardStats:FlxText;
	private var songInfoCardDifficulty:FlxText;
	private var songInfoCardScores:FlxText;
	private var songInfoPlatformIcons:Array<FlxSprite> = [];
	private var songInfoLicenseIcons:Array<FlxSprite> = [];
	private var songInfoLicenseText:FlxText;
	private var songInfoCardLoadingLabel:FlxText;
	private var songInfoCardSpinner:MaterialWavyProgressIndicator;
	private var songInfoCardY:Float = 0;
	private var songInfoCardHiddenY:Float = 0;
	private var songInfoCardShownY:Float = 0;
	private var songInfoCardTween:FlxTween = null;
	private var songInfoCardLoadTimer:FlxTimer = null;
	private var songInfoCardLoadToken:Int = 0;

	private static var roundedImageCache:Map<String, FlxGraphic> = [];

	private var songInfoCardLoading:Bool = false;
	private var songInfoCardData:FreeplaySongCardData = null;
	private var songInfoPlatformLinks:Array<String> = [];
	private var songInfoCardCache:Map<String, FreeplaySongCardData> = new Map<String, FreeplaySongCardData>();
	private var songInfoCardCacheOrder:Array<String> = [];

	private static var songMetaCache:Map<String, FreeplaySongMeta> = new Map<String, FreeplaySongMeta>();

	private var selectedSongDataTimer:FlxTimer = null;
	private var selectedSongDataLoadToken:Int = 0;

	private var iconArray:Array<HealthIcon> = [];

	public var bg:FlxSprite;
	public var bgTransition:FlxSprite;
	public var intendedColor:Int;

	var bgSwapTimer:FlxTimer = null;
	var bgFadeTweenIn:FlxTween = null;
	var bgFadeTweenOut:FlxTween = null;
	var currentBgSignature:String = null;
	var pendingBgSignature:String = null;

	static inline var BG_SWAP_DELAY:Float = 1.0;

	public var missingTextBG:FlxSprite;
	public var missingText:FlxText;
	public var missingTextTween:FlxTween = null;
	public var missingTextShownX:Float = 48;
	public var missingTextHiddenX:Float = -470;
	public var missingTextCardY:Float = 0;

	public var bottomString:String;
	public var bottomText:FlxText;

	public var player:MusicPlayer;

	var freeplayTouchInputBlockTime:Float = 0;

	public var inDifficultySelect:Bool = false;
	public var difficultySelector:DifficultySelector;
	public var songsOffsetX:Float = 0;

	public var blackOverlay:FlxSprite;
	public var layerFree:FlxSprite;
	public var cardArray:Array<FlxSprite> = [];
	public var cardAccentArray:Array<FlxSprite> = [];
	public var modTextArray:Array<FlxText> = [];
	public var freeplayText:FlxText;
	public var lastThemeSignature:String = "";

	// Opponent Mode toggle
	public static var viewingOpponentScores:Bool = false;

	public var opponentModeText:FlxText;

	// Variables para el zoom del bg
	public var bgZoom:Float = 1;
	public var defaultBgZoom:Float = 1;

	// Full-width bottom spectral visualizer bars
	public var vizBarsGroup:FlxTypedGroup<FlxSprite>;

	#if funkin.vis
	public var _analyzer:SpectralAnalyzer = null;
	public var _analyzerLevels:Array<funkin.vis.dsp.SpectralAnalyzer.Bar> = null;
	public var _needsAnalyzerInit:Bool = false;
	public var _vizMusicRef:FlxSound = null;
	public var _vizBeatPulse:Float = 0;
	#end
	#if (target.threaded && sys)
	public var _pendingInstSound:openfl.media.Sound = null;
	public var _pendingInstToken:Int = 0;
	public var _pendingInstIndex:Int = -1;
	public var _pendingInstBpm:Float = 102;
	public var _instLoadMutex:Mutex = new Mutex();
	public var _pendingSongCardData:FreeplaySongCardData = null;
	public var _pendingSongCardToken:Int = 0;
	public var _pendingSongCardIndex:Int = -1;
	public var _songCardMutex:Mutex = new Mutex();
	#end
	public var _prevInstSongName:String = null;
	public var currentBPM:Float = 102;
	public var previewTimer:FlxTimer = null;
	public var previewLoadToken:Int = 0;
	public var previewLoadTimer:FlxTimer = null;

	private var currentPreviewStartMs:Float = 0;
	private var currentPreviewEndMs:Float = 0;

	static inline var SELECTED_DATA_LOAD_DELAY:Float = 1.0;
	static inline var PREVIEW_LOAD_DELAY:Float = 0.12;
	static inline var SONG_INFO_CARD_CACHE_LIMIT:Int = 32;
	static inline var SONG_INFO_CARD_WIDTH:Int = 402;
	static inline var SONG_INFO_ALBUM_SIZE:Int = 224;
	static inline var SONG_INFO_COVER_SIZE:Int = 184;
	static inline var SONG_INFO_CARD_GAP:Int = 16;
	static inline var SONG_INFO_DATA_HEIGHT:Int = 330;
	static inline var SONG_INFO_CARD_HEIGHT:Int = 570;
	static inline var SONG_INFO_SOCIAL_ICON_SIZE:Int = 24;
	static inline var SONG_INFO_LICENSE_ICON_SIZE:Int = 32;
	static final FREEPLAY_LINK_PLATFORMS:Array<String> = [
		'audius',
		'bandcamp',
		'bluesky',
		'buymeacoffe',
		'discord',
		'facebook',
		'instagram',
		'ko-fi',
		'newgrounds',
		'patreon',
		'soundcloud',
		'spotify',
		'tiktok',
		'x',
		'youtube',
		'yt-music'
	];
	public static var instSound:FlxSound = null;

	#if mobile
	static inline var VIZ_BAR_COUNT:Int = 56;
	#else
	static inline var VIZ_BAR_COUNT:Int = 88;
	#end

	public static inline var VIZ_BAR_MAX_H:Int = 150;
	public static inline var VIZ_BAR_FILL:Float = 0.62;
	public static inline var VIZ_MIN_H:Int = 2;
	public static inline var VIZ_SMOOTH_SPEED:Float = 18;
	public static inline var VIZ_UPDATE_INTERVAL:Float = 1 / 60;

	public var _curAccentColor:Int = 0xFFB566FF;
	public var _vizCurrentHeights:Array<Float> = [];
	public var _vizTargetHeights:Array<Float> = [];
	public var _vizUpdateAccum:Float = 0;

	var _cardVisualSignatures:Array<String> = [];

	#if (MODS_ALLOWED && sys && !mobile)
	var droppedModPath:String = null;
	#end

	function getSelectedSongModFolder():String
	{
		if (songs == null || curSelected < 0 || curSelected >= songs.length || songs[curSelected] == null)
			return null;

		var modFolder:String = songs[curSelected].folder;
		if (modFolder == null || modFolder.length == 0 || songs[curSelected].isStepMania)
			return null;
		return modFolder;
	}

	function getFreeplayBackgroundSignature(?songIndex:Int = -1):String
	{
		if (songIndex < 0)
			songIndex = curSelected;

		if (songs == null || songIndex < 0 || songIndex >= songs.length || songs[songIndex] == null)
			return 'default';

		var modFolder:String = songs[songIndex].isStepMania ? null : songs[songIndex].folder;
		if (modFolder == null || modFolder.length == 0)
			return 'default';
		return modFolder;
	}

	function resolveFreeplayBackgroundGraphic(?songIndex:Int = -1):FlxGraphic
	{
		if (songIndex < 0)
			songIndex = curSelected;

		var bgGraphic:FlxGraphic = null;
		var signature = getFreeplayBackgroundSignature(songIndex);
		if (signature != 'default')
			bgGraphic = Paths.image('menuDesat', signature);
		if (bgGraphic == null)
			bgGraphic = Paths.image('menuDesat');
		return bgGraphic;
	}

	function applyFreeplayBackgroundGraphic(target:FlxSprite, bgGraphic:FlxGraphic):Void
	{
		if (target == null || bgGraphic == null)
			return;

		target.loadGraphic(bgGraphic);
		target.antialiasing = ClientPrefs.data.antialiasing;
		target.setGraphicSize(FlxG.width, FlxG.height);
		target.updateHitbox();
		target.origin.set(target.frameWidth * 0.5, target.frameHeight * 0.5);
		centerScaledFreeplayBackground(target);
	}

	inline function centerScaledFreeplayBackground(target:FlxSprite):Void
	{
		if (target == null || target.graphic == null)
			return;

		target.x = (FlxG.width - target.frameWidth) * 0.5;
		target.y = (FlxG.height - target.frameHeight) * 0.5;
	}

	function loadSelectedFreeplayBackground(?force:Bool = false):Void
	{
		if (bg == null)
			return;

		var signature = getFreeplayBackgroundSignature();
		if (!force && signature == currentBgSignature)
			return;

		var bgGraphic = resolveFreeplayBackgroundGraphic();
		if (bgGraphic == null)
			return;

		applyFreeplayBackgroundGraphic(bg, bgGraphic);
		bg.alpha = 1;
		bg.visible = true;
		if (bgTransition != null)
		{
			bgTransition.alpha = 0;
			bgTransition.visible = false;
		}
		currentBgSignature = signature;
		pendingBgSignature = null;
	}

	function queueSelectedFreeplayBackgroundSwap():Void
	{
		pendingBgSignature = getFreeplayBackgroundSignature();
		if (pendingBgSignature == currentBgSignature)
		{
			if (bgSwapTimer != null)
				bgSwapTimer.cancel();
			return;
		}

		if (bgSwapTimer != null)
			bgSwapTimer.cancel();

		if (bgSwapTimer == null)
			bgSwapTimer = new FlxTimer();
		bgSwapTimer.start(BG_SWAP_DELAY, function(_:FlxTimer)
		{
			performSelectedFreeplayBackgroundSwap();
		});
	}

	function performSelectedFreeplayBackgroundSwap():Void
	{
		if (bg == null || bgTransition == null)
			return;

		var signature = getFreeplayBackgroundSignature();
		if (signature == currentBgSignature || signature != pendingBgSignature)
			return;

		var bgGraphic = resolveFreeplayBackgroundGraphic();
		if (bgGraphic == null)
			return;

		applyFreeplayBackgroundGraphic(bgTransition, bgGraphic);
		bgTransition.color = intendedColor;
		bgTransition.alpha = 0;
		bgTransition.visible = true;

		if (bgFadeTweenIn != null)
			bgFadeTweenIn.cancel();
		if (bgFadeTweenOut != null)
			bgFadeTweenOut.cancel();

		bgFadeTweenOut = FlxTween.tween(bg, {alpha: 0}, 0.35, {ease: FlxEase.quadOut});
		bgFadeTweenIn = FlxTween.tween(bgTransition, {alpha: 1}, 0.35, {
			ease: FlxEase.quadOut,
			onComplete: function(_:FlxTween)
			{
				var previousBg = bg;
				bg = bgTransition;
				bgTransition = previousBg;
				bg.alpha = 1;
				bg.visible = true;
				bgTransition.alpha = 0;
				bgTransition.visible = false;
				currentBgSignature = signature;
				pendingBgSignature = null;
				bgFadeTweenIn = null;
				bgFadeTweenOut = null;
			}
		});
	}

	function refreshVizBarsLayout():Void
	{
		if (vizBarsGroup == null)
			return;

		var vizBarW:Int = Std.int(FlxG.width / VIZ_BAR_COUNT);
		var vizDrawW:Int = Std.int(Math.max(1, vizBarW * VIZ_BAR_FILL));
		var vizOffsetX:Float = (vizBarW - vizDrawW) * 0.5;

		for (i in 0...vizBarsGroup.members.length)
		{
			var vbar = vizBarsGroup.members[i];
			if (vbar == null)
				continue;

			vbar.x = i * vizBarW + vizOffsetX;
			vbar.y = FlxG.height - Math.max(VIZ_MIN_H, _vizCurrentHeights[i]);
			vbar.visible = true;
			vbar.alpha = 1.0;
		}
	}

	function ensureSongVisual(index:Int):Void
	{
		if (index < 0
			|| index >= songs.length
			|| songs[index] == null
			|| songs[index].songName == null
			|| songs[index].songName == "")
			return;
		if (index < songTextArray.length && songTextArray[index] != null)
			return;

		if (songTextArray.length < songs.length)
			songTextArray.resize(songs.length);
		if (iconArray.length < songs.length)
			iconArray.resize(songs.length);
		if (cardArray.length < songs.length)
			cardArray.resize(songs.length);
		if (cardAccentArray.length < songs.length)
			cardAccentArray.resize(songs.length);
		if (modTextArray.length < songs.length)
			modTextArray.resize(songs.length);
		if (_cardVisualSignatures.length < songs.length)
			_cardVisualSignatures.resize(songs.length);

		var card:FlxSprite = new FlxSprite();
		var meta:FreeplaySongMeta = loadSongMeta(songs[index]);
		var songKey:String = Paths.formatToSongPath(songs[index].songName);
		var listCardKey:String = meta != null && meta.cardKey != null ? meta.cardKey : 'albumRoll/cards/$songKey';
		var customListCard:FlxGraphic = getOptionalSongImage(listCardKey, songs[index]);
		if (loadRoundedGraphic(card, customListCard, 470, 110, 22, 'listCard:$listCardKey'))
		{
			card.updateHitbox();
			_cardVisualSignatures[index] = 'custom:$listCardKey';
		}
		else
		{
			var darkestColor = FlxColor.interpolate(songs[index].color, FlxColor.BLACK, 0.5);
			MD3ShapeTools.fillAndStrokeRoundRect(card, 470, 110, 22, 2, darkestColor, OptionsMenuTheme.cardStroke(false));
		}
		card.antialiasing = ClientPrefs.data.antialiasing;
		card.visible = false;
		cardArray[index] = card;
		cardGroup.add(card);

		var accentBar:FlxSprite = new FlxSprite();
		MD3ShapeTools.fillRoundRect(accentBar, 10, 84, 5);
		accentBar.visible = false;
		cardAccentArray[index] = accentBar;
		cardAccentGroup.add(accentBar);

		var songText:FlxText = new FlxText(90, 320, 400, songs[index].songName, 32);
		songText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		songText.borderSize = 2;
		songText.ID = index;
		songText.visible = songText.active = false;
		songTextArray[index] = songText;
		grpSongs.add(songText);

		var previousModDirectory:String = Mods.currentModDirectory;
		if (!songs[index].isStepMania)
			Mods.currentModDirectory = songs[index].folder;

		var characterName = songs[index].songCharacter;
		if (characterName == null || characterName == "")
			characterName = songs[index].isStepMania ? "stepmania" : "bf";

		var icon:HealthIcon = new HealthIcon(characterName);
		icon.scale.set(0.8, 0.8);
		icon.visible = icon.active = false;
		iconArray[index] = icon;
		iconGroup.add(icon);
		Mods.currentModDirectory = previousModDirectory;

		var modName:String = songs[index].folder;
		if (modName == null || modName == '')
			modName = songs[index].isStepMania ? "StepMania" : "Friday Night Funkin";

		var modText:FlxText = new FlxText(0, 0, 430, modName, 16);
		modText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		modText.borderSize = 1.5;
		modText.alpha = 0.7;
		modText.visible = false;
		modTextArray[index] = modText;
		modTextGroup.add(modText);
	}

	override function create()
	{
		// Paths.clearStoredMemory();
		// Paths.clearUnusedMemory();
		roundedImageCache = [];
		FlxG.mouse.visible = true;

		instance = this;
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		final accept:String = (controls.mobileC) ? "A" : "ACCEPT";
		final reject:String = (controls.mobileC) ? "B" : "BACK";

		if (WeekData.weeksList.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(backend.ScriptableState.tryCreate('ErrorState',
				new states.ErrorState("NO WEEKS ADDED FOR FREEPLAY\n\nPress " + accept + " to go to the Week Editor Menu.\nPress " + reject
					+ " to return to Main Menu.",
					function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
					function() MusicBeatState.switchState(backend.ScriptableState.tryCreate('MainMenuState', new states.MainMenuState())))));
			return;
		}

		for (i in 0...WeekData.weeksList.length)
		{
			if (weekIsLocked(WeekData.weeksList[i]))
				continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				// Skip erect variant songs as they will be shown as difficulties
				var songName:String = song[0].toLowerCase();
				if (songName.endsWith('-erect'))
					continue;

				var colors:Array<Int> = song[2];
				if (colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		Mods.loadTopMod();

		// Cargar archivos StepMania (.sm)
		loadStepManiaFiles();

		bg = new FlxSprite();
		bgTransition = new FlxSprite();
		add(bg);
		add(bgTransition);
		loadSelectedFreeplayBackground(true);
		bgZoom = defaultBgZoom = 1;

		blackOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		blackOverlay.alpha = 0.1;
		add(blackOverlay);

		vizBarsGroup = new FlxTypedGroup<FlxSprite>();

		var vizBarW:Int = Std.int(FlxG.width / VIZ_BAR_COUNT);
		var vizDrawW:Int = Std.int(Math.max(1, vizBarW * VIZ_BAR_FILL));
		var vizOffsetX:Float = (vizBarW - vizDrawW) * 0.5;

		for (i in 0...VIZ_BAR_COUNT)
		{
			var vbar:FlxSprite = new FlxSprite();
			vbar.makeGraphic(vizDrawW, 1, FlxColor.WHITE);
			vbar.origin.set(0, 0);
			vbar.x = i * vizBarW + vizOffsetX;
			vbar.y = FlxG.height - VIZ_MIN_H;
			vbar.alpha = 0.7;
			vbar.scale.y = VIZ_MIN_H;
			vbar.visible = true;

			vizBarsGroup.add(vbar);
		}
		_vizCurrentHeights.resize(VIZ_BAR_COUNT);
		_vizTargetHeights.resize(VIZ_BAR_COUNT);
		for (i in 0...VIZ_BAR_COUNT)
		{
			_vizCurrentHeights[i] = VIZ_MIN_H;
			_vizTargetHeights[i] = VIZ_MIN_H;
		}

		add(vizBarsGroup);
		layerFree = new FlxSprite().loadGraphic(Paths.image('ui/layerfree'));
		layerFree.antialiasing = ClientPrefs.data.antialiasing;
		layerFree.setGraphicSize(FlxG.width, FlxG.height);
		layerFree.updateHitbox();
		layerFree.alpha = 0.5;
		add(layerFree);
		vizBarsGroup.visible = true;
		OptionsMenuTheme.syncAccent();
		lastThemeSignature = OptionsMenuTheme.signature();
		cardGroup = new FlxTypedGroup<FlxSprite>();
		add(cardGroup);
		cardAccentGroup = new FlxTypedGroup<FlxSprite>();
		add(cardAccentGroup);
		grpSongs = new FlxTypedGroup<FlxText>();
		add(grpSongs);
		modTextGroup = new FlxTypedGroup<FlxText>();
		add(modTextGroup);
		iconGroup = new FlxTypedGroup<HealthIcon>();
		add(iconGroup);
		songTextArray.resize(songs.length);
		iconArray.resize(songs.length);
		cardArray.resize(songs.length);
		cardAccentArray.resize(songs.length);
		modTextArray.resize(songs.length);
		_cardVisualSignatures.resize(songs.length);
		WeekData.setDirectoryFromWeek();

		// Eliminar scoreText de la esquina ya que ahora se mostrará debajo de cada dificultad
		// scoreText ya no se usa

		freeplayText = new FlxText(0, 0, 0, "FREEPLAY", 40);
		freeplayText.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE, CENTER);
		freeplayText.borderSize = 0;
		freeplayText.updateHitbox();
		freeplayText.x = FlxG.width * 0.41;
		freeplayText.y = 15;
		add(freeplayText);

		searchField = new MaterialTextField(FlxG.width - 238, 12, 206, Language.getPhrase("new_freeplay_search", "Search..."));
		searchField.helperText = "Press B to focus, ESC to exit";
		searchField.onChange = function(value:String)
		{
			updateSongFilter(value);
		};
		add(searchField);
		createSongInfoCard();

		// Opponent Mode indicator
		opponentModeText = new FlxText(FlxG.width * 0.68, 5, 0, "", 20);
		opponentModeText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.YELLOW, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		opponentModeText.borderSize = 1.5;
		opponentModeText.visible = false;
		add(opponentModeText);

		missingTextCardY = Math.max(90, (FlxG.height * 0.5) - 120);
		missingTextBG = new FlxSprite(missingTextHiddenX, missingTextCardY);
		MD3ShapeTools.fillAndStrokeRoundRect(missingTextBG, 430, 220, 24, 3, OptionsMenuTheme.cardFill(false), OptionsMenuTheme.cardStroke(true));
		missingTextBG.alpha = 0.96;
		missingTextBG.visible = false;
		add(missingTextBG);

		missingText = new FlxText(missingTextHiddenX + 20, missingTextCardY + 20, 390, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.borderSize = 2;
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		if (curSelected >= songs.length)
			curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;
		for (i in 0...vizBarsGroup.members.length)
		{
			var bar = vizBarsGroup.members[i];
			var lightBar = FlxColor.interpolate(intendedColor, FlxColor.WHITE, 0.3);
			if (bar != null)
				bar.color = lightBar;
		}
		lerpSelected = curSelected;

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		final space:String = (controls.mobileC) ? "X" : "SPACE";
		final control:String = (controls.mobileC) ? "C" : "CTRL";
		final reset:String = (controls.mobileC) ? "Y" : "RESET";

		var leText:String = Language.getPhrase("new_freeplay_tip",
			"Press {1} to listen to the Song / Press {2} to open the Gameplay Changers Menu / Press {3} to Reset your Score and Accuracy.",
			[space, control, reset]);
		#if (MODS_ALLOWED && sys && !mobile)
		leText += " / F5 reloads mods / drop a mod folder to import it.";
		#end
		bottomString = leText;
		var size:Int = 16;
		bottomText = new FlxText(5, FlxG.height - 50, FlxG.width - 10, leText, size);
		bottomText.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, CENTER);
		bottomText.wordWrap = true;
		bottomText.alignment = CENTER;
		bottomText.scrollFactor.set();
		bottomText.y = FlxG.height - bottomText.height - 4;
		add(bottomText);

		player = new MusicPlayer(this);
		add(player);

		difficultySelector = new DifficultySelector();
		add(difficultySelector.cards);
		add(difficultySelector.items);
		add(difficultySelector.scoreTexts);

		#if funkin.vis
		_needsAnalyzerInit = true;
		#end
		Conductor.bpm = 102;

		changeSelection();
		updateTexts();

		super.create();

		#if (MODS_ALLOWED && sys && !mobile)
		FlxG.stage.window.onDropFile.add(onDropFile);
		#end

		addTouchPad('UP_DOWN', 'A_B_C_X_Y_Z');
		addTouchPadCamera();
		if (touchPad != null)
		{
			touchPad.visible = true;
			touchPad.updateTrackedButtons();
		}
		freeplayTouchInputBlockTime = 0.12;
	}

	override function closeSubState()
	{
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
		removeTouchPad();
		addTouchPad('UP_DOWN', 'A_B_C_X_Y_Z');
		addTouchPadCamera();
		if (touchPad != null)
		{
			touchPad.visible = true;
			touchPad.updateTrackedButtons();
		}
		freeplayTouchInputBlockTime = 0.12;
	}

	inline function touchActionReleased(button:Dynamic):Bool
	{
		return freeplayTouchInputBlockTime <= 0 && button != null && button.justReleased;
	}

	function hideMissingCard(?instant:Bool = false):Void
	{
		if (missingTextTween != null)
		{
			missingTextTween.cancel();
			missingTextTween = null;
		}

		if (instant)
		{
			missingTextBG.x = missingTextHiddenX;
			missingText.x = missingTextHiddenX + 28;
			missingText.visible = false;
			missingTextBG.visible = false;
			return;
		}

		if (!missingText.visible && !missingTextBG.visible)
			return;

		missingTextTween = FlxTween.tween(missingTextBG, {x: missingTextHiddenX}, 0.22, {
			ease: FlxEase.expoIn,
			onUpdate: function(_)
			{
				missingText.x = missingTextBG.x + 28;
			},
			onComplete: function(_)
			{
				missingText.visible = false;
				missingTextBG.visible = false;
				missingText.x = missingTextHiddenX + 28;
				missingTextTween = null;
			}
		});
	}

	function updateMissingCardLayout(message:String):Void
	{
		final displayText = 'No chart is available for this difficulty.';
		missingText.text = displayText;
		missingText.wordWrap = false;
		if (missingText.textField != null)
			missingText.textField.autoSize = openfl.text.TextFieldAutoSize.LEFT;

		final textField = missingText.textField;
		final textW:Int = Std.int(Math.ceil((textField != null ? textField.textWidth : missingText.width) + 1));
		final textH:Int = Std.int(Math.ceil((textField != null ? textField.textHeight : missingText.height) + 1));
		final padX:Int = 28;
		final padY:Int = 28;
		final cardW:Int = Std.int(Math.max(360, textW + padX * 2));
		final cardH:Int = Std.int(Math.max(120, textH + padY * 2));

		missingTextHiddenX = -cardW - 40;
		missingTextCardY = Math.max(90, (FlxG.height * 0.5) - (cardH * 0.5));
		missingTextBG.y = missingTextCardY;
		MD3ShapeTools.fillAndStrokeRoundRect(missingTextBG, cardW, cardH, 24, 3, OptionsMenuTheme.cardFill(false), OptionsMenuTheme.cardStroke(true));
		missingTextBG.x = missingTextHiddenX;
		missingTextBG.visible = true;
		missingText.visible = true;
		missingText.fieldWidth = cardW - padX * 2;
		missingText.x = missingTextBG.x + padX;
		missingText.y = missingTextCardY + padY - 2;
	}

	function showMissingCard(message:String):Void
	{
		if (missingTextTween != null)
		{
			missingTextTween.cancel();
			missingTextTween = null;
		}

		updateMissingCardLayout(message);

		missingTextTween = FlxTween.tween(missingTextBG, {x: missingTextShownX}, 0.28, {
			ease: FlxEase.expoOut,
			onUpdate: function(_)
			{
				missingText.x = missingTextBG.x + 28;
			},
			onComplete: function(_)
			{
				missingTextTween = null;
			}
		});
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function songMatchesFilter(song:SongMetadata, queryLower:String):Bool
	{
		if (song == null || queryLower == null || queryLower.length == 0)
			return true;

		var songName:String = song.songName != null ? song.songName.toLowerCase() : "";
		var folderName:String = song.folder != null ? song.folder.toLowerCase() : "";
		var characterName:String = song.songCharacter != null ? song.songCharacter.toLowerCase() : "";
		var smFolderName:String = song.smFolder != null ? song.smFolder.toLowerCase() : "";

		return songName.contains(queryLower) || folderName.contains(queryLower) || characterName.contains(queryLower) || smFolderName.contains(queryLower);
	}

	function updateSongFilter(value:String):Void
	{
		songSearchQuery = StringTools.trim(value != null ? value : "");

		if (songSearchQuery.length > 0)
		{
			var query:String = songSearchQuery.toLowerCase();
			var matchedIndex:Int = -1;

			for (i in 0...songs.length)
			{
				if (songMatchesFilter(songs[i], query))
				{
					matchedIndex = i;
					break;
				}
			}

			if (matchedIndex != -1 && matchedIndex != curSelected)
			{
				curSelected = matchedIndex;
				lerpSelected = curSelected;
				changeSelection(0, false);
			}
		}

		queueSelectedSongDataLoad();
		updateTexts();
	}

	function updateCurrentBpmFromSelection():Void
	{
		if (songs == null || songs.length == 0 || curSelected < 0 || curSelected >= songs.length)
		{
			currentBPM = 102;
			Conductor.bpm = currentBPM;
			return;
		}

		var selectedSong:SongMetadata = songs[curSelected];
		var resolvedBpm:Float = 102;

		try
		{
			if (selectedSong != null && selectedSong.isStepMania)
			{
				#if sys
				var smDiffName:String = (selectedSong.smDifficulties != null && selectedSong.smDifficulties.length > 0) ? Paths.formatToSongPath(selectedSong.smDifficulties[Std.int(FlxMath.bound(curDifficulty,
					0, selectedSong.smDifficulties.length
					- 1))]) : 'normal';
				var smDir:String = #if mobile StorageUtil.getSMDirectory() #else './sm/' #end;
				var smPath:String = smDir + selectedSong.smFolder + '/' + smDiffName + '.json';
				var rawJson:String = AssetLoader.loadText(smPath);
				if (rawJson != null && rawJson.length > 0)
				{
					var chart:SwagSong = Song.parseJSON(rawJson, selectedSong.songName);
					if (chart != null && chart.bpm > 0)
						resolvedBpm = chart.bpm;
				}
				#end
			}
			else
			{
				var songKey:String = Paths.formatToSongPath(selectedSong.songName);
				var chartName:String = Highscore.formatSong(songKey, curDifficulty);
				var chart:SwagSong = Song.getChart(chartName, songKey);
				if (chart != null && chart.bpm > 0)
					resolvedBpm = chart.bpm;
			}
		}
		catch (e:Dynamic)
		{
			trace('[FreePlay] BPM resolve failed: $e');
		}

		currentBPM = resolvedBpm;
		Conductor.bpm = currentBPM;
	}

	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked
			&& leWeek.weekBefore.length > 0
			&& (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	var instPlaying:Int = -1;

	public static var vocals:FlxSound = null;
	public static var opponentVocals:FlxSound = null;

	var holdTime:Float = 0;

	var stopMusicPlay:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (freeplayTouchInputBlockTime > 0)
			freeplayTouchInputBlockTime -= elapsed;

		var searchFocused:Bool = searchField != null && searchField.focused;

		if (searchFocused && FlxG.keys.justPressed.ESCAPE)
		{
			searchField.blur();
			updateTexts(elapsed);
			return;
		}

		if (searchField != null && searchField.escapeConsumed)
		{
			searchField.escapeConsumed = false;
			updateTexts(elapsed);
			return;
		}

		if (handleSongInfoLinkMouse())
		{
			updateTexts(elapsed);
			return;
		}
		enforceSongPreviewWindow();

		#if (target.threaded && sys)
		// Dispatch a pending inst sound loaded by the background thread.
		// playMusic() and all OpenAL calls must happen on the main thread.
		_instLoadMutex.acquire();
		var pendingSound:openfl.media.Sound = _pendingInstSound;
		var pendingToken:Int = _pendingInstToken;
		var pendingIndex:Int = _pendingInstIndex;
		var pendingBpm:Float = _pendingInstBpm;
		if (pendingSound != null)
			_pendingInstSound = null;
		_instLoadMutex.release();

		if (pendingSound != null && pendingToken == previewLoadToken && pendingIndex == curSelected)
		{
			try
			{
				// Register in Paths cache so it gets cleaned up correctly later
				var cacheKey:String = getInstPreviewCacheKey(songs[pendingIndex]);
				if (cacheKey != null && cacheKey.length > 0)
				{
					if (!Paths.currentTrackedSounds.exists(cacheKey))
						Paths.currentTrackedSounds.set(cacheKey, pendingSound);
					Paths.localTrackedAssets.push(cacheKey);
				}

				FlxG.sound.playMusic(pendingSound, 0, true);
				applySongPreviewStart(songs[pendingIndex]);
				FlxG.sound.music.fadeIn(1.0, 0, 0.7);
				instSound = FlxG.sound.music;
				instPlaying = pendingIndex;

				if (songInfoCardData != null && pendingIndex == curSelected && songInfoCardData.durationMs <= 0 && pendingSound.length > 0)
				{
					songInfoCardData.durationMs = pendingSound.length;
					if (songInfoCardStats != null)
						songInfoCardStats.text = formatSongInfoStats(songInfoCardData);
				}

				Conductor.bpm = pendingBpm;

				#if funkin.vis
				_analyzer = null;
				_analyzerLevels = null;
				_needsAnalyzerInit = true;
				#end
			}
			catch (e:Dynamic)
			{
				trace('[FreePlay] Error playing async-loaded inst: $e');
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7);
			}
		}
		#end

		#if (target.threaded && sys)
		_songCardMutex.acquire();
		var pendingCard:FreeplaySongCardData = _pendingSongCardData;
		var pendingCardToken:Int = _pendingSongCardToken;
		var pendingCardIndex:Int = _pendingSongCardIndex;
		if (pendingCard != null)
			_pendingSongCardData = null;
		_songCardMutex.release();

		if (pendingCard != null && pendingCardToken == songInfoCardLoadToken && pendingCardIndex == curSelected)
		{
			applySongInfoCardData(pendingCard);
		}
		#end

		// Full-width bottom spectral visualizer bars — driven exclusively by SpectralAnalyzer.
		#if funkin.vis
		if (FlxG.sound.music != _vizMusicRef)
		{
			_vizMusicRef = FlxG.sound.music;
			_analyzer = null;
			_analyzerLevels = null;
			_needsAnalyzerInit = _vizMusicRef != null;
		}

		// Lazy-init: attach to FlxG.sound.music as soon as __audioSource is ready.
		// Both inst preview and freeplay bg music go through FlxG.sound.music now.
		if (_needsAnalyzerInit && FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			@:privateAccess
			if (FlxG.sound.music._channel != null && FlxG.sound.music._channel.__audioSource != null)
			{
				_analyzer = new SpectralAnalyzer(FlxG.sound.music._channel.__audioSource, VIZ_BAR_COUNT, 0.08, 25);
				_analyzer.minFreq = 40;
				_analyzer.maxFreq = 18000;
				_analyzer.minDb = -80;
				_analyzer.maxDb = -15;
				#if mobile
				_analyzer.fftN = 256;
				#elseif !web
				_analyzer.fftN = 512;
				#end
				_needsAnalyzerInit = false;
			}
		}
		_vizUpdateAccum += elapsed;
		if (vizBarsGroup != null)
		{
			var vizBarW:Int = Std.int(FlxG.width / VIZ_BAR_COUNT);
			var vizOffsetX:Float = (vizBarW - Std.int(Math.max(1, vizBarW * VIZ_BAR_FILL))) * 0.5;

			if (_vizUpdateAccum >= VIZ_UPDATE_INTERVAL)
			{
				_vizUpdateAccum = 0;
				if (_analyzer != null)
				{
					_analyzerLevels = _analyzer.getLevels(_analyzerLevels);
					for (i in 0...vizBarsGroup.members.length)
					{
						var level:Float = (i < _analyzerLevels.length) ? _analyzerLevels[i].value : 0.0;
						var bandPos:Float = vizBarsGroup.members.length > 1 ? i / (vizBarsGroup.members.length - 1) : 0;
						var lowBias:Float = 1.0 - bandPos;
						var highBias:Float = bandPos;
						var rhythmicPulse:Float = 0.72 + (0.28 * Math.abs(Math.sin((Conductor.songPosition * (0.004 + bandPos * 0.003)) + (i * 0.11))));
						var shapedLevel:Float = Math.pow(Math.max(0, level), 0.78);
						var spectralH:Float = shapedLevel * VIZ_BAR_MAX_H;
						var bandEmphasis:Float = (spectralH * (0.55 + lowBias * 0.30 + highBias * 0.15)) + (rhythmicPulse * (12 + highBias * 18));
						_vizTargetHeights[i] = Math.max(VIZ_MIN_H, bandEmphasis);
					}
				}
				else
				{
					_vizBeatPulse = Math.max(0, _vizBeatPulse - elapsed * 1.8);
					for (i in 0...vizBarsGroup.members.length)
					{
						var bandPos:Float = vizBarsGroup.members.length > 1 ? i / (vizBarsGroup.members.length - 1) : 0;
						var wave:Float = Math.abs(Math.sin((Conductor.songPosition * (0.003 + bandPos * 0.0025)) + (i * 0.29)));
						var fallbackH:Float = VIZ_MIN_H + 6 + (wave * (18 + bandPos * 32)) + (_vizBeatPulse * (12 + bandPos * 10));
						_vizTargetHeights[i] = Math.max(VIZ_MIN_H, fallbackH);
					}
				}
			}

			var lerpFactor:Float = 1 - Math.exp(-elapsed * VIZ_SMOOTH_SPEED);
			for (i in 0...vizBarsGroup.members.length)
			{
				var vbar = vizBarsGroup.members[i];
				if (vbar == null)
					continue;

				var curH:Float = _vizCurrentHeights[i];
				var targetH:Float = _vizTargetHeights[i];
				curH = FlxMath.lerp(targetH, curH, 1 - lerpFactor);
				_vizCurrentHeights[i] = curH;

				vbar.scale.y = Math.max(1, curH);
				// vbar.x is set once at create() — vizBarW/vizOffsetX are constants
				vbar.y = FlxG.height - Math.max(VIZ_MIN_H, curH);
				vbar.alpha = 1.0;
				vbar.visible = true;
				var colorMix:Float = 0.28 + (0.22 * (i / Math.max(1, vizBarsGroup.members.length - 1)));
				vbar.color = FlxColor.interpolate(intendedColor, FlxColor.WHITE, colorMix);
			}
		}
		#end

		if (songs.length < 1)
			return;

		if (FlxG.sound.music == null)
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7, true);

		if (FlxG.sound.music == null)
			return;

		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * elapsed;

		Conductor.songPosition = FlxG.sound.music.time;

		bgZoom = FlxMath.lerp(defaultBgZoom, bgZoom, Math.exp(-elapsed * 3.125));
		bg.scale.set(bgZoom, bgZoom);
		centerScaledFreeplayBackground(bg);
		if (bgTransition != null)
		{
			bgTransition.scale.set(bgZoom, bgZoom);
			centerScaledFreeplayBackground(bgTransition);
		}

		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
		lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingPercent:Float = CoolUtil.floorDecimal(lerpRating * 100, 2);
		var ratingSplit:Array<String> = Std.string(Math.abs(ratingPercent)).split('.');
		if (ratingSplit.length < 2) // No decimals, add an empty space
			ratingSplit.push('');

		while (ratingSplit[1].length < 2) // Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';

		var ratingDisplay:String = ratingSplit.join('.');
		if (ratingPercent < 0)
			ratingDisplay = '-' + ratingDisplay;

		var shiftMult:Int = 1;
		if ((FlxG.keys.pressed.SHIFT || (touchPad != null && touchPad.buttonZ.pressed)) && !player.playingMusic)
			shiftMult = 3;

		if (!searchFocused && !player.playingMusic)
		{
			// scoreText ya no se muestra, los scores se muestran debajo de cada dificultad

			if (!inDifficultySelect)
			{
				if (songs.length > 1)
				{
					if (FlxG.keys.justPressed.HOME)
					{
						curSelected = 0;
						changeSelection();
						holdTime = 0;
					}
					else if (FlxG.keys.justPressed.END)
					{
						curSelected = songs.length - 1;
						changeSelection();
						holdTime = 0;
					}
					if (controls.UI_UP_P || (touchPad != null && touchPad.buttonUp.justPressed))
					{
						changeSelection(-shiftMult);
						holdTime = 0;
					}
					if (controls.UI_DOWN_P || (touchPad != null && touchPad.buttonDown.justPressed))
					{
						changeSelection(shiftMult);
						holdTime = 0;
					}

					if (controls.UI_DOWN
						|| controls.UI_UP
						|| (touchPad != null && (touchPad.buttonDown.pressed || touchPad.buttonUp.pressed)))
					{
						var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
						holdTime += elapsed;
						var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

						if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						{
							var isUp:Bool = controls.UI_UP || (touchPad != null && touchPad.buttonUp.pressed);
							changeSelection((checkNewHold - checkLastHold) * (isUp ? -shiftMult : shiftMult));
						}
					}
					if (FlxG.mouse.wheel != 0)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
						changeSelection(-shiftMult * FlxG.mouse.wheel, false);
					}
				}
			}
			else
			{
				if (controls.UI_UP_P || (touchPad != null && touchPad.buttonUp.justPressed))
				{
					changeDifficultySelection(-1);
				}
				if (controls.UI_DOWN_P || (touchPad != null && touchPad.buttonDown.justPressed))
				{
					changeDifficultySelection(1);
				}
			}
		}

		// Toggle between normal and opponent mode scores
		if (!searchFocused && FlxG.keys.justPressed.TAB && !player.playingMusic)
		{
			viewingOpponentScores = !viewingOpponentScores;
			FlxG.sound.play(Paths.sound('scrollMenu'));

			// Update scores with new mode
			#if !switch
			intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty, viewingOpponentScores);
			intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty, viewingOpponentScores);
			#end

			// Update UI
			if (viewingOpponentScores)
			{
				opponentModeText.text = "[OPPONENT MODE]";
				opponentModeText.visible = true;
			}
			else
			{
				opponentModeText.visible = false;
			}

			if (songInfoCardData != null)
				applySongInfoCardData(songInfoCardData);
		}

		if (!searchFocused && FlxG.keys.justPressed.B && !player.playingMusic && searchField != null)
		{
			searchField.focus();
		}

		if (!searchFocused && (controls.BACK || (touchPad != null && touchActionReleased(touchPad.buttonB))))
		{
			if (player.playingMusic)
			{
				FlxG.sound.music.stop();
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				instPlaying = -1;

				player.playingMusic = false;
				player.switchPlayMusic();

				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
				FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
			}
			else if (inDifficultySelect)
			{
				exitDifficultySelect();
			}
			else
			{
				persistentUpdate = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				stopInstPreview(false);
				destroyFreeplayVocals();
				FlxG.sound.music.stop();
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7, true);
				stopMusicPlay = true;
				MusicBeatState.switchState(backend.ScriptableState.tryCreate('MainMenuState', new MainMenuState()));
			}
		}

		if (!searchFocused
			&& (FlxG.keys.justPressed.CONTROL || (touchPad != null && touchActionReleased(touchPad.buttonC)))
			&& !player.playingMusic)
		{
			persistentUpdate = false;
			removeTouchPad();
			openSubState(backend.ScriptableSubstate.tryCreate('GameplayChangersSubstate', new GameplayChangersSubstate()));
		}
		if (!searchFocused && (FlxG.keys.justPressed.SPACE || (touchPad != null && touchActionReleased(touchPad.buttonX))))
		{
			if (instPlaying != curSelected && !player.playingMusic)
			{
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;

				Mods.currentModDirectory = songs[curSelected].folder;

				// Load all available difficulties for this song before loading the chart
				Difficulty.loadFromWeek();
				detectAndLoadAllDifficulties();

				// Make sure curDifficulty is within bounds
				if (curDifficulty >= Difficulty.list.length)
					curDifficulty = 0;

				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				if (PlayState.SONG == null)
				{
					showMissingCard('No chart is available for this difficulty!');
					return;
				}
				if (PlayState.SONG.needsVoices)
				{
					vocals = new FlxSound();
					try
					{
						var playerVocals:String = getVocalFromCharacter(PlayState.SONG.player1);
						var loadedVocals = Paths.voices(PlayState.SONG.song, (playerVocals != null && playerVocals.length > 0) ? playerVocals : 'Player');
						if (loadedVocals == null)
							loadedVocals = Paths.voices(PlayState.SONG.song);

						if (loadedVocals != null && loadedVocals.length > 0)
						{
							vocals.loadEmbedded(loadedVocals);
							FlxG.sound.list.add(vocals);
							vocals.persist = vocals.looped = true;
							vocals.volume = 0.8;
							vocals.play();
							vocals.pause();
						}
						else
							vocals = FlxDestroyUtil.destroy(vocals);
					}
					catch (e:Dynamic)
					{
						vocals = FlxDestroyUtil.destroy(vocals);
					}

					opponentVocals = new FlxSound();
					try
					{
						// trace('please work...');
						var oppVocals:String = getVocalFromCharacter(PlayState.SONG.player2);
						var loadedVocals = Paths.voices(PlayState.SONG.song, (oppVocals != null && oppVocals.length > 0) ? oppVocals : 'Opponent');

						if (loadedVocals != null && loadedVocals.length > 0)
						{
							opponentVocals.loadEmbedded(loadedVocals);
							FlxG.sound.list.add(opponentVocals);
							opponentVocals.persist = opponentVocals.looped = true;
							opponentVocals.volume = 0.8;
							opponentVocals.play();
							opponentVocals.pause();
							// trace('yaaay!!');
						}
						else
							opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
					}
					catch (e:Dynamic)
					{
						// trace('FUUUCK');
						opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
					}
				}
				FlxG.sound.music.pause();
				instPlaying = curSelected;

				player.playingMusic = true;
				player.curTime = 0;
				player.switchPlayMusic();
				player.pauseOrResume(true);
			}
			else if (instPlaying == curSelected && player.playingMusic)
			{
				player.pauseOrResume(!player.playing);
			}
		}
		else if (!searchFocused
			&& (controls.ACCEPT || (touchPad != null && touchActionReleased(touchPad.buttonA)))
			&& !player.playingMusic)
		{
			if (!inDifficultySelect)
			{
				enterDifficultySelect();
			}
			else
			{
				persistentUpdate = false;

				var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
				var poop:String = Highscore.formatSong(songLowercase, difficultySelector.curSelected);

				try
				{
					// Para canciones de StepMania, cargar desde la carpeta ./sm/
					if (songs[curSelected].isStepMania)
					{
						#if MODS_ALLOWED
						// Obtener el nombre de la dificultad del .sm usando el índice actual
						var smDiffIndex:Int = difficultySelector.curSelected;
						if (smDiffIndex < 0 || smDiffIndex >= songs[curSelected].smDifficulties.length)
						{
							throw 'Invalid difficulty index: $smDiffIndex';
						}

						var smDiffName:String = Paths.formatToSongPath(songs[curSelected].smDifficulties[smDiffIndex]);

						// Buscar el archivo JSON en la carpeta sm usando el nombre de dificultad del .sm
						#if mobile
						var smDir = StorageUtil.getSMDirectory();
						#else
						var smDir = './sm/';
						#end
						var smPath:String = smDir + songs[curSelected].smFolder + '/' + smDiffName + '.json';
						trace('Loading SM chart from: $smPath');

						var rawJson:String = AssetLoader.loadText(smPath);
						if (rawJson != null && rawJson.length > 0)
						{
							PlayState.SONG = Song.parseJSON(rawJson, songLowercase);
							if (PlayState.SONG == null)
								throw 'SM chart failed to parse: $smPath';
							Song.loadedSongName = songLowercase;
							Song.chartPath = smPath;

							// Establecer la ruta de audio personalizada para StepMania
							#if mobile
							PlayState.customAudioPath = StorageUtil.getSMDirectory() + songs[curSelected].smFolder + '/';
							#else
							PlayState.customAudioPath = './sm/' + songs[curSelected].smFolder + '/';
							#end

							StageData.loadDirectory(PlayState.SONG);
						}
						else
						{
							throw 'SM chart file not found: $smPath';
						}
						#else
						throw 'StepMania support requires MODS_ALLOWED';
						#end
					}
					else
					{
						PlayState.customAudioPath = null; // Limpiar ruta personalizada
						Song.loadFromJson(poop, songLowercase);
						if (PlayState.SONG == null)
							throw 'Chart failed to load: $poop';
					}

					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = difficultySelector.curSelected;

					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
				}
				catch (e:haxe.Exception)
				{
					trace('ERROR! ${e.message}');

					var errorStr:String = e.message;
					if (errorStr.contains('There is no TEXT asset with an ID of')
						|| errorStr.contains('Invalid difficulty index')
						|| errorStr.contains('chart file not found'))
						errorStr = 'No chart is available for this difficulty!';
					else
						errorStr += '\n\n' + e.stack;

					showMissingCard(errorStr);
					FlxG.sound.play(Paths.sound('cancelMenu'));

					updateTexts(elapsed);
					return;
				}
				@:privateAccess
				if (PlayState._lastLoadedModDirectory != Mods.currentModDirectory)
				{
					trace('CHANGED MOD DIRECTORY, RELOADING STUFF');
					Paths.freeGraphicsFromMemory();
				}
				LoadingState.prepareToSong();
				LoadingState.returnState = FreeplayStateSelector.create(); // Establecer estado de retorno
				LoadingState.loadAndSwitchState(new PlayState());
				#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
				stopMusicPlay = true;
				destroyFreeplayVocals();
				#if (MODS_ALLOWED && DISCORD_ALLOWED)
				DiscordClient.loadModRPC();
				#end
			}
		}
		else if (!searchFocused && (controls.RESET || (touchPad != null && touchActionReleased(touchPad.buttonY))) && !player.playingMusic)
		{
			persistentUpdate = false;
			removeTouchPad();
			openSubState(backend.ScriptableSubstate.tryCreate('ResetScoreSubState',
				new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter)));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		#if (MODS_ALLOWED && sys && !mobile)
		if (!searchFocused && !player.playingMusic && FlxG.keys.justPressed.F5)
		{
			reloadModsFromFreeplay();
			return;
		}
		#end

		updateSongInfoCardLayout();
		updateTexts(elapsed);
	}

	function getVocalFromCharacter(char:String)
	{
		try
		{
			var path:String = Paths.getPath('characters/$char.json', TEXT);
			var rawText:String = AssetLoader.loadText(path);
			if (rawText == null || rawText.length == 0)
				return null;
			var character:Dynamic = Json.parse(rawText);
			return character.vocals_file;
		}
		catch (e:Dynamic)
		{
		}
		return null;
	}

	public static function destroyFreeplayVocals()
	{
		if (vocals != null)
			vocals.stop();
		vocals = FlxDestroyUtil.destroy(vocals);

		if (opponentVocals != null)
			opponentVocals.stop();
		opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
	}

	function changeDiff(change:Int = 0)
	{
		if (player.playingMusic)
			return;

		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length - 1);
		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty, viewingOpponentScores);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty, viewingOpponentScores);
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty, false);

		hideMissingCard(true);
	}

	function enterDifficultySelect()
	{
		inDifficultySelect = true;
		FlxG.sound.play(Paths.sound('scrollMenu'));
		hideSongInfoCard();

		difficultySelector.loadDifficulties();
		if (Difficulty.list == null || Difficulty.list.length == 0)
			Difficulty.list = ['Normal'];
		curDifficulty = Std.int(FlxMath.bound(curDifficulty, 0, Difficulty.list.length - 1));
		difficultySelector.curSelected = curDifficulty;
		difficultySelector.lerpSelected = curDifficulty;

		FlxTween.tween(this, {songsOffsetX: -1000}, 0.3, {ease: FlxEase.expoOut});
		FlxTween.tween(blackOverlay, {alpha: 0.6}, 1.0, {ease: FlxEase.sineInOut});
		FlxTween.tween(difficultySelector, {enterProgress: 1}, 0.4, {ease: FlxEase.expoOut, startDelay: 0.1});
	}

	function exitDifficultySelect()
	{
		FlxG.sound.play(Paths.sound('cancelMenu'));

		FlxTween.tween(difficultySelector, {enterProgress: 0}, 0.25, {
			ease: FlxEase.expoIn,
			onComplete: function(twn:FlxTween)
			{
				inDifficultySelect = false;
				difficultySelector.items.clear();
				difficultySelector.cards.clear();
			}
		});

		FlxTween.tween(this, {songsOffsetX: 0}, 0.3, {ease: FlxEase.expoOut});
		FlxTween.tween(blackOverlay, {alpha: 0.1}, 1.0, {ease: FlxEase.sineInOut});
		showSongInfoCard();
	}

	function changeDifficultySelection(change:Int = 0)
	{
		difficultySelector.changeSelection(change);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, difficultySelector.curSelected, viewingOpponentScores);
		intendedRating = Highscore.getRating(songs[curSelected].songName, difficultySelector.curSelected, viewingOpponentScores);
		#end

		// Actualizar textos de score cuando cambia la selección
		difficultySelector.updateScoreTexts();
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (player.playingMusic)
			return;

		hideMissingCard();

		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length - 1);
		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		queueSelectedFreeplayBackgroundSwap();

		var newColor:Int = songs[curSelected].color;
		if (newColor != intendedColor)
		{
			intendedColor = newColor;
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 1, bg.color, intendedColor);
			for (bar in 0...vizBarsGroup.members.length)
			{
				var vizBar:FlxSprite = vizBarsGroup.members[bar];
				var lightBar = FlxColor.interpolate(intendedColor, FlxColor.WHITE, 0.3);
				if (vizBar == null)
					continue;
				FlxTween.cancelTweensOf(vizBar);
				if (vizBar != null)
					FlxTween.color(vizBar, 1, vizBar.color, lightBar);
			}
		}

		// Para canciones de StepMania, no cambiar el directorio de mod
		if (!songs[curSelected].isStepMania)
		{
			Mods.currentModDirectory = songs[curSelected].folder;
		}
		else
		{
			Mods.currentModDirectory = '';
		}

		PlayState.storyWeek = songs[curSelected].week;

		// Solo cargar dificultades desde semana si NO es StepMania
		loadBaseDifficultiesForSelection();

		// Heavy difficulty detection runs after the selection settles.

		// Protección para canciones de StepMania o sin dificultades
		if (Difficulty.list == null || Difficulty.list.length == 0)
		{
			Difficulty.list = ['Normal']; // Dificultad por defecto
		}

		var savedDiff:String = songs[curSelected].lastDifficulty;

		var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);

		if (savedDiff != null && Difficulty.list.contains(savedDiff))
			curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
		else if (lastDiff > -1)
			curDifficulty = lastDiff;
		else if (Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		changeDiff();
		_updateSongLastDifficulty();
		queueSelectedSongDataLoad();
	}

	function loadBaseDifficultiesForSelection():Void
	{
		if (songs == null || songs.length == 0 || curSelected < 0 || curSelected >= songs.length || songs[curSelected] == null)
		{
			Difficulty.list = ['Normal'];
			return;
		}

		if (songs[curSelected].isStepMania)
		{
			if (songs[curSelected].smDifficulties != null && songs[curSelected].smDifficulties.length > 0)
				Difficulty.list = songs[curSelected].smDifficulties.copy();
			else
				Difficulty.list = ['Normal'];
		}
		else
		{
			Difficulty.loadFromWeek();
			if (Difficulty.list == null || Difficulty.list.length == 0)
				Difficulty.list = [Difficulty.getDefault()];
		}
	}

	function queueSelectedSongDataLoad(?delay:Float = SELECTED_DATA_LOAD_DELAY):Void
	{
		selectedSongDataLoadToken++;
		songInfoCardLoadToken++;
		previewLoadToken++;

		if (selectedSongDataTimer != null)
			selectedSongDataTimer.cancel();

		if (songInfoCardLoadTimer != null)
			songInfoCardLoadTimer.cancel();

		if (previewTimer != null)
			previewTimer.cancel();

		if (previewLoadTimer != null)
			previewLoadTimer.cancel();

		#if (target.threaded && sys)
		_instLoadMutex.acquire();
		_pendingInstSound = null;
		_instLoadMutex.release();

		_songCardMutex.acquire();
		_pendingSongCardData = null;
		_songCardMutex.release();
		#end

		if (instPlaying != -1 || instSound != null || _prevInstSongName != null)
			stopInstPreview(false);

		var selectedSong:SongMetadata = (songs != null && curSelected >= 0 && curSelected < songs.length) ? songs[curSelected] : null;
		if (selectedSong != null && !songInfoCardCache.exists(getSongInfoCardCacheKey(selectedSong)))
		{
			songInfoCardLoading = true;
			setFreeplayLoadingUi(true);
		}

		var requestToken:Int = selectedSongDataLoadToken;
		var requestIndex:Int = curSelected;
		if (selectedSongDataTimer == null)
			selectedSongDataTimer = new FlxTimer();
		selectedSongDataTimer.start(delay, function(_:FlxTimer)
		{
			if (requestToken != selectedSongDataLoadToken
				|| requestIndex != curSelected
				|| songs == null
				|| requestIndex < 0
				|| requestIndex >= songs.length)
				return;

			loadStableSelectedSongData(requestIndex);
		});
	}

	function loadStableSelectedSongData(requestIndex:Int):Void
	{
		if (songs == null || requestIndex < 0 || requestIndex >= songs.length || songs[requestIndex] == null)
			return;

		loadBaseDifficultiesForSelection();
		detectAndLoadAllDifficulties();

		if (Difficulty.list == null || Difficulty.list.length == 0)
			Difficulty.list = ['Normal'];

		var savedDiff:String = songs[requestIndex].lastDifficulty;
		var savedDiffIndex:Int = (savedDiff != null && Difficulty.list.contains(savedDiff)) ? Difficulty.list.indexOf(savedDiff) : -1;
		var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);

		if (savedDiffIndex > -1)
			curDifficulty = savedDiffIndex;
		else if (lastDiff > -1)
			curDifficulty = lastDiff;
		else if (Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Difficulty.list.indexOf(Difficulty.getDefault());
		else
			curDifficulty = 0;

		changeDiff();
		_updateSongLastDifficulty();
		updateCurrentBpmFromSelection();
		queueSongInfoCardLoad(0.05);

		if (!songs[requestIndex].isStepMania)
		{
			if (previewTimer == null)
				previewTimer = new FlxTimer();
			previewTimer.start(0.5, function(_:FlxTimer)
			{
				playInstPreview();
			});
		}
	}

	public function detectAndLoadAllDifficulties():Void
	{
		// Para canciones de StepMania, cargar las dificultades guardadas del .sm
		if (songs[curSelected].isStepMania)
		{
			// Usar las dificultades guardadas del archivo .sm
			if (songs[curSelected].smDifficulties != null && songs[curSelected].smDifficulties.length > 0)
			{
				Difficulty.list = songs[curSelected].smDifficulties.copy();
			}
			else
			{
				// Fallback si no hay dificultades guardadas
				Difficulty.list = ['Normal'];
				trace('No SM difficulties found, using default');
			}
			return;
		}

		// Para canciones normales, detectar dificultades de archivos JSON
		var songName:String = Paths.formatToSongPath(songs[curSelected].songName);
		var availableDiffs:Array<String> = [];

		// Check default difficulties
		for (diff in Difficulty.list)
		{
			availableDiffs.push(diff);
		}

		// Check for erect and nightmare difficulties
		var erectDiffs:Array<String> = ['Erect', 'Nightmare'];
		for (diff in erectDiffs)
		{
			if (!availableDiffs.contains(diff))
			{
				var checkPath:String = Paths.formatToSongPath(diff);
				var fullPath:String = Paths.json('$songName/$songName-$checkPath');
				if (AssetLoader.exists(fullPath, TEXT))
				{
					availableDiffs.push(diff);
				}
			}
		}

		// Update Difficulty.list with all available difficulties
		Difficulty.list = availableDiffs;
	}

	inline private function _updateSongLastDifficulty()
		songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty, false);

	function createSongInfoCard():Void
	{
		var cardW:Int = SONG_INFO_CARD_WIDTH;
		var cardH:Int = SONG_INFO_CARD_HEIGHT;
		songInfoCardShownY = Math.max(56, (FlxG.height - cardH) * 0.5);
		songInfoCardHiddenY = FlxG.height + 60;
		songInfoCardY = songInfoCardShownY;

		var cardX:Float = FlxG.width - cardW - 58;

		var albumX:Float = cardX + (cardW - SONG_INFO_ALBUM_SIZE) * 0.5;
		songInfoAlbumBg = new FlxSprite(albumX, songInfoCardY);
		MD3ShapeTools.fillAndStrokeRoundRect(songInfoAlbumBg, SONG_INFO_ALBUM_SIZE, SONG_INFO_ALBUM_SIZE, 24, 3, OptionsMenuTheme.cardFill(true),
			intendedColor);
		songInfoAlbumBg.alpha = 0.94;
		add(songInfoAlbumBg);

		songInfoCardBg = new FlxSprite(cardX, songInfoCardY + SONG_INFO_ALBUM_SIZE + SONG_INFO_CARD_GAP);
		MD3ShapeTools.fillAndStrokeRoundRect(songInfoCardBg, cardW, SONG_INFO_DATA_HEIGHT, 24, 3, OptionsMenuTheme.cardFill(true), intendedColor);
		songInfoCardBg.alpha = 0.94;
		add(songInfoCardBg);

		songInfoCardCover = new FlxSprite(albumX + (SONG_INFO_ALBUM_SIZE - SONG_INFO_COVER_SIZE) * 0.5, songInfoCardY + 20);
		songInfoCardCover.antialiasing = ClientPrefs.data.antialiasing;
		var fallbackCover = Paths.image('albumRoll/example');
		if (!loadRoundedGraphic(songInfoCardCover, fallbackCover, SONG_INFO_COVER_SIZE, SONG_INFO_COVER_SIZE, 22, 'cover:fallback'))
			songInfoCardCover.makeGraphic(SONG_INFO_COVER_SIZE, SONG_INFO_COVER_SIZE, 0x00000000);
		songInfoCardCover.updateHitbox();
		add(songInfoCardCover);

		songInfoCardTitle = new FlxText(cardX + 20, songInfoCardY + SONG_INFO_ALBUM_SIZE + SONG_INFO_CARD_GAP + 18, cardW - 76, "", 24);
		songInfoCardTitle.setFormat(Paths.font('NotoSans-Medium.ttf'), 24, FlxColor.WHITE, LEFT);
		songInfoCardTitle.borderSize = 0;
		songInfoCardTitle.alpha = 0.95;
		add(songInfoCardTitle);

		songInfoCardStats = new FlxText(cardX + 20, songInfoCardY + SONG_INFO_ALBUM_SIZE + SONG_INFO_CARD_GAP + 58, cardW - 76, "", 15);
		songInfoCardStats.setFormat(Paths.font('NotoSans-Medium.ttf'), 15, FlxColor.WHITE, LEFT);
		songInfoCardStats.alpha = 0.9;
		add(songInfoCardStats);

		songInfoCardDifficulty = new FlxText(cardX + 20, songInfoCardY + SONG_INFO_ALBUM_SIZE + SONG_INFO_CARD_GAP + 128, cardW - 76, "", 13);
		songInfoCardDifficulty.setFormat(Paths.font('NotoSans-Medium.ttf'), 13, FlxColor.WHITE, LEFT);
		songInfoCardDifficulty.alpha = 0.88;
		songInfoCardDifficulty.visible = false;
		songInfoCardDifficulty.wordWrap = true;
		add(songInfoCardDifficulty);

		songInfoCardScores = new FlxText(cardX + 20, songInfoCardY + SONG_INFO_ALBUM_SIZE + SONG_INFO_CARD_GAP + 182, cardW - 76, "", 13);
		songInfoCardScores.setFormat(Paths.font('NotoSans-Medium.ttf'), 13, FlxColor.WHITE, LEFT);
		songInfoCardScores.alpha = 0.88;
		songInfoCardScores.wordWrap = true;
		add(songInfoCardScores);

		for (i in 0...FREEPLAY_LINK_PLATFORMS.length)
		{
			var icon = new FlxSprite();
			icon.antialiasing = ClientPrefs.data.antialiasing;
			icon.visible = false;
			songInfoPlatformIcons.push(icon);
			songInfoPlatformLinks.push(null);
			add(icon);
		}

		for (i in 0...6)
		{
			var icon = new FlxSprite();
			icon.antialiasing = ClientPrefs.data.antialiasing;
			icon.visible = false;
			songInfoLicenseIcons.push(icon);
			add(icon);
		}

		songInfoLicenseText = new FlxText(cardX + 20, songInfoCardY + SONG_INFO_ALBUM_SIZE + SONG_INFO_CARD_GAP + 284, cardW - 40, "", 12);
		songInfoLicenseText.setFormat(Paths.font('NotoSans-Medium.ttf'), 12, 0xFFE8EEF7, CENTER);
		songInfoLicenseText.alpha = 0.86;
		songInfoLicenseText.wordWrap = true;
		add(songInfoLicenseText);

		songInfoCardSpinner = new MaterialWavyProgressIndicator(FlxG.width * 0.5 - 28, FlxG.height * 0.5 - 28, CIRCULAR, 56);
		songInfoCardSpinner.indeterminate = true;
		songInfoCardSpinner.alpha = 0.9;
		songInfoCardSpinner.visible = false;
		add(songInfoCardSpinner);

		songInfoCardLoadingLabel = new FlxText(FlxG.width * 0.5 - 120, FlxG.height * 0.5 + 42, 240, "Loading...", 14);
		songInfoCardLoadingLabel.setFormat(Paths.font('NotoSans-Medium.ttf'), 14, FlxColor.WHITE, CENTER);
		songInfoCardLoadingLabel.alpha = 0.8;
		songInfoCardLoadingLabel.visible = false;
		add(songInfoCardLoadingLabel);

		updateSongInfoCardLayout();
	}

	function hideSongInfoCard():Void
	{
		if (songInfoCardTween != null)
		{
			songInfoCardTween.cancel();
			songInfoCardTween = null;
		}

		songInfoCardTween = FlxTween.tween(this, {songInfoCardY: songInfoCardHiddenY}, 0.32, {
			ease: FlxEase.expoInOut,
			onComplete: function(_)
			{
				songInfoCardTween = null;
			}
		});
	}

	function showSongInfoCard():Void
	{
		if (songInfoCardTween != null)
		{
			songInfoCardTween.cancel();
			songInfoCardTween = null;
		}

		songInfoCardTween = FlxTween.tween(this, {songInfoCardY: songInfoCardShownY}, 0.35, {
			ease: FlxEase.expoOut,
			onComplete: function(_)
			{
				songInfoCardTween = null;
			}
		});
	}

	function setFreeplayLoadingUi(active:Bool):Void
	{
		// Solo se oculta la card de datos de la canción; el resto del Freeplay sigue normal.
		if (songInfoCardCover != null)
			songInfoCardCover.visible = !active;
		if (songInfoCardTitle != null)
			songInfoCardTitle.visible = !active;
		if (songInfoCardStats != null)
			songInfoCardStats.visible = !active;
		if (songInfoCardDifficulty != null)
			songInfoCardDifficulty.visible = false;
		if (songInfoCardScores != null)
			songInfoCardScores.visible = !active;
		for (icon in songInfoPlatformIcons)
			if (icon != null)
				icon.visible = !active && icon.exists;
		for (icon in songInfoLicenseIcons)
			if (icon != null)
				icon.visible = !active && icon.exists;
		if (songInfoLicenseText != null)
			songInfoLicenseText.visible = !active;
		if (songInfoCardSpinner != null)
			songInfoCardSpinner.visible = active;
		if (songInfoCardLoadingLabel != null)
			songInfoCardLoadingLabel.visible = active;
	}

	inline function getSongInfoCardCacheKey(song:SongMetadata):String
	{
		return song == null ? '' : getSongInfoCardCacheKeyByName(song.songName);
	}

	inline function getSongInfoCardCacheKeyByName(songName:String):String
	{
		return Paths.formatToSongPath(songName == null ? '' : songName);
	}

	function queueSongInfoCardLoad(?delay:Float = 0.25):Void
	{
		if (songs == null || songs.length == 0 || curSelected < 0 || curSelected >= songs.length)
			return;

		songInfoCardLoadToken++;
		var requestToken:Int = songInfoCardLoadToken;
		var requestIndex:Int = curSelected;

		if (songInfoCardLoadTimer != null)
			songInfoCardLoadTimer.cancel();

		var song:SongMetadata = songs[requestIndex];
		var cacheKey:String = getSongInfoCardCacheKey(song);
		if (songInfoCardCache.exists(cacheKey))
		{
			applySongInfoCardData(songInfoCardCache.get(cacheKey));
			return;
		}

		songInfoCardLoading = true;
		setFreeplayLoadingUi(true);

		if (songInfoCardLoadTimer == null)
			songInfoCardLoadTimer = new FlxTimer();
		songInfoCardLoadTimer.start(delay, function(_:FlxTimer)
		{
			if (requestToken != songInfoCardLoadToken || requestIndex != curSelected)
				return;

			var diffNames:Array<String> = getSongDifficultyNames(song);
			var bpmSnapshot:Float = currentBPM;

			#if (target.threaded && sys)
			_songCardMutex.acquire();
			_pendingSongCardData = null;
			_songCardMutex.release();

			ThreadUtil.execAsync(function()
			{
				try
				{
					var cardData:FreeplaySongCardData = buildSongInfoCardData(song, diffNames, bpmSnapshot);
					_songCardMutex.acquire();
					if (requestToken == songInfoCardLoadToken)
					{
						_pendingSongCardData = cardData;
						_pendingSongCardToken = requestToken;
						_pendingSongCardIndex = requestIndex;
					}
					_songCardMutex.release();
				}
				catch (e:Dynamic)
				{
					trace('[FreePlay] Song card load failed: $e');
					_songCardMutex.acquire();
					if (requestToken == songInfoCardLoadToken)
					{
						_pendingSongCardData = {
							songName: song.songName,
							folder: song.folder,
							coverKey: 'albumRoll/${Paths.formatToSongPath(song.songName)}',
							cardKey: 'albumRoll/cards/${Paths.formatToSongPath(song.songName)}',
							cardMode: 'background',
							author: null,
							links: null,
							licenses: ['no-licenses'],
							licenseText: null,
							bpm: bpmSnapshot > 0 ? bpmSnapshot : 102,
							durationMs: 0,
							noteCount: 0,
							difficultyNames: diffNames != null ? diffNames.copy() : []
						};
						_pendingSongCardToken = requestToken;
						_pendingSongCardIndex = requestIndex;
					}
					_songCardMutex.release();
				}
			});
			#else
			applySongInfoCardData(buildSongInfoCardData(song, diffNames, bpmSnapshot));
			#end
		});
	}

	function applySongInfoCardData(data:FreeplaySongCardData):Void
	{
		if (data == null)
			return;

		songInfoCardData = data;
		var cacheKey:String = getSongInfoCardCacheKeyByName(data.songName);
		if (!songInfoCardCache.exists(cacheKey))
		{
			songInfoCardCacheOrder.push(cacheKey);
			while (songInfoCardCacheOrder.length > SONG_INFO_CARD_CACHE_LIMIT)
				songInfoCardCache.remove(songInfoCardCacheOrder.shift());
		}
		songInfoCardCache.set(cacheKey, data);
		songInfoCardLoading = false;
		setFreeplayLoadingUi(false);

		if (songInfoCardTitle != null)
			songInfoCardTitle.text = data.songName;

		if (songInfoCardStats != null)
			songInfoCardStats.text = formatSongInfoStats(data);

		if (songInfoCardDifficulty != null)
			songInfoCardDifficulty.text = '';

		if (songInfoCardScores != null)
		{
			var diffList:Array<String> = data.difficultyNames != null ? data.difficultyNames.copy() : [];
			if (diffList.length == 0)
				diffList.push('Normal');

			var scoreLines:Array<String> = [];
			for (i in 0...diffList.length)
			{
				var diffName:String = diffList[i];
				var score:Int = Highscore.getScore(data.songName, i, viewingOpponentScores);
				var accuracySystem:String = Highscore.getAccuracySystem(data.songName, i, viewingOpponentScores);
				if (accuracySystem == null || accuracySystem.length == 0)
					accuracySystem = ClientPrefs.data.accuracySystem;
				scoreLines.push('${diffName}: ${score} [$accuracySystem]');
			}
			songInfoCardScores.text = 'Diff and Scores:\n' + scoreLines.join('\n');
		}

		var coverGraphic:FlxGraphic = getOptionalImageInFolder(data.coverKey, data.folder);
		if (coverGraphic == null)
			coverGraphic = Paths.image('albumRoll/example');
		if (songInfoCardCover != null)
		{
			if (!loadRoundedGraphic(songInfoCardCover, coverGraphic, SONG_INFO_COVER_SIZE, SONG_INFO_COVER_SIZE, 22, 'cover:${data.coverKey}'))
				songInfoCardCover.makeGraphic(SONG_INFO_COVER_SIZE, SONG_INFO_COVER_SIZE, 0x00000000);
			songInfoCardCover.updateHitbox();
		}

		updateSongInfoPlatformIcons(data.links);
		updateSongInfoLicenses(data.licenses, data.licenseText);

		if (!inDifficultySelect)
			showSongInfoCard();
	}

	function formatSongInfoStats(data:FreeplaySongCardData):String
	{
		var statsLines:Array<String> = [
			Language.getPhrase("new_freeplay_song_time", "Time: {1}", [formatDuration(data.durationMs)]),
			'BPM: ${formatFloat(data.bpm)}'
		];
		if (data.author != null && data.author.length > 0)
			statsLines.push('By: ${data.author}');
		return statsLines.join('\n');
	}

	function getOptionalImage(key:String):FlxGraphic
	{
		if (key == null || key.length == 0)
			return null;

		var imagePath:String = Paths.getPath('images/$key.png', IMAGE, null, true);
		if (!AssetLoader.exists(imagePath, IMAGE))
			return null;

		return Paths.image(key);
	}

	function getOptionalSongImage(key:String, song:SongMetadata):FlxGraphic
	{
		return getOptionalImageInFolder(key, song != null ? song.folder : null);
	}

	function getOptionalImageInFolder(key:String, folder:String):FlxGraphic
	{
		if (key == null || key.length == 0)
			return null;

		var previousModDirectory:String = Mods.currentModDirectory;
		if (folder != null)
			Mods.currentModDirectory = folder;

		var graphic:FlxGraphic = getOptionalImage(key);
		Mods.currentModDirectory = previousModDirectory;
		return graphic;
	}

	function getLicenseImage(id:String):FlxGraphic
	{
		if (id == null || id.length == 0)
			return null;

		var graphic:FlxGraphic = getOptionalImage('albumRoll/licenses/$id');
		if (graphic == null)
			graphic = getOptionalImage('albumRoll/licences/$id');
		return graphic;
	}

	function updateSongInfoLicenses(licenses:Array<String>, ?licenseText:String):Void
	{
		var list:Array<String> = licenses != null && licenses.length > 0 ? licenses.copy() : ['no-licenses'];
		if (list.length == 0)
			list.push('no-licenses');

		for (i in 0...songInfoLicenseIcons.length)
		{
			var icon = songInfoLicenseIcons[i];
			if (icon == null)
				continue;

			icon.exists = false;
			icon.visible = false;
			if (i >= list.length)
				continue;

			var id:String = list[i];
			var graphic:FlxGraphic = getLicenseImage(id);
			if (graphic == null)
				continue;

			icon.loadGraphic(graphic);
			icon.setGraphicSize(SONG_INFO_LICENSE_ICON_SIZE, SONG_INFO_LICENSE_ICON_SIZE);
			icon.updateHitbox();
			icon.alpha = 0.88;
			icon.exists = true;
			icon.visible = !songInfoCardLoading;
		}

		if (songInfoLicenseText != null)
		{
			songInfoLicenseText.text = licenseText != null
				&& licenseText.length > 0 ? licenseText : list.map(formatLicenseLabel).join('  +  ');
			songInfoLicenseText.visible = !songInfoCardLoading;
		}

		updateSongInfoCardLayout();
	}

	function formatLicenseLabel(id:String):String
	{
		return switch (id)
		{
			case 'no-licenses': 'No License';
			case 'creative-commons': 'Creative Commons';
			case 'cc-by': 'CC BY';
			case 'cc-by-sa': 'CC BY-SA';
			case 'cc-by-nd': 'CC BY-ND';
			case 'cc-by-nc': 'CC BY-NC';
			case 'cc-by-nc-sa': 'CC BY-NC-SA';
			case 'cc-by-nc-nd': 'CC BY-NC-ND';
			case 'public-domain': 'Public Domain';
			case 'royalty-free': 'Royalty Free';
			case 'copyright': 'Copyright';
			case 'permission-required': 'Permission Required';
			case 'comercial-use': 'Commercial Use';
			case 'no-comercial': 'Non-Commercial';
			case 'no-derivatives': 'No Derivatives';
			case 'share-alike': 'Share Alike';
			case 'atribution-required': 'Attribution Required';
			case 'redistribution-allow': 'Redistribution Allowed';
			case 'modify-allow': 'Modification Allowed';
			case 'streaming-allow': 'Streaming Allowed';
			case 'public-access': 'Public Access';
			case 'public-execution': 'Public Performance';
			case 'sync': 'Sync';
			default: id.split('-').map((part) -> part.length > 0 ? part.charAt(0).toUpperCase() + part.substr(1) : part).join(' ');
		}
	}

	function loadRoundedGraphic(target:FlxSprite, graphic:FlxGraphic, width:Int, height:Int, radius:Float, cacheTag:String):Bool
	{
		if (target == null || graphic == null || graphic.bitmap == null || graphic.bitmap.width <= 0 || graphic.bitmap.height <= 0 || width <= 0 || height <= 0)
			return false;

		var rounded:FlxGraphic = getRoundedImage(graphic, width, height, radius, cacheTag);
		if (rounded == null || rounded.bitmap == null)
			return false;

		try
		{
			target.loadGraphic(rounded);
			return true;
		}
		catch (e:Dynamic)
		{
			trace('[FreePlay] Failed to load rounded graphic "$cacheTag": $e');
		}

		try
		{
			target.loadGraphic(rounded.bitmap);
			return true;
		}
		catch (e:Dynamic)
		{
			trace('[FreePlay] Failed to load rounded bitmap fallback "$cacheTag": $e');
		}

		return false;
	}

	function getRoundedImage(graphic:FlxGraphic, width:Int, height:Int, radius:Float, cacheTag:String):FlxGraphic
	{
		if (graphic == null || graphic.bitmap == null || graphic.bitmap.width <= 0 || graphic.bitmap.height <= 0 || width <= 0 || height <= 0)
			return null;

		var sourceKey:String = graphic.key != null ? graphic.key : Std.string(graphic);
		var cacheKey:String = 'freeplayRounded:${cacheTag}:${width}x${height}:${radius}:${sourceKey}';
		if (roundedImageCache.exists(cacheKey))
		{
			var cached:FlxGraphic = roundedImageCache.get(cacheKey);
			if (cached != null && cached.bitmap != null && cached.bitmap.width > 0 && cached.bitmap.height > 0)
				return cached;
			roundedImageCache.remove(cacheKey);
		}

		var source:BitmapData = graphic.bitmap;
		var output:BitmapData = new BitmapData(width, height, true, 0x00000000);
		var scale:Float = Math.max(width / source.width, height / source.height);
		var matrix:Matrix = new Matrix();
		matrix.scale(scale, scale);
		matrix.translate((width - source.width * scale) * 0.5, (height - source.height * scale) * 0.5);
		try
		{
			output.draw(source, matrix, null, null, null, true);
		}
		catch (e:Dynamic)
		{
			trace('[FreePlay] Failed to draw rounded image "$cacheTag": $e');
			output.dispose();
			return null;
		}

		var feather:Float = 1.25;
		var maxX:Float = width - 1;
		var maxY:Float = height - 1;
		var r:Float = Math.max(0, Math.min(radius, Math.min(width, height) * 0.5));
		for (py in 0...height)
		{
			for (px in 0...width)
			{
				var cx:Float = px < r ? r : (px > maxX - r ? maxX - r : px);
				var cy:Float = py < r ? r : (py > maxY - r ? maxY - r : py);
				var dx:Float = px - cx;
				var dy:Float = py - cy;
				var distance:Float = Math.sqrt(dx * dx + dy * dy);
				if (distance >= r)
				{
					output.setPixel32(px, py, 0x00000000);
				}
				else if (distance > r - feather)
				{
					var pixel:Int = output.getPixel32(px, py);
					var alpha:Int = (pixel >>> 24) & 0xFF;
					var edgeAlpha:Float = (r - distance) / feather;
					output.setPixel32(px, py, (Std.int(alpha * edgeAlpha) << 24) | (pixel & 0x00FFFFFF));
				}
			}
		}

		var roundedGraphic:FlxGraphic = FlxGraphic.fromBitmapData(output, false, cacheKey);
		roundedGraphic.persist = true;
		roundedImageCache.set(cacheKey, roundedGraphic);
		return roundedGraphic;
	}

	function updateSongInfoPlatformIcons(links:Dynamic):Void
	{
		for (i in 0...songInfoPlatformIcons.length)
		{
			var icon = songInfoPlatformIcons[i];
			if (icon == null)
				continue;

			if (i < songInfoPlatformLinks.length)
				songInfoPlatformLinks[i] = null;
			icon.exists = false;
			icon.visible = false;
			if (i >= FREEPLAY_LINK_PLATFORMS.length || links == null)
				continue;

			var platform:String = FREEPLAY_LINK_PLATFORMS[i];
			var link:String = stringOrNull(getLinkValue(links, platform));
			if (link == null)
				continue;

			var graphic:FlxGraphic = getOptionalImage('albumRoll/platformIcons/${platform}');
			if (graphic == null)
				continue;

			icon.loadGraphic(graphic);
			icon.setGraphicSize(SONG_INFO_SOCIAL_ICON_SIZE, SONG_INFO_SOCIAL_ICON_SIZE);
			icon.updateHitbox();
			icon.alpha = 0.88;
			icon.exists = true;
			icon.visible = !songInfoCardLoading;
			if (i < songInfoPlatformLinks.length)
				songInfoPlatformLinks[i] = link;
		}

		updateSongInfoCardLayout();
	}

	function handleSongInfoLinkMouse():Bool
	{
		if (songInfoCardLoading || songInfoPlatformIcons == null || songInfoPlatformLinks == null)
			return false;

		var clicked:Bool = FlxG.mouse.justReleased;
		var hovered:Bool = false;
		for (i in 0...songInfoPlatformIcons.length)
		{
			var icon = songInfoPlatformIcons[i];
			if (icon == null || !icon.exists || !icon.visible)
				continue;

			var link:String = i < songInfoPlatformLinks.length ? songInfoPlatformLinks[i] : null;
			if (link == null || link.length == 0)
				continue;

			if (FlxG.mouse.overlaps(icon))
			{
				hovered = true;
				icon.alpha = 1.0;
				if (clicked)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					FlxG.openURL(normalizeExternalLink(link));
					return true;
				}
			}
			else
			{
				icon.alpha = 0.88;
			}
		}

		if (hovered)
			FlxG.mouse.visible = true;
		return false;
	}

	function normalizeExternalLink(link:String):String
	{
		var trimmed:String = StringTools.trim(link);
		if (trimmed.length == 0)
			return trimmed;
		var lower:String = trimmed.toLowerCase();
		if (lower.startsWith('http://') || lower.startsWith('https://') || lower.startsWith('mailto:') || lower.indexOf('://') > 0)
			return trimmed;
		return 'https://$trimmed';
	}

	function getLinkValue(links:Dynamic, platform:String):Dynamic
	{
		var aliases:Array<String> = switch (platform)
		{
			case 'youtube': ['youtube', 'yt'];
			case 'youtube-music': ['youtubeMusic', 'youtube-music', 'ytMusic', 'yt-music'];
			case 'instagram': ['instagram', 'ig'];
			case 'x': ['x', 'twitter'];
			case 'newgrounds': ['newgrounds', 'ng'];
			case 'facebook': ['facebook', 'fb'];
			default: [platform];
		}

		for (alias in aliases)
		{
			if (Reflect.hasField(links, alias))
				return Reflect.field(links, alias);
		}
		return null;
	}

	function layoutSongInfoPlatformIcons(x:Float, y:Float, height:Float):Void
	{
		var visibleIcons:Array<FlxSprite> = [];
		for (icon in songInfoPlatformIcons)
		{
			if (icon != null && icon.exists)
				visibleIcons.push(icon);
		}

		if (visibleIcons.length == 0)
			return;

		var gap:Float = 10;
		var iconSize:Float = SONG_INFO_SOCIAL_ICON_SIZE;
		var totalHeight:Float = visibleIcons.length * iconSize + (visibleIcons.length - 1) * gap;
		var startY:Float = y + Math.max(0, (height - totalHeight) * 0.5);
		for (i in 0...visibleIcons.length)
		{
			visibleIcons[i].x = x;
			visibleIcons[i].y = startY + i * (iconSize + gap);
		}
	}

	function layoutSongInfoLicenseIcons(cardX:Float, dataY:Float, cardW:Float, dataH:Float):Void
	{
		var visibleIcons:Array<FlxSprite> = [];
		for (icon in songInfoLicenseIcons)
		{
			if (icon != null && icon.exists)
				visibleIcons.push(icon);
		}

		var iconY:Float = dataY + dataH - SONG_INFO_LICENSE_ICON_SIZE - 26;
		var labelY:Float = iconY + SONG_INFO_LICENSE_ICON_SIZE + 4;
		if (songInfoLicenseText != null)
		{
			songInfoLicenseText.x = cardX + 24;
			songInfoLicenseText.y = labelY;
			songInfoLicenseText.fieldWidth = cardW - 48;
		}

		if (visibleIcons.length == 0)
			return;

		var gap:Float = 6;
		var iconSize:Float = SONG_INFO_LICENSE_ICON_SIZE;
		var totalWidth:Float = visibleIcons.length * iconSize + (visibleIcons.length - 1) * gap;
		var startX:Float = cardX + (cardW - totalWidth) * 0.5;
		for (i in 0...visibleIcons.length)
		{
			visibleIcons[i].x = startX + i * (iconSize + gap);
			visibleIcons[i].y = iconY;
		}
	}

	function updateSongInfoCardLayout():Void
	{
		if (songInfoCardBg == null)
			return;

		var cardW:Int = SONG_INFO_CARD_WIDTH;
		var cardH:Int = SONG_INFO_CARD_HEIGHT;
		var albumSize:Int = SONG_INFO_ALBUM_SIZE;
		var coverSize:Int = SONG_INFO_COVER_SIZE;
		var gap:Int = SONG_INFO_CARD_GAP;
		var dataH:Int = SONG_INFO_DATA_HEIGHT;
		var dataY:Float = songInfoCardY + albumSize + gap;
		var cardX:Float = FlxG.width - cardW - 58;
		var albumX:Float = cardX + (cardW - albumSize) * 0.5;
		var baseY:Float = songInfoCardY;
		var padX:Float = 20;
		var iconColumnW:Float = 44;
		var textW:Float = cardW - (padX * 2) - iconColumnW;

		if (songInfoAlbumBg != null)
		{
			songInfoAlbumBg.x = albumX;
			songInfoAlbumBg.y = baseY;
			MD3ShapeTools.fillAndStrokeRoundRect(songInfoAlbumBg, albumSize, albumSize, 24, 3, OptionsMenuTheme.cardFill(true), intendedColor);
			songInfoAlbumBg.alpha = 0.94;
		}

		songInfoCardBg.x = cardX;
		songInfoCardBg.y = dataY;
		MD3ShapeTools.fillAndStrokeRoundRect(songInfoCardBg, cardW, dataH, 24, 3, OptionsMenuTheme.cardFill(true), intendedColor);
		songInfoCardBg.alpha = 0.94;

		songInfoCardCover.x = albumX + (albumSize - coverSize) * 0.5;
		songInfoCardCover.y = baseY + (albumSize - coverSize) * 0.5;
		songInfoCardTitle.x = cardX + padX;
		songInfoCardTitle.y = dataY + 18;
		songInfoCardTitle.fieldWidth = textW;
		songInfoCardStats.x = cardX + padX;
		songInfoCardStats.y = dataY + 62;
		songInfoCardStats.fieldWidth = textW;
		songInfoCardDifficulty.x = cardX + padX;
		songInfoCardDifficulty.y = dataY + 132;
		songInfoCardDifficulty.fieldWidth = textW;
		songInfoCardDifficulty.visible = false;
		songInfoCardScores.x = cardX + padX;
		songInfoCardScores.y = dataY + 138;
		songInfoCardScores.fieldWidth = textW;
		layoutSongInfoPlatformIcons(cardX + cardW - padX - SONG_INFO_SOCIAL_ICON_SIZE, dataY + 22, dataH - 44);
		layoutSongInfoLicenseIcons(cardX, dataY, cardW, dataH);
		if (songInfoCardSpinner != null)
		{
			if (songInfoCardLoading)
			{
				songInfoCardSpinner.x = cardX + (cardW * 0.5) - 28;
				songInfoCardSpinner.y = baseY + (cardH * 0.5) - 54;
			}
			else
			{
				songInfoCardSpinner.x = cardX + 170;
				songInfoCardSpinner.y = baseY + 86;
			}
		}
		if (songInfoCardLoadingLabel != null)
		{
			if (songInfoCardLoading)
			{
				songInfoCardLoadingLabel.x = cardX + (cardW * 0.5) - 120;
				songInfoCardLoadingLabel.y = baseY + (cardH * 0.5) + 12;
			}
			else
			{
				songInfoCardLoadingLabel.x = cardX + 126;
				songInfoCardLoadingLabel.y = baseY + 146;
			}
		}
	}

	function getSongDifficultyNames(song:SongMetadata):Array<String>
	{
		if (song == null)
			return [];

		if (song.isStepMania)
		{
			if (song.smDifficulties != null && song.smDifficulties.length > 0)
				return song.smDifficulties.copy();
			return ['Normal'];
		}

		if (Difficulty.list != null && Difficulty.list.length > 0)
			return Difficulty.list.copy();

		return [Difficulty.getDefault()];
	}

	function buildSongInfoCardData(song:SongMetadata, diffNames:Array<String>, capturedBpm:Float):FreeplaySongCardData
	{
		var totalNotes:Int = 0;
		var longestDuration:Float = 0;
		var songKey:String = Paths.formatToSongPath(song.songName);

		var meta:FreeplaySongMeta = loadSongMeta(song);
		var metaDurationMs:Float = meta != null
			&& meta.durationSeconds != null
			&& meta.durationSeconds > 0 ? meta.durationSeconds * 1000 : 0;
		if (metaDurationMs > 0)
			longestDuration = metaDurationMs;

		if (diffNames != null)
		{
			for (i in 0...diffNames.length)
			{
				var diffName:String = diffNames[i];
				var chartPath:String = resolveSongChartPath(song, i, diffName);
				var rawChart:String = AssetLoader.loadText(chartPath);
				if (rawChart == null || rawChart.length == 0)
					continue;

				var summary:FreeplayChartSummary = summarizeChart(rawChart);
				totalNotes += summary.noteCount;
				if (metaDurationMs <= 0 && summary.durationMs > longestDuration)
					longestDuration = summary.durationMs;
				if (capturedBpm <= 0 && summary.bpm > 0)
					capturedBpm = summary.bpm;
			}
		}

		return {
			songName: song.songName,
			folder: song.folder,
			coverKey: meta != null && meta.coverKey != null ? meta.coverKey : 'albumRoll/$songKey',
			cardKey: meta != null && meta.cardKey != null ? meta.cardKey : 'albumRoll/cards/$songKey',
			cardMode: meta != null && meta.cardMode != null ? meta.cardMode : 'background',
			author: meta != null ? meta.author : null,
			links: meta != null ? meta.links : null,
			licenses: meta != null && meta.licenses != null && meta.licenses.length > 0 ? meta.licenses.copy() : ['no-licenses'],
			licenseText: meta != null ? meta.licenseText : null,
			bpm: capturedBpm > 0 ? capturedBpm : 102,
			durationMs: longestDuration,
			noteCount: totalNotes,
			difficultyNames: diffNames != null ? diffNames.copy() : []
		};
	}

	function loadSongMeta(song:SongMetadata):FreeplaySongMeta
	{
		if (song == null || song.isStepMania)
			return null;

		var songKey:String = Paths.formatToSongPath(song.songName);
		var cacheKey:String = '${song.folder == null ? "" : song.folder}:$songKey';
		if (songMetaCache.exists(cacheKey))
			return songMetaCache.get(cacheKey);

		var rawMeta:String = cleanJsonText(loadSongMetaText(song, songKey));
		if (rawMeta == null || rawMeta.length == 0)
			return null;

		try
		{
			var parsed:Dynamic = Json.parse(rawMeta);
			var coverValue:Dynamic = firstMetaValue(parsed, ['cover', 'coverAlbum', 'albumId', 'coverImage', 'albumCover']);
			var cardValue:Dynamic = firstMetaValue(parsed, ['card', 'cardImage', 'cardKey', 'infoCard']);
			var authorValue:Dynamic = firstMetaValue(parsed, ['songAuthor', 'songAutor', 'author', 'artist', 'composer', 'musicArtist']);
			var cardModeValue:Dynamic = firstMetaValue(parsed, ['cardMode']);
			var linksValue:Dynamic = firstMetaValue(parsed, ['links', 'artistLinks', 'platformLinks', 'socials']);
			var durationValue:Dynamic = firstMetaValue(parsed, ['freeplaySongLength', 'songLength', 'length', 'duration', 'durationSeconds']);
			var licensesValue:Dynamic = firstMetaValue(parsed, ['licenses', 'licences', 'musicLicenses', 'musicLicences', 'license', 'licence']);
			var licenseTextValue:Dynamic = firstMetaValue(parsed, ['licenseText', 'licenceText', 'musicLicenseText', 'musicLicenceText']);
			var previewStartValue:Dynamic = firstMetaValue(parsed, ['freeplayPrevStart', 'previewStart', 'songPreviewStart']);
			var previewEndValue:Dynamic = firstMetaValue(parsed, ['freeplayPrevEnd', 'previewEnd', 'songPreviewEnd']);

			var meta:FreeplaySongMeta = {
				coverKey: normalizeAlbumRollKey(coverValue, 'albumRoll/$songKey'),
				cardKey: normalizeAlbumRollKey(cardValue, 'albumRoll/cards/$songKey', 'cards'),
				cardMode: stringOrNull(cardModeValue),
				author: stringOrNull(authorValue),
				links: linksValue,
				durationSeconds: positiveFloatOrNull(durationValue),
				licenses: normalizeLicenseList(licensesValue),
				licenseText: stringOrNull(licenseTextValue),
				previewStartSeconds: nonNegativeFloatOrNull(previewStartValue),
				previewEndSeconds: nonNegativeFloatOrNull(previewEndValue)
			};
			songMetaCache.set(cacheKey, meta);
			return meta;
		}
		catch (e:Dynamic)
		{
			trace('[FreePlay] Invalid song_meta.json for ${song.songName}: $e');
		}

		return null;
	}

	function loadSongMetaText(song:SongMetadata, songKey:String):String
	{
		#if MODS_ALLOWED
		if (song != null && song.folder != null && song.folder.length > 0)
		{
			var modMetaPath:String = Paths.mods('${song.folder}/data/$songKey/song_meta.json');
			if (FileSystem.exists(modMetaPath))
				return File.getContent(modMetaPath);
		}
		#end

		return AssetLoader.loadText(Paths.json('$songKey/song_meta'));
	}

	function firstMetaValue(meta:Dynamic, names:Array<String>):Dynamic
	{
		if (meta == null || names == null)
			return null;

		for (name in names)
		{
			if (Reflect.hasField(meta, name))
				return Reflect.field(meta, name);
		}
		return null;
	}

	function cleanJsonText(raw:String):String
	{
		if (raw == null)
			return null;
		var text:String = StringTools.trim(raw);
		if (text.length > 0 && text.charCodeAt(0) == 0xFEFF)
			text = text.substr(1);
		return text;
	}

	function stringOrNull(value:Dynamic):String
	{
		if (value == null)
			return null;
		var text:String = Std.string(value).trim();
		return text.length > 0 ? text : null;
	}

	function positiveFloatOrNull(value:Dynamic):Null<Float>
	{
		if (value == null)
			return null;
		var parsed:Float = Std.parseFloat(Std.string(value));
		return !Math.isNaN(parsed) && parsed > 0 ? parsed : null;
	}

	function nonNegativeFloatOrNull(value:Dynamic):Null<Float>
	{
		if (value == null)
			return null;
		var parsed:Float = Std.parseFloat(Std.string(value));
		return !Math.isNaN(parsed) && parsed >= 0 ? parsed : null;
	}

	function normalizeLicenseList(value:Dynamic):Array<String>
	{
		var licenses:Array<String> = [];
		if (value != null)
		{
			if (Std.isOfType(value, Array))
			{
				for (item in (value : Array<Dynamic>))
					addNormalizedLicense(licenses, item);
			}
			else
			{
				var raw:String = Std.string(value);
				for (part in raw.split(','))
					addNormalizedLicense(licenses, part);
			}
		}

		if (licenses.length == 0)
			licenses.push('no-licenses');
		return licenses;
	}

	function addNormalizedLicense(licenses:Array<String>, value:Dynamic):Void
	{
		var text:String = stringOrNull(value);
		if (text == null)
			return;

		text = Paths.formatToSongPath(text);
		text = StringTools.replace(text, '_', '-');
		if (text == 'cc')
			text = 'creative-commons';
		if (!licenses.contains(text))
			licenses.push(text);
	}

	function normalizeAlbumRollKey(value:Dynamic, defaultKey:String, ?subFolder:String):String
	{
		var text:String = stringOrNull(value);
		if (text == null)
			return defaultKey;

		text = StringTools.replace(text, '\\', '/');
		if (text.endsWith('.png'))
			text = text.substr(0, text.length - 4);
		if (text.startsWith('images/'))
			text = text.substr('images/'.length);
		if (text.startsWith('albumRoll/'))
			return text;
		if (text.indexOf('/') >= 0)
			return text;
		return subFolder != null && subFolder.length > 0 ? 'albumRoll/$subFolder/$text' : 'albumRoll/$text';
	}

	function resolveSongChartPath(song:SongMetadata, diffIndex:Int, diffName:String):String
	{
		if (song == null)
			return null;

		if (song.isStepMania)
		{
			#if mobile
			var smDir = StorageUtil.getSMDirectory();
			#else
			var smDir = './sm/';
			#end
			return smDir + song.smFolder + '/' + Paths.formatToSongPath(diffName) + '.json';
		}

		var songKey:String = Paths.formatToSongPath(song.songName);
		var diffKey:String = Paths.formatToSongPath(diffName);
		var chartPath:String = Paths.json('$songKey/${songKey}-$diffKey');
		if (AssetLoader.exists(chartPath, TEXT))
			return chartPath;

		if (diffKey == Paths.formatToSongPath(Difficulty.getDefault()))
		{
			var normalFallback:String = Paths.json('$songKey/$songKey');
			if (AssetLoader.exists(normalFallback, TEXT))
				return normalFallback;
		}

		return chartPath;
	}

	function summarizeChart(rawChart:String):FreeplayChartSummary
	{
		var summary:FreeplayChartSummary = {bpm: 0, noteCount: 0, durationMs: 0};
		if (rawChart == null || rawChart.length == 0)
			return summary;

		try
		{
			var parsed:Dynamic = haxe.Json.parse(rawChart);
			if (Reflect.hasField(parsed, 'song'))
			{
				var subSong:Dynamic = Reflect.field(parsed, 'song');
				if (subSong != null)
					parsed = subSong;
			}

			if (parsed == null)
				return summary;

			var fmt:Dynamic = Reflect.field(parsed, 'format');
			var formatStr:String = fmt != null ? Std.string(fmt) : '';
			var bpmField:Dynamic = Reflect.field(parsed, 'bpm');
			if (bpmField != null)
				summary.bpm = getDynamicFloat(parsed, 'bpm');

			if (formatStr != null && formatStr.indexOf('psych_v2') == 0)
			{
				var notesV2:Array<Dynamic> = cast Reflect.field(parsed, 'notes');
				if (notesV2 != null)
				{
					for (note in notesV2)
					{
						if (note == null)
							continue;
						var t:Float = getDynamicFloat(note, 't');
						var l:Float = getDynamicFloat(note, 'l');
						summary.noteCount++;
						if (t + l > summary.durationMs)
							summary.durationMs = t + l;
					}
				}
			}
			else
			{
				var sections:Array<Dynamic> = cast Reflect.field(parsed, 'notes');
				if (sections != null)
				{
					for (section in sections)
					{
						if (section == null)
							continue;
						var sectionNotes:Array<Dynamic> = cast Reflect.field(section, 'sectionNotes');
						if (sectionNotes == null)
							continue;

						for (note in sectionNotes)
						{
							if (note == null)
								continue;

							var noteArray:Array<Dynamic> = cast note;
							if (noteArray != null && noteArray.length > 0)
							{
								var t:Float = Std.parseFloat(Std.string(noteArray[0]));
								if (Math.isNaN(t))
									t = 0;
								var sustain:Float = noteArray.length > 2
									&& noteArray[2] != null ? Std.parseFloat(Std.string(noteArray[2])) : 0;
								if (Math.isNaN(sustain))
									sustain = 0;
								summary.noteCount++;
								if (t + sustain > summary.durationMs)
									summary.durationMs = t + sustain;
							}
						}
					}
				}
			}
		}
		catch (e:Dynamic)
		{
			trace('[FreePlay] Chart summary failed: $e');
		}

		return summary;
	}

	inline function getDynamicFloat(value:Dynamic, field:String):Float
	{
		var raw:Dynamic = Reflect.field(value, field);
		if (raw == null)
			return 0;
		var parsed:Float = Std.parseFloat(Std.string(raw));
		return Math.isNaN(parsed) ? 0 : parsed;
	}

	inline function formatFloat(value:Float):String
	{
		if (Math.isNaN(value) || value <= 0)
			return '0';
		var rounded:Float = CoolUtil.floorDecimal(value, 2);
		return Std.string(rounded);
	}

	inline function formatDuration(durationMs:Float):String
	{
		if (Math.isNaN(durationMs) || durationMs <= 0)
			return '???';

		var totalSeconds:Int = Std.int(durationMs / 1000);
		var minutes:Int = Std.int(totalSeconds / 60);
		var seconds:Int = totalSeconds % 60;
		return StringTools.lpad(Std.string(minutes), '0', 1) + ':' + StringTools.lpad(Std.string(seconds), '0', 2);
	}

	function applySongPreviewStart(song:SongMetadata):Void
	{
		currentPreviewStartMs = 0;
		currentPreviewEndMs = 0;
		if (song == null || FlxG.sound.music == null)
			return;

		var meta:FreeplaySongMeta = loadSongMeta(song);
		if (meta == null)
			return;

		var startSeconds:Null<Float> = meta.previewStartSeconds;
		var endSeconds:Null<Float> = meta.previewEndSeconds;
		var startMs:Float = startSeconds != null ? startSeconds * 1000 : 0;
		var endMs:Float = endSeconds != null ? endSeconds * 1000 : 0;
		if (!Math.isNaN(startMs) && FlxG.sound.music.length > 0)
		{
			currentPreviewStartMs = Math.min(startMs, Math.max(0, FlxG.sound.music.length - 100));
			currentPreviewEndMs = (!Math.isNaN(endMs) && endMs > currentPreviewStartMs) ? Math.min(endMs, FlxG.sound.music.length) : 0;
			FlxG.sound.music.time = currentPreviewStartMs;
		}
	}

	function enforceSongPreviewWindow():Void
	{
		if (instPlaying < 0 || FlxG.sound.music == null || currentPreviewEndMs <= currentPreviewStartMs)
			return;

		if (FlxG.sound.music.time >= currentPreviewEndMs)
			FlxG.sound.music.time = currentPreviewStartMs;
	}

	function playInstPreview():Void
	{
		if (songs.length == 0 || curSelected >= songs.length)
			return;

		previewLoadToken++;
		var requestToken:Int = previewLoadToken;
		var requestedIndex:Int = curSelected;
		var requestedSong:SongMetadata = songs[requestedIndex];
		var songName:String = getInstPreviewCacheKey(requestedSong);
		if (songName == null || songName.length == 0)
		{
			trace('[FreePlay] Missing inst preview path for ${requestedSong != null ? requestedSong.songName : Std.string(requestedIndex)}.');
			return;
		}

		if (previewLoadTimer != null)
			previewLoadTimer.cancel();

		if (previewLoadTimer == null)
			previewLoadTimer = new FlxTimer();
		previewLoadTimer.start(PREVIEW_LOAD_DELAY, function(_:FlxTimer)
		{
			if (requestToken != previewLoadToken || songs.length == 0 || requestedIndex != curSelected)
				return;

			// Free old preview cache before requesting a different song preview.
			if (_prevInstSongName != null && _prevInstSongName != songName)
				releasePreviewSoundCache(_prevInstSongName);

			_prevInstSongName = songName;

			#if (target.threaded && sys)
			// Resolve the file path on the main thread (safe, read-only) to avoid
			// touching shared Paths data from inside the worker thread.
			var filePath:String = getInstPreviewFilePath(songs[requestedIndex]);
			if (filePath == null || filePath.length == 0)
				return;
			var capturedBpm:Float = currentBPM;
			var capturedToken:Int = requestToken;
			var capturedIndex:Int = requestedIndex;

			// Cancel any stale pending result so update() ignores it.
			_instLoadMutex.acquire();
			_pendingInstSound = null;
			_instLoadMutex.release();

			ThreadUtil.execAsync(function()
			{
				var loadedSound:openfl.media.Sound = null;
				try
				{
					// Sound.fromFile() is the slow, blocking part (disk read + OGG decode).
					// It is safe to call from a non-main thread on native C++ targets because
					// OpenAL buffer upload only happens on the first play() call.
					loadedSound = AssetLoader.loadSound(filePath);
				}
				catch (e:Dynamic)
				{
					trace('[FreePlay] Thread error loading inst "$songName": $e');
				}

				// Hand off to the main thread via mutex-protected fields.
				// update() will pick this up and call playMusic() safely.
				_instLoadMutex.acquire();
				if (capturedToken == previewLoadToken)
				{
					_pendingInstSound = loadedSound;
					_pendingInstToken = capturedToken;
					_pendingInstIndex = capturedIndex;
					_pendingInstBpm = capturedBpm;
				}
				_instLoadMutex.release();
			});
			#else
			// Fallback for single-threaded targets (web, etc.): load synchronously.
			try
			{
				FlxG.sound.playMusic(Paths.inst(Paths.formatToSongPath(songs[requestedIndex].songName)), 0, true);
				applySongPreviewStart(songs[requestedIndex]);
				FlxG.sound.music.fadeIn(1.0, 0, 0.7);
				instSound = FlxG.sound.music;
				instPlaying = requestedIndex;

				Conductor.bpm = currentBPM;

				#if funkin.vis
				_analyzer = null;
				_analyzerLevels = null;
				_needsAnalyzerInit = true;
				#end
			}
			catch (e:Dynamic)
			{
				trace('Error loading inst for $songName: $e');
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7);
			}
			#end
		});
	}

	function getInstPreviewCacheKey(song:SongMetadata):String
	{
		if (song == null)
			return null;
		return Paths.getPath(Language.getFileTranslation('${Paths.formatToSongPath(song.songName)}/Inst') + '.${Paths.SOUND_EXT}', SOUND, 'songs', true);
	}

	function getInstPreviewFilePath(song:SongMetadata):String
	{
		if (song == null)
			return null;
		return Paths.getPath(Language.getFileTranslation('${Paths.formatToSongPath(song.songName)}/Inst') + '.${Paths.SOUND_EXT}', SOUND, 'songs', true);
	}

	/**
	 * Stop instrumental preview and return to freakyMenu.
	 */
	function stopInstPreview(?restoreMenuMusic:Bool = true):Void
	{
		previewLoadToken++;
		if (previewLoadTimer != null)
			previewLoadTimer.cancel();

		instPlaying = -1;
		instSound = null;

		if (restoreMenuMusic)
		{
			// Restore freeplay menu music — playMusic creates a fresh stream so
			// the SpectralAnalyzer can re-attach to it on the next frame.
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0, true);
			FlxG.sound.music.fadeIn(0.5, 0, 0.7);
		}

		#if funkin.vis
		_analyzer = null;
		_analyzerLevels = null;
		_needsAnalyzerInit = true;
		#end

		Conductor.bpm = 102;
		currentBPM = 102;
	}

	function releasePreviewSoundCache(songPath:String):Void
	{
		if (songPath == null || songPath.length == 0)
			return;

		var toRemove:Array<String> = [];
		for (key in Paths.currentTrackedSounds.keys())
		{
			if (key == songPath || key.contains(songPath) || key.contains('/' + songPath + '/'))
				toRemove.push(key);
		}

		for (key in toRemove)
		{
			openfl.Assets.cache.clear(key);
			Paths.currentTrackedSounds.remove(key);
			while (Paths.localTrackedAssets.remove(key))
			{
			}
		}
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];

	public function updateTexts(elapsed:Float = 0.0)
	{
		var themeSignature = OptionsMenuTheme.signature();
		if (themeSignature != lastThemeSignature)
		{
			lastThemeSignature = themeSignature;
			_cardVisualSignatures = [];
		}

		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
		var query:String = StringTools.trim(songSearchQuery != null ? songSearchQuery.toLowerCase() : "");
		for (i in _lastVisibles)
		{
			if (i >= 0 && i < songTextArray.length && songTextArray[i] != null)
				songTextArray[i].visible = songTextArray[i].active = false;
			if (i >= 0 && i < iconArray.length && iconArray[i] != null)
				iconArray[i].visible = iconArray[i].active = false;
			if (i >= 0 && i < cardArray.length && cardArray[i] != null)
				cardArray[i].visible = false;
			if (i >= 0 && i < cardAccentArray.length && cardAccentArray[i] != null)
				cardAccentArray[i].visible = false;
			if (i >= 0 && i < modTextArray.length && modTextArray[i] != null)
				modTextArray[i].visible = false;
		}
		_lastVisibles = [];

		var min:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected + _drawDistance)));
		for (i in min...max)
		{
			if (i < 0 || i >= songs.length || songs[i] == null)
				continue;
			if (query.length > 0 && !songMatchesFilter(songs[i], query))
				continue;

			ensureSongVisual(i);
			var item:FlxText = songTextArray[i];
			if (item == null)
				continue;
			item.visible = item.active = true;

			var difference:Float = item.ID - lerpSelected;
			var baseY:Float = 320;
			item.y = baseY + (difference * 120);

			var curveOffset:Float = Math.abs(difference) * Math.abs(difference) * 60;
			var itemOffset:Float = songsOffsetX;
			if (inDifficultySelect && item.ID == curSelected)
			{
				itemOffset = 0;
			}

			var baseX:Float = 90 - curveOffset + itemOffset;
			var icon:HealthIcon = iconArray[i];
			if (icon == null)
				continue;

			icon.visible = icon.active = true;
			var visibleAlpha:Float = (i == curSelected) ? 1 : 0.6;
			item.alpha = visibleAlpha;
			icon.alpha = visibleAlpha;
			icon.y = item.y - 20;

			var card:FlxSprite = cardArray[i];
			if (card == null)
				continue;
			card.visible = true;
			card.x = baseX + 80;
			card.y = item.y - 10;
			var isSelected = (i == curSelected) && !inDifficultySelect;
			var cardColor = songs[i].color;
			var cardFillColor = OptionsMenuTheme.difficultyCardFill(cardColor, isSelected);
			var cardStrokeColor = OptionsMenuTheme.difficultyCardStroke(cardColor, isSelected);
			if (i >= _cardVisualSignatures.length)
				_cardVisualSignatures.resize(i + 1);
			var usesCustomListCard:Bool = _cardVisualSignatures[i] != null && _cardVisualSignatures[i].startsWith('custom:');
			if (!usesCustomListCard)
			{
				var cardSignature:String = cardColor + ':' + isSelected;
				if (_cardVisualSignatures[i] != cardSignature)
				{
					MD3ShapeTools.fillAndStrokeRoundRect(card, 470, 110, 22, isSelected ? 3 : 2, cardFillColor, cardStrokeColor);
					_cardVisualSignatures[i] = cardSignature;
				}
			}

			var accentBar:FlxSprite = cardAccentArray[i];
			if (accentBar != null)
			{
				if (Std.int(accentBar.width) != 10 || Std.int(accentBar.height) != 84)
					MD3ShapeTools.fillRoundRect(accentBar, 10, 84, 5);
				accentBar.visible = true;
				accentBar.x = card.x + 12;
				accentBar.y = card.y + 13;
				accentBar.color = OptionsMenuTheme.cardAccent(isSelected);
				accentBar.alpha = isSelected ? 1.0 : 0.72;
			}

			icon.x = card.x + 340;
			item.x = card.x + 50;
			item.color = usesCustomListCard ? FlxColor.WHITE : OptionsMenuTheme.readableTextOn(cardFillColor);

			var modText:FlxText = modTextArray[i];
			if (modText == null)
				continue;
			var textBlockHeight:Float = item.height + 4 + modText.height;
			var textStartY:Float = card.y + Math.max(12, (card.height - textBlockHeight) * 0.5);
			item.y = textStartY;
			modText.visible = true;
			modText.x = item.x;
			modText.y = item.y + item.height + 4;
			modText.alpha = (i == curSelected) ? 0.82 : 0.58;
			modText.color = usesCustomListCard ? 0xFFD8DEE9 : OptionsMenuTheme.readableMetaTextOn(cardFillColor);

			_lastVisibles.push(i);
		}

		layerFree.color = intendedColor;

		if (inDifficultySelect || difficultySelector.enterProgress > 0)
		{
			difficultySelector.update(elapsed);
		}
		else
		{
			// Ocultar completamente los scoreTexts cuando no estamos en selector de dificultad
			for (scoreText in difficultySelector.scoreTexts.members)
			{
				if (scoreText != null)
					scoreText.alpha = 0;
			}
		}
	}

	#if (MODS_ALLOWED && sys && !mobile)
	function reloadModsFromFreeplay():Void
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));
		WeekData.reloadWeekFiles(false);
		Mods.loadTopMod();
		persistentUpdate = false;
		MusicBeatState.switchState(FreeplayStateSelector.create());
	}

	function copyModFolderRecursive(source:String, target:String):Void
	{
		if (!FileSystem.exists(target))
			FileSystem.createDirectory(target);

		for (entry in FileSystem.readDirectory(source))
		{
			var srcPath:String = Path.join([source, entry]);
			var dstPath:String = Path.join([target, entry]);
			if (FileSystem.isDirectory(srcPath))
				copyModFolderRecursive(srcPath, dstPath);
			else
			{
				var parentDir:String = Path.directory(dstPath);
				if (parentDir != null && parentDir.length > 0 && !FileSystem.exists(parentDir))
					FileSystem.createDirectory(parentDir);
				File.copy(srcPath, dstPath);
			}
		}
	}

	function importDroppedModFolder(path:String):Void
	{
		if (path == null || path.length < 1 || !FileSystem.exists(path) || !FileSystem.isDirectory(path))
			return;

		var folderName:String = Path.withoutDirectory(path);
		if (folderName == null || folderName.length < 1)
			return;

		var targetPath:String = Paths.mods(folderName);
		copyModFolderRecursive(path, targetPath);
		reloadModsFromFreeplay();
	}

	function onDropFile(path:String):Void
	{
		if (player != null && player.playingMusic)
			return;
		importDroppedModFolder(path);
	}
	#end

	/**
	 * Escanea la carpeta sm/ en la raíz del juego para cargar archivos .sm
	 */
	function loadStepManiaFiles():Void
	{
		#if sys
		#if mobile
		var smDir = StorageUtil.getSMDirectory();
		#else
		var smDir = './sm/';
		#end

		// Verificar si la carpeta sm existe
		if (!sys.FileSystem.exists(smDir))
		{
			trace('SM folder not found, creating it...');
			sys.FileSystem.createDirectory(smDir);
			return;
		}

		trace('Scanning for StepMania files...');

		// Escanear cada subcarpeta en sm/
		for (folder in sys.FileSystem.readDirectory(smDir))
		{
			var folderPath = smDir + folder;

			if (!sys.FileSystem.isDirectory(folderPath))
				continue;

			// Buscar archivo .sm en la carpeta
			var smFile:String = null;
			for (file in sys.FileSystem.readDirectory(folderPath))
			{
				if (file.endsWith('.sm'))
				{
					smFile = file;
					break;
				}
			}

			if (smFile == null)
			{
				trace('No .sm file found in ' + folder);
				continue;
			}

			// Cargar el archivo SM
			var fullPath = folderPath + '/' + smFile;

			try
			{
				var sm = backend.stepmania.SMFile.loadFile(fullPath);

				if (sm == null || !sm.isValid)
				{
					trace('Invalid SM file: ' + smFile);
					continue;
				}

				// Validar que el título no esté vacío
				if (sm.header == null || sm.header.TITLE == null || sm.header.TITLE.trim() == "")
				{
					trace('SM file has no title: ' + smFile);
					continue;
				}

				var cleanTitle = sm.header.TITLE;
				cleanTitle = StringTools.replace(cleanTitle, '\r', '');
				cleanTitle = StringTools.replace(cleanTitle, '\n', '');
				cleanTitle = StringTools.trim(cleanTitle);

				if (cleanTitle == "")
				{
					trace('Empty title after cleaning for: ' + smFile);
					continue;
				}

				// Crear nombre de archivo base
				var songNameClean = Paths.formatToSongPath(cleanTitle);
				if (songNameClean == null || songNameClean == "")
				{
					trace('Failed to format song name for: ' + cleanTitle);
					continue;
				}

				// Procesar cada dificultad del archivo SM
				for (diffIndex in 0...sm.difficulties.length)
				{
					var difficulty = sm.difficulties[diffIndex];

					var diffName = Paths.formatToSongPath(difficulty.name);
					// Usar solo el nombre de dificultad para el archivo JSON
					var jsonFileName = '$diffName.json';
					var jsonPath = folderPath + '/' + jsonFileName;
					var needsConversion = !sys.FileSystem.exists(jsonPath);

					// Convertir el SM a formato FNF
					if (needsConversion)
					{
						trace('Converting SM file: ${cleanTitle} [${difficulty.name}]');
						var song = sm.convertToFNF(diffName, diffIndex);

						if (song != null)
						{
							// Guardar el JSON convertido
							try
							{
								var json = haxe.Json.stringify({song: song}, null, '\t');
								sys.io.File.saveContent(jsonPath, json);
								trace('Saved converted chart: ' + jsonPath);
							}
							catch (e:Dynamic)
							{
								trace('Error saving converted chart: ' + e);
								continue;
							}
						}
						else
						{
							trace('Failed to convert SM difficulty: ${difficulty.name}');
							continue;
						}
					}
				}

				// Agregar UNA SOLA entrada para la canción (no una por dificultad)
				addSong(cleanTitle, -1, 'stepmania', FlxColor.fromRGB(255, 140, 0));

				// Marcar como canción de StepMania
				var lastSong = songs[songs.length - 1];
				if (lastSong != null)
				{
					lastSong.folder = '';
					lastSong.isStepMania = true;
					lastSong.smFolder = folder;
					// Guardar el nombre base de la canción (sin dificultad)
					lastSong.songName = songNameClean;

					// Guardar los nombres de las dificultades del .sm
					lastSong.smDifficulties = [];
					for (diff in sm.difficulties)
					{
						lastSong.smDifficulties.push(diff.name);
					}
				}
			}
			catch (e:Dynamic)
			{
				trace('Error loading SM file ' + smFile + ': ' + e);
				continue;
			}
		}
		#else
		trace('StepMania support not available on this platform');
		#end
	}

	override public function beatHit():Void
	{
		super.beatHit();
		bgZoom = 1.06;
		#if funkin.vis
		_vizBeatPulse = 1;
		if (vizBarsGroup != null)
			vizBarsGroup.visible = true;
		#end
	}

	override function destroy():Void
	{
		#if (MODS_ALLOWED && sys && !mobile)
		FlxG.stage.window.onDropFile.remove(onDropFile);
		#end

		if (songInfoCardLoadTimer != null)
		{
			songInfoCardLoadTimer.cancel();
			songInfoCardLoadTimer = null;
		}
		if (selectedSongDataTimer != null)
		{
			selectedSongDataTimer.cancel();
			selectedSongDataTimer = null;
		}
		if (previewTimer != null)
		{
			previewTimer.cancel();
			previewTimer = null;
		}
		if (previewLoadTimer != null)
		{
			previewLoadTimer.cancel();
			previewLoadTimer = null;
		}
		if (bgSwapTimer != null)
		{
			bgSwapTimer.cancel();
			bgSwapTimer = null;
		}
		if (bgFadeTweenIn != null)
		{
			bgFadeTweenIn.cancel();
			bgFadeTweenIn = null;
		}
		if (bgFadeTweenOut != null)
		{
			bgFadeTweenOut.cancel();
			bgFadeTweenOut = null;
		}
		if (songInfoCardTween != null)
		{
			songInfoCardTween.cancel();
			songInfoCardTween = null;
		}
		songInfoCardData = null;

		if (vizBarsGroup != null)
		{
			vizBarsGroup.destroy();
			vizBarsGroup = null;
		}

		#if funkin.vis
		_analyzer = null;
		_analyzerLevels = null;
		#end

		Conductor.bpm = 102;
		FlxG.mouse.visible = false;

		super.destroy();

		FlxG.autoPause = ClientPrefs.data.autoPause;
		if (!stopMusicPlay && (FlxG.sound.music == null || !FlxG.sound.music.playing))
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";
	public var lastDifficulty:String = null;
	public var isStepMania:Bool = false; // Identificador para canciones SM
	public var smFolder:String = ""; // Carpeta original del archivo .sm
	public var smDifficulties:Array<String> = []; // Nombres de las dificultades del .sm

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Mods.currentModDirectory;
		if (this.folder == null)
			this.folder = '';
	}
}

typedef FreeplayChartSummary =
{
	var bpm:Float;
	var noteCount:Int;
	var durationMs:Float;
}

typedef FreeplaySongCardData =
{
	var songName:String;
	var folder:String;
	var coverKey:String;
	var cardKey:String;
	var cardMode:String;
	var author:String;
	var links:Dynamic;
	var licenses:Array<String>;
	var licenseText:String;
	var bpm:Float;
	var durationMs:Float;
	var noteCount:Int;
	var difficultyNames:Array<String>;
}

typedef FreeplaySongMeta =
{
	var ?coverKey:String;
	var ?cardKey:String;
	var ?cardMode:String;
	var ?author:String;
	var ?links:Dynamic;
	var ?durationSeconds:Float;
	var ?licenses:Array<String>;
	var ?licenseText:String;
	var ?previewStartSeconds:Float;
	var ?previewEndSeconds:Float;
}

class DifficultySelector
{
	public var items:FlxTypedGroup<FlxText>;
	public var cards:FlxTypedGroup<FlxSprite>;
	public var scoreTexts:FlxTypedGroup<FlxText>; // Textos de score/accuracy
	public var curSelected:Int = 0;
	public var lerpSelected:Float = 0;
	public var enterProgress:Float = 0;

	private var baseXOffset:Float = 300;
	private var slideDistance:Float = 500;
	private var selectionTween:FlxTween;

	public function new()
	{
		items = new FlxTypedGroup<FlxText>();
		cards = new FlxTypedGroup<FlxSprite>();
		scoreTexts = new FlxTypedGroup<FlxText>();
	}

	public function loadDifficulties():Void
	{
		items.clear();
		cards.clear();
		scoreTexts.clear();

		// Solo cargar dificultades desde semana si NO es StepMania
		if (FreeplayState.instance != null && FreeplayState.instance.songs[FreeplayState.curSelected] != null)
		{
			if (!FreeplayState.instance.songs[FreeplayState.curSelected].isStepMania)
			{
				Difficulty.loadFromWeek();
			}

			// Detect all available difficulties using the FreeplayState function
			FreeplayState.instance.detectAndLoadAllDifficulties();
		}

		for (i in 0...Difficulty.list.length)
		{
			var diffText:FlxText = new FlxText(0, 0, 500, Difficulty.getString(i), 48);
			diffText.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			diffText.borderSize = 2;
			diffText.ID = i;
			diffText.alpha = 0;
			items.add(diffText);

			var card:FlxSprite = new FlxSprite();
			MD3ShapeTools.fillAndStrokeRoundRect(card, 470, 110, 22, 2, OptionsMenuTheme.cardFill(false), OptionsMenuTheme.cardStroke(false));
			card.alpha = 0;
			cards.add(card);

			// Crear texto de score/accuracy debajo de la dificultad
			var scoreInfoText:FlxText = new FlxText(0, 0, 450, "", 18);
			scoreInfoText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			scoreInfoText.ID = i;
			scoreInfoText.alpha = 0;
			scoreTexts.add(scoreInfoText);
		}

		// Actualizar los textos de score/accuracy
		updateScoreTexts();
	}

	public function updateScoreTexts():Void
	{
		if (FreeplayState.instance == null)
			return;

		for (i in 0...scoreTexts.members.length)
		{
			var scoreText:FlxText = scoreTexts.members[i];
			if (scoreText == null)
				continue;

			var diffIndex:Int = scoreText.ID;
			var song:SongMetadata = FreeplayState.instance.songs[FreeplayState.curSelected];
			var songName:String = song.songName;

			#if !switch
			var score:Int = 0;
			var accuracy:Float = 0;
			var accSystem:String = 'Unknown';
			score = Highscore.getScore(songName, diffIndex, FreeplayState.viewingOpponentScores);
			accuracy = Highscore.getRating(songName, diffIndex, FreeplayState.viewingOpponentScores);
			accSystem = Highscore.getAccuracySystem(songName, diffIndex, FreeplayState.viewingOpponentScores);

			var accPercent:String = '';
			if (accuracy > 0)
			{
				var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(accuracy * 100, 2)).split('.');
				if (ratingSplit.length < 2)
					ratingSplit.push('');
				while (ratingSplit[1].length < 2)
					ratingSplit[1] += '0';
				accPercent = ratingSplit.join('.');
			}
			else
			{
				accPercent = '0.00';
			}

			if (score > 0)
			{
				scoreText.text = Language.getPhrase('new_personal_best', 'Score: {1}\nAccuracy: {2}% ({3})', [score, accPercent, accSystem]);
			}
			else
			{
				scoreText.text = Language.getPhrase('new_no_score', 'No score yet');
			}
			#else
			scoreText.text = '';
			#end
		}
	}

	private function getDifficultyColor(diffName:String):Int
	{
		var lowerName = diffName.toLowerCase();

		// Normalizar nombres traducidos a inglés para detección consistente
		var normalizedName = normalizeDifficultyName(lowerName);

		// Colores pastel correspondientes a cada dificultad
		if (normalizedName == 'easy')
			return 0x8FD9A8; // Verde pastel
		else if (normalizedName == 'normal')
			return 0xFFE69C; // Amarillo pastel
		else if (normalizedName == 'hard')
			return 0xFFB3BA; // Rojo pastel
		else if (normalizedName == 'erect')
			return 0xFFB5E8; // Rosa/magenta pastel
		else if (normalizedName == 'nightmare')
			return 0xC7A3FF; // Púrpura pastel
		else
		{
			// Para dificultades personalizadas, generar colores pastel únicos
			var pastelColors:Array<Int> = [
				0xA78BFA, // Lavanda pastel
				0xFBB6CE, // Rosa claro pastel
				0x99E9F2, // Cyan pastel
				0xB8E994, // Verde lima pastel
				0xFFD8A8, // Naranja pastel
				0xE0BBE4, // Lila pastel
				0xBAE1FF, // Azul cielo pastel
				0xFFDAB9 // Durazno pastel
			];
			var hash = 0;
			for (i in 0...diffName.length)
				hash = hash * 31 + diffName.charCodeAt(i);
			var index = (hash < 0 ? -hash : hash) % pastelColors.length;
			return pastelColors[index];
		}
	}

	/**
	 * Normaliza nombres de dificultades traducidas a sus equivalentes en inglés
	 * para detección consistente de colores en diferentes idiomas
	 */
	private function normalizeDifficultyName(diffName:String):String
	{
		var lower = diffName.toLowerCase();

		// Obtener las traducciones de las dificultades estándar
		var easyTranslated = Language.getPhrase('difficulty_Easy', 'Easy').toLowerCase();
		var normalTranslated = Language.getPhrase('difficulty_Normal', 'Normal').toLowerCase();
		var hardTranslated = Language.getPhrase('difficulty_Hard', 'Hard').toLowerCase();
		var erectTranslated = Language.getPhrase('difficulty_Erect', 'Erect').toLowerCase();
		var nightmareTranslated = Language.getPhrase('difficulty_Nightmare', 'Nightmare').toLowerCase();

		// Comparar con traducciones
		if (lower == easyTranslated || lower == 'easy')
			return 'easy';

		if (lower == normalTranslated || lower == 'normal')
			return 'normal';

		if (lower == hardTranslated || lower == 'hard')
			return 'hard';

		if (lower == erectTranslated || lower == 'erect')
			return 'erect';

		if (lower == nightmareTranslated || lower == 'nightmare')
			return 'nightmare';

		// Si no coincide con ninguno, devolver el original
		return lower;
	}

	public function changeSelection(change:Int = 0):Void
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, Difficulty.list.length - 1);

		if (selectionTween != null)
			selectionTween.cancel();

		selectionTween = FlxTween.tween(this, {lerpSelected: curSelected}, 0.25, {
			ease: FlxEase.expoOut,
			onComplete: function(twn:FlxTween)
			{
				selectionTween = null;
			}
		});
	}

	public function update(elapsed:Float):Void
	{
		for (i in 0...items.members.length)
		{
			var item:FlxText = items.members[i];
			var card:FlxSprite = cards.members[i];
			var difference:Float = item.ID - lerpSelected;
			item.y = (difference * 120) + (FlxG.height * 0.5) - 60;
			var difficultyColor:Int = getDifficultyColor(item.text);
			var isSelected:Bool = (i == curSelected);
			var cardFillColor:Int = OptionsMenuTheme.difficultyCardFill(difficultyColor, isSelected);

			var baseX:Float = (FlxG.width * 0.5) - (card.width * 0.5) + baseXOffset;
			var targetX:Float = FlxMath.lerp(baseX + slideDistance, baseX, enterProgress);
			card.x = targetX;
			card.y = item.y - 15;
			MD3ShapeTools.fillAndStrokeRoundRect(card, 470, 110, 22, isSelected ? 3 : 2, cardFillColor,
				OptionsMenuTheme.difficultyCardStroke(difficultyColor, isSelected));

			item.x = card.x + (card.width * 0.5) - (item.width * 0.5);
			card.y = item.y - 15;
			item.color = OptionsMenuTheme.difficultyTitleColor(difficultyColor, isSelected);

			// Posicionar texto de score/accuracy debajo de la dificultad
			if (i < scoreTexts.members.length)
			{
				var scoreText:FlxText = scoreTexts.members[i];
				if (scoreText != null)
				{
					scoreText.x = card.x + (card.width * 0.5) - (scoreText.width * 0.5);
					scoreText.y = item.y + 50; // Más abajo del nombre de dificultad
					scoreText.color = OptionsMenuTheme.difficultyMetaColor(difficultyColor, isSelected);

					if (isSelected)
					{
						scoreText.alpha = 1.0 * enterProgress;
					}
					else
					{
						scoreText.alpha = 0.6 * enterProgress;
					}
				}
			}

			if (isSelected)
			{
				item.alpha = 1.0 * enterProgress;
				card.alpha = 1.0 * enterProgress;
			}
			else
			{
				item.alpha = 0.6 * enterProgress;
				card.alpha = 0.6 * enterProgress;
			}
		}
	}
}

