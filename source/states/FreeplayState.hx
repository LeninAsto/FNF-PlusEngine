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
	private var curPlaying:Bool = false;
	private var searchField:MaterialTextField;
	private var songSearchQuery:String = "";
	private var songInfoCardBg:FlxSprite;
	private var songInfoCardCover:FlxSprite;
	private var songInfoCardTitle:FlxText;
	private var songInfoCardStats:FlxText;
	private var songInfoCardDifficulty:FlxText;
	private var songInfoCardScores:FlxText;
	private var songInfoCardLoadingLabel:FlxText;
	private var songInfoCardSpinner:MaterialWavyProgressIndicator;
	private var songInfoCardY:Float = 0;
	private var songInfoCardHiddenY:Float = 0;
	private var songInfoCardShownY:Float = 0;
	private var songInfoCardTween:FlxTween = null;
	private var songInfoCardLoadTimer:FlxTimer = null;
	private var songInfoCardLoadToken:Int = 0;
	private var songInfoCardLoading:Bool = false;
	private var songInfoCardData:FreeplaySongCardData = null;

	private var iconArray:Array<HealthIcon> = [];

	public var bg:FlxSprite;
	public var intendedColor:Int;

	public var missingTextBG:FlxSprite;
	public var missingText:FlxText;

	public var bottomString:String;
	public var bottomText:FlxText;

	public var player:MusicPlayer;
	
	public var inDifficultySelect:Bool = false;
	public var difficultySelector:DifficultySelector;
	public var songsOffsetX:Float = 0;
	
	public var blackOverlay:FlxSprite;
	public var layerFree:FlxSprite;
	public var cardArray:Array<FlxSprite> = [];
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
	static inline var PREVIEW_LOAD_DELAY:Float = 0.12;
	public static var instSound:FlxSound = null;

	#if mobile
	static inline var VIZ_BAR_COUNT:Int = 96;
	#else
	static inline var VIZ_BAR_COUNT:Int = 160;
	#end

	public static inline var VIZ_BAR_MAX_H:Int = 240;
	public static inline var VIZ_BAR_FILL:Float = 0.62;
	public static inline var VIZ_MIN_H:Int = 2;
	public static inline var VIZ_SMOOTH_SPEED:Float = 18;
	public static inline var VIZ_UPDATE_INTERVAL:Float = 1 / 60;

	public var _curAccentColor:Int = 0xFFB566FF;
	public var _vizCurrentHeights:Array<Float> = [];
	public var _vizTargetHeights:Array<Float> = [];
	public var _vizUpdateAccum:Float = 0;

	override function create()
	{
		//Paths.clearStoredMemory();
		//Paths.clearUnusedMemory();
		
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

		if(WeekData.weeksList.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new states.ErrorState("NO WEEKS ADDED FOR FREEPLAY\n\nPress " + accept + " to go to the Week Editor Menu.\nPress " + reject + " to return to Main Menu.",
				function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
				function() MusicBeatState.switchState(new states.MainMenuState())));
			return;
		}

		for (i in 0...WeekData.weeksList.length)
		{
			if(weekIsLocked(WeekData.weeksList[i])) continue;

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
				if(songName.endsWith('-erect'))
					continue;
				
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		Mods.loadTopMod();

		// Cargar archivos StepMania (.sm)
		loadStepManiaFiles();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();
		bgZoom = defaultBgZoom = 1;
		
		blackOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		blackOverlay.alpha = 0.1;
		add(blackOverlay);

        vizBarsGroup = new FlxTypedGroup<FlxSprite>();

		var vizBarW:Int = Std.int(FlxG.width / VIZ_BAR_COUNT);
		var vizDrawW:Int = Std.int(Math.max(1, vizBarW * VIZ_BAR_FILL));
		var vizOffsetX:Float = (vizBarW - vizDrawW) * 0.5;

		for(i in 0...VIZ_BAR_COUNT) {
		    var vbar:FlxSprite = new FlxSprite();
		    vbar.makeGraphic(vizDrawW, VIZ_BAR_MAX_H, FlxColor.WHITE);
		    vbar.x = i * vizBarW + vizOffsetX;
		    vbar.y = FlxG.height - VIZ_BAR_MAX_H;
		    vbar.alpha = 0.7;
		
		    vizBarsGroup.add(vbar);
		}

		add(vizBarsGroup);
		
		layerFree = new FlxSprite().loadGraphic(Paths.image('ui/layerfree'));
		layerFree.antialiasing = ClientPrefs.data.antialiasing;
		layerFree.setGraphicSize(FlxG.width, FlxG.height);
		layerFree.updateHitbox();
		layerFree.alpha = 0.5;
		add(layerFree);
		OptionsMenuTheme.syncAccent();
		lastThemeSignature = OptionsMenuTheme.signature();

		// Primero crear y añadir las cards (fondo)
		for (i in 0...songs.length)
		{
			// Validar que la canción tenga datos válidos
			if (songs[i] == null || songs[i].songName == null || songs[i].songName == "")
			{
				trace('Skipping invalid song at index $i');
				continue;
			}

			try 
			{
				var card:FlxSprite = new FlxSprite();
				var cardColor:Int = songs[i].color;
				var darkestColor = FlxColor.interpolate(cardColor, FlxColor.BLACK, 0.5);
				MD3ShapeTools.fillAndStrokeRoundRect(card, 470, 110, 22, 2, darkestColor, OptionsMenuTheme.cardStroke(false));
				if (card != null && card.graphic != null)
				{
					card.antialiasing = ClientPrefs.data.antialiasing;
					card.visible = false;
					cardArray.push(card);
					add(card);
				}
				else
				{
					// Crear card vacía si falla la carga de imagen
					var card:FlxSprite = new FlxSprite().makeGraphic(470, 110, FlxColor.GRAY);
					card.visible = false;
					cardArray.push(card);
					add(card);
				}
			}
			catch (e:Dynamic)
			{
				trace('Error creating card for song ${songs[i].songName}: $e');
				// Crear card de respaldo
				var card:FlxSprite = new FlxSprite().makeGraphic(470, 110, FlxColor.GRAY);
				card.visible = false;
				cardArray.push(card);
				add(card);
			}
		}

		// Ahora crear los textos y elementos que van encima
		grpSongs = new FlxTypedGroup<FlxText>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			// Validar que la canción tenga datos válidos
			if (songs[i] == null || songs[i].songName == null || songs[i].songName == "")
			{
				trace('Skipping invalid song at index $i');
				continue;
			}
			
			var songText:FlxText = new FlxText(90, 320, 400, songs[i].songName, 32);
			songText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			songText.borderSize = 2;
			songText.ID = i;
			grpSongs.add(songText);

			// Para canciones de StepMania, no cambiar el directorio de mod
			if (!songs[i].isStepMania)
			{
				Mods.currentModDirectory = songs[i].folder;
			}
			
			// Validar el personaje para el icono
			var characterName = songs[i].songCharacter;
			if (characterName == null || characterName == "")
			{
				characterName = songs[i].isStepMania ? "stepmania" : "bf";
			}
			
			var icon:HealthIcon = new HealthIcon(characterName);
			icon.scale.set(0.8, 0.8);
			
			// too laggy with a lot of songs, so i had to recode the logic for it
			songText.visible = songText.active = false;
			icon.visible = icon.active = false;
		
			var modName:String = songs[i].folder;
			if (modName == null || modName == '')
			{
				// Verificar si es una canción de StepMania
				if (songs[i].isStepMania)
					modName = "StepMania";
				else
					modName = "Friday Night Funkin";
			}

			var modText:FlxText = new FlxText(0, 0, 400, modName, 20);
			modText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT);
			modText.alpha = 0.7;
			modText.visible = false;
			modTextArray.push(modText);
			add(modText);

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);
			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}
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

		searchField = new MaterialTextField(FlxG.width - 238, 12, 206, Language.getPhrase("freeplay_search", "Search..."));
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

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;
		for (i in 0...vizBarsGroup.members.length)
		{
			var bar = vizBarsGroup.members[i];
			var lightBar = FlxColor.interpolate(intendedColor, FlxColor.WHITE, 0.3);
			if(bar != null) bar.color = lightBar;
		}
		lerpSelected = curSelected;

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		final space:String = (controls.mobileC) ? "X" : "SPACE";
		final control:String = (controls.mobileC) ? "C" : "CTRL";
		final reset:String = (controls.mobileC) ? "Y" : "RESET";
		
		var leText:String = Language.getPhrase("freeplay_tip", "Press {1} to listen to the Song / Press {2} to open the Gameplay Changers Menu / Press {3} to Reset your Score and Accuracy.", [space, control, reset]);
		bottomString = leText;
		var size:Int = 16;
		bottomText = new FlxText(0, FlxG.height - 24, FlxG.width, leText, size);
		bottomText.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, CENTER);
		bottomText.scrollFactor.set();
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
		
		addTouchPad('UP_DOWN', 'A_B_C_X_Y_Z');
		addTouchPadCamera();
		if(touchPad != null) {
			touchPad.visible = true;
			touchPad.updateTrackedButtons();
		}
	}

	override function closeSubState()
	{
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
		removeTouchPad();
		addTouchPad('UP_DOWN', 'A_B_C_X_Y_Z');
		addTouchPadCamera();
		if(touchPad != null) {
			touchPad.visible = true;
			touchPad.updateTrackedButtons();
		}
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

		return songName.contains(queryLower)
			|| folderName.contains(queryLower)
			|| characterName.contains(queryLower)
			|| smFolderName.contains(queryLower);
	}

	function updateSongFilter(value:String):Void
	{
		songSearchQuery = StringTools.trim(value != null ? value : "");

		if (songSearchQuery.length > 0 && curSelected >= 0 && curSelected < songs.length)
		{
			var query:String = songSearchQuery.toLowerCase();
			if (!songMatchesFilter(songs[curSelected], query))
			{
				for (i in 0...songs.length)
				{
					if (songMatchesFilter(songs[i], query))
					{
						curSelected = i;
						break;
					}
				}
			}
		}

		updateCurrentBpmFromSelection();
		queueSongInfoCardLoad();
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
				var smDiffName:String = (selectedSong.smDifficulties != null && selectedSong.smDifficulties.length > 0)
					? Paths.formatToSongPath(selectedSong.smDifficulties[Std.int(FlxMath.bound(curDifficulty, 0, selectedSong.smDifficulties.length - 1))])
					: 'normal';
				var smDir:String = #if mobile StorageUtil.getSMDirectory() #else './sm/' #end;
				var smPath:String = smDir + selectedSong.smFolder + '/' + smDiffName + '.json';
				if (sys.FileSystem.exists(smPath))
				{
					var rawJson:String = sys.io.File.getContent(smPath);
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
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	public static var opponentVocals:FlxSound = null;
	var holdTime:Float = 0;

	var stopMusicPlay:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);
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

		 #if (target.threaded && sys)
        // Dispatch a pending inst sound loaded by the background thread.
        // playMusic() and all OpenAL calls must happen on the main thread.
        _instLoadMutex.acquire();
        var pendingSound:openfl.media.Sound = _pendingInstSound;
        var pendingToken:Int = _pendingInstToken;
        var pendingIndex:Int = _pendingInstIndex;
        var pendingBpm:Float = _pendingInstBpm;
        if(pendingSound != null) _pendingInstSound = null;
        _instLoadMutex.release();

        if(pendingSound != null && pendingToken == previewLoadToken && pendingIndex == curSelected) {
            try {
                // Register in Paths cache so it gets cleaned up correctly later
                var cacheKey:String = Paths.getPath(
                    Language.getFileTranslation('${Paths.formatToSongPath(songs[pendingIndex].songName)}/Inst') + '.${Paths.SOUND_EXT}',
                    openfl.utils.AssetType.SOUND, 'songs', true
                );
                if(!Paths.currentTrackedSounds.exists(cacheKey))
                    Paths.currentTrackedSounds.set(cacheKey, pendingSound);
                Paths.localTrackedAssets.push(cacheKey);

				FlxG.sound.playMusic(pendingSound, 0, true);
				FlxG.sound.music.fadeIn(1.0, 0, 0.7);
				instSound = FlxG.sound.music;
				instPlaying = pendingIndex;

				if (songInfoCardData != null && pendingIndex == curSelected && songInfoCardData.durationMs <= 0 && pendingSound.length > 0)
				{
					songInfoCardData.durationMs = pendingSound.length;
					if (songInfoCardStats != null)
						songInfoCardStats.text = 'Tiempo: ${formatDuration(songInfoCardData.durationMs)}\nBPM: ${formatFloat(songInfoCardData.bpm)}';
				}

				Conductor.bpm = pendingBpm;

                #if funkin.vis
                _analyzer = null;
                _analyzerLevels = null;
                _needsAnalyzerInit = true;
                #end
            } catch(e:Dynamic) {
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
		if(pendingCard != null) _pendingSongCardData = null;
		_songCardMutex.release();

		if(pendingCard != null && pendingCardToken == songInfoCardLoadToken && pendingCardIndex == curSelected)
		{
			applySongInfoCardData(pendingCard);
		}
		#end
		
		// Full-width bottom spectral visualizer bars — driven exclusively by SpectralAnalyzer.
        #if funkin.vis
        // Lazy-init: attach to FlxG.sound.music as soon as __audioSource is ready.
        // Both inst preview and freeplay bg music go through FlxG.sound.music now.
        if(_needsAnalyzerInit && FlxG.sound.music != null && FlxG.sound.music.playing) {
            @:privateAccess
            if(FlxG.sound.music._channel != null && FlxG.sound.music._channel.__audioSource != null) {
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
        if(vizBarsGroup != null) {
            var vizBarW:Int = Std.int(FlxG.width / VIZ_BAR_COUNT);
            var vizOffsetX:Float = (vizBarW - Std.int(Math.max(1, vizBarW * VIZ_BAR_FILL))) * 0.5;

            if (_vizUpdateAccum >= VIZ_UPDATE_INTERVAL)
            {
                _vizUpdateAccum = 0;
                if(_analyzer != null) {
                    _analyzerLevels = _analyzer.getLevels(_analyzerLevels);
                    for(i in 0...vizBarsGroup.members.length) {
                        var level:Float = (i < _analyzerLevels.length) ? _analyzerLevels[i].value : 0.0;
                        _vizTargetHeights[i] = Math.max(VIZ_MIN_H, level * VIZ_BAR_MAX_H);
                    }
                } else {
                    for(i in 0...vizBarsGroup.members.length) {
                        _vizTargetHeights[i] = VIZ_MIN_H;
                    }
                }
            }

            var lerpFactor:Float = 1 - Math.exp(-elapsed * VIZ_SMOOTH_SPEED);
            for(i in 0...vizBarsGroup.members.length) {
                var vbar = vizBarsGroup.members[i];
                if(vbar == null) continue;

                var curH:Float = _vizCurrentHeights[i];
                var targetH:Float = _vizTargetHeights[i];
                curH = FlxMath.lerp(targetH, curH, 1 - lerpFactor);
                _vizCurrentHeights[i] = curH;

                vbar.scale.y = curH / VIZ_BAR_MAX_H;
                // vbar.x is set once at create() — vizBarW/vizOffsetX are constants
                vbar.y = FlxG.height - curH;
                vbar.alpha = 1.0;
            }
        }
        #end
		
		if(WeekData.weeksList.length < 1)
			return;

		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * elapsed;
		
		Conductor.songPosition = FlxG.sound.music.time;
		
		bgZoom = FlxMath.lerp(defaultBgZoom, bgZoom, Math.exp(-elapsed * 3.125));
		bg.scale.set(bgZoom, bgZoom);
		bg.updateHitbox();
		bg.screenCenter();

		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
		lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingPercent:Float = CoolUtil.floorDecimal(lerpRating * 100, 2);
		var ratingSplit:Array<String> = Std.string(Math.abs(ratingPercent)).split('.');
		if(ratingSplit.length < 2) //No decimals, add an empty space
			ratingSplit.push('');
	
		while(ratingSplit[1].length < 2) //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
	
		var ratingDisplay:String = ratingSplit.join('.');
		if(ratingPercent < 0) ratingDisplay = '-' + ratingDisplay;

		var shiftMult:Int = 1;
		if((FlxG.keys.pressed.SHIFT || (touchPad != null && touchPad.buttonZ.pressed)) && !player.playingMusic) shiftMult = 3;

		if (!searchFocused && !player.playingMusic)
		{
			// scoreText ya no se muestra, los scores se muestran debajo de cada dificultad
			
			if (!inDifficultySelect)
			{
				if(songs.length > 1)
				{
					if(FlxG.keys.justPressed.HOME)
					{
						curSelected = 0;
						changeSelection();
						holdTime = 0;	
					}
					else if(FlxG.keys.justPressed.END)
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

				if(controls.UI_DOWN || controls.UI_UP || (touchPad != null && (touchPad.buttonDown.pressed || touchPad.buttonUp.pressed)))
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						var isUp:Bool = controls.UI_UP || (touchPad != null && touchPad.buttonUp.pressed);
						changeSelection((checkNewHold - checkLastHold) * (isUp ? -shiftMult : shiftMult));
					}
				}					if(FlxG.mouse.wheel != 0)
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

		if (!searchFocused && (controls.BACK || (touchPad != null && touchPad.buttonB.justPressed)))
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
				MusicBeatState.switchState(new MainMenuState());
			}
		}

		if(!searchFocused && (FlxG.keys.justPressed.CONTROL || (touchPad != null && touchPad.buttonC.justPressed)) && !player.playingMusic)
		{
			persistentUpdate = false;
			removeTouchPad();
			openSubState(new GameplayChangersSubstate());
		}
		if(!searchFocused && (FlxG.keys.justPressed.SPACE || (touchPad != null && touchPad.buttonX.justPressed)))
		{
			if(instPlaying != curSelected && !player.playingMusic)
			{
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;

				Mods.currentModDirectory = songs[curSelected].folder;
				
				// Load all available difficulties for this song before loading the chart
				Difficulty.loadFromWeek();
				detectAndLoadAllDifficulties();
				
				// Make sure curDifficulty is within bounds
				if(curDifficulty >= Difficulty.list.length)
					curDifficulty = 0;
				
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				if (PlayState.SONG.needsVoices)
				{
					vocals = new FlxSound();
					try
					{
						var playerVocals:String = getVocalFromCharacter(PlayState.SONG.player1);
						var loadedVocals = Paths.voices(PlayState.SONG.song, (playerVocals != null && playerVocals.length > 0) ? playerVocals : 'Player');
						if(loadedVocals == null) loadedVocals = Paths.voices(PlayState.SONG.song);
						
						if(loadedVocals != null && loadedVocals.length > 0)
						{
							vocals.loadEmbedded(loadedVocals);
							FlxG.sound.list.add(vocals);
							vocals.persist = vocals.looped = true;
							vocals.volume = 0.8;
							vocals.play();
							vocals.pause();
						}
						else vocals = FlxDestroyUtil.destroy(vocals);
					}
					catch(e:Dynamic)
					{
						vocals = FlxDestroyUtil.destroy(vocals);
					}
					
					opponentVocals = new FlxSound();
					try
					{
						//trace('please work...');
						var oppVocals:String = getVocalFromCharacter(PlayState.SONG.player2);
						var loadedVocals = Paths.voices(PlayState.SONG.song, (oppVocals != null && oppVocals.length > 0) ? oppVocals : 'Opponent');
						
						if(loadedVocals != null && loadedVocals.length > 0)
						{
							opponentVocals.loadEmbedded(loadedVocals);
							FlxG.sound.list.add(opponentVocals);
							opponentVocals.persist = opponentVocals.looped = true;
							opponentVocals.volume = 0.8;
							opponentVocals.play();
							opponentVocals.pause();
							//trace('yaaay!!');
						}
						else opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
					}
					catch(e:Dynamic)
					{
						//trace('FUUUCK');
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
			else if (!searchFocused && (controls.ACCEPT || (touchPad != null && touchPad.buttonA.justPressed)) && !player.playingMusic)
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
						if (smDiffIndex < 0 || smDiffIndex >= songs[curSelected].smDifficulties.length) {
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
					
					if (sys.FileSystem.exists(smPath))
					{
						var rawJson:String = sys.io.File.getContent(smPath);
						PlayState.SONG = Song.parseJSON(rawJson, songLowercase);
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
					}
					
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = difficultySelector.curSelected;

					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
				}
				catch(e:haxe.Exception)
				{
					trace('ERROR! ${e.message}');

					var errorStr:String = e.message;
					if(errorStr.contains('There is no TEXT asset with an ID of')) errorStr = 'Missing file: ' + errorStr.substring(errorStr.indexOf(songLowercase), errorStr.length-1); //Missing chart
					else errorStr += '\n\n' + e.stack;


				missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
				missingText.screenCenter(Y);
				missingText.visible = true;
				missingTextBG.visible = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));

				updateTexts(elapsed);
				return;
		}			@:privateAccess
			if(PlayState._lastLoadedModDirectory != Mods.currentModDirectory)
			{
				trace('CHANGED MOD DIRECTORY, RELOADING STUFF');
				Paths.freeGraphicsFromMemory();
			}
			LoadingState.prepareToSong();
			LoadingState.returnState = new FreeplayState(); // Establecer estado de retorno
			LoadingState.loadAndSwitchState(new PlayState());
			#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
			stopMusicPlay = true;				destroyFreeplayVocals();
				#if (MODS_ALLOWED && DISCORD_ALLOWED)
				DiscordClient.loadModRPC();
				#end
			}
		}
		else if(!searchFocused && (controls.RESET || (touchPad != null && touchPad.buttonY.justPressed)) && !player.playingMusic)
		{
		persistentUpdate = false;
		removeTouchPad();
		openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

		updateSongInfoCardLayout();
		updateTexts(elapsed);
	}
	function getVocalFromCharacter(char:String)
	{
		try
		{
			var path:String = Paths.getPath('characters/$char.json', TEXT);
			var rawText:String = AssetLoader.loadText(path);
			if(rawText == null || rawText.length == 0) return null;
			var character:Dynamic = Json.parse(rawText);
			return character.vocals_file;
		}
		catch (e:Dynamic) {}
		return null;
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) vocals.stop();
		vocals = FlxDestroyUtil.destroy(vocals);

		if(opponentVocals != null) opponentVocals.stop();
		opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
	}

	function changeDiff(change:Int = 0)
	{
		if (player.playingMusic)
			return;

		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length-1);
		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty, viewingOpponentScores);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty, viewingOpponentScores);
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty, false);

		missingText.visible = false;
		missingTextBG.visible = false;
	}

	function enterDifficultySelect()
	{
		inDifficultySelect = true;
		FlxG.sound.play(Paths.sound('scrollMenu'));
		hideSongInfoCard();

		difficultySelector.loadDifficulties();
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
			onComplete: function(twn:FlxTween) {
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

		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length-1);
		_updateSongLastDifficulty();
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var newColor:Int = songs[curSelected].color;
		if(newColor != intendedColor)
		{
			intendedColor = newColor;
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 1, bg.color, intendedColor);
			for (bar in 0...vizBarsGroup.members.length)
			{
				var vizBar:FlxSprite = vizBarsGroup.members[bar];
				var lightBar = FlxColor.interpolate(intendedColor, FlxColor.WHITE, 0.3);
				if(vizBar == null) continue;
				FlxTween.cancelTweensOf(vizBar);
				if(vizBar != null) FlxTween.color(vizBar, 1, vizBar.color, lightBar);
			}
		}

		for (num => item in grpSongs.members)
		{
			var icon:HealthIcon = iconArray[num];
			item.alpha = 0.6;
			icon.alpha = 0.6;
			if (item.ID == curSelected)
			{
			item.alpha = 1;
			icon.alpha = 1;
			}
		}

		// Para canciones de StepMania, no cambiar el directorio de mod
		if (!songs[curSelected].isStepMania) {
			Mods.currentModDirectory = songs[curSelected].folder;
		} else {
			Mods.currentModDirectory = '';
		}
		
		PlayState.storyWeek = songs[curSelected].week;
		
		// Solo cargar dificultades desde semana si NO es StepMania
		if (!songs[curSelected].isStepMania) {
			Difficulty.loadFromWeek();
		}
		
		// Detect all available difficulties for this song
		detectAndLoadAllDifficulties();
		
		
		// Protección para canciones de StepMania o sin dificultades
		if (Difficulty.list == null || Difficulty.list.length == 0) {
			Difficulty.list = ['Normal']; // Dificultad por defecto
		}
		
		var savedDiff:String = songs[curSelected].lastDifficulty;
		
		var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
		
		if(savedDiff != null && !Difficulty.list.contains(savedDiff) && Difficulty.list.contains(savedDiff))
			curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
		else if(lastDiff > -1)
			curDifficulty = lastDiff;
		else if(Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		changeDiff();
		_updateSongLastDifficulty();

		if(previewTimer != null) {
            previewTimer.cancel();
            previewTimer = null;
        }
        
		if (instPlaying != -1 || instSound != null || _prevInstSongName != null)
            stopInstPreview(false);

		updateCurrentBpmFromSelection();
		queueSongInfoCardLoad();

		if (songs[curSelected].isStepMania) {
            // StepMania songs don't use the regular inst preview loader.
        } else {
            previewTimer = new FlxTimer().start(0.5, function(tmr:FlxTimer) {
                playInstPreview();
                previewTimer = null;
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
		var cardW:Int = 402;
		var cardH:Int = 418;
		songInfoCardShownY = Math.max(56, (FlxG.height - cardH) * 0.5);
		songInfoCardHiddenY = FlxG.height + 60;
		songInfoCardY = songInfoCardShownY;

		var cardX:Float = FlxG.width - cardW - 58;

		songInfoCardBg = new FlxSprite(cardX, songInfoCardY);
		MD3ShapeTools.fillAndStrokeRoundRect(songInfoCardBg, cardW, cardH, 24, 3, OptionsMenuTheme.cardFill(true), intendedColor);
		songInfoCardBg.alpha = 0.94;
		add(songInfoCardBg);

		songInfoCardCover = new FlxSprite(cardX + (cardW - 128) * 0.5, songInfoCardY + 18);
		songInfoCardCover.antialiasing = ClientPrefs.data.antialiasing;
		var fallbackCover = Paths.image('albumRoll/example');
		if (fallbackCover != null)
			songInfoCardCover.loadGraphic(fallbackCover);
		songInfoCardCover.setGraphicSize(128, 128);
		songInfoCardCover.updateHitbox();
		add(songInfoCardCover);

		songInfoCardTitle = new FlxText(cardX + 18, songInfoCardY + 160, cardW - 36, "", 26);
		songInfoCardTitle.setFormat(Paths.font('NotoSans-Medium.ttf'), 26, FlxColor.WHITE, CENTER);
		songInfoCardTitle.borderSize = 0;
		songInfoCardTitle.alpha = 0.95;
		add(songInfoCardTitle);

		songInfoCardStats = new FlxText(cardX + 18, songInfoCardY + 206, cardW - 36, "", 16);
		songInfoCardStats.setFormat(Paths.font('NotoSans-Medium.ttf'), 16, FlxColor.WHITE, LEFT);
		songInfoCardStats.alpha = 0.9;
		add(songInfoCardStats);

		songInfoCardDifficulty = new FlxText(cardX + 18, songInfoCardY + 258, cardW - 36, "", 13);
		songInfoCardDifficulty.setFormat(Paths.font('NotoSans-Medium.ttf'), 13, FlxColor.WHITE, LEFT);
		songInfoCardDifficulty.alpha = 0.88;
		songInfoCardDifficulty.wordWrap = true;
		add(songInfoCardDifficulty);

		songInfoCardScores = new FlxText(cardX + 18, songInfoCardY + 294, cardW - 36, "", 13);
		songInfoCardScores.setFormat(Paths.font('NotoSans-Medium.ttf'), 13, FlxColor.WHITE, LEFT);
		songInfoCardScores.alpha = 0.88;
		songInfoCardScores.wordWrap = true;
		add(songInfoCardScores);

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
		queueSongInfoCardLoad();
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
			onComplete: function(_) {
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
			onComplete: function(_) {
				songInfoCardTween = null;
			}
		});
	}

	function setFreeplayLoadingUi(active:Bool):Void
	{
		// Solo se oculta la card de datos de la canción; el resto del Freeplay sigue normal.
		if (songInfoCardCover != null) songInfoCardCover.visible = !active;
		if (songInfoCardTitle != null) songInfoCardTitle.visible = !active;
		if (songInfoCardStats != null) songInfoCardStats.visible = !active;
		if (songInfoCardDifficulty != null) songInfoCardDifficulty.visible = !active;
		if (songInfoCardScores != null) songInfoCardScores.visible = !active;
		if (songInfoCardSpinner != null) songInfoCardSpinner.visible = active;
		if (songInfoCardLoadingLabel != null) songInfoCardLoadingLabel.visible = active;
	}

	function queueSongInfoCardLoad():Void
	{
		if (songs == null || songs.length == 0 || curSelected < 0 || curSelected >= songs.length)
			return;

		songInfoCardLoadToken++;
		var requestToken:Int = songInfoCardLoadToken;
		var requestIndex:Int = curSelected;

		if (songInfoCardLoadTimer != null)
		{
			songInfoCardLoadTimer.cancel();
			songInfoCardLoadTimer = null;
		}

		songInfoCardLoading = true;
		setFreeplayLoadingUi(true);

		songInfoCardLoadTimer = new FlxTimer().start(1.0, function(_:FlxTimer) {
			songInfoCardLoadTimer = null;
			if (requestToken != songInfoCardLoadToken || requestIndex != curSelected)
				return;

			var song:SongMetadata = songs[requestIndex];
			var diffNames:Array<String> = getSongDifficultyNames(song);
			var bpmSnapshot:Float = currentBPM;

			#if (target.threaded && sys)
			_songCardMutex.acquire();
			_pendingSongCardData = null;
			_songCardMutex.release();

			ThreadUtil.execAsync(function() {
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
							coverKey: 'albumRoll/${Paths.formatToSongPath(song.songName)}',
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
		songInfoCardLoading = false;
		setFreeplayLoadingUi(false);

		if (songInfoCardTitle != null)
			songInfoCardTitle.text = data.songName;

		if (songInfoCardStats != null)
			songInfoCardStats.text = 'Tiempo: ${formatDuration(data.durationMs)}\nBPM: ${formatFloat(data.bpm)}';

		var diffList:Array<String> = data.difficultyNames != null ? data.difficultyNames.copy() : [];
		var diffLabel:String = diffList.length > 0 ? diffList.join(', ') : 'Normal';
		if (songInfoCardDifficulty != null)
			songInfoCardDifficulty.text = 'Difficulties: $diffLabel';

		if (songInfoCardScores != null)
		{
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
			songInfoCardScores.text = 'Scores:\n' + scoreLines.join('\n');
		}

		var coverGraphic:FlxGraphic = Paths.image(data.coverKey);
		if (coverGraphic == null)
			coverGraphic = Paths.image('albumRoll/example');
		if (coverGraphic != null && songInfoCardCover != null)
		{
			songInfoCardCover.loadGraphic(coverGraphic);
			songInfoCardCover.setGraphicSize(128, 128);
			songInfoCardCover.updateHitbox();
		}

		if (!inDifficultySelect)
			showSongInfoCard();
	}

	function updateSongInfoCardLayout():Void
	{
		if (songInfoCardBg == null)
			return;

		var cardW:Int = 402;
		var cardH:Int = 418;
		var cardX:Float = FlxG.width - cardW - 58;
		var baseY:Float = songInfoCardY;

		songInfoCardBg.x = cardX;
		songInfoCardBg.y = baseY;
		MD3ShapeTools.fillAndStrokeRoundRect(songInfoCardBg, cardW, cardH, 24, 3, OptionsMenuTheme.cardFill(true), intendedColor);
		songInfoCardBg.alpha = 0.94;

		songInfoCardCover.x = cardX + (cardW - 128) * 0.5;
		songInfoCardCover.y = baseY + 18;
		songInfoCardTitle.x = cardX + 18;
		songInfoCardTitle.y = baseY + 160;
		songInfoCardStats.x = cardX + 18;
		songInfoCardStats.y = baseY + 206;
		songInfoCardDifficulty.x = cardX + 18;
		songInfoCardDifficulty.y = baseY + 258;
		songInfoCardScores.x = cardX + 18;
		songInfoCardScores.y = baseY + 294;
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
				if (summary.durationMs > longestDuration)
					longestDuration = summary.durationMs;
				if (capturedBpm <= 0 && summary.bpm > 0)
					capturedBpm = summary.bpm;
			}
		}

		return {
			songName: song.songName,
			coverKey: 'albumRoll/$songKey',
			bpm: capturedBpm > 0 ? capturedBpm : 102,
			durationMs: longestDuration,
			noteCount: totalNotes,
			difficultyNames: diffNames != null ? diffNames.copy() : []
		};
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
		return Paths.json('$songKey/${songKey}-${Paths.formatToSongPath(diffName)}');
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
								if (Math.isNaN(t)) t = 0;
								var sustain:Float = noteArray.length > 2 && noteArray[2] != null ? Std.parseFloat(Std.string(noteArray[2])) : 0;
								if (Math.isNaN(sustain)) sustain = 0;
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

	 function playInstPreview():Void {
        if(songs.length == 0 || curSelected >= songs.length) return;

        previewLoadToken++;
        var requestToken:Int = previewLoadToken;
        var requestedIndex:Int = curSelected;
        var songName:String = Paths.formatToSongPath(songs[requestedIndex].songName);

        if(previewLoadTimer != null) {
            previewLoadTimer.cancel();
            previewLoadTimer = null;
        }

        previewLoadTimer = new FlxTimer().start(PREVIEW_LOAD_DELAY, function(_:FlxTimer) {
            previewLoadTimer = null;

            if(requestToken != previewLoadToken || songs.length == 0 || requestedIndex != curSelected)
                return;

            // Free old preview cache before requesting a different song preview.
            if(_prevInstSongName != null && _prevInstSongName != songName)
                releasePreviewSoundCache(_prevInstSongName);

            _prevInstSongName = songName;

            #if (target.threaded && sys)
            // Resolve the file path on the main thread (safe, read-only) to avoid
            // touching shared Paths data from inside the worker thread.
            var filePath:String = Paths.getPath(
                Language.getFileTranslation('${songName}/Inst') + '.${Paths.SOUND_EXT}',
                SOUND, 'songs', true
            );
            var capturedBpm:Float = currentBPM;
            var capturedToken:Int = requestToken;
            var capturedIndex:Int = requestedIndex;

            // Cancel any stale pending result so update() ignores it.
            _instLoadMutex.acquire();
            _pendingInstSound = null;
            _instLoadMutex.release();

            ThreadUtil.execAsync(function() {
                var loadedSound:openfl.media.Sound = null;
                try {
                    // Sound.fromFile() is the slow, blocking part (disk read + OGG decode).
                    // It is safe to call from a non-main thread on native C++ targets because
                    // OpenAL buffer upload only happens on the first play() call.
                    loadedSound = AssetLoader.loadSound(filePath);
                } catch(e:Dynamic) {
                    trace('[FreePlay] Thread error loading inst "$songName": $e');
                }

                // Hand off to the main thread via mutex-protected fields.
                // update() will pick this up and call playMusic() safely.
                _instLoadMutex.acquire();
                if(capturedToken == previewLoadToken) {
                    _pendingInstSound = loadedSound;
                    _pendingInstToken = capturedToken;
                    _pendingInstIndex = capturedIndex;
                    _pendingInstBpm  = capturedBpm;
                }
                _instLoadMutex.release();
            });

            #else
            // Fallback for single-threaded targets (web, etc.): load synchronously.
            try {
                FlxG.sound.playMusic(Paths.inst(songName), 0, true);
                FlxG.sound.music.fadeIn(1.0, 0, 0.7);
                instSound = FlxG.sound.music;
                instPlaying = requestedIndex;

                Conductor.bpm = currentBPM;

                #if funkin.vis
                _analyzer = null;
                _analyzerLevels = null;
                _needsAnalyzerInit = true;
                #end
            } catch(e:Dynamic) {
                trace('Error loading inst for $songName: $e');
                FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7);
            }
            #end
        });
    }
    
    /**
     * Stop instrumental preview and return to freakyMenu.
     */
    function stopInstPreview(?restoreMenuMusic:Bool = true):Void {
        previewLoadToken++;
        if(previewLoadTimer != null) {
            previewLoadTimer.cancel();
            previewLoadTimer = null;
        }

        instPlaying = -1;
        instSound = null;
        
        if(restoreMenuMusic) {
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

	function releasePreviewSoundCache(songPath:String):Void {
        if(songPath == null || songPath.length == 0) return;

        var toRemove:Array<String> = [];
        for(key in Paths.currentTrackedSounds.keys()) {
            if(key.contains('/' + songPath + '/'))
                toRemove.push(key);
        }

        for(key in toRemove) {
            openfl.Assets.cache.clear(key);
            Paths.currentTrackedSounds.remove(key);
            while(Paths.localTrackedAssets.remove(key)) {}
        }
    }

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	public function updateTexts(elapsed:Float = 0.0)
	{
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
		var query:String = StringTools.trim(songSearchQuery != null ? songSearchQuery.toLowerCase() : "");
		for (i in _lastVisibles)
		{
			if (i >= 0 && i < grpSongs.members.length && grpSongs.members[i] != null)
				grpSongs.members[i].visible = grpSongs.members[i].active = false;
			if (i >= 0 && i < iconArray.length && iconArray[i] != null)
				iconArray[i].visible = iconArray[i].active = false;
			if (i >= 0 && i < cardArray.length && cardArray[i] != null)
				cardArray[i].visible = false;
			if (i >= 0 && i < modTextArray.length && modTextArray[i] != null)
				modTextArray[i].visible = false;
		}
		_lastVisibles = [];

		var min:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected + _drawDistance)));
		for (i in min...max)
		{
			if (i < 0 || i >= grpSongs.members.length || i >= iconArray.length || i >= cardArray.length || i >= modTextArray.length || songs[i] == null)
				continue;
			if (query.length > 0 && !songMatchesFilter(songs[i], query))
				continue;

			var item:FlxText = grpSongs.members[i];
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
			icon.updateHitbox();
			icon.y = item.y - 20;

			var card:FlxSprite = cardArray[i];
			if (card == null)
				continue;
			card.visible = true;
			card.x = baseX + 80;
			card.y = item.y - 10;
			var isSelected = (i == curSelected) && !inDifficultySelect;
			var cardColor = songs[i].color;
			var darkestColor = FlxColor.interpolate(cardColor, FlxColor.BLACK, 0.5);
			MD3ShapeTools.fillAndStrokeRoundRect(card, 470, 110, 22, isSelected ? 3 : 2, darkestColor, OptionsMenuTheme.cardStroke(isSelected));

			icon.x = card.x + 340;
			item.x = card.x + 50;

			var modText:FlxText = modTextArray[i];
			if (modText == null)
				continue;
			modText.visible = true;
			modText.x = item.x;
			modText.y = item.y + 60;
			modText.alpha = (i == curSelected) ? 0.8 : 0.5;
			modText.color = OptionsMenuTheme.optionDescriptionColor(isSelected);
			item.color = OptionsMenuTheme.optionTitleColor(isSelected);

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
	
	/**
	 * Escanea la carpeta sm/ en la raíz del juego para cargar archivos .sm
	 */
	function loadStepManiaFiles():Void {
		#if sys
		#if mobile
		var smDir = StorageUtil.getSMDirectory();
		#else
		var smDir = './sm/';
		#end
		
		// Verificar si la carpeta sm existe
		if (!sys.FileSystem.exists(smDir)) {
			trace('SM folder not found, creating it...');
			sys.FileSystem.createDirectory(smDir);
			return;
		}
		
		trace('Scanning for StepMania files...');
		
		// Escanear cada subcarpeta en sm/
		for (folder in sys.FileSystem.readDirectory(smDir)) {
			var folderPath = smDir + folder;
			
			if (!sys.FileSystem.isDirectory(folderPath)) continue;
			
			// Buscar archivo .sm en la carpeta
			var smFile:String = null;
			for (file in sys.FileSystem.readDirectory(folderPath)) {
				if (file.endsWith('.sm')) {
					smFile = file;
					break;
				}
			}
			
			if (smFile == null) {
				trace('No .sm file found in ' + folder);
				continue;
			}
			
			// Cargar el archivo SM
			var fullPath = folderPath + '/' + smFile;
			
			try {
				var sm = backend.stepmania.SMFile.loadFile(fullPath);
				
				if (sm == null || !sm.isValid) {
					trace('Invalid SM file: ' + smFile);
					continue;
				}
				
				// Validar que el título no esté vacío
				if (sm.header == null || sm.header.TITLE == null || sm.header.TITLE.trim() == "") {
					trace('SM file has no title: ' + smFile);
					continue;
				}
				
				var cleanTitle = sm.header.TITLE;
				cleanTitle = StringTools.replace(cleanTitle, '\r', '');
				cleanTitle = StringTools.replace(cleanTitle, '\n', '');
				cleanTitle = StringTools.trim(cleanTitle);
				
				if (cleanTitle == "") {
					trace('Empty title after cleaning for: ' + smFile);
					continue;
				}
				
				// Crear nombre de archivo base
				var songNameClean = Paths.formatToSongPath(cleanTitle);
				if (songNameClean == null || songNameClean == "") {
					trace('Failed to format song name for: ' + cleanTitle);
					continue;
				}
				
				// Procesar cada dificultad del archivo SM
				for (diffIndex in 0...sm.difficulties.length) {
					var difficulty = sm.difficulties[diffIndex];
					
					var diffName = Paths.formatToSongPath(difficulty.name);
					// Usar solo el nombre de dificultad para el archivo JSON
					var jsonFileName = '$diffName.json';
					var jsonPath = folderPath + '/' + jsonFileName;
					var needsConversion = !sys.FileSystem.exists(jsonPath);
					
					// Convertir el SM a formato FNF
					if (needsConversion) {
						trace('Converting SM file: ${cleanTitle} [${difficulty.name}]');
						var song = sm.convertToFNF(diffName, diffIndex);
						
						if (song != null) {
							// Guardar el JSON convertido
							try {
								var json = haxe.Json.stringify({song: song}, null, '\t');
								sys.io.File.saveContent(jsonPath, json);
								trace('Saved converted chart: ' + jsonPath);
							} catch (e:Dynamic) {
								trace('Error saving converted chart: ' + e);
								continue;
							}
						} else {
							trace('Failed to convert SM difficulty: ${difficulty.name}');
							continue;
						}
					}
				}
				
				// Agregar UNA SOLA entrada para la canción (no una por dificultad)
				addSong(cleanTitle, -1, 'stepmania', FlxColor.fromRGB(255, 140, 0));
				
				// Marcar como canción de StepMania
				var lastSong = songs[songs.length - 1];
				if (lastSong != null) {
					lastSong.folder = '';
					lastSong.isStepMania = true;
					lastSong.smFolder = folder;
					// Guardar el nombre base de la canción (sin dificultad)
					lastSong.songName = songNameClean;
					
					// Guardar los nombres de las dificultades del .sm
					lastSong.smDifficulties = [];
					for (diff in sm.difficulties) {
						lastSong.smDifficulties.push(diff.name);
					}
				}
				
			} catch (e:Dynamic) {
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

		bgZoom += 0.05; // Mismo valor que en PlayState para la cámara
	}
	
	override function destroy():Void
	{
		if (songInfoCardLoadTimer != null)
		{
			songInfoCardLoadTimer.cancel();
			songInfoCardLoadTimer = null;
		}
		if (songInfoCardTween != null)
		{
			songInfoCardTween.cancel();
			songInfoCardTween = null;
		}
		songInfoCardData = null;

		if(vizBarsGroup != null) {
		    vizBarsGroup.destroy();
		    vizBarsGroup = null;
		}

		#if funkin.vis
		_analyzer = null;
		_analyzerLevels = null;
		#end

		Conductor.bpm = 102;

		super.destroy();

		FlxG.autoPause = ClientPrefs.data.autoPause;
		if (!FlxG.sound.music.playing && !stopMusicPlay)
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
		if(this.folder == null) this.folder = '';
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
	var coverKey:String;
	var bpm:Float;
	var durationMs:Float;
	var noteCount:Int;
	var difficultyNames:Array<String>;
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
		if (FreeplayState.instance == null) return;
		
		for (i in 0...scoreTexts.members.length)
		{
			var scoreText:FlxText = scoreTexts.members[i];
			if (scoreText == null) continue;
			
			var diffIndex:Int = scoreText.ID;
			var songName:String = FreeplayState.instance.songs[FreeplayState.curSelected].songName;
			
			#if !switch
			var score:Int = Highscore.getScore(songName, diffIndex, FreeplayState.viewingOpponentScores);
			var accuracy:Float = Highscore.getRating(songName, diffIndex, FreeplayState.viewingOpponentScores);
			var accSystem:String = Highscore.getAccuracySystem(songName, diffIndex, FreeplayState.viewingOpponentScores);
			
			var accPercent:String = '';
			if (accuracy > 0)
			{
				var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(accuracy * 100, 2)).split('.');
				if(ratingSplit.length < 2) ratingSplit.push('');
				while(ratingSplit[1].length < 2) ratingSplit[1] += '0';
				accPercent = ratingSplit.join('.');
			}
			else
			{
				accPercent = '0.00';
			}
			
			if (score > 0)
			{
				scoreText.text = 'Score: ' + score + '\nAccuracy: ' + accPercent + '% (' + accSystem + ')';
			}
			else
			{
				scoreText.text = Language.getPhrase('no_score', 'No score yet');
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
				0xFFDAB9  // Durazno pastel
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
		
		if (selectionTween != null) selectionTween.cancel();
		
		selectionTween = FlxTween.tween(this, {lerpSelected: curSelected}, 0.25, {
			ease: FlxEase.expoOut,
			onComplete: function(twn:FlxTween) {
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

			var baseX:Float = (FlxG.width * 0.5) - (card.width * 0.5) + baseXOffset;
			var targetX:Float = FlxMath.lerp(baseX + slideDistance, baseX, enterProgress);
			card.x = targetX;
			card.y = item.y - 15;
			card.color = difficultyColor;
			
			item.x = card.x + (card.width * 0.5) - (item.width * 0.5);
			card.y = item.y - 15;
			item.color = difficultyColor;
			
			// Posicionar texto de score/accuracy debajo de la dificultad
			if (i < scoreTexts.members.length)
			{
				var scoreText:FlxText = scoreTexts.members[i];
				if (scoreText != null)
				{
					scoreText.x = card.x + (card.width * 0.5) - (scoreText.width * 0.5);
					scoreText.y = item.y + 50; // Más abajo del nombre de dificultad
					scoreText.color = difficultyColor;
					
					if (i == curSelected)
					{
						scoreText.alpha = 1.0 * enterProgress;
					}
					else
					{
						scoreText.alpha = 0.6 * enterProgress;
					}
				}
			}
			
			if (i == curSelected)
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
