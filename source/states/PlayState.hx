package states;

import sys.thread.Thread;
import backend.Highscore;
import backend.StageData;
import backend.WeekData;
import backend.Song;
import backend.SongLoadPlan;
import backend.SongLoadMetrics;
import backend.Rating;
import backend.AccuracyTools;
import backend.AudioTempo;
import backend.BotplayCPU;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSave;
import flixel.graphics.FlxGraphic;
import flixel.input.keyboard.FlxKey;
import flixel.animation.FlxAnimationController;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import openfl.events.KeyboardEvent;
import haxe.Json;

import cutscenes.DialogueBoxPsych;

import states.StoryMenuState;
import states.FreeplayState;
import states.editors.ChartingState;
import states.editors.CharacterEditorState;
import states.play.BreakTimerHud;
import states.play.HealthIconHud;
import states.play.HudSafeZone;
import states.play.NoteSplashHelper;
import states.play.PlayModes;
import states.play.RatingNames;
#if windows
import states.play.WindowBorderPulse;
#end

import substates.PauseSubState;
import substates.GameOverSubstate;

#if !flash
import openfl.filters.ShaderFilter;
#end

import shaders.ErrorHandledShader;

import objects.VideoSprite;
import objects.Note.EventNote;
import objects.*;
import states.stages.*;
import states.stages.objects.*;

#if MODCHART_ALLOWED
import modchart.Manager;
#end

#if LUA_ALLOWED
import psychlua.*;
import psychlua.backend.*;
#else
import psychlua.backend.LuaUtils;
import psychlua.backend.HScript;
#end

#if HSCRIPT_ALLOWED
import psychlua.backend.HScript.HScriptInfos;
import crowplexus.iris.Iris;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end

/**
 * This is where all the Gameplay stuff happens and is managed
 *
 * here's some useful tips if you are making a mod in source:
 *
 * If you want to add your stage to the game, copy states/stages/Template.hx,
 * and put your stage code there, then, on PlayState, search for
 * "switch (curStage)", and add your stage to that list.
 *
 * If you want to code Events, you can either code it on a Stage file or on PlayState, if you're doing the latter, search for:
 *
 * "function eventPushed" - Only called *one time* when the game loads, use it for precaching events that use the same assets, no matter the values
 * "function eventPushedUnique" - Called one time per event, use it for precaching events that uses different assets based on its values
 * "function eventEarlyTrigger" - Used for making your event start a few MILLISECONDS earlier
 * "function triggerEvent" - Called when the song hits your event's timestamp, this is probably what you were looking for
**/
class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2],
		['Shit', 0.4],
		['Bad', 0.5],
		['Bruh', 0.6],
		['Meh', 0.69],
		['Nice', 0.7],
		['Good', 0.8],
		['Great', 0.9],
		['Sick!', 1],
		['Perfect!!', 1]
	];

	public static function getRatingStuff():Array<Dynamic>
		return RatingNames.list();

	//event variables
	private var isCameraOnForcedPos:Bool = false;

	public var boyfriendMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();

	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public static var curStage:String = '';
	public static var stageUI(default, set):String = "normal";
	public static var uiPrefix:String = "";
	public static var uiPostfix:String = "";
	public static var temporaryStageUI:String = null;
	public static var isPixelStage(get, never):Bool;

	@:noCompletion
	static function set_stageUI(value:String):String
	{
		uiPrefix = uiPostfix = "";
		if (value != "normal")
		{
			Paths.setUIPath(value);
			uiPrefix = Paths.getUIPrefix();
			uiPostfix = Paths.uiSuffix;
		}
		else
			Paths.resetUIPath();
		return stageUI = value;
	}

	@:noCompletion
	static function get_isPixelStage():Bool
		return stageUI == "pixel" || stageUI.endsWith("-pixel");

	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	public static var returnToScriptedState:String = null;

	public var spawnTime:Float = 2000;

	public var inst:FlxSound;
	public var vocals:FlxSound;
	public var opponentVocals:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Character = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	private var denseChartQueue:Bool = false;
	private var unspawnNoteCursor:Int = 0;
	private var denseHitVisualsThisFrame:Int = 0;
	private var denseRatingPending:Bool = false;
	private var denseRatingHadMiss:Bool = false;
	private static inline final DENSE_QUEUE_COMPACT_AT:Int = 2048;
	public var eventNotes:Array<EventNote> = [];

	public var camFollow:FlxObject;
	private static var prevCamFollow:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var opponentStrums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var playerStrums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash> = new FlxTypedGroup<NoteSplash>();
	public var grpHoldSplashes:FlxTypedGroup<SustainSplash> = new FlxTypedGroup<SustainSplash>();

	#if LUA_ALLOWED
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, FlxSprite> = new Map<String, FlxSprite>();
	public var modchartTexts:Map<String, FlxText> = new Map<String, FlxText>();
	#end

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	public var cameraBopEnabled:Bool = false;
	public var cameraBopFrequency:Float = 1;
	public var cameraBopIntensity:Float = 1;
	public var windowResizedByScript:Bool = false;
	public var keyViewer:objects.KeyViewer;
	public var modchartManagerEnabled:Bool = true;
	public var modchartControlsStrumRender:Bool = true;
	#if MODCHART_ALLOWED
	var mcDbgTxt:FlxText = null;
	var mcDbgOn:Bool = false;
	var mcDbgTime:Float = 0;
	var mcDbgSamples:Int = 0;
	var mcDbgFps:Float = 0;
	var mcDbgTick:Float = 0;
	var mcDbgRenderer:String = 'OpenFL - OpenGL Unknown';
	var mcInitCb:Void->Void = null;
	var mcInitDone:Bool = false;
	#end
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health(default, set):Float = 1;
	public var combo:Int = 0;

	public var healthBar:Bar;
	public var timeBar:Bar;
	var songPercent:Float = 0;

	public var ratingsData:Array<Rating> = Rating.loadDefault();

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;

	public var guitarHeroSustains:Bool = false;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;
	public var perfectMode(get, never):Bool;
	public var playOpponent(get, never):Bool;
	public var noDropPenalty(get, never):Bool;
	public var opponentDrain(get, never):Bool;
	public var pressMissDamage:Float = 0.05;
	var modes:PlayModes = new PlayModes();

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;
	var botplayCPU:BotplayCPU;
	var hitTimes:Array<{time:Float, count:Int}> = [];
	var msTxt:FlxText;
	var msTween:FlxTween;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var iconGF:HealthIcon;

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var luaTpadCam:FlxCamera;
	public var cameraSpeed:Float = 1;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var maxCombo:Int = 0;
	public var totalNotes:Int = 0;
	var bonusLimit:Float = AccuracyTools.BONUS_MAX;
	var bonusLocked:Bool = false;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var timeTween:FlxTween;
	var scoreTxtTween:FlxTween;
	var endCountdownText:FlxText = null;
	var endCountdownTween:FlxTween = null;
	var lastEndCountdown:Int = -1;
	var iconTurn:Float = 10;
	var lyricText:FlxText;
	var lyricTween:FlxTween;
	var versionText:FlxText;
	var verTween:FlxTween;
	var languageRevision:Int = -1;
	var gfIconSide:String = '';
	var gfIconSwapOnSing:Bool = false;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var campaignFlawlesss:Int = 0;
	public static var campaignSicks:Int = 0;
	public static var campaignGoods:Int = 0;
	public static var campaignBads:Int = 0;
	public static var campaignShits:Int = 0;
	public static var campaignMaxCombo:Int = 0;
	public static var campaignTotalNotes:Int = 0;
	public static var campaignSongsPlayed:Array<String> = [];
	public static var campaignAccuracySum:Float = 0;
	public static var campaignSongsCount:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if DISCORD_ALLOWED
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Int> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	#if LUA_ALLOWED public var luaArray:Array<FunkinLua> = []; #end

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	private var luaDebugGroup:FlxTypedGroup<psychlua.backend.DebugLuaText>;
	#end
	public var introSoundsSuffix:String = '';

	// Less laggy controls
	private var keysArray:Array<String>;
	public var songName:String;

	// Callbacks for stages
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;

	private var shutdownThread:Bool = false;
	private var gameFroze:Bool = false;
	private var requiresSyncing:Bool = false;
	private var lastCorrectSongPos:Float = -1.0;
	private var songSyncThreadRunning:Bool = false;

	private static var _lastLoadedModDirectory:String = '';
	public static var nextReloadAll:Bool = false;

	public var luaTouchPad:TouchPad;

	override public function create()
	{
		//trace('Playback Rate: ' + playbackRate);
		_lastLoadedModDirectory = Mods.currentModDirectory;
		NoteSplash.clearCache();
		Paths.clearStoredMemory();
		if(nextReloadAll)
		{
			Paths.clearUnusedMemory();
			Language.reloadPhrases();
		}
		nextReloadAll = false;

		startCallback = startCountdown;
		endCallback = endSong;

		// for lua
		instance = this;

		PauseSubState.songName = null; //Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed');

		keysArray = [
			'note_left',
			'note_down',
			'note_up',
			'note_right'
		];

		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain');
		healthLoss = ClientPrefs.getGameplaySetting('healthloss');
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill');
		practiceMode = ClientPrefs.getGameplaySetting('practice');
		cpuControlled = ClientPrefs.getGameplaySetting('botplay');
		modes.load();
		guitarHeroSustains = ClientPrefs.data.guitarHeroSustains;
		showRating = ClientPrefs.data.showRating;
		showCombo = ClientPrefs.data.showCombo;
		showComboNum = ClientPrefs.data.showComboNum;

		if (perfectMode)
		{
			practiceMode = false;
			instakillOnMiss = true;
		}

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = initPsychCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		luaTpadCam = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;
		luaTpadCam.bgColor.alpha = 0;

		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(luaTpadCam, false);

		persistentUpdate = true;
		persistentDraw = true;

		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;

		#if DISCORD_ALLOWED
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		storyDifficultyText = Difficulty.getString();

		if (isStoryMode)
			detailsText = Language.getPhrase('playstate.presence.story', 'Story Mode: {1}', [WeekData.getCurrentWeek().weekName]);
		else
			detailsText = Language.getPhrase('playstate.presence.freeplay', 'Freeplay');

		// String for when the game is paused
		detailsPausedText = Language.getPhrase('playstate.presence.paused', 'Paused - {1}', [detailsText]);
		#end

		GameOverSubstate.resetVariables();
		songName = Paths.formatToSongPath(SONG.song);
		if(SONG.stage == null || SONG.stage.length < 1)
			SONG.stage = StageData.vanillaSongStage(Paths.formatToSongPath(Song.loadedSongName));

		curStage = SONG.stage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		defaultCamZoom = stageData.defaultZoom;

		stageUI = "normal";
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			stageUI = stageData.stageUI;
		else if (stageData.isPixelStage == true) //Backward compatibility
			stageUI = "pixel";

		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'stage': new StageWeek1(); 			//Week 1
			case 'spooky': new Spooky();				//Week 2
			case 'philly': new Philly();				//Week 3
			case 'limo': new Limo();					//Week 4
			case 'mall': new Mall();					//Week 5 - Cocoa, Eggnog
			case 'mallEvil': new MallEvil();			//Week 5 - Winter Horrorland
			case 'school': new School();				//Week 6 - Senpai, Roses
			case 'schoolEvil': new SchoolEvil();		//Week 6 - Thorns
			case 'tank': new Tank();					//Week 7 - Ugh, Guns, Stress
			case 'phillyStreets': new PhillyStreets(); 	//Weekend 1 - Darnell, Lit Up, 2Hot
			case 'phillyBlazin': new PhillyBlazin();	//Weekend 1 - Blazin
		}
		if(isPixelStage) introSoundsSuffix = '-pixel';

		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		luaDebugGroup = new FlxTypedGroup<psychlua.backend.DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		if (!stageData.hide_girlfriend)
		{
			if(SONG.gfVersion == null || SONG.gfVersion.length < 1) SONG.gfVersion = 'gf'; //Fix for the Chart Editor
			gf = new Character(0, 0, SONG.gfVersion);
			startCharacterPos(gf);
			gfGroup.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);

		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);

		if(stageData.objects != null && stageData.objects.length > 0)
		{
			var list:Map<String, FlxSprite> = StageData.addObjectsToState(stageData.objects, !stageData.hide_girlfriend ? gfGroup : null, dadGroup, boyfriendGroup, this);
			for (key => spr in list)
				if(!StageData.reservedNames.contains(key))
					variables.set(key, spr);
		}
		else
		{
			add(gfGroup);
			add(dadGroup);
			add(boyfriendGroup);
		}

		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		// "SCRIPTS FOLDER" SCRIPTS
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/'))
			#if linux
			for (file in CoolUtil.sortAlphabetically(Paths.readDirectory(folder)))
			#else
			for (file in Paths.readDirectory(folder))
			#end
			{
				#if LUA_ALLOWED
				if(file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);
				#end

				#if HSCRIPT_ALLOWED
				if(file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
				#end
			}
		#end

		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}

		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		// STAGE SCRIPTS
		#if LUA_ALLOWED startLuasNamed('stages/' + curStage + '.lua'); #end
		#if HSCRIPT_ALLOWED startHScriptsNamed('stages/' + curStage + '.hx'); #end

		// CHARACTER SCRIPTS
		if(gf != null) startCharacterScripts(gf.curCharacter);
		startCharacterScripts(dad.curCharacter);
		startCharacterScripts(boyfriend.curCharacter);
		#end

		uiGroup = new FlxSpriteGroup();
		comboGroup = new FlxSpriteGroup();
		noteGroup = new FlxTypedGroup<FlxBasic>();
		add(comboGroup);
		add(uiGroup);
		add(noteGroup);

		Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
		var showTime:Bool = (ClientPrefs.data.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = updateTime = showTime;
		if(ClientPrefs.data.downScroll) timeTxt.y = HudSafeZone.y() + HudSafeZone.height() - 44;
		if(ClientPrefs.data.timeBarType == 'Song Name') timeTxt.text = SONG.song;

		timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 4), 'timeBar', function() return songPercent, 0, 1);
		timeBar.scrollFactor.set();
		timeBar.x = HudSafeZone.x() + (HudSafeZone.width() - timeBar.width) / 2;
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		uiGroup.add(timeBar);
		uiGroup.add(timeTxt);

		noteGroup.add(strumLineNotes);

		if(ClientPrefs.data.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		generateSong();

		noteGroup.add(grpNoteSplashes);
		if(!ClientPrefs.data.hideSustainSplash && !ClientPrefs.data.lowQuality)
			noteGroup.add(grpHoldSplashes);

		if(eventsPushed.contains('Lyric Event'))
		{
			lyricText = new FlxText(0, FlxG.height * 0.72, FlxG.width, "", 32);
			lyricText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			lyricText.scrollFactor.set();
			lyricText.borderSize = 2;
			lyricText.alpha = 0;
			lyricText.visible = !ClientPrefs.data.hideHud;
			lyricText.cameras = [camHUD];
			uiGroup.add(lyricText);
		}

		camFollow = new FlxObject();
		camFollow.setPosition(camPos.x, camPos.y);
		camPos.put();

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.snapToTarget();

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		moveCameraSection();

		healthBar = new Bar(0, HudSafeZone.y() + HudSafeZone.height() * (!ClientPrefs.data.downScroll ? 0.89 : 0.11), 'healthBar', function() return health, 0, 2);
		healthBar.x = HudSafeZone.x() + (HudSafeZone.width() - healthBar.width) / 2;
		healthBar.leftToRight = false;
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.data.hideHud;
		healthBar.alpha = ClientPrefs.data.healthBarAlpha;
		reloadHealthBarColors();
		uiGroup.add(healthBar);

		var animatedIcon:Bool = (SONG.isAnimated == true);
		iconP1 = new HealthIcon(playerChar().healthIcon, true, true, playerChar().iconFps);
		if (animatedIcon || playerChar().animatedIcon) iconP1.changeIcon(iconP1.getCharacter(), true, true, playerChar().iconFps);
		iconP1.y = ClientPrefs.data.iconBounceType == 'Old' ? healthBar.y - (iconP1.height / 2) : healthBar.y - 75;
		iconP1.visible = !ClientPrefs.data.hideHud;
		iconP1.alpha = ClientPrefs.data.healthBarAlpha;
		uiGroup.add(iconP1);

		iconP2 = new HealthIcon(opponentChar().healthIcon, false, true, opponentChar().iconFps);
		if (animatedIcon || opponentChar().animatedIcon) iconP2.changeIcon(iconP2.getCharacter(), true, true, opponentChar().iconFps);
		iconP2.y = ClientPrefs.data.iconBounceType == 'Old' ? healthBar.y - (iconP2.height / 2) : healthBar.y - 75;
		iconP2.visible = !ClientPrefs.data.hideHud;
		iconP2.alpha = ClientPrefs.data.healthBarAlpha;
		uiGroup.add(iconP2);

		if(eventsPushed.contains('Add Secondary Icon'))
		{
			iconGF = new HealthIcon(gf != null ? gf.healthIcon : 'gf', true, false, gf != null ? gf.iconFps : 24);
			if (animatedIcon || (gf != null && gf.animatedIcon)) iconGF.changeIcon(iconGF.getCharacter(), false, true, gf != null ? gf.iconFps : 24);
			iconGF.y = ClientPrefs.data.iconBounceType == 'Old' ? healthBar.y - (iconGF.height / 2) : healthBar.y - 75;
			iconGF.visible = false;
			iconGF.alpha = ClientPrefs.data.healthBarAlpha;
			uiGroup.add(iconGF);
		}

		scoreTxt = new FlxText(0, healthBar.y + 40, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		uiGroup.add(scoreTxt);

		botplayTxt = new FlxText(400, healthBar.y - 90, FlxG.width - 800, botplayLabel(), 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled || perfectMode || playOpponent || practiceMode;
		uiGroup.add(botplayTxt);
		if(ClientPrefs.data.downScroll)
			botplayTxt.y = healthBar.y + 70;

		if(ClientPrefs.data.showKeyViewer && !ClientPrefs.data.hideHud)
		{
			var kv = new objects.KeyViewer(0, 0, this);
			kv.visible = true;
			keyViewer = kv;
			uiGroup.insert(0, kv);
		}

		if(ClientPrefs.data.showVersionText && !ClientPrefs.data.hideHud)
		{
			versionText = new FlxText(0, -22, FlxG.width, versionLabel(), 14);
			versionText.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			versionText.scrollFactor.set();
			versionText.borderSize = 1;
			versionText.alpha = 0.75;
			uiGroup.add(versionText);
		}

		uiGroup.cameras = [camHUD];
		noteGroup.cameras = [camHUD];
		comboGroup.cameras = [ClientPrefs.data.comboInGame ? camGame : camHUD];

		startingSong = true;

		#if LUA_ALLOWED
		for (notetype in noteTypes)
			startLuasNamed('custom_notetypes/' + notetype + '.lua');
		for (event in eventsPushed)
			startLuasNamed('custom_events/' + event + '.lua');
		#end

		#if HSCRIPT_ALLOWED
		for (notetype in noteTypes)
			startHScriptsNamed('custom_notetypes/' + notetype + '.hx');
		for (event in eventsPushed)
			startHScriptsNamed('custom_events/' + event + '.hx');
		#end
		noteTypes = null;
		eventsPushed = null;

		// SONG SPECIFIC SCRIPTS
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'data/$songName/'))
			#if linux
			for (file in CoolUtil.sortAlphabetically(Paths.readDirectory(folder)))
			#else
			for (file in Paths.readDirectory(folder))
			#end
			{
				#if LUA_ALLOWED
				if(file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);
				#end

				#if HSCRIPT_ALLOWED
				if(file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
				#end
			}
		#end

		addMobileControls();
		mobileControls.instance.visible = true;
		mobileControls.onButtonDown.add(onButtonPress);
		mobileControls.onButtonUp.add(onButtonRelease);

		if(eventNotes.length > 0)
		{
			for (event in eventNotes) event.strumTime -= eventEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}

		startCallback();
		RecalculateRating(false, false);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		//PRECACHING THINGS THAT GET USED FREQUENTLY TO AVOID LAGSPIKES
		if(!ClientPrefs.data.ghostTapping) for (i in 1...4) Paths.sound('missnote$i');
		Paths.image('alphabet');

		if (PauseSubState.songName != null)
			Paths.music(PauseSubState.songName);
		else if(Paths.formatToSongPath(ClientPrefs.data.pauseMusic) != 'none')
			Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic));

		resetRPC();

		stagesFunc(function(stage:BaseStage) stage.createPost());
		callOnScripts('onCreatePost');

		initModchart();
		#if MODCHART_ALLOWED
		if (Manager.instance != null && ClientPrefs.data.modchartDebug)
			mcDebug(0);
		#end

		NoteSplashHelper.warmup(this);

		#if !android
		addTouchPad('NONE', 'P');
		addTouchPadCamera();
		#end

		super.create();
		Paths.clearUnusedMemory();

		cacheCountdown();
		cachePopUpScore();
		initBreakTimerHud();

		if(eventNotes.length < 1) checkEventNote();
	}

	function initModchart():Void
	{
		#if MODCHART_ALLOWED
		if (mcInitDone)
			return;
		mcInitDone = true;

		if (!modchartManagerEnabled)
			return;

		try
		{
			ensureModchartManager();
			if (Manager.instance == null)
				return;

			syncModMgr();
			mcInitCb = function()
			{
				if (PlayState.instance != this || Manager.instance == null)
				{
					FlxG.signals.postUpdate.remove(mcInitCb);
					mcInitCb = null;
					return;
				}

				syncModMgr();
				callOnScripts('onInitModchart');
				FlxG.signals.postUpdate.remove(mcInitCb);
				mcInitCb = null;
			};
			FlxG.signals.postUpdate.add(mcInitCb);
		}
		catch (e:Dynamic)
		{
			trace('Error initializing modcharts: $e');
		}
		#end
	}

	#if MODCHART_ALLOWED
	function ensureModchartManager():Void
	{
		if (!modchartManagerEnabled)
			return;
		if (!generatedMusic)
		{
			trace('Modchart Manager postponed: chart notes are not ready yet.');
			return;
		}

		if (Manager.instance == null)
		{
			var manager:Manager = new Manager();
			if (noteGroup != null)
				noteGroup.insert(0, manager);
			else
				add(manager);
		}

		if (Manager.instance != null)
		{
			Manager.instance.cameras = [camHUD];
			syncModMgr();
		}
	}

	function syncModMgr():Void
	{
		setOnScripts('instance', Manager.instance);
		setOnScripts('manager', Manager.instance);
		setOnScripts('modManager', Manager.instance);
		setOnScripts('modchartManager', Manager.instance);
	}

	function mcDebug(elapsed:Float):Void
	{
		if (Manager.instance == null || !ClientPrefs.data.modchartDebug)
		{
			mcDebugOff();
			return;
		}

		if (mcDbgTxt == null)
		{
			mcDbgOn = true;
			mcDbgTime = 0;
			mcDbgSamples = 0;
			mcDbgTick = 999;
			mcDbgFps = ClientPrefs.data.framerate;
			mcDbgTxt = new FlxText(0, 10, 560, "", 18);
			mcDbgTxt.setFormat(Paths.font("NotoSans-Medium.ttf"), 18, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
			mcDbgTxt.scrollFactor.set();
			mcDbgTxt.borderSize = 1.2;
			mcDbgTxt.alpha = 0.7;
			mcDbgTxt.wordWrap = false;
			mcDbgTxt.cameras = [camOther];
			mcDbgRenderer = 'OpenFL - ${backend.Native.getOpenGLLabel()} [${backend.GLCapabilities.tierLabel()}]';
			add(mcDbgTxt);
		}

		final stats = Manager.instance.rendererStats;
		stats.collectDebugStats = true;
		if (elapsed > 0)
		{
			mcDbgTime += elapsed;
			mcDbgSamples++;
			if (mcDbgSamples >= 30)
			{
				mcDbgFps = mcDbgSamples / mcDbgTime;
				mcDbgTime = 0;
				mcDbgSamples = 0;
			}

			mcDbgTick += elapsed;
			if (mcDbgTick < 0.12)
				return;
			mcDbgTick = 0;
		}

		final currentFPS = Main.fpsVar != null ? Main.fpsVar.currentFPS : ClientPrefs.data.framerate;
		final averageFPS = mcDbgFps > 0 ? mcDbgFps : currentFPS;
		final drawsPerFrame = stats.dbgDrawCmds;
		final drawsPerSecond = Std.int(Math.round(drawsPerFrame * averageFPS));
		final memoryText = Main.fpsVar != null ? FlxStringUtil.formatBytes(Main.fpsVar.memoryMegas) : "0 MB";
		final itemText = '${stats.dbgArrows}N/${stats.dbgHolds}H/${stats.dbgReceptors}R/${stats.dbgAttachments}A';

		mcDbgTxt.text = '${currentFPS} FPS / ${Std.int(Math.round(averageFPS))} AVG'
			+ '\n${fmt(currentFPS > 0 ? 1000 / currentFPS : 0, 1)} ms frame'
			+ '\nPF ${Manager.instance.activePlayfieldCount} | Mods ${Manager.instance.totalModifierCount} | Events ${Manager.instance.totalEventCount}'
			+ '\nItems ${itemText}'
			+ '\nVerts ${stats.dbgVertices} | Draws ${drawsPerFrame} (${drawsPerSecond}/s)'
			+ '\nHolds ${stats.dbgHoldCmds}/${stats.dbgActiveHolds} | Paths ${stats.dbgPathCmds}'
			+ '\nEmit ${fmt(stats.dbgEmitMs, 2)} ms | Subdiv ${stats.dbgHoldSubdivisions} | Q ${fmt(stats.dbgPathQuality, 2)}'
			+ '\nCollect ${fmt(stats.dbgCollectMs, 2)} | A ${fmt(stats.dbgArrowMs, 2)} H ${fmt(stats.dbgHoldMs, 2)} P ${fmt(stats.dbgPathMs, 2)}'
			+ '\nSort ${fmt(stats.dbgSortMs, 2)} | Submit ${fmt(stats.dbgSubmitMs, 2)} | Mods ${stats.dbgModifierCalls}/${stats.dbgPathSamples}'
			+ '\nCulled ${stats.dbgSpawnCulled} | Hold slots ${stats.dbgSlotsReused}'
			+ '\nLoad ${SongLoadMetrics.summary()}'
			+ '\nGC ${memoryText} | ${mcDbgRenderer}';
		mcDbgTxt.x = FlxG.width - mcDbgTxt.width - 10;
		mcDbgTxt.y = 10;
	}

	function mcDebugOff():Void
	{
		mcDbgOn = false;
		mcDbgTick = 0;
		if (Manager.instance != null)
			Manager.instance.rendererStats.collectDebugStats = false;
		if (mcDbgTxt != null)
		{
			remove(mcDbgTxt);
			mcDbgTxt.destroy();
			mcDbgTxt = null;
		}
	}

	function fmt(value:Float, decimals:Int):String
	{
		var multiplier:Float = Math.pow(10, decimals);
		var rounded:Float = Math.round(value * multiplier) / multiplier;
		var str:String = Std.string(rounded);
		if (str.indexOf('.') == -1)
			str += '.';
		var parts:Array<String> = str.split('.');
		while (parts[1].length < decimals)
			parts[1] += '0';
		return parts[0] + '.' + parts[1];
	}
	#end

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			if(ratio != 1)
			{
				for (note in notes.members)
					if (note != null) note.resizeByRatio(ratio);
				for (i in (denseChartQueue ? unspawnNoteCursor : 0)...unspawnNotes.length)
				{
					var note:Note = unspawnNotes[i];
					if (note != null) note.resizeByRatio(ratio);
				}
			}
		}
		songSpeed = value;
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);
		return value;
	}

	function set_playbackRate(value:Float):Float
	{
		#if FLX_PITCH
		if(generatedMusic)
		{
			var preservePitch:Bool = ClientPrefs.getGameplaySetting('preservepitch', false);
			AudioTempo.apply(vocals, value, preservePitch);
			AudioTempo.apply(opponentVocals, value, preservePitch);
			AudioTempo.apply(FlxG.sound.music, value, preservePitch);

			var ratio:Float = playbackRate / value; //funny word huh
			if(ratio != 1)
			{
				for (note in notes.members)
					if (note != null) note.resizeByRatio(ratio);
				for (i in (denseChartQueue ? unspawnNoteCursor : 0)...unspawnNotes.length)
				{
					var note:Note = unspawnNotes[i];
					if (note != null) note.resizeByRatio(ratio);
				}
			}
		}
		playbackRate = value;
		FlxG.animationTimeScale = value;
		Conductor.offset = Reflect.hasField(PlayState.SONG, 'offset') ? (PlayState.SONG.offset / value) : 0;
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * value;
		#if VIDEOS_ALLOWED
		if (videoCutscene != null && videoCutscene.videoSprite != null && videoCutscene.videoSprite.bitmap != null)
			videoCutscene.videoSprite.bitmap.rate = value;
		#if LUA_ALLOWED
		psychlua.VideoFunctions.setPlaybackRate(value);
		#end
		#end
		setOnScripts('playbackRate', playbackRate);
		#else
		playbackRate = 1.0; // ensuring -Crow
		#end
		return playbackRate;
	}

	inline function applyAudioRate(sound:FlxSound):Void
	{
		AudioTempo.apply(sound, playbackRate, ClientPrefs.getGameplaySetting('preservepitch', false));
	}

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	public function addTextToDebug(text:String, color:FlxColor) {
		var debugPanel:psychlua.backend.DebugLuaText = null;
		for (spr in luaDebugGroup.members)
		{
			if (spr != null)
			{
				debugPanel = spr;
				break;
			}
		}
		if (debugPanel == null)
		{
			debugPanel = new psychlua.backend.DebugLuaText();
			luaDebugGroup.add(debugPanel);
		}
		debugPanel.pushMessage(text, color);
		debug.TraceDisplay.addDebugText(Std.string(text), color);

		Sys.println(text);
	}
	#end

	public function reloadHealthBarColors() {
		var dadColor:FlxColor = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
		var bfColor:FlxColor = FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]);
		healthBar.setColors(dadColor, bfColor);
		if(timeBar != null)
		{
			if(ClientPrefs.data.shadedTimeBar)
				timeBar.setGradientColors(bfColor, dadColor);
			else
				timeBar.setColors(FlxColor.WHITE, FlxColor.BLACK);
		}
	}

	public function reloadGradientColors():Void
	{
		if (timeBar == null)
			return;

		if (ClientPrefs.data.shadedTimeBar && dad != null && boyfriend != null)
		{
			var dadColor:FlxColor = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
			var bfColor:FlxColor = FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]);
			timeBar.setGradientColors(bfColor, dadColor);
		}
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterScripts(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterScripts(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterScripts(newGf.curCharacter);
				}
		}
	}

	function startCharacterScripts(name:String)
	{
		// Lua
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/$name.lua';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(luaFile);
		if(FileSystem.exists(replacePath))
		{
			luaFile = replacePath;
			doPush = true;
		}
		else
		{
			luaFile = Paths.getSharedPath(luaFile);
			if(FileSystem.exists(luaFile))
				doPush = true;
		}
		#else
		luaFile = Paths.getSharedPath(luaFile);
		if(Assets.exists(luaFile)) doPush = true;
		#end

		if(doPush)
		{
			for (script in luaArray)
			{
				if(script.scriptName == luaFile)
				{
					doPush = false;
					break;
				}
			}
			if(doPush) new FunkinLua(luaFile);
		}
		#end

		// HScript
		#if HSCRIPT_ALLOWED
		var doPush:Bool = false;
		var scriptFile:String = 'characters/' + name + '.hx';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(scriptFile);
		if(FileSystem.exists(replacePath))
		{
			scriptFile = replacePath;
			doPush = true;
		}
		else
		#end
		{
			scriptFile = Paths.getSharedPath(scriptFile);
			if(FileSystem.exists(scriptFile))
				doPush = true;
		}

		if(doPush)
		{
			if(Iris.instances.exists(scriptFile))
				doPush = false;

			if(doPush) initHScript(scriptFile);
		}
		#end
	}

	public function getLuaObject(tag:String):Dynamic
		return variables.get(tag);

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public var videoCutscene:VideoSprite = null;
	public function startVideo(name:String, forMidSong:Bool = false, canSkip:Bool = true, loop:Bool = false, playOnLoad:Bool = true)
	{
		#if VIDEOS_ALLOWED
		inCutscene = !forMidSong;
		canPause = forMidSong;

		var foundFile:Bool = false;
		var fileName:String = Paths.video(name);

		#if sys
		if (FileSystem.exists(fileName))
		#else
		if (OpenFlAssets.exists(fileName))
		#end
		foundFile = true;

		if (foundFile)
		{
			videoCutscene = new VideoSprite(fileName, forMidSong, canSkip, loop);
			if (videoCutscene.videoSprite != null && videoCutscene.videoSprite.bitmap != null)
				videoCutscene.videoSprite.bitmap.rate = playbackRate;

			// Finish callback
			if (!forMidSong)
			{
				function onVideoEnd()
				{
					if (!isDead && generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
					{
						moveCameraSection();
						FlxG.camera.snapToTarget();
					}
					videoCutscene = null;
					canPause = true;
					inCutscene = false;
					startAndEnd();
				}
				videoCutscene.finishCallback = onVideoEnd;
				videoCutscene.onSkip = onVideoEnd;
			}
			if (GameOverSubstate.instance != null && isDead) GameOverSubstate.instance.add(videoCutscene);
			else add(videoCutscene);

			if (playOnLoad)
				videoCutscene.play();
			return videoCutscene;
		}
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		else addTextToDebug("Video not found: " + fileName, FlxColor.RED);
		#else
		else FlxG.log.error("Video not found: " + fileName);
		#end
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		#end
		return null;
	}

	function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogue')))" and it should load dialogue.json
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			startAndEnd();
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		var introImagesArray:Array<String> = switch(stageUI) {
			case "pixel": ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel'];
			case "normal": ["ready", "set" ,"go"];
			default: [uiAsset('ready'), uiAsset('set'), uiAsset('go')];
		}
		introAssets.set(stageUI, introImagesArray);
		var introAlts:Array<String> = introAssets.get(stageUI);
		for (asset in introAlts) Paths.image(asset);

		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}

	public function startCountdown()
	{
		if(startedCountdown) {
			callOnScripts('onStartCountdown');
			return false;
		}

		seenCutscene = true;
		inCutscene = false;
		var ret:Dynamic = callOnScripts('onStartCountdown', null, true);
		if(ret != LuaUtils.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			canPause = true;
			generateStaticArrows(0);
			generateStaticArrows(1);
			for (i in 0...playerStrums.length) {
				setOnScripts('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnScripts('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnScripts('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnScripts('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				//if(ClientPrefs.data.middleScroll) opponentStrums.members[i].visible = false;
			}

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
			setOnScripts('startedCountdown', true);
			callOnScripts('onCountdownStarted');

			var swagCounter:Int = 0;
			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return true;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return true;
			}
			moveCameraSection();

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				characterBopper(tmr.loopsLeft);

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				var introImagesArray:Array<String> = switch(stageUI) {
					case "pixel": ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel'];
					case "normal": ["ready", "set" ,"go"];
					default: [uiAsset('ready'), uiAsset('set'), uiAsset('go')];
				}
				introAssets.set(stageUI, introImagesArray);

				var introAlts:Array<String> = introAssets.get(stageUI);
				var antialias:Bool = (ClientPrefs.data.antialiasing && !isPixelStage);
				var tick:Countdown = THREE;

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
						tick = THREE;
					case 1:
						countdownReady = createCountdownSprite(introAlts[0], antialias);
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
						tick = TWO;
					case 2:
						countdownSet = createCountdownSprite(introAlts[1], antialias);
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
						tick = ONE;
					case 3:
						countdownGo = createCountdownSprite(introAlts[2], antialias);
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						tick = GO;
					case 4:
						tick = START;
				}

				if(!skipArrowStartTween)
				{
					notes.forEachAlive(function(note:Note) {
						if(ClientPrefs.data.opponentStrums || note.mustPress)
						{
							note.copyAlpha = false;
							note.alpha = note.multAlpha;
							if(ClientPrefs.data.middleScroll && !note.mustPress)
								note.alpha *= 0.35;
						}
					});
				}

				stagesFunc(function(stage:BaseStage) stage.countdownTick(tick, swagCounter));
				callOnLuas('onCountdownTick', [swagCounter]);
				callOnHScript('onCountdownTick', [tick, swagCounter]);

				swagCounter += 1;
			}, 5);
		}
		return true;
	}

	inline private function createCountdownSprite(image:String, antialias:Bool):FlxSprite
	{
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(image));
		spr.cameras = [camHUD];
		spr.scrollFactor.set();
		spr.updateHitbox();

		if (PlayState.isPixelStage)
			spr.setGraphicSize(Std.int(spr.width * daPixelZoom));

		spr.screenCenter();
		spr.antialiasing = antialias;
		insert(members.indexOf(noteGroup), spr);
		FlxTween.tween(spr, {/*y: spr.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				remove(spr);
				spr.destroy();
			}
		});
		return spr;
	}

	public function resumeWithCountdown(?pauseSubState:PauseSubState):Void
	{
		var ret:Dynamic = callOnScripts('onResumeCountdown', null, true);
		if (ret != LuaUtils.Function_Stop)
		{
			var swagCounter:Int = 0;
			new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				var introImagesArray:Array<String> = switch(stageUI) {
					case "pixel": ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel'];
					case "normal": ["ready", "set" ,"go"];
					default: [uiAsset('ready'), uiAsset('set'), uiAsset('go')];
				}
				var antialias:Bool = (ClientPrefs.data.antialiasing && !isPixelStage);
				var tick:Countdown = THREE;

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
						tick = THREE;
					case 1:
						countdownReady = createCountdownSprite(introImagesArray[0], antialias);
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
						tick = TWO;
					case 2:
						countdownSet = createCountdownSprite(introImagesArray[1], antialias);
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
						tick = ONE;
					case 3:
						countdownGo = createCountdownSprite(introImagesArray[2], antialias);
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						tick = GO;
					case 4:
						if (pauseSubState != null)
							pauseSubState.close();
						else
							finishResumeCountdown();
						callOnScripts('onResumeCountdownFinished');
						return;
				}

				stagesFunc(function(stage:BaseStage) stage.countdownTick(tick, swagCounter));
				callOnLuas('onCountdownTick', [swagCounter]);
				callOnHScript('onCountdownTick', [tick, swagCounter]);
				swagCounter += 1;
			}, 5);
		}
		else
		{
			if (pauseSubState != null)
				pauseSubState.close();
			else
				finishResumeCountdown();
		}
	}

	function finishResumeCountdown():Void
	{
		if (FlxG.sound.music != null && !startingSong && canResync)
			resyncVocals();
		refreshModchartAfterPause();
		resumeGameplayVideos();
		paused = false;
		resumingWithCountdown = false;
		callOnScripts('onResume');
		resetRPC(startTimer != null && startTimer.finished);
		runSongSyncThread();
	}

	public function addBehindGF(obj:FlxBasic)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	public function addBehindBF(obj:FlxBasic)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	public function addBehindDad(obj:FlxBasic)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int;
		if (denseChartQueue)
		{
			var queued:Note = nextUnspawnNote();
			while (queued != null && queued.strumTime - 350 < time)
			{
				queued.active = queued.visible = false;
				queued.ignoreNote = true;
				queued.destroy();
				unspawnNoteCursor++;
				queued = nextUnspawnNote();
			}
			compactDenseUnspawnQueue(true);
		}
		else
		{
			i = unspawnNotes.length - 1;
			while (i >= 0) {
				var daNote:Note = unspawnNotes[i];
				if(daNote.strumTime - 350 < time)
				{
					daNote.active = false;
					daNote.visible = false;
					daNote.ignoreNote = true;
					unspawnNotes.remove(daNote);
					daNote.destroy();
				}
				--i;
			}
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote != null && daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;
				invalidateNote(daNote);
			}
			--i;
		}
	}

	// fun fact: Dynamic Functions can be overriden by just doing this
	// `updateScore = function(miss:Bool = false) { ... }
	// its like if it was a variable but its just a function!
	// cool right? -Crow
	public dynamic function updateScore(miss:Bool = false, scoreBop:Bool = true)
	{
		var ret:Dynamic = callOnScripts('preUpdateScore', [miss], true);
		if (ret == LuaUtils.Function_Stop)
			return;

		updateScoreText();
		if (!miss && !cpuControlled && scoreBop)
			doScoreBop();

		callOnScripts('onUpdateScore', [miss]);
	}

	public dynamic function updateScoreText()
	{
		if (cpuControlled && !isBotplayCPU())
		{
			scoreTxt.text = Language.getPhrase('playstate.hud.botplay_mode', 'BOTPLAY MODE');
			return;
		}

		var str:String = Language.getPhrase('rating_$ratingName', ratingName);
		if(totalPlayed != 0)
		{
			str += ' (${AccuracyTools.format(ratingPercent)}) - ' + Language.getPhrase(ratingFC);
		}

		var tempScore:String;
		var score:String = ClientPrefs.data.abbreviateScore ? CoolUtil.formatScore(songScore) : Std.string(songScore);
		if(ClientPrefs.data.psychScoreText)
		{
			if(!instakillOnMiss) tempScore = Language.getPhrase('playstate.hud.score.psych',
				Language.getPhrase('score_text', 'Score: {1} | Misses: {2} | Rating: {3}', [score, songMisses, str]), [score, songMisses, str]);
			else tempScore = Language.getPhrase('playstate.hud.score.psych_instakill',
				Language.getPhrase('score_text_instakill', 'Score: {1} | Rating: {2}', [score, str]), [score, str]);
		}
		else
		{
			var tps:String = Std.string(getTPS());
			if(!instakillOnMiss) tempScore = Language.getPhrase('playstate.hud.score.plus',
				Language.getPhrase('score_text_plus', 'Score: {1} | Misses: {2} | Combo: {3} | TPS: {4} | Rating: {5}',
					[score, songMisses, combo, tps, str]), [score, songMisses, combo, tps, str]);
			else tempScore = Language.getPhrase('playstate.hud.score.plus_instakill',
				Language.getPhrase('score_text_plus_instakill', 'Score: {1} | Combo: {2} | TPS: {3} | Rating: {4}', [score, combo, tps, str]),
				[score, combo, tps, str]);
		}
		scoreTxt.text = tempScore;
	}

	function botplayLabel():String
		return modes.label(cpuControlled, practiceMode, isBotplayCPU()
			? Language.getPhrase('playstate.hud.botplay_cpu', 'BOTPLAY CPU: {1}', [botplayCPUProfile().toUpperCase()])
			: Language.getPhrase('playstate.hud.botplay', 'BOTPLAY'));

	function versionLabel():String
	{
		var value:String = Language.getPhrase('playstate.hud.version', '{1} ({2}) - Plus Engine v{3}',
			[SONG.song, Difficulty.getString(), MainMenuState.plusEngineVersion]);
		if(BuildInfo.githubDevBuild && BuildInfo.commit.length > 0)
			value += ' #' + BuildInfo.shortCommit();
		return value;
	}

	function refreshLocalizedHud():Void
	{
		languageRevision = Language.revision;
		if (scoreTxt != null)
			updateScoreText();
		if (botplayTxt != null)
			botplayTxt.text = botplayLabel();
		if (versionText != null)
			versionText.text = versionLabel();
	}

	function botplayKind():String
		return CoolUtil.botplayType(ClientPrefs.getGameplaySetting('botplayType', 'Normal'));

	inline function isBotplayCPU():Bool
		return cpuControlled && botplayKind() == 'CPU';

	function botplayCPUProfile():String
		return BotplayCPU.normalizeProfile(ClientPrefs.getGameplaySetting('botplayCPUProfile', 'Skilled'));

	inline function get_perfectMode():Bool
		return modes.perfect;

	inline function get_playOpponent():Bool
		return modes.opponent;

	inline function get_noDropPenalty():Bool
		return modes.noDrop;

	inline function get_opponentDrain():Bool
		return modes.drain;

	inline function playerChar():Character
		return modes.player(boyfriend, dad);

	inline function opponentChar():Character
		return modes.rival(boyfriend, dad);

	function getTPS():Int
	{
		if (cpuControlled && !isBotplayCPU())
			return 0;

		var minTime:Float = Conductor.songPosition - 1000;
		while (hitTimes.length > 0 && hitTimes[0].time < minTime)
			hitTimes.shift();
		var count:Int = 0;
		for (hit in hitTimes)
			count += hit.count;
		return count;
	}

	function botplayCPUHitOffset(note:Note):Float
	{
		if (botplayCPU == null || botplayCPU.profileName != botplayCPUProfile())
			botplayCPU = new BotplayCPU(botplayCPUProfile());
		return botplayCPU.hitOffset(note, Conductor.safeZoneOffset);
	}

	public dynamic function fullComboFunction()
	{
		var sicks:Int = ratingsData[0].hits;
		var goods:Int = ratingsData[1].hits;
		var bads:Int = ratingsData[2].hits;
		var shits:Int = ratingsData[3].hits;

		ratingFC = "";
		if(songMisses == 0)
		{
			if (bads > 0 || shits > 0) ratingFC = 'FC';
			else if (goods > 0) ratingFC = 'GFC';
			else if (sicks > 0) ratingFC = 'SFC';
		}
		else {
			if (songMisses < 10) ratingFC = 'SDCB';
			else ratingFC = 'Clear';
		}
	}

	public function doScoreBop():Void {
		if(!ClientPrefs.data.scoreZoom)
			return;

		if(scoreTxtTween != null)
			scoreTxtTween.cancel();

		scoreTxt.scale.x = 1.075;
		scoreTxt.scale.y = 1.075;
		scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
			onComplete: function(twn:FlxTween) {
				scoreTxtTween = null;
			}
		});
	}

	public function setSongTime(time:Float)
	{
		FlxG.sound.music.pause();
		if (hasAudio(vocals)) vocals.pause();
		if (hasAudio(opponentVocals)) opponentVocals.pause();

		FlxG.sound.music.time = time - Conductor.offset;
		FlxG.sound.music.play();
		#if FLX_PITCH applyAudioRate(FlxG.sound.music); #end

		if (hasAudio(vocals) && Conductor.songPosition < vocals.length)
		{
			vocals.time = time - Conductor.offset;
			vocals.play();
			#if FLX_PITCH applyAudioRate(vocals); #end
		}
		else if (hasAudio(vocals)) vocals.pause();

		if (hasAudio(opponentVocals) && Conductor.songPosition < opponentVocals.length)
		{
			opponentVocals.time = time - Conductor.offset;
			opponentVocals.play();
			#if FLX_PITCH applyAudioRate(opponentVocals); #end
		}
		else if (hasAudio(opponentVocals)) opponentVocals.pause();
		Conductor.songPosition = time;
	}

	inline function hasAudio(sound:FlxSound):Bool
		return sound != null && sound.length > 0;

	public function startNextDialogue() {
		dialogueCount++;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue() {
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}

	function startSong():Void
	{
		startingSong = false;

		@:privateAccess
		FlxG.sound.playMusic(inst._sound, 1, false);
		#if FLX_PITCH applyAudioRate(FlxG.sound.music); #end
		FlxG.sound.music.onComplete = finishSong.bind();
		if (hasAudio(vocals)) vocals.play();
		if (hasAudio(opponentVocals)) opponentVocals.play();

		setSongTime(Math.max(0, startOnTime - 500) + Conductor.offset);
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			if (hasAudio(vocals)) vocals.pause();
			if (hasAudio(opponentVocals)) opponentVocals.pause();
		}

		stagesFunc(function(stage:BaseStage) stage.startSong());

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		if (versionText != null)
		{
			FlxTween.tween(versionText, {y: 5}, 0.5, {ease: FlxEase.circOut});
			new FlxTimer().start(5, function(tmr:FlxTimer)
			{
				if (versionText != null)
					FlxTween.tween(versionText, {alpha: 0.4}, 1, {ease: FlxEase.sineInOut});
			});
		}

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence (with Time Left)
		if(autoUpdateRPC) DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart');

		runSongSyncThread();
	}

	public function doTimeBump():Void
	{
		if (timeTxt == null || !ClientPrefs.data.timeBump)
			return;

		if (timeTween != null)
			timeTween.cancel();

		timeTxt.scale.set(1.5, 1.5);
		timeTween = FlxTween.tween(timeTxt.scale, {x: 1, y: 1}, 0.3 / playbackRate, {
			ease: FlxEase.expoOut,
			onComplete: function(twn:FlxTween) timeTween = null
		});
	}

	private var noteTypes:Array<String> = [];
	private var eventsPushed:Array<String> = [];
	private var totalColumns: Int = 4;

	private function generateSong():Void
	{
		var generateStarted:Float = haxe.Timer.stamp();
		// FlxG.log.add(ChartParser.parse());
		songSpeed = PlayState.SONG.speed;
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');
		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}

		var songData = SONG;
		Conductor.bpm = songData.bpm;

		curSong = songData.song;

		vocals = new FlxSound();
		opponentVocals = new FlxSound();
		try
		{
			if (songData.needsVoices)
			{
				var playerVocals = Paths.voices(songData.song, (boyfriend.vocalsFile == null || boyfriend.vocalsFile.length < 1) ? 'Player' : boyfriend.vocalsFile);
				vocals.loadEmbedded(playerVocals != null ? playerVocals : Paths.voices(songData.song));

				var oppVocals = Paths.voices(songData.song, (dad.vocalsFile == null || dad.vocalsFile.length < 1) ? 'Opponent' : dad.vocalsFile);
				if(oppVocals != null && oppVocals.length > 0) opponentVocals.loadEmbedded(oppVocals);
			}
		}
		catch (e:Dynamic) {}
		if (songData.needsVoices && !hasAudio(vocals) && !hasAudio(opponentVocals))
			songData.needsVoices = false;

		#if FLX_PITCH
		if (hasAudio(vocals)) applyAudioRate(vocals);
		if (hasAudio(opponentVocals)) applyAudioRate(opponentVocals);
		#end
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(opponentVocals);

		inst = new FlxSound();
		try
		{
			inst.loadEmbedded(Paths.inst(songData.song));
		}
		catch (e:Dynamic) {}
		FlxG.sound.list.add(inst);
		var audioFinished:Float = haxe.Timer.stamp();

		notes = new FlxTypedGroup<Note>();
		noteGroup.add(notes);

		try
		{
			var eventsChart:SwagSong = Song.getChart('events', songName);
			if(eventsChart != null)
				for (event in eventsChart.events) //Event Notes
					for (i in 0...event[1].length)
						makeEvent(event, i);
		}
		catch(e:Dynamic) {}

		var oldNote:Note = null;
		var ghostNotesCaught:Int = 0;
		var chartNotes:Map<String, Note> = [];
		var loadPlan:SongLoadPlan = SongLoadPlan.get(songData);
		denseChartQueue = loadPlan.denseChart;
		unspawnNoteCursor = 0;

		for (chartNote in loadPlan.notes)
		{
				var spawnTime:Float = chartNote.strumTime;
				var noteColumn:Int = chartNote.column;
				var holdLength:Float = chartNote.sustainLength;
				var noteType:String = chartNote.noteType;
				var gottaHitNote:Bool = chartNote.gottaHit;
				var mustPress:Bool = modes.chartHit(gottaHitNote);

				// A map avoids rescanning every generated note for each chart entry.
				var chartNoteKey:String = '$spawnTime|$noteColumn|$mustPress|$noteType';
				var evilNote:Note = chartNotes.get(chartNoteKey);
				if (evilNote != null)
				{
					for (tail in evilNote.tail)
					{
						tail.destroy();
						unspawnNotes.remove(tail);
					}
					if (oldNote == evilNote)
						oldNote = null;
					evilNote.destroy();
					unspawnNotes.remove(evilNote);
					ghostNotesCaught++;
				}

				var swagNote:Note = new Note(spawnTime, noteColumn, oldNote);
				swagNote.gfNote = chartNote.gfNote;
				swagNote.animSuffix = chartNote.altAnim ? "-alt" : "";
				swagNote.mustPress = mustPress;
				swagNote.sustainLength = holdLength;
				swagNote.noteType = noteType;
				swagNote.noteDensity = chartNote.density;

				swagNote.scrollFactor.set();
				unspawnNotes.push(swagNote);
				chartNotes.set(chartNoteKey, swagNote);

				var curStepCrochet:Float = chartNote.stepCrochet;
				final roundSus:Int = Math.round(swagNote.sustainLength / curStepCrochet);
				if(roundSus > 0)
				{
					for (susNote in 0...roundSus)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(spawnTime + (curStepCrochet * susNote), noteColumn, oldNote, true);
						sustainNote.animSuffix = swagNote.animSuffix;
						sustainNote.mustPress = swagNote.mustPress;
						sustainNote.gfNote = swagNote.gfNote;
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
						swagNote.tail.push(sustainNote);

						sustainNote.correctionOffset = swagNote.height / 2;
						if(!PlayState.isPixelStage)
						{
							if(oldNote.isSustainNote)
							{
								oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
								oldNote.scale.y /= playbackRate;
								oldNote.resizeByRatio(curStepCrochet / Conductor.stepCrochet);
							}

							if(ClientPrefs.data.downScroll)
								sustainNote.correctionOffset = 0;
						}
						else if(oldNote.isSustainNote)
						{
							oldNote.scale.y /= playbackRate;
							oldNote.resizeByRatio(curStepCrochet / Conductor.stepCrochet);
						}

						if (sustainNote.mustPress)
						{
							sustainNote.x += HudSafeZone.x();
							sustainNote.x += HudSafeZone.width() / 2;
						}
						else if(ClientPrefs.data.middleScroll)
						{
							sustainNote.x += 310;
							if(noteColumn > 1) //Up and Right
								sustainNote.x += FlxG.width / 2 + 25;
						}
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += HudSafeZone.x();
					swagNote.x += HudSafeZone.width() / 2;
				}
				else if(ClientPrefs.data.middleScroll)
				{
					swagNote.x += 310;
					if(noteColumn > 1) //Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}
				if(!noteTypes.contains(swagNote.noteType))
					noteTypes.push(swagNote.noteType);

				oldNote = swagNote;
		}
		trace('["${SONG.song.toUpperCase()}" CHART INFO]: Ghost Notes Cleared: $ghostNotesCaught');
		for (event in songData.events) //Event Notes
			for (i in 0...event[1].length)
				makeEvent(event, i);

		unspawnNotes.sort(sortByTime);
		totalNotes = 0;
		for(note in unspawnNotes)
			if(note != null && !note.isSustainNote && note.mustPress)
				totalNotes += noteDensityCount(note);
		if (denseChartQueue)
			trace('[DENSE CHART]: packed ${loadPlan.sourceNoteCount} chart taps into ${unspawnNotes.length} runtime notes at 120 Hz.');
		generatedMusic = true;
		var generateFinished:Float = haxe.Timer.stamp();
		SongLoadMetrics.recordGeneration((generateFinished - generateStarted) * 1000, (audioFinished - generateStarted) * 1000,
			(generateFinished - audioFinished) * 1000, unspawnNotes.length);
	}

	// called only once per different event (Used for precaching)
	function eventPushed(event:EventNote) {
		eventPushedUnique(event);
		if(eventsPushed.contains(event.event)) {
			return;
		}

		stagesFunc(function(stage:BaseStage) stage.eventPushed(event));
		eventsPushed.push(event.event);
	}

	// called by every event with the same name
	function eventPushedUnique(event:EventNote) {
		switch(event.event) {
			case "Change Character":
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						var val1:Int = Std.parseInt(event.value1);
						if(Math.isNaN(val1)) val1 = 0;
						charType = val1;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);

			case 'Play Sound':
				Paths.sound(event.value1); //Precache sound
		}
		stagesFunc(function(stage:BaseStage) stage.eventPushedUnique(event));
	}

	function eventEarlyTrigger(event:EventNote):Float {
		var returnedValue:Null<Float> = callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], true);
		if(returnedValue != null && returnedValue != 0) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	public static function sortNotesByY(order:Int, noteA:Note, noteB:Note):Int
	{
		if (noteA == null)
			return noteB == null ? 0 : 1;
		if (noteB == null)
			return -1;
		return FlxSort.byY(order, noteA, noteB);
	}

	function makeEvent(event:Array<Dynamic>, i:Int)
	{
		var subEvent:EventNote = {
			strumTime: event[0] + ClientPrefs.data.noteOffset,
			event: event[1][i][0],
			value1: event[1][i][1],
			value2: event[1][i][2]
		};

		if (event[1][i].length > 3 && event[1][i][3] != null)
			subEvent.value3 = event[1][i][3];
		else
			subEvent.value3 = '';

		if (event[1][i].length > 4 && event[1][i][4] != null)
			subEvent.value4 = event[1][i][4];
		else
			subEvent.value4 = '';

		eventNotes.push(subEvent);
		eventPushed(subEvent);
		callOnScripts('onEventPushed', [subEvent.event, subEvent.value1 != null ? subEvent.value1 : '', subEvent.value2 != null ? subEvent.value2 : '', subEvent.strumTime, subEvent.value3 != null ? subEvent.value3 : '', subEvent.value4 != null ? subEvent.value4 : '']);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int):Void
	{
		var strumLineX:Float = ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
		var strumLineY:Float = HudSafeZone.y() + (ClientPrefs.data.downScroll ? (HudSafeZone.height() - 150) : 50);
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1)
			{
				if(!ClientPrefs.data.opponentStrums) targetAlpha = 0;
				else if(ClientPrefs.data.middleScroll) targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			if (!isStoryMode && !skipArrowStartTween)
			{
				//babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10,*/ alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else babyArrow.alpha = targetAlpha;

			if (modes.playerStrum(player))
				playerStrums.add(babyArrow);
			else
			{
				if(ClientPrefs.data.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.playerPosition();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		stagesFunc(function(stage:BaseStage) stage.openSubState(SubState));
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				opponentVocals.pause();
			}
			pauseGameplayVideos();
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if(!tmr.finished) tmr.active = false);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if(!twn.finished) twn.active = false);
		}

		super.openSubState(SubState);
	}

	public var canResync:Bool = true;
	override function closeSubState()
	{
		super.closeSubState();

		stagesFunc(function(stage:BaseStage) stage.closeSubState());
		if (paused)
		{
			if (ClientPrefs.data.pauseCountdown)
				resumingWithCountdown = true;

			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if(!tmr.finished) tmr.active = true);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if(!twn.finished) twn.active = true);

			if (resumingWithCountdown)
			{
				resumeWithCountdown();
				return;
			}

			finishResumeCountdown();
		}
	}

	#if DISCORD_ALLOWED
	override public function onFocus():Void
	{
		super.onFocus();
		if (!paused && health > 0)
		{
			resetRPC(Conductor.songPosition > 0.0);
		}
		shutdownThread = false;
		runSongSyncThread();
	}

	override public function onFocusLost():Void
	{
		super.onFocusLost();
		if (!paused && health > 0 && autoUpdateRPC)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		shutdownThread = true;
	}
	#end

	// Updating Discord Rich Presence.
	public var autoUpdateRPC:Bool = true; //performance setting for custom RPC things
	function resetRPC(?showTime:Bool = false)
	{
		#if DISCORD_ALLOWED
		if(!autoUpdateRPC) return;

		if (showTime)
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.data.noteOffset);
		else
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		trace('resynced vocals at ' + Math.floor(Conductor.songPosition));

		FlxG.sound.music.play();
		#if FLX_PITCH applyAudioRate(FlxG.sound.music); #end
		Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

		var checkVocals = [vocals, opponentVocals];
		for (voc in checkVocals)
		{
			if (!hasAudio(voc))
				continue;
			if (FlxG.sound.music.time < voc.length)
			{
				voc.time = FlxG.sound.music.time;
				#if FLX_PITCH applyAudioRate(voc); #end
				voc.play();
			}
			else voc.pause();
		}
	}

	function pauseGameplayVideos():Void
	{
		if (videoCutscene != null)
			videoCutscene.pause();
		#if LUA_ALLOWED
		psychlua.VideoFunctions.pauseAll();
		#end
	}

	function resumeGameplayVideos():Void
	{
		if (videoCutscene != null)
			videoCutscene.resume();
		#if LUA_ALLOWED
		psychlua.VideoFunctions.resumeAll();
		#end
	}

	function refreshModchartAfterPause():Void
	{
		#if MODCHART_ALLOWED
		if (Manager.instance != null)
			Manager.instance.refreshFrameState();
		#end
	}

	public var paused:Bool = false;
	public var resumingWithCountdown:Bool = false;
	public var canReset:Bool = true;
	var audioRecoveryPending:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var freezeCamera:Bool = false;
	var allowDebugKeys:Bool = true;

	private inline function nextUnspawnNote():Note
		return denseChartQueue ? (unspawnNoteCursor < unspawnNotes.length ? unspawnNotes[unspawnNoteCursor] : null) : unspawnNotes[0];

	private function compactDenseUnspawnQueue(?force:Bool = false):Void
	{
		if (!denseChartQueue || unspawnNoteCursor <= 0)
			return;
		if (!force && unspawnNoteCursor < DENSE_QUEUE_COMPACT_AT)
			return;
		unspawnNotes.splice(0, unspawnNoteCursor);
		unspawnNoteCursor = 0;
	}

	private static inline function noteDensityCount(note:Note):Int
		return note == null ? 1 : Std.int(Math.max(1, Math.round(note.noteDensity)));

	private inline function requestRatingRecalculation(badHit:Bool):Void
	{
		if (!denseChartQueue)
		{
			RecalculateRating(badHit);
			return;
		}
		denseRatingPending = true;
		denseRatingHadMiss = denseRatingHadMiss || badHit;
	}

	private function flushDenseRatingRecalculation():Void
	{
		if (!denseRatingPending)
			return;
		var badHit:Bool = denseRatingHadMiss;
		denseRatingPending = false;
		denseRatingHadMiss = false;
		RecalculateRating(badHit);
	}

	override public function update(elapsed:Float)
	{
		denseHitVisualsThisFrame = 0;
		if(!inCutscene && !paused && !freezeCamera) {
			FlxG.camera.followLerp = 0.04 * cameraSpeed * playbackRate;
			var pc:Character = playerChar();
			var idleAnim:Bool = (pc.getAnimationName().startsWith('idle') || pc.getAnimationName().startsWith('danceLeft') || pc.getAnimationName().startsWith('danceRight'));
			if(!startingSong && !endingSong && idleAnim) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}
		else FlxG.camera.followLerp = 0;
		callOnScripts('onUpdate', [elapsed]);
		if (languageRevision != Language.revision)
			refreshLocalizedHud();

		super.update(elapsed);
		if (audioRecoveryPending && startedCountdown && !startingSong && !endingSong && !paused && FlxG.sound.music != null)
		{
			audioRecoveryPending = false;
			setSongTime(Math.max(0, Conductor.songPosition));
		}

		#if android
		updateAndroidComboSprites(elapsed);
		#end

		#if MODCHART_ALLOWED
		mcDebug(elapsed);
		#end

		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);

		if(botplayTxt != null && botplayTxt.visible) {
			botplayTxt.text = botplayLabel();
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE #if android || FlxG.android.justReleased.BACK #end && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnScripts('onPause', null, true);
			if(ret != LuaUtils.Function_Stop) {
				openPauseMenu();
			}
		}

		if(!endingSong && !inCutscene && allowDebugKeys)
		{
			if (controls.justPressed('debug_1'))
				openChartEditor();
			else if (controls.justPressed('debug_2'))
				openCharacterEditor();
		}

		if (healthBar.bounds.max != null && health > healthBar.bounds.max)
			health = healthBar.bounds.max;

		updateIconsScale(elapsed);
		updateIconsPosition();

		if (startedCountdown && !paused)
		{
			Conductor.songPosition += elapsed * 1000 * playbackRate;
			if (Conductor.songPosition >= Conductor.offset)
			{
				Conductor.songPosition = FlxMath.lerp(FlxG.sound.music.time + Conductor.offset, Conductor.songPosition, Math.exp(-elapsed * 5));
				var timeDiff:Float = Math.abs((FlxG.sound.music.time + Conductor.offset) - Conductor.songPosition);
				if (timeDiff > 1000 * playbackRate)
					Conductor.songPosition = Conductor.songPosition + 1000 * FlxMath.signOf(timeDiff);
			}
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= Conductor.offset)
				startSong();
			else if(!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
		}
		else if (!paused && updateTime)
		{
			if (breakTimerHud != null && playerStrums != null && playerStrums.length > 0)
				breakTimerHud.updateDisplay(Conductor.songPosition, startingSong, playerStrums, ClientPrefs.data.downScroll, strumCenterX, strumTopY);

			var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.data.noteOffset);
			songPercent = (curTime / songLength);

			var songCalc:Float = (songLength - curTime);
			if(ClientPrefs.data.timeBarType == 'Time Elapsed') songCalc = curTime;

			var secondsTotal:Int = Math.floor(songCalc / 1000);
			if(secondsTotal < 0) secondsTotal = 0;

			if(ClientPrefs.data.timeBarType != 'Song Name')
			{
				timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
			}

			if (ClientPrefs.data.endCountdown || endCountdownText != null)
				updateEndCountdown(curTime);
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.data.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		var queuedNote:Note = nextUnspawnNote();
		if (queuedNote != null)
		{
			var time:Float = spawnTime;
			#if MODCHART_ALLOWED
			if (Manager.instance != null)
				time = Manager.instance.getNoteSpawnTime(queuedNote.mustPress ? 1 : 0, time);
			#end
			// Chart time advances playbackRate times faster than real time. Scale the
			// final Manager/fallback window so notes still enter from off-screen.
			time *= playbackRate;
			if(songSpeed < 1) time /= songSpeed;
			if(queuedNote.multSpeed < 1) time /= queuedNote.multSpeed;

			while ((queuedNote = nextUnspawnNote()) != null && queuedNote.strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = queuedNote;
				if (denseChartQueue)
					notes.add(dunceNote);
				else
					notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote, dunceNote.strumTime]);
				callOnHScript('onSpawnNote', [dunceNote]);

				if (denseChartQueue)
					unspawnNoteCursor++;
				else
					unspawnNotes.splice(0, 1);
			}
			compactDenseUnspawnQueue();
		}

		if (generatedMusic)
		{
			if(!inCutscene)
			{
				if(!cpuControlled)
					keysCheck();
				else
					playerDance();

				if(notes.length > 0)
				{
					if(startedCountdown)
					{
						var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
						var i:Int = 0;
						while(i < notes.length)
						{
							var daNote:Note = notes.members[i];
							if(daNote == null)
							{
								i++;
								continue;
							}

							var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
							if(!daNote.mustPress) strumGroup = opponentStrums;

							var strum:StrumNote = strumGroup.members[daNote.noteData];
							daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);

							if(daNote.mustPress)
							{
								if(cpuControlled && !daNote.blockHit && daNote.canBeHit && (daNote.isSustainNote || daNote.strumTime <= Conductor.songPosition))
								{
									var realSongPosition:Float = Conductor.songPosition;
									var canHit:Bool = true;
									if (isBotplayCPU() && !daNote.isSustainNote)
									{
										var hitMs:Float = botplayCPUHitOffset(daNote);
										canHit = !Math.isNaN(hitMs);
										if (canHit)
											Conductor.songPosition = daNote.strumTime + ClientPrefs.data.ratingOffset - (hitMs * playbackRate);
									}
									else if (isBotplayCPU())
										canHit = !Math.isNaN(botplayCPUHitOffset(daNote));
									else
										Conductor.songPosition = daNote.strumTime + ClientPrefs.data.ratingOffset;

									if (canHit)
										goodNoteHit(daNote);
									else
										daNote.blockHit = true;
									Conductor.songPosition = realSongPosition;
								}
							}
							else if (daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
								opponentNoteHit(daNote);

							if(daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumNote(strum);

							// Kill extremely late notes and cause misses
							if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
							{
								var shouldMiss:Bool = daNote.mustPress && (!cpuControlled || isBotplayCPU()) && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit);

								if (shouldMiss && daNote.isSustainNote && noDropPenalty)
									shouldMiss = false;

								if (shouldMiss)
									noteMiss(daNote);

								daNote.active = daNote.visible = false;
								invalidateNote(daNote);
							}
							if(daNote.exists) i++;
						}
					}
					else
					{
						notes.forEachAlive(function(daNote:Note)
						{
							daNote.canBeHit = false;
							daNote.wasGoodHit = false;
						});
					}
				}
			}
			flushDenseRatingRecalculation();
			checkEventNote();
		}

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		setOnScripts('botPlay', cpuControlled);
		setOnScripts('botPlayCPUProfile', isBotplayCPU() ? botplayCPUProfile() : '');
		callOnScripts('onUpdatePost', [elapsed]);
	}

	override function onAudioDeviceReopened():Void
	{
		audioRecoveryPending = true;
	}

	// Health icon updaters
	public dynamic function updateIconsScale(elapsed:Float)
		HealthIconHud.scale(elapsed, playbackRate, iconP1, iconP2, iconGF);

	public dynamic function updateIconsPosition()
	{
		var isGFSinging:Bool = (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection);
		HealthIconHud.position(healthBar, isGFSinging, gfIconSide, gfIconSwapOnSing, iconP1, iconP2, iconGF);
	}

	function updateIconAnimations():Void
		HealthIconHud.frames(healthBar, playOpponent, gfIconSide, iconP1, iconP2, iconGF);

	function set_health(value:Float):Float // You can alter how icon animations work here
	{
		value = FlxMath.roundDecimal(value, 5); //Fix Float imprecision
		if(healthBar == null || !healthBar.enabled || healthBar.valueFunction == null)
		{
			health = value;
			return health;
		}

		// update health bar
		health = value;
		var newPercent:Null<Float> = FlxMath.remapToRange(FlxMath.bound(healthBar.valueFunction(), healthBar.bounds.min, healthBar.bounds.max), healthBar.bounds.min, healthBar.bounds.max, 0, 100);
		healthBar.percent = (newPercent != null ? newPercent : 0);

		updateIconAnimations();
		return health;
	}

	function openPauseMenu()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		if(FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}
		if(!cpuControlled)
		{
			for (note in playerStrums)
				if(note.animation.curAnim != null && note.animation.curAnim.name != 'static')
				{
					note.playAnim('static');
					note.resetAnim = 0;
				}
		}
		#if HSCRIPT_ALLOWED
		openSubState(backend.ScriptableSubstate.tryCreate('PauseSubState', new PauseSubState()));
		#else
		openSubState(new PauseSubState());
		#end

		#if DISCORD_ALLOWED
		if(autoUpdateRPC) DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	public function openChartEditor()
	{
		canResync = false;
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		chartingMode = true;
		paused = true;

		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();
		if(vocals != null)
			vocals.pause();
		if(opponentVocals != null)
			opponentVocals.pause();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence(Language.getPhrase('playstate.presence.chart_editor', 'Chart Editor'), null, null, true);
		DiscordClient.resetClientID();
		#end

		MusicBeatState.switchState(new ChartingState());
	}

	function openCharacterEditor()
	{
		canResync = false;
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;

		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();
		if(vocals != null)
			vocals.pause();
		if(opponentVocals != null)
			opponentVocals.pause();

		#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
		MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	public var gameOverTimer:FlxTimer;
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead && gameOverTimer == null)
		{
			var ret:Dynamic = callOnScripts('onGameOver', null, true);
			if(ret != LuaUtils.Function_Stop)
			{
				FlxG.animationTimeScale = 1;
				playerChar().stunned = true;
				deathCounter++;

				paused = true;
				canResync = false;
				canPause = false;
				#if VIDEOS_ALLOWED
				if(videoCutscene != null)
				{
					videoCutscene.destroy();
					videoCutscene = null;
				}
				#end

				persistentUpdate = false;
				persistentDraw = false;
				FlxTimer.globalManager.clear();
				FlxTween.globalManager.clear();
				FlxG.camera.setFilters([]);

				if(GameOverSubstate.deathDelay > 0)
				{
					gameOverTimer = new FlxTimer().start(GameOverSubstate.deathDelay, function(_)
					{
						vocals.stop();
						opponentVocals.stop();
						FlxG.sound.music.stop();
						#if HSCRIPT_ALLOWED
						openSubState(backend.ScriptableSubstate.tryCreate('GameOverSubstate', new GameOverSubstate(playerChar())));
						#else
						openSubState(new GameOverSubstate(playerChar()));
						#end
						gameOverTimer = null;
					});
				}
				else
				{
					vocals.stop();
					opponentVocals.stop();
					FlxG.sound.music.stop();
					#if HSCRIPT_ALLOWED
					openSubState(backend.ScriptableSubstate.tryCreate('GameOverSubstate', new GameOverSubstate(boyfriend)));
					#else
					openSubState(new GameOverSubstate(boyfriend));
					#end
				}

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if DISCORD_ALLOWED
				// Game Over doesn't get his its variable because it's only used here
				if(autoUpdateRPC) DiscordClient.changePresence(Language.getPhrase('playstate.presence.game_over', 'Game Over - {1}', [detailsText]),
					SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				return;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			var value3:String = '';
			if (eventNotes[0].value3 != null)
				value3 = eventNotes[0].value3;

			var value4:String = '';
			if (eventNotes[0].value4 != null)
				value4 = eventNotes[0].value4;

			triggerEvent(eventNotes[0].event, value1, value2, value3, value4, leStrumTime);
			eventNotes.shift();
		}
	}

	public function triggerEvent(eventName:String, value1:String, value2:String, value3:String, value4:String, strumTime:Float) {
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		var flValue3:Null<Float> = Std.parseFloat(value3);
		var flValue4:Null<Float> = Std.parseFloat(value4);
		if(Math.isNaN(flValue1)) flValue1 = null;
		if(Math.isNaN(flValue2)) flValue2 = null;
		if(Math.isNaN(flValue3)) flValue3 = null;
		if(Math.isNaN(flValue4)) flValue4 = null;

		switch(eventName) {
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				if(flValue2 == null || flValue2 <= 0) flValue2 = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = flValue2;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = flValue2;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = flValue2;
				}

			case 'Set GF Speed':
				if(flValue1 == null || flValue1 < 1) flValue1 = 1;
				gfSpeed = Math.round(flValue1);

			case 'Add Camera Zoom':
				if(ClientPrefs.data.camZooms && FlxG.camera.zoom < 1.35) {
					if(flValue1 == null) flValue1 = 0.015;
					if(flValue2 == null) flValue2 = 0.03;

					FlxG.camera.zoom += flValue1;
					camHUD.zoom += flValue2;
				}

			case 'Set Camera Bopping':
				if(flValue1 == null || flValue1 <= 0) flValue1 = 1;
				if(flValue2 == null) flValue2 = 1;

				cameraBopFrequency = flValue1;
				cameraBopIntensity = flValue2;
				cameraBopEnabled = cameraBopIntensity > 0;

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						if(flValue2 == null) flValue2 = 0;
						switch(Math.round(flValue2)) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				if(camFollow != null)
				{
					isCameraOnForcedPos = false;
					if(flValue1 != null || flValue2 != null)
					{
						isCameraOnForcedPos = true;
						if(flValue1 == null) flValue1 = 0;
						if(flValue2 == null) flValue2 = 0;
						camFollow.x = flValue1;
						camFollow.y = flValue2;
					}
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}


			case 'Change Character':
				var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon, true, SONG.isAnimated == true || boyfriend.animatedIcon, boyfriend.iconFps);
							updateIconAnimations();
						}
						setOnScripts('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf-') || dad.curCharacter == 'gf';
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf-') && dad.curCharacter != 'gf') {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon, true, SONG.isAnimated == true || dad.animatedIcon, dad.iconFps);
							updateIconAnimations();
						}
						setOnScripts('dadName', dad.curCharacter);

					case 2:
						if(gf != null)
						{
							if(gf.curCharacter != value2)
							{
								if(!gfMap.exists(value2)) {
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
								if(iconGF != null)
									iconGF.changeIcon(gf.healthIcon, false, SONG.isAnimated == true || gf.animatedIcon, gf.iconFps);
								updateIconAnimations();
							}
							setOnScripts('gfName', gf.curCharacter);
						}
				}
				reloadHealthBarColors();

			case 'Change Scroll Speed':
				if (songSpeedType != "constant")
				{
					if(flValue1 == null) flValue1 = 1;
					if(flValue2 == null) flValue2 = 0;

					var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed') * flValue1;
					if(flValue2 <= 0)
						songSpeed = newValue;
					else
						songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, flValue2 / playbackRate, {ease: FlxEase.linear, onComplete:
							function (twn:FlxTween)
							{
								songSpeedTween = null;
							}
						});
				}

			case 'Set Property':
				try
				{
					var trueValue:Dynamic = value2.trim();
					if (trueValue == 'true' || trueValue == 'false') trueValue = trueValue == 'true';
					else if (flValue2 != null) trueValue = flValue2;
					else trueValue = value2;

					var split:Array<String> = value1.split('.');
					if(split.length > 1) {
						LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1], trueValue);
					} else {
						LuaUtils.setVarInArray(this, value1, trueValue);
					}
				}
				catch(e:Dynamic)
				{
					var len:Int = e.message.indexOf('\n') + 1;
					if(len <= 0) len = e.message.length;
					#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
					addTextToDebug('ERROR ("Set Property" Event) - ' + e.message.substr(0, len), FlxColor.RED);
					#else
					FlxG.log.warn('ERROR ("Set Property" Event) - ' + e.message.substr(0, len));
					#end
				}

			case 'Play Sound':
				if(flValue2 == null) flValue2 = 1;
				FlxG.sound.play(Paths.sound(value1), flValue2);

			case 'Change BPM':
				if (flValue1 != null && flValue1 > 0)
				{
					Conductor.bpm = flValue1;
					Conductor.crochet = (60 / flValue1) * 1000;
					Conductor.stepCrochet = Conductor.crochet / 4;
					setOnScripts('curBpm', Conductor.bpm);
					setOnScripts('crochet', Conductor.crochet);
					setOnScripts('stepCrochet', Conductor.stepCrochet);
				}

			case 'Lyric Event':
				if(lyricText != null)
				{
					if(lyricTween != null)
					{
						lyricTween.cancel();
						lyricTween = null;
					}

					var lyr = value1.trim();
					if(lyr.length > 0)
					{
						var col = FlxColor.WHITE;
						var raw = value2.trim();
						if(raw.length > 0)
						{
							try
							{
								col = FlxColor.fromString(raw);
							}
							catch(e:Dynamic)
							{
								col = FlxColor.WHITE;
							}
						}

						lyricText.text = lyr;
						lyricText.color = col;
						lyricText.alpha = 0;
						lyricTween = FlxTween.tween(lyricText, {alpha: 1}, 0.25, {
							ease: FlxEase.cubeOut,
							onComplete: function(t:FlxTween) lyricTween = null
						});
					}
					else
					{
						lyricTween = FlxTween.tween(lyricText, {alpha: 0}, 0.4, {
							ease: FlxEase.cubeIn,
							onComplete: function(t:FlxTween)
							{
								lyricText.text = "";
								lyricTween = null;
							}
						});
					}
				}

			case 'Add Secondary Icon':
				gfIconSide = value1.toLowerCase().trim();
				gfIconSwapOnSing = (value2.toLowerCase().trim() == 'true');

				if (iconGF != null)
				{
					var valid:Bool = (gfIconSide == 'dad' || gfIconSide == 'bf');
					iconGF.visible = !ClientPrefs.data.hideHud && valid;
					iconGF.flipX = (gfIconSide == 'bf');
				}

		    case 'Change UI':
				var skinChanged:Bool = false;

				if (value1 != null && value1.trim().length > 0)
				{
					SONG.arrowSkin = value1.trim();
					skinChanged = true;
				}
				if (value2 != null && value2.trim().length > 0)
				{
					SONG.splashSkin = value2.trim();
					skinChanged = true;
				}

				if (value3 != null && value3.trim().length > 0)
				{
					var newUI:String = value3.trim();
					if (stageUI != newUI)
					{
						if (temporaryStageUI == null)
							temporaryStageUI = stageUI;

						stageUI = newUI;

						reloadHealthBarColors();
						reloadGradientColors();
						refreshBreakTimerVisualStyle();

						if (iconP1 != null) iconP1.alpha = ClientPrefs.data.healthBarAlpha;
						if (iconP2 != null) iconP2.alpha = ClientPrefs.data.healthBarAlpha;
						if (iconGF != null) iconGF.alpha = ClientPrefs.data.healthBarAlpha;

						cacheCountdown();
						cachePopUpScore();

						skinChanged = true;
					}
				}

				if (skinChanged)
					reloadAllNotesSkin();

				callOnScripts('onUIChanged', [value3 != null ? value3 : '']);
		}

		stagesFunc(function(stage:BaseStage) stage.eventCalled(eventName, value1, value2, value3, value4, flValue1, flValue2, flValue3, flValue4, strumTime));
		callOnScripts('onEvent', [eventName, value1, value2, value3, value4, strumTime]);
	}

	public function moveCameraSection(?sec:Null<Int>):Void {
		if(sec == null) sec = curSection;
		if(sec < 0) sec = 0;

		if(SONG.notes[sec] == null) return;

		if (gf != null && SONG.notes[sec].gfSection)
		{
			moveCameraToGirlfriend();
			callOnScripts('onMoveCamera', ['gf']);
			return;
		}

		var isDad:Bool = (SONG.notes[sec].mustHitSection != true);
		if (playOpponent) isDad = !isDad;
		moveCamera(isDad);
		if (isDad)
			callOnScripts('onMoveCamera', ['dad']);
		else
			callOnScripts('onMoveCamera', ['boyfriend']);
	}

	public function moveCameraToGirlfriend()
	{
		camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
		camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
		camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
		tweenCamIn();
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		if(isDad)
		{
			if(dad == null) return;
			camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			tweenCamIn();
		}
		else
		{
			if(boyfriend == null) return;
			camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			if (songName == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
	}

	public function tweenCamIn() {
		if (songName == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		updateTime = false;
		FlxG.sound.music.volume = 0;

		vocals.volume = 0;
		vocals.pause();
		opponentVocals.volume = 0;
		opponentVocals.pause();

		if(ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset) {
			endCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer) {
				endCallback();
			});
		}
	}


	public var transitioning = false;

	public static function exitToScriptedStateIfNeeded():Bool
	{
		#if HSCRIPT_ALLOWED
		var explicitTarget:String = returnToScriptedState;
		returnToScriptedState = null;

		if (Mods.launchedMod == null || Mods.launchedMod.length < 1 || !Mods.isLaunchable(Mods.launchedMod))
			return false;

		var target:String = explicitTarget;
		if (target == null || target.length < 1)
			target = scripting.ScriptedStates.activeScriptedState;
		if (target == null || target.length < 1)
			target = Mods.getEntryState(Mods.launchedMod);
		if (target == null || target.length < 1)
			return false;

		FlxG.sound.playMusic(Paths.music(Mods.getMenuMusic(Mods.launchedMod)), 0);
		MusicBeatState.switchState(new scripting.ScriptedStates.ScriptedReturnState(target, scripting.ScriptedStates.ResolveScope.LAUNCHED));
		return true;
		#else
		return false;
		#end
	}

	public static function setExitTarget(name:String):Void
	{
		returnToScriptedState = name;
	}

	public static function exitToState(name:String):Void
	{
		returnToScriptedState = name;
		if (exitToScriptedStateIfNeeded())
			return;

		FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
		MusicBeatState.switchState(states.FreeplayStateSelector.create());
	}

	public function endSong()
	{
		mobileControls.instance.visible = #if !android touchPad.visible = #end false;
		//Should kill you if you tried to cheat
		if(!startingSong)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset)
						health -= 0.05 * healthLoss * noteDensityCount(daNote);
			});
			for (i in (denseChartQueue ? unspawnNoteCursor : 0)...unspawnNotes.length)
			{
				var daNote:Note = unspawnNotes[i];
				if(daNote != null && daNote.strumTime < songLength - Conductor.safeZoneOffset)
					health -= 0.05 * healthLoss * noteDensityCount(daNote);
			}

			if(doDeathCheck()) {
				return false;
			}
		}

		clearEndCountdown();
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		var weekNoMiss:String = WeekData.getWeekFileName() + '_nomiss';
		checkForAchievement([weekNoMiss, 'ur_bad', 'ur_good', 'hype', 'two_keys', 'toastie' #if BASE_GAME_FILES, 'debugger' #end]);
		#end

		var ret:Dynamic = callOnScripts('onEndSong', null, true);
		if(ret != LuaUtils.Function_Stop && !transitioning)
		{
			#if !switch
			var percent:Float = ratingPercent;
			if(Math.isNaN(percent)) percent = 0;
			Highscore.saveScore(Song.loadedSongName, songScore, storyDifficulty, percent);
			#end
			playbackRate = 1;

			if (!chartingMode && !isStoryMode)
			{
				if (ClientPrefs.data.resultsStateAtEnd && !cpuControlled)
				{
					trace('WENT BACK TO RESULTS??');
					new FlxTimer().start(0, function(_) {
						MusicBeatState.switchState(backend.ScriptableState.tryCreate('ResultsState', new ResultsState({
							score: songScore,
							prevHighScore: Highscore.getScore(Song.loadedSongName, storyDifficulty),
							accuracy: ratingPercent,
							flawlesss: Rating.getHits(ratingsData, 'flawless'),
							sicks: Rating.getHits(ratingsData, 'sick'),
							goods: Rating.getHits(ratingsData, 'good'),
							bads: Rating.getHits(ratingsData, 'bad'),
							shits: Rating.getHits(ratingsData, 'shit'),
							misses: songMisses,
							maxCombo: maxCombo,
							totalNotes: totalNotes,
							songName: SONG.song,
							difficulty: Difficulty.getString(),
							isMod: Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0,
							modFolder: Mods.currentModDirectory,
							isPractice: practiceMode,
							ratingName: ratingName,
							ratingFC: ratingFC
						})));
					});
					transitioning = true;
					return true;
				}

				trace('WENT BACK TO FREEPLAY??');
				Mods.loadTopMod();
				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

				canResync = false;
				if(!exitToScriptedStateIfNeeded())
				{
					MusicBeatState.switchState(states.FreeplayStateSelector.create());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
				}
				changedDifficulty = false;
				transitioning = true;
				return true;
			}

			if (chartingMode)
			{
				openChartEditor();
				return false;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;
				campaignFlawlesss += Rating.getHits(ratingsData, 'flawless');
				campaignSicks += Rating.getHits(ratingsData, 'sick');
				campaignGoods += Rating.getHits(ratingsData, 'good');
				campaignBads += Rating.getHits(ratingsData, 'bad');
				campaignShits += Rating.getHits(ratingsData, 'shit');
				if(maxCombo > campaignMaxCombo)
					campaignMaxCombo = maxCombo;
				campaignTotalNotes += totalNotes;
				campaignSongsPlayed.push(SONG.song);
				if(!Math.isNaN(ratingPercent))
					campaignAccuracySum += ratingPercent;
				campaignSongsCount++;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					Mods.loadTopMod();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

					canResync = false;
					if (ClientPrefs.data.resultsStateAtEnd)
					{
						var weekAccuracy:Float = 0;
						if(campaignSongsCount > 0)
							weekAccuracy = campaignAccuracySum / campaignSongsCount;

						var allSongsName:String = campaignSongsPlayed.join(" + ");
						var weekRatingName:String = '';
						var weekRatingFC:String = '';

						var ratingStuff:Array<Dynamic> = PlayState.getRatingStuff();
						for (i in 0...ratingStuff.length)
						{
							if (weekAccuracy < ratingStuff[i][1])
							{
								weekRatingName = ratingStuff[i][0];
								break;
							}
						}
						if (weekRatingName == '')
							weekRatingName = ratingStuff[ratingStuff.length - 1][0];

						if (campaignMisses == 0)
						{
							if (campaignBads == 0 && campaignShits == 0)
							{
								if (campaignGoods == 0)
								{
									if (campaignSicks == 0)
										weekRatingFC = Language.getPhrase('rating_efc', 'EFC');
									else
										weekRatingFC = Language.getPhrase('rating_sfc', 'SFC');
								}
								else weekRatingFC = Language.getPhrase('rating_gfc', 'GFC');
							}
							else weekRatingFC = Language.getPhrase('rating_fc', 'FC');
						}
						else
						{
							if (campaignMisses < 2)
								weekRatingFC = Language.getPhrase('rating_smc', 'SMC');
							else if (campaignMisses < 5)
								weekRatingFC = Language.getPhrase('rating_lmc', 'LMC');
							else if (campaignMisses < 10)
								weekRatingFC = Language.getPhrase('rating_mmc', 'MMC');
							else
								weekRatingFC = Language.getPhrase('rating_clear', 'Clear');
						}

						if(!ClientPrefs.getGameplaySetting('practice') && !ClientPrefs.getGameplaySetting('botplay')) {
							StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);

							FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
							FlxG.save.flush();
						}
						changedDifficulty = false;

						MusicBeatState.switchState(backend.ScriptableState.tryCreate('ResultsState', new ResultsState({
							score: campaignScore,
							prevHighScore: Highscore.getWeekScore(WeekData.getWeekFileName(), storyDifficulty),
							accuracy: weekAccuracy,
							flawlesss: campaignFlawlesss,
							sicks: campaignSicks,
							goods: campaignGoods,
							bads: campaignBads,
							shits: campaignShits,
							misses: campaignMisses,
							maxCombo: campaignMaxCombo,
							totalNotes: campaignTotalNotes,
							songName: allSongsName,
							difficulty: Difficulty.getString(),
							isMod: Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0,
							modFolder: Mods.currentModDirectory,
							isPractice: practiceMode,
							ratingName: weekRatingName,
							ratingFC: weekRatingFC,
							isWeek: true
						})));
					}
					else
					{
						MusicBeatState.switchState(backend.ScriptableState.tryCreate('StoryMenuState', new StoryMenuState()));

						if(!ClientPrefs.getGameplaySetting('practice') && !ClientPrefs.getGameplaySetting('botplay')) {
							StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);

							FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
							FlxG.save.flush();
						}
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = Difficulty.getFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					prevCamFollow = camFollow;

					Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					canResync = false;
					LoadingState.prepareToSong();
					LoadingState.loadAndSwitchState(new PlayState(), false, false);
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				Mods.loadTopMod();
				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

				canResync = false;
				if(!exitToScriptedStateIfNeeded())
				{
					MusicBeatState.switchState(states.FreeplayStateSelector.create());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
				}
				changedDifficulty = false;
			}
			transitioning = true;
		}
		return true;
	}

	public function KillNotes() {
		for (daNote in notes.members)
			if (daNote != null)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.destroy();
			}
		notes.clear();
		unspawnNotes = [];
		unspawnNoteCursor = 0;
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	// Stores Ratings and Combo Sprites in a group
	public var comboGroup:FlxSpriteGroup;
	#if android
	var androidComboSpritePool:Array<FlxSprite> = [];
	var androidComboSpriteLife:Array<Float> = [];
	var androidComboSpriteFadeStart:Array<Float> = [];
	var androidRatingGraphics:Map<String, FlxGraphic> = new Map<String, FlxGraphic>();
	var androidNumGraphics:Array<FlxGraphic> = [];
	var androidMinusGraphic:FlxGraphic;
	var androidComboKGraphic:FlxGraphic;
	var androidComboDotGraphic:FlxGraphic;
	#end
	var breakTimerHud:BreakTimerHud = null;
	// Stores HUD Objects in a Group
	public var uiGroup:FlxSpriteGroup;
	// Stores Note Objects in a Group
	public var noteGroup:FlxTypedGroup<FlxBasic>;

	private function cachePopUpScore()
	{
		for (rating in ratingsData)
			Paths.image(uiAsset(rating.image));
		for (i in 0...10)
			Paths.image(uiAsset('num' + i));
		Paths.image(uiAsset('k'));
		Paths.image(uiAsset('dot'));
		Paths.image(uiAsset('combo'));
		Paths.image(uiAsset('miss'));
		Paths.image(popupMinusAsset());
		Paths.image(uiAsset('early'));
		Paths.image(uiAsset('late'));

		#if android
		androidRatingGraphics.clear();
		androidNumGraphics.resize(0);
		for (rating in ratingsData)
			androidRatingGraphics.set(rating.image, Paths.image(uiAsset(rating.image)));
		androidRatingGraphics.set('miss', Paths.image(uiAsset('miss')));
		androidMinusGraphic = Paths.image(popupMinusAsset());
		androidComboKGraphic = Paths.image(uiAsset('k'));
		androidComboDotGraphic = Paths.image(uiAsset('dot'));
		for (i in 0...10)
			androidNumGraphics[i] = Paths.image(uiAsset('num' + i));
		for (i in 0...18)
			createAndroidComboSprite();
		#end
	}

	#if android
	function createAndroidComboSprite():FlxSprite
	{
		var spr:FlxSprite = new FlxSprite();
		spr.ID = androidComboSpritePool.length;
		spr.exists = false;
		spr.active = false;
		spr.visible = false;
		androidComboSpritePool.push(spr);
		androidComboSpriteLife.push(0);
		androidComboSpriteFadeStart.push(0);
		if (comboGroup != null)
			comboGroup.add(spr);
		return spr;
	}

	function getAndroidComboSprite():FlxSprite
	{
		for (spr in androidComboSpritePool)
			if (spr != null && !spr.exists)
				return spr;
		return createAndroidComboSprite();
	}

	function releaseAndroidComboSprite(spr:FlxSprite):Void
	{
		if (spr == null)
			return;

		spr.exists = false;
		spr.active = false;
		spr.visible = false;
		spr.alpha = 1;
		spr.color = FlxColor.WHITE;
		spr.velocity.set();
		spr.acceleration.set();
		if (spr.ID >= 0 && spr.ID < androidComboSpriteLife.length)
		{
			androidComboSpriteLife[spr.ID] = 0;
			androidComboSpriteFadeStart[spr.ID] = 0;
		}
	}

	function setupAndroidComboSprite(spr:FlxSprite, graphic:FlxGraphic, x:Float, y:Float, scale:Float, antialias:Bool, visible:Bool):Void
	{
		if (spr == null || graphic == null)
			return;

		spr.loadGraphic(graphic);
		spr.setGraphicSize(Std.int(spr.width * scale));
		spr.updateHitbox();
		spr.x = x;
		spr.y = y;
		spr.alpha = 1;
		spr.visible = visible;
		spr.color = FlxColor.WHITE;
		spr.active = true;
		spr.exists = visible;
		spr.antialiasing = antialias;
		if (comboGroup != null && comboGroup.members.indexOf(spr) < 0)
			comboGroup.add(spr);
		spr.velocity.set(0, -125 * playbackRate);
		spr.acceleration.set(0, 360 * playbackRate * playbackRate);

		if (visible)
		{
			var safeRate:Float = playbackRate <= 0 ? 1 : playbackRate;
			androidComboSpriteLife[spr.ID] = 0.28 / safeRate;
			androidComboSpriteFadeStart[spr.ID] = 0.16 / safeRate;
		}
	}

	function updateAndroidComboSprites(elapsed:Float):Void
	{
		for (spr in androidComboSpritePool)
		{
			if (spr == null || !spr.exists)
				continue;

			var id:Int = spr.ID;
			var life:Float = androidComboSpriteLife[id] - elapsed;
			androidComboSpriteLife[id] = life;
			if (life <= 0)
			{
				releaseAndroidComboSprite(spr);
				continue;
			}

			var fadeStart:Float = androidComboSpriteFadeStart[id];
			if (life < fadeStart && fadeStart > 0)
				spr.alpha = life / fadeStart;
		}
	}

	function popUpScoreAndroid(daRating:Rating, isMiss:Bool = false):Void
	{
		if (!ClientPrefs.data.popUpRating || ClientPrefs.data.hideHud || comboGroup == null)
			return;

		var antialias:Bool = ClientPrefs.data.antialiasing;
		if (stageUI != "normal")
			antialias = !isPixelStage;

		var placement:Float = FlxG.width * 0.35;
		var ratingScale:Float = PlayState.isPixelStage ? daPixelZoom * 0.85 : 0.7;
		var numScale:Float = PlayState.isPixelStage ? daPixelZoom : 0.5;
		var rating:FlxSprite = getAndroidComboSprite();
		setupAndroidComboSprite(rating, androidRatingGraphics.get(isMiss ? 'miss' : daRating.image), placement - 40 + ClientPrefs.data.comboOffset[0],
			(FlxG.height * 0.5) - 60 - ClientPrefs.data.comboOffset[1], ratingScale, antialias, showRating);

		if (!showComboNum || (!isMiss && combo > 0 && combo < 10))
			return;

		var popupCount:Int = isMiss ? songMisses : combo;
		var comboStr:String = !isMiss && popupCount >= 10000 ? formatComboCount(popupCount)
			: (ClientPrefs.data.dynamicCombo ? Std.string(popupCount) : Std.string(popupCount).lpad('0', 3));
		for (i in 0...(comboStr.length + (isMiss ? 1 : 0)))
		{
			var isMinus:Bool = i == comboStr.length;
			var character:String = isMinus ? '-' : comboStr.charAt(i);
			var digit:Null<Int> = isMinus ? null : Std.parseInt(character);
			var graphic:FlxGraphic = switch (character)
			{
				case '-': androidMinusGraphic;
				case '.': androidComboDotGraphic;
				case 'k': androidComboKGraphic;
				default: digit != null && digit >= 0 && digit <= 9 ? androidNumGraphics[digit] : null;
			};
			if (graphic == null)
				continue;

			var numScore:FlxSprite = getAndroidComboSprite();
			setupAndroidComboSprite(numScore, graphic, placement + (43 * i) - 90 + ClientPrefs.data.comboOffset[2],
				(FlxG.height * 0.5) + 80 - ClientPrefs.data.comboOffset[3], numScale, antialias, true);
			numScore.velocity.x = FlxG.random.float(-3, 3) * playbackRate;
			if (isMiss) numScore.color = 0xFFB060FF;
		}
	}
	#end

	inline function uiAsset(name:String):String
		return Paths.getUIPath(name);

	public static function formatComboCount(value:Int):String
	{
		if (value < 10000)
			return Std.string(value);
		var tenths:Int = Math.floor(value / 100);
		return '${Std.int(tenths / 10)}.${tenths % 10}k';
	}

	inline function comboCharacterAsset(character:String):String
		return switch (character)
		{
			case '.': uiAsset('dot');
			case 'k': uiAsset('k');
			default: uiAsset('num' + character);
		};

	function popupMinusAsset():String
	{
		var custom = uiAsset('minus');
		return Paths.fileExists('images/$custom.png', IMAGE) ? custom : (isPixelStage ? 'pixelUI/minus-pixel' : 'minus');
	}

	function initBreakTimerHud():Void
	{
		if (!ClientPrefs.data.breakTimer || breakTimerHud != null)
			return;

		breakTimerHud = new BreakTimerHud(camHUD);
		breakTimerHud.addTo(this);
		breakTimerHud.cacheNotes(unspawnNotes);
	}

	function refreshBreakTimerVisualStyle():Void
	{
		if (breakTimerHud != null)
			breakTimerHud.refreshVisualStyle();
	}

	inline function strumCenterX(strum:StrumNote):Float
		return strum.x + strum.width * 0.5;

	inline function strumTopY(strum:StrumNote):Float
		return strum.y;

	function updateEndCountdown(curTime:Float):Void
	{
		if (!ClientPrefs.data.endCountdown)
		{
			clearEndCountdown();
			return;
		}

		var secs:Int = ClientPrefs.data.endCountSecs;
		if (secs <= 0)
		{
			clearEndCountdown();
			return;
		}

		var timeLeft:Int = Math.floor((songLength - curTime) / 1000);
		if (timeLeft > secs || timeLeft <= 0)
		{
			clearEndCountdown();
			return;
		}

		if (endCountdownText == null)
		{
			endCountdownText = new FlxText(0, 0, 0, "", 40);
			endCountdownText.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			endCountdownText.cameras = [camOther];
			endCountdownText.scrollFactor.set();
			endCountdownText.borderSize = 3;
			add(endCountdownText);
		}

		if (lastEndCountdown != timeLeft)
		{
			endCountdownText.text = Std.string(timeLeft);
			endCountdownText.updateHitbox();
			endCountdownText.x = FlxG.width * 0.5 - endCountdownText.width * 0.5;
			endCountdownText.y = FlxG.height * 0.5 - 150;

			if (endCountdownTween != null)
				endCountdownTween.cancel();
			endCountdownText.scale.set(2, 2);
			endCountdownTween = FlxTween.tween(endCountdownText.scale, {x: 1, y: 1}, 0.25, {
				ease: FlxEase.circOut,
				onComplete: function(_) endCountdownTween = null
			});
			lastEndCountdown = timeLeft;
		}
	}

	function clearEndCountdown():Void
	{
		if (endCountdownTween != null)
		{
			endCountdownTween.cancel();
			endCountdownTween = null;
		}
		lastEndCountdown = -1;
		if (endCountdownText != null)
		{
			remove(endCountdownText);
			endCountdownText.destroy();
			endCountdownText = null;
		}
	}

	function addTiming(rating:FlxSprite, hitDiff:Float, antialias:Bool):Void
	{
		if ((cpuControlled && !isBotplayCPU()) || rating == null || comboGroup == null || (!ClientPrefs.data.showTimingTags && !ClientPrefs.data.showHitMs))
			return;

		var early:Bool = hitDiff > 0;
		var color:FlxColor = early ? 0xFF66D9FF : 0xFFFFD166;
		var showTag:Bool = ClientPrefs.data.showTimingTags && Math.abs(hitDiff) >= Math.max(1, Conductor.safeZoneOffset * 0.5);

		if (showTag)
		{
			var tag:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiAsset(early ? 'early' : 'late')));
			tag.setGraphicSize(Std.int(Math.max(1, rating.width * 0.48)));
			tag.updateHitbox();
			tag.x = early ? rating.x - tag.width * 0.18 : rating.x + rating.width - tag.width * 0.82;
			tag.y = rating.y - tag.height * 0.82;
			tag.angle = early ? -18 : 18;
			tag.antialiasing = antialias;
			tag.velocity.set(rating.velocity.x, rating.velocity.y);
			tag.acceleration.set(rating.acceleration.x, rating.acceleration.y);
			comboGroup.add(tag);
			FlxTween.tween(tag, {alpha: 0}, 0.2 / playbackRate, {
				startDelay: Conductor.crochet * 0.001 / playbackRate,
				onComplete: function(twn:FlxTween) tag.destroy()
			});
		}

		if (ClientPrefs.data.showHitMs)
		{
			if (msTxt == null)
			{
				msTxt = new FlxText(0, 0, 96, "", 18);
				msTxt.setFormat(Paths.font("vcr.ttf"), 18, color, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				msTxt.borderSize = 1.25;
			}
			if (msTween != null)
				msTween.cancel();
			if (comboGroup.members.indexOf(msTxt) < 0)
				comboGroup.add(msTxt);

		msTxt.text = Language.getPhrase('playstate.hud.milliseconds', '{1}ms', [Std.int(Math.round(hitDiff))]);
			msTxt.color = color;
			msTxt.alpha = 1;
			msTxt.visible = true;
			msTxt.x = FlxG.width * 0.35 - msTxt.fieldWidth * 0.5 + ClientPrefs.data.hitMsOffset[0];
			msTxt.y = rating.y + rating.height + 8 - ClientPrefs.data.hitMsOffset[1];
			msTxt.velocity.set(rating.velocity.x, rating.velocity.y - 12 * playbackRate);
			msTxt.acceleration.set(rating.acceleration.x, rating.acceleration.y);
			msTween = FlxTween.tween(msTxt, {alpha: 0}, 0.2 / playbackRate, {
				startDelay: Conductor.crochet * 0.001 / playbackRate,
				onComplete: function(twn:FlxTween)
				{
					if (comboGroup != null && msTxt != null)
						comboGroup.remove(msTxt, true);
					if (msTxt != null)
						msTxt.visible = false;
					msTween = null;
				}
			});
		}
	}

	function showMissPopup():Void
	{
		popUpScore(null, true);
	}

	function clearComboPopups():Void
	{
		if (comboGroup == null || comboGroup.members.length == 0)
			return;

		while (comboGroup.members.length > 0)
		{
			var spr:FlxSprite = comboGroup.members[0];
			if (spr == null)
			{
				comboGroup.members.shift();
				continue;
			}

			if (spr == msTxt)
			{
				if (msTween != null)
				{
					msTween.cancel();
					msTween = null;
				}
				comboGroup.remove(spr, true);
				spr.visible = false;
				spr.alpha = 0;
				continue;
			}

			comboGroup.remove(spr, true);
			FlxTween.cancelTweensOf(spr);
			if (spr.scale != null) FlxTween.cancelTweensOf(spr.scale);
			#if android
			if (spr.ID >= 0 && spr.ID < androidComboSpritePool.length && androidComboSpritePool[spr.ID] == spr)
			{
				releaseAndroidComboSprite(spr);
				continue;
			}
			#end
			spr.destroy();
		}
	}

	private function popUpScore(note:Note = null, isMiss:Bool = false):Void
	{
		if (!isMiss && note == null) return;
		var density:Int = noteDensityCount(note);
		var suppressDenseVisuals:Bool = denseChartQueue && !isMiss && denseHitVisualsThisFrame >= 4;
		if (denseChartQueue && !isMiss)
			denseHitVisualsThisFrame++;
		var hitDiff:Float = isMiss ? 0 : (note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset) / playbackRate;
		var noteDiff:Float = Math.abs(hitDiff);
		if (!isMiss) vocals.volume = 1;
		#if android
		var lightHitVisuals:Bool = !ClientPrefs.data.nfRatingStyle;
		#else
		var lightHitVisuals:Bool = false;
		#end

		if (!suppressDenseVisuals && !lightHitVisuals && (!ClientPrefs.data.comboStacking || ClientPrefs.data.nfRatingStyle))
			clearComboPopups();

		var placement:Float = FlxG.width * 0.35;
		var score:Int = if (ClientPrefs.data.systemScoreMultiplier == 'Codename') 300 else 350;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = isMiss ? null : Conductor.judgeNote(ratingsData, noteDiff);

		if (!isMiss)
		{
			totalNotesHit += daRating.ratingMod * density;
			note.ratingMod = daRating.ratingMod;
			if(!note.ratingDisabled) daRating.hits += density;
			note.rating = daRating.name;
			score = daRating.score;

			if(!suppressDenseVisuals && !lightHitVisuals && daRating.noteSplash && !note.noteSplashData.disabled)
				spawnNoteSplashOnNote(note);

			if(!cpuControlled || isBotplayCPU()) {
				songScore += score * density;
				if(!note.ratingDisabled)
				{
					if (!perfectBonusHit(daRating.name))
						lockAccuracyBonus();
					songHits += density;
					totalPlayed += density;
					hitTimes.push({time: Conductor.songPosition, count: density});
					requestRatingRecalculation(false);

					if (perfectMode && !practiceMode && !perfectBonusHit(daRating.name))
						doDeathCheck(true);
				}
				if (ClientPrefs.data.badShitBreakCombo && (daRating.name == 'bad' || daRating.name == 'shit'))
				{
					combo = 0;
					isMiss = true;
				}
			}
		}
		if (suppressDenseVisuals)
			return;
		if (isMiss && (!ClientPrefs.data.popUpRating || ClientPrefs.data.hideHud || comboGroup == null)) return;

		if (lightHitVisuals)
		{
			#if android
			popUpScoreAndroid(daRating, isMiss);
			#end
			return;
		}
		var rating:FlxSprite = new FlxSprite();

		var antialias:Bool = ClientPrefs.data.antialiasing;
		if (stageUI != "normal")
		{
			antialias = !isPixelStage;
		}

		if (ClientPrefs.data.popUpRating || ClientPrefs.data.showTimingTags || ClientPrefs.data.showHitMs)
		{
			rating.loadGraphic(Paths.image(uiAsset(isMiss ? 'miss' : daRating.image)));
			rating.screenCenter();
			rating.x = placement - 40;
			rating.y -= 60;
			rating.acceleration.y = 550 * playbackRate * playbackRate;
			rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
			rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
			if (ClientPrefs.data.nfRatingStyle)
			{
				rating.velocity.set(0, 0);
				rating.acceleration.set(0, 0);
			}
			rating.visible = (ClientPrefs.data.popUpRating && !ClientPrefs.data.hideHud && showRating);
			rating.x += ClientPrefs.data.comboOffset[0];
			rating.y -= ClientPrefs.data.comboOffset[1];
			rating.antialiasing = antialias;

			var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiAsset('combo')));
			comboSpr.screenCenter();
			comboSpr.x = placement;
			comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			if (ClientPrefs.data.nfRatingStyle)
			{
				comboSpr.velocity.set(0, 0);
				comboSpr.acceleration.set(0, 0);
			}
			comboSpr.visible = (!isMiss && ClientPrefs.data.popUpRating && !ClientPrefs.data.hideHud && showCombo);
			comboSpr.x += ClientPrefs.data.comboOffset[0];
			comboSpr.y -= ClientPrefs.data.comboOffset[1];
			comboSpr.antialiasing = antialias;
			comboSpr.y += 60;
			comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
			comboGroup.add(rating);

			if (!PlayState.isPixelStage)
			{
				rating.setGraphicSize(Std.int(rating.width * 0.7));
				comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			}
			else
			{
				rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
				comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
			}

			comboSpr.updateHitbox();
			rating.updateHitbox();

			var daLoop:Int = 0;
			var xThing:Float = 0;
			if (!isMiss && ClientPrefs.data.popUpRating && showCombo)
				comboGroup.add(comboSpr);

			var popupCount:Int = isMiss ? songMisses : combo;
			var comboStr:String = !isMiss && popupCount >= 10000 ? formatComboCount(popupCount)
				: (ClientPrefs.data.dynamicCombo ? Std.string(popupCount) : Std.string(popupCount).lpad('0', 3));
			for (i in 0...(comboStr.length + (isMiss ? 1 : 0)))
			{
				var isMinus:Bool = i == comboStr.length;
				var numberAsset:String = isMinus ? popupMinusAsset() : comboCharacterAsset(comboStr.charAt(i));
				var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(numberAsset));
				if (isMiss) numScore.color = 0xFFB060FF;
				numScore.screenCenter();
				numScore.x = placement + (43 * daLoop) - 90 + ClientPrefs.data.comboOffset[2];
				numScore.y += 80 - ClientPrefs.data.comboOffset[3];

				if (!PlayState.isPixelStage)
					numScore.setGraphicSize(Std.int(numScore.width * 0.5));
				else
					numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
				numScore.updateHitbox();

				numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
				numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
				numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
				if (ClientPrefs.data.nfRatingStyle)
				{
					numScore.velocity.set(0, 0);
					numScore.acceleration.set(0, 0);
				}
				numScore.visible = ClientPrefs.data.popUpRating && !ClientPrefs.data.hideHud && showComboNum;
				numScore.antialiasing = antialias;

				if (isMiss || combo >= 10 || combo == 0)
					if (ClientPrefs.data.popUpRating && showComboNum)
						comboGroup.add(numScore);

				if (ClientPrefs.data.nfRatingStyle)
					FlxTween.tween(numScore.scale, {x: numScore.scale.x * 0.88, y: numScore.scale.y * 0.88}, 0.12 / playbackRate, {ease: FlxEase.quadOut});

				FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
					onComplete: function(tween:FlxTween)
					{
						numScore.destroy();
					},
					startDelay: Conductor.crochet * (ClientPrefs.data.nfRatingStyle ? 0.0016 : 0.002) / playbackRate
				});

				daLoop++;
				if (numScore.x > xThing)
					xThing = numScore.x;
			}
			if (!ClientPrefs.data.nfRatingStyle)
				comboSpr.x = xThing + 50;
			if (ClientPrefs.data.nfRatingStyle)
			{
				rating.scale.scale(1.16);
				comboSpr.scale.scale(1.1);
				FlxTween.tween(rating.scale, {x: rating.scale.x / 1.16, y: rating.scale.y / 1.16}, 0.12 / playbackRate, {ease: FlxEase.quadOut});
				FlxTween.tween(comboSpr.scale, {x: comboSpr.scale.x / 1.1, y: comboSpr.scale.y / 1.1}, 0.12 / playbackRate, {ease: FlxEase.quadOut});
			}
			if (!isMiss) addTiming(rating, hitDiff, antialias);
			FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
				startDelay: Conductor.crochet * (ClientPrefs.data.nfRatingStyle ? 0.0016 : 0.001) / playbackRate
			});

			FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					comboSpr.destroy();
					rating.destroy();
				},
				startDelay: Conductor.crochet * (ClientPrefs.data.nfRatingStyle ? 0.0016 : 0.002) / playbackRate
			});
		}
	}

	public var strumsBlocked:Array<Bool> = [];
	private var hitCandidates:Array<Note> = [];
	private var inputCheckDepth:Int = 0;
	private var inputBuffers:Array<{hold:Array<Bool>, press:Array<Bool>, release:Array<Bool>}> = [];
	private function onKeyPress(event:KeyboardEvent):Void
	{

		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);

		if (!controls.controllerMode)
		{
			#if debug
			//Prevents crash specifically on debug without needing to try catch shit
			@:privateAccess if (!FlxG.keys._keyListMap.exists(eventKey)) return;
			#end

			if(FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) keyPressed(key);
		}
	}

	private function keyPressed(key:Int)
	{
		if(cpuControlled || paused || inCutscene || key < 0 || key >= playerStrums.length || !generatedMusic || endingSong || playerChar().stunned) return;

		if(keyViewer != null)
			keyViewer.keyPressed(key);

		var ret:Dynamic = callOnScripts('onKeyPressPre', [key]);
		if(ret == LuaUtils.Function_Stop) return;

		// more accurate hit time for the ratings?
		var lastTime:Float = Conductor.songPosition;
		if(Conductor.songPosition >= 0) Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

		// obtain notes that the player can hit
		var plrInputNotes = hitCandidates;
		plrInputNotes.resize(0);
		for (n in notes.members)
		{
			var canHit:Bool = n != null && !strumsBlocked[n.noteData] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit;
			if (canHit && !n.isSustainNote && n.noteData == key)
				plrInputNotes.push(n);
		}
		plrInputNotes.sort(sortHitNotes);
		var funnyNote:Note = plrInputNotes.length > 0 ? plrInputNotes[0] : null;
		var doubleNote:Note = plrInputNotes.length > 1 ? plrInputNotes[1] : null;
		// Release candidate references before any script can recursively dispatch input.
		plrInputNotes.resize(0);

		if (funnyNote != null) {
			if (doubleNote != null) {
				if (doubleNote.noteData == funnyNote.noteData) {
					// if the note has a 0ms distance (is on top of the current note), kill it
					if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0)
						invalidateNote(doubleNote);
					else if (doubleNote.strumTime < funnyNote.strumTime)
					{
						// replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
						funnyNote = doubleNote;
					}
				}
			}
			goodNoteHit(funnyNote);
		}
		else
		{
			if (ClientPrefs.data.ghostTapping)
				callOnScripts('onGhostTap', [key]);
			else
				noteMissPress(key);
		}

		// Needed for the  "Just the Two of Us" achievement.
		//									- Shadow Mario
		if(!keysPressed.contains(key)) keysPressed.push(key);

		//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
		Conductor.songPosition = lastTime;

		var spr:StrumNote = playerStrums.members[key];
		if(strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
		{
			spr.playAnim('pressed');
			spr.resetAnim = 0;
		}
		callOnScripts('onKeyPress', [key]);
	}

	public static function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);
		if(!controls.controllerMode && key > -1) keyReleased(key);
	}

	private function keyReleased(key:Int)
	{
		if(cpuControlled || !startedCountdown || paused || key < 0 || key >= playerStrums.length) return;

		if(keyViewer != null)
			keyViewer.keyReleased(key);

		var ret:Dynamic = callOnScripts('onKeyReleasePre', [key]);
		if(ret == LuaUtils.Function_Stop) return;

		var spr:StrumNote = playerStrums.members[key];
		if(spr != null)
		{
			spr.playAnim('static');
			spr.resetAnim = 0;
		}
		callOnScripts('onKeyRelease', [key]);
	}

	public static function getKeyFromEvent(arr:Array<String>, key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...arr.length)
			{
				var note:Array<FlxKey> = Controls.instance.keyboardBinds[arr[i]];
				for (noteKey in note)
					if(key == noteKey)
						return i;
			}
		}
		return -1;
	}

	private function onButtonPress(button:TouchButton):Void
	{
		if (button.IDs.filter(id -> id.toString().startsWith("EXTRA")).length > 0)
			return;

		var buttonCode:Int = (button.IDs[0].toString().startsWith('NOTE')) ? button.IDs[0] : button.IDs[1];
		callOnScripts('onButtonPressPre', [buttonCode]);
		if (button.justPressed) keyPressed(buttonCode);
		callOnScripts('onButtonPress', [buttonCode]);
	}

	private function onButtonRelease(button:TouchButton):Void
	{
		if (button.IDs.filter(id -> id.toString().startsWith("EXTRA")).length > 0)
			return;

		var buttonCode:Int = (button.IDs[0].toString().startsWith('NOTE')) ? button.IDs[0] : button.IDs[1];
		callOnScripts('onButtonReleasePre', [buttonCode]);
		if(buttonCode > -1) keyReleased(buttonCode);
		callOnScripts('onButtonRelease', [buttonCode]);
	}

	// Hold notes
	private function keysCheck():Void
	{
		// Scripts can reenter input handling; each depth owns its snapshot.
		if (inputCheckDepth == inputBuffers.length)
			inputBuffers.push({hold: [], press: [], release: []});
		var buffer = inputBuffers[inputCheckDepth++];
		try
		{
			checkKeysWithBuffers(buffer.hold, buffer.press, buffer.release);
		}
		catch (error:Dynamic)
		{
			inputCheckDepth--;
			throw error;
		}
		inputCheckDepth--;
	}

	private function checkKeysWithBuffers(holdArray:Array<Bool>, pressArray:Array<Bool>, releaseArray:Array<Bool>):Void
	{
		// HOLDING
		if (holdArray.length != keysArray.length)
		{
			holdArray.resize(keysArray.length);
			pressArray.resize(keysArray.length);
			releaseArray.resize(keysArray.length);
		}
		for (i in 0...keysArray.length)
		{
			var key:String = keysArray[i];
			holdArray[i] = controls.pressed(key);
			pressArray[i] = controls.justPressed(key);
			releaseArray[i] = controls.justReleased(key);

			#if mobile
			if (mobileControls != null && mobileControls.instance != null && i < 4)
			{
				var mobileButtonID:MobileInputID = cast i;
				if (mobileControls.instance.buttonPressed(mobileButtonID))
					holdArray[i] = true;
				if (mobileControls.instance.buttonJustPressed(mobileButtonID))
					pressArray[i] = true;
				if (mobileControls.instance.buttonJustReleased(mobileButtonID))
					releaseArray[i] = true;
			}
			#end
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(controls.controllerMode && pressArray.contains(true))
			for (i in 0...pressArray.length)
				if(pressArray[i] && strumsBlocked[i] != true)
					keyPressed(i);

		if (startedCountdown && !inCutscene && !playerChar().stunned && generatedMusic)
		{
			if (notes.length > 0) {
				for (n in notes) { // I can't do a filter here, that's kinda awesome
					var canHit:Bool = (n != null && !strumsBlocked[n.noteData] && n.canBeHit
						&& n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit);

					if (guitarHeroSustains)
						canHit = canHit && n.parent != null && n.parent.wasGoodHit;

					if (canHit && n.isSustainNote) {
						var released:Bool = !holdArray[n.noteData];

						if (!released)
							goodNoteHit(n);
					}
				}
			}

			if (!holdArray.contains(true) || endingSong)
				playerDance();

			#if ACHIEVEMENTS_ALLOWED
			else checkForAchievement(['oversinging']);
			#end
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if((controls.controllerMode || strumsBlocked.contains(true)) && releaseArray.contains(true))
			for (i in 0...releaseArray.length)
				if(releaseArray[i] || strumsBlocked[i] == true)
					keyReleased(i);
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		// Dense charts already merge equivalent taps during loading. Scanning every
		// live sprite for each miss would turn a dense burst into quadratic work.
		if (!denseChartQueue)
		{
			notes.forEachAlive(function(note:Note) {
				if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1)
					invalidateNote(note);
			});
		}

		noteMissCommon(daNote.noteData, daNote);
		stagesFunc(function(stage:BaseStage) stage.noteMiss(daNote));
		var result:Dynamic = callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('noteMiss', [daNote]);
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if(ClientPrefs.data.ghostTapping) return; //fuck it

		noteMissCommon(direction);
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		stagesFunc(function(stage:BaseStage) stage.noteMissPress(direction));
		callOnScripts('noteMissPress', [direction]);
	}

	function noteMissCommon(direction:Int, note:Note = null)
	{
		var density:Int = noteDensityCount(note);
		// score and data
		var subtract:Float = pressMissDamage;
		if(note != null) subtract = note.missHealth;

		// GUITAR HERO SUSTAIN CHECK LOL!!!!
		if (note != null && guitarHeroSustains && note.parent == null) {
			if(note.tail.length > 0) {
				note.alpha = 0.35;
				for(childNote in note.tail) {
					childNote.alpha = note.alpha;
					childNote.missed = true;
					childNote.canBeHit = false;
					childNote.ignoreNote = true;
					childNote.tooLate = true;
				}
				note.missed = true;
				note.canBeHit = false;

				//subtract += 0.385; // you take more damage if playing with this gameplay changer enabled.
				// i mean its fair :p -Crow
				subtract *= note.tail.length + 1;
				// i think it would be fair if damage multiplied based on how long the sustain is -[REDACTED]
			}

			if (note.missed)
				return;
		}
		if (note != null && guitarHeroSustains && note.parent != null && note.isSustainNote) {
			if (note.missed)
				return;

			var parentNote:Note = note.parent;
			if (parentNote.wasGoodHit && parentNote.tail.length > 0) {
				for (child in parentNote.tail) if (child != note) {
					child.missed = true;
					child.canBeHit = false;
					child.ignoreNote = true;
					child.tooLate = true;
				}
			}
		}

		if(instakillOnMiss)
		{
			vocals.volume = 0;
			opponentVocals.volume = 0;
			doDeathCheck(true);
		}

		var lastCombo:Int = combo;
		combo = 0;

		health -= subtract * healthLoss * density;
		songScore -= 10 * density;
		lockAccuracyBonus();
		if(!endingSong) songMisses += density;
		if (!endingSong) showMissPopup();
		totalPlayed += density;
		requestRatingRecalculation(true);

		// play character anims
		var char:Character = playerChar();
		if((note != null && note.gfNote) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection)) char = gf;

		if(char != null && (note == null || !note.noMissAnimation) && char.hasMissAnimations)
		{
			var postfix:String = '';
			if(note != null) postfix = note.animSuffix;

			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, direction)))] + 'miss' + postfix;
			char.playAnim(animToPlay, true);

			if(char != gf && lastCombo > 5 && gf != null && gf.hasAnimation('sad'))
			{
				gf.playAnim('sad');
				gf.specialAnim = true;
			}
		}
		vocals.volume = 0;
	}

	function opponentNoteHit(note:Note):Void
	{
		var result:Dynamic = callOnLuas('opponentNoteHitPre', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) result = callOnHScript('opponentNoteHitPre', [note]);

		if(result == LuaUtils.Function_Stop) return;

		if (songName != 'tutorial')
			camZooming = true;

		if(note.noteType == 'Hey!' && opponentChar().hasAnimation('hey'))
		{
			opponentChar().playAnim('hey', true);
			opponentChar().specialAnim = true;
			opponentChar().heyTimer = 0.6;
		}
		else if(!note.noAnimation)
		{
			var char:Character = opponentChar();
			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, note.noteData)))] + note.animSuffix;
			if(note.gfNote) char = gf;

			if(char != null)
			{
				var canPlay:Bool = true;
				if(note.isSustainNote)
				{
					var holdAnim:String = animToPlay + '-hold';
					if(char.animation.exists(holdAnim)) animToPlay = holdAnim;
					if(char.getAnimationName() == holdAnim || char.getAnimationName() == holdAnim + '-loop') canPlay = false;
				}

				if(canPlay) char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}
		}

		if(opponentVocals.length <= 0) vocals.volume = 1;
		strumPlayAnim(true, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
		note.hitByOpponent = true;
		if (opponentDrain && !note.isSustainNote && !practiceMode && health > PlayModes.DRAIN_FLOOR)
			health = Math.max(PlayModes.DRAIN_FLOOR, health - note.hitHealth * healthLoss * noteDensityCount(note));

		stagesFunc(function(stage:BaseStage) stage.opponentNoteHit(note));
		var result:Dynamic = callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('opponentNoteHit', [note]);

		if (!note.isSustainNote) invalidateNote(note);
	}

	public function goodNoteHit(note:Note):Void
	{
		if(note.wasGoodHit) return;
		if(cpuControlled && note.ignoreNote) return;
		#if android
		var lightHitVisuals = ClientPrefs.data.runOnLightVisual;
		#else
		var lightHitVisuals:Bool = false;
		#end

		var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		var leData:Int = Math.round(Math.abs(note.noteData));
		var leType:String = note.noteType;

		var result:Dynamic = callOnLuas('goodNoteHitPre', [notes.members.indexOf(note), leData, leType, isSus]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) result = callOnHScript('goodNoteHitPre', [note]);

		if(result == LuaUtils.Function_Stop) return;

		note.wasGoodHit = true;

		#if windows
		if (ClientPrefs.data.changeWindowBorderColorWithNoteHit && !cpuControlled)
			WindowBorderPulse.hit(note);
		#end

		if(!note.hitCausesMiss) //Common notes
		{
			if(!note.noAnimation)
			{
				var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, note.noteData)))] + note.animSuffix;

				var char:Character = playerChar();
				var animCheck:String = 'hey';
				if(note.gfNote)
				{
					char = gf;
					animCheck = 'cheer';
				}

				if(char != null)
				{
					var canPlay:Bool = true;
					if(note.isSustainNote)
					{
						var holdAnim:String = animToPlay + '-hold';
						if(char.animation.exists(holdAnim)) animToPlay = holdAnim;
						if(char.getAnimationName() == holdAnim || char.getAnimationName() == holdAnim + '-loop') canPlay = false;
					}

					if(canPlay) char.playAnim(animToPlay, true);
					char.holdTimer = 0;

					if(note.noteType == 'Hey!')
					{
						if(char.hasAnimation(animCheck))
						{
							char.playAnim(animCheck, true);
							char.specialAnim = true;
							char.heyTimer = 0.6;
						}
					}
				}
			}

			if(!cpuControlled)
			{
				var spr = playerStrums.members[note.noteData];
				if(spr != null) spr.playAnim('confirm', true);
			}
			else strumPlayAnim(false, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
			vocals.volume = 1;

			if (!note.isSustainNote)
			{
				combo += noteDensityCount(note);
				if(combo > maxCombo) maxCombo = combo;
				popUpScore(note);

				if(!lightHitVisuals && !ClientPrefs.data.hideSustainSplash && !ClientPrefs.data.lowQuality && !note.noteSplashData.disabled && note.tail.length > 1)
				{
					var strum = playerStrums.members[note.noteData];
					if(strum != null)
					{
						var end = note.tail[note.tail.length - 1];
						var sus = grpHoldSplashes.recycle(SustainSplash);
						sus.setupSusSplash(strum, note, playbackRate);
						grpHoldSplashes.add(end.noteHoldSplash = sus);
					}
				}
			}
			var gainHealth:Bool = true; // prevent health gain, *if* sustains are treated as a singular note
			if (guitarHeroSustains && note.isSustainNote) gainHealth = false;
			if (gainHealth) health += note.hitHealth * healthGain * noteDensityCount(note);

		}
		else //Notes that count as a miss if you hit them (Hurt notes for example)
		{
			if(!note.noMissAnimation)
			{
				switch(note.noteType)
				{
					case 'Hurt Note':
						if(playerChar().hasAnimation('hurt'))
						{
							playerChar().playAnim('hurt', true);
							playerChar().specialAnim = true;
						}
				}
			}

			noteMiss(note);
			if(!lightHitVisuals && !note.noteSplashData.disabled && !note.isSustainNote) spawnNoteSplashOnNote(note);
		}

		stagesFunc(function(stage:BaseStage) stage.goodNoteHit(note));
		var result:Dynamic = callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('goodNoteHit', [note]);
		if(!note.isSustainNote) invalidateNote(note);
	}

	public function invalidateNote(note:Note):Void {
		//if(!ClientPrefs.data.lowQuality || !cpuControlled) note.kill();
		// Keep reusable holes on dense charts. Splicing shifts every later member,
		// which is needlessly expensive when hundreds of notes expire together.
		notes.remove(note, !denseChartQueue);
		note.destroy();
	}

	public function spawnNoteSplashOnNote(note:Note) {
		NoteSplashHelper.spawnOnNote(this, note);
	}

	public function spawnNoteSplash(x:Float = 0, y:Float = 0, ?data:Int = 0, ?note:Note, ?strum:StrumNote) {
		NoteSplashHelper.spawn(this, x, y, data, note, strum);
	}

	public function reloadAllNotesSkin():Void
	{
		var newSkin:String = (SONG != null && SONG.arrowSkin != null && SONG.arrowSkin.length > 0)
			? SONG.arrowSkin
			: Note.getDefaultNoteSkinPath(isPixelStage);

		for (note in notes)
			if (note != null) note.reloadNote();
		for (i in (denseChartQueue ? unspawnNoteCursor : 0)...unspawnNotes.length)
		{
			var note:Note = unspawnNotes[i];
			if (note != null) note.reloadNote();
		}

		for (strum in strumLineNotes)
			if (strum != null) strum.texture = newSkin;

		NoteSplash.configs.clear();
		NoteSplash.clearCache();
		for (splash in grpNoteSplashes)
			if (splash != null) splash.loadSplash();
	}

	override function destroy() {
		#if MODCHART_ALLOWED
		if (mcInitCb != null)
		{
			FlxG.signals.postUpdate.remove(mcInitCb);
			mcInitCb = null;
		}
		mcDebugOff();
		destroyModchartManager();
		#end

		if (Main.fpsVar != null)
			Main.fpsVar.modAuthor = "";

		if (psychlua.backend.CustomSubstate.instance != null)
		{
			closeSubState();
			resetSubState();
		}

		#if LUA_ALLOWED
		for (lua in luaArray)
		{
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = null;
		FunkinLua.customFunctions.clear();
		#end

		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
			if(script != null)
			{
				if(script.exists('onDestroy')) script.call('onDestroy');
				script.destroy();
			}

		hscriptArray = null;
		#end
		stagesFunc(function(stage:BaseStage) stage.destroy());

		#if VIDEOS_ALLOWED
		if(videoCutscene != null)
		{
			videoCutscene.destroy();
			videoCutscene = null;
		}
		#end
		#if LUA_ALLOWED
		psychlua.VideoFunctions.clearAll();
		#end

		if (breakTimerHud != null)
		{
			breakTimerHud.destroyFrom(this);
			breakTimerHud = null;
		}
		clearEndCountdown();

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		FlxG.camera.setFilters([]);

		#if FLX_PITCH FlxG.sound.music.pitch = 1; #end
		FlxG.animationTimeScale = 1;

		Note.globalRgbShaders = [];
		backend.NoteTypesConfig.clearNoteTypesData();

		NoteSplash.clearCache();
		instance = null;
		if (temporaryStageUI != null)
		{
			stageUI = temporaryStageUI;
			temporaryStageUI = null;
		}
		shutdownThread = true;
		FlxG.signals.preUpdate.remove(checkForResync);
		super.destroy();
	}

	#if MODCHART_ALLOWED
	function destroyModchartManager():Void
	{
		var manager:Manager = Manager.instance;
		if (manager == null)
			return;

		if (noteGroup != null)
			noteGroup.remove(manager, true);
		remove(manager, true);
		manager.destroy();
		if (Manager.instance == manager)
			Manager.instance = null;
	}
	#end

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit');
	}

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
			notes.sort(sortNotesByY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		switch (ClientPrefs.data.iconBounceType)
		{
			case 'NF':
				iconP1.scale.set(1.3, 1.3);
				iconP2.scale.set(1.3, 1.3);
				if (iconGF != null) iconGF.scale.set(1.3, 1.3);
				iconP1.updateHitbox();
				iconP2.updateHitbox();
				if (iconGF != null) iconGF.updateHitbox();

			case 'Old':
				iconP1.setGraphicSize(Std.int(iconP1.width + 30));
				iconP2.setGraphicSize(Std.int(iconP2.width + 30));
				if (iconGF != null) iconGF.setGraphicSize(Std.int(iconGF.width + 30));
				iconP1.updateHitbox();
				iconP2.updateHitbox();
				if (iconGF != null) iconGF.updateHitbox();

			case 'D&B':
				bumpIconsDnb();

			default:
				iconP1.scale.set(1.2, 1.2);
				iconP2.scale.set(1.2, 1.2);
				if (iconGF != null) iconGF.scale.set(1.2, 1.2);
				iconP1.updateHitbox();
				iconP2.updateHitbox();
				if (iconGF != null) iconGF.updateHitbox();
		}

		characterBopper(curBeat);
		doTimeBump();

		if (versionText != null)
		{
			if (verTween != null)
			verTween.cancel();

			versionText.scale.set(1.5, 1.5);
			verTween = FlxTween.tween(versionText.scale, {x: 1, y: 1}, 0.3 / playbackRate, {
				ease: FlxEase.expoOut,
				onComplete: function(twn:FlxTween) verTween = null
			});
		}

		super.beatHit();
		var bopEvery:Int = Math.round(cameraBopFrequency);
		if (bopEvery < 1)
			bopEvery = 1;
		if (cameraBopEnabled && ClientPrefs.data.camZooms && FlxG.camera.zoom < 1.35 && curBeat % bopEvery == 0)
		{
			FlxG.camera.zoom += 0.015 * cameraBopIntensity;
			camHUD.zoom += 0.03 * cameraBopIntensity;
		}
		lastBeatHit = curBeat;

		setOnScripts('curBeat', curBeat);
		callOnScripts('onBeatHit');
	}

	function bumpIconsDnb():Void
	{
		iconTurn = -iconTurn;
		for (icon in [iconP1, iconP2, iconGF])
		{
			if (icon == null || !icon.visible)
				continue;

			FlxTween.cancelTweensOf(icon);
			FlxTween.cancelTweensOf(icon.scale);
			icon.angle = iconTurn;
			icon.scale.set(1.2, 0.3);
			icon.updateHitbox();
			FlxTween.tween(icon, {angle: 0}, Conductor.crochet / 1000, {ease: FlxEase.circOut});
			FlxTween.tween(icon.scale, {x: 1, y: 1}, Conductor.crochet / 1000, {
				ease: FlxEase.circOut,
				onComplete: function(twn:FlxTween) icon.updateHitbox()
			});
		}
	}

	public function characterBopper(beat:Int):Void
	{
		if (gf != null && beat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.getAnimationName().startsWith('sing') && !gf.stunned)
			gf.dance();
		var pc:Character = playerChar();
		if (pc != null && beat % pc.danceEveryNumBeats == 0 && !pc.getAnimationName().startsWith('sing') && !pc.stunned)
			pc.dance();
		var oc:Character = opponentChar();
		if (oc != null && beat % oc.danceEveryNumBeats == 0 && !oc.getAnimationName().startsWith('sing') && !oc.stunned)
			oc.dance();
	}

	public function playerDance():Void
	{
		var pc:Character = playerChar();
		if (pc == null) return;
		var anim:String = pc.getAnimationName();
		if(pc.holdTimer > Conductor.stepCrochet * (0.0011 #if FLX_PITCH / FlxG.sound.music.pitch #end) * pc.singDuration
			&& anim.startsWith('sing') && !anim.endsWith('miss'))
			pc.dance();
	}

	override function sectionHit()
	{
		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
				moveCameraSection();

			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.data.camZooms)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.bpm = SONG.notes[curSection].bpm;
				setOnScripts('curBpm', Conductor.bpm);
				setOnScripts('crochet', Conductor.crochet);
				setOnScripts('stepCrochet', Conductor.stepCrochet);
			}
			setOnScripts('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnScripts('altAnim', SONG.notes[curSection].altAnim);
			setOnScripts('gfSection', SONG.notes[curSection].gfSection);
		}
		super.sectionHit();

		setOnScripts('curSection', curSection);
		callOnScripts('onSectionHit');
	}

	#if LUA_ALLOWED
	public function startLuasNamed(luaFile:String)
	{
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if(!FileSystem.exists(luaToLoad))
			luaToLoad = Paths.getSharedPath(luaFile);

		if(FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getSharedPath(luaFile);
		if(OpenFlAssets.exists(luaToLoad))
		#end
		{
			for (script in luaArray)
				if(script.scriptName == luaToLoad) return false;

			new FunkinLua(luaToLoad);
			return true;
		}
		return false;
	}
	#end

	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String)
	{
		#if MODS_ALLOWED
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if(!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getSharedPath(scriptFile);
		#else
		var scriptToLoad:String = Paths.getSharedPath(scriptFile);
		#end

		if(FileSystem.exists(scriptToLoad))
		{
			if (Iris.instances.exists(scriptToLoad)) return false;

			initHScript(scriptToLoad);
			return true;
		}
		return false;
	}

	public function initHScript(file:String)
	{
		var newScript:HScript = null;
		try
		{
			newScript = new HScript(null, file);
			if (newScript.exists('onCreate')) newScript.call('onCreate');
			trace('initialized hscript interp successfully: $file');
			hscriptArray.push(newScript);
		}
		catch(e:IrisError)
		{
			var pos:HScriptInfos = cast {fileName: file, showLine: false};
			Iris.error(Printer.errorToString(e, false), pos);
			var newScript:HScript = cast (Iris.instances.get(file), HScript);
			if(newScript != null)
				newScript.destroy();
		}
	}
	#end

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var hasScripts:Bool = false;
		#if LUA_ALLOWED
		hasScripts = luaArray != null && luaArray.length > 0;
		#end
		#if HSCRIPT_ALLOWED
		hasScripts = hasScripts || (hscriptArray != null && hscriptArray.length > 0);
		#end
		if (!hasScripts) return LuaUtils.Function_Continue;
		if(args == null) args = [];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || isScriptValueExcluded(result, excludeValues)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

	private static inline function isScriptValueExcluded(value:Dynamic, exclusions:Array<Dynamic>):Bool
		return exclusions == null ? value == LuaUtils.Function_Continue : exclusions.contains(value);

	public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		#if LUA_ALLOWED
		if(luaArray == null || luaArray.length == 0) return returnVal;
		if(args == null) args = [];

		var arr:Array<FunkinLua> = null;
		for (script in luaArray)
		{
			if(script.closed)
			{
				if(arr == null) arr = [];
				arr.push(script);
				continue;
			}

			if(exclusions != null && exclusions.contains(script.scriptName))
				continue;

			var myValue:Dynamic = script.call(funcToCall, args);
			if((myValue == LuaUtils.Function_StopLua || myValue == LuaUtils.Function_StopAll) && !isScriptValueExcluded(myValue, excludeValues) && !ignoreStops)
			{
				returnVal = myValue;
				break;
			}

			if(myValue != null && !isScriptValueExcluded(myValue, excludeValues))
				returnVal = myValue;

			if(script.closed)
			{
				if(arr == null) arr = [];
				arr.push(script);
			}
		}

		if(arr != null)
			for (script in arr)
				luaArray.remove(script);
		#end
		return returnVal;
	}

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;

		#if HSCRIPT_ALLOWED
		if (hscriptArray == null || hscriptArray.length == 0)
			return returnVal;

		for(script in hscriptArray)
		{
			@:privateAccess
			if(script == null || !script.exists(funcToCall) || (exclusions != null && exclusions.contains(script.origin)))
				continue;

			var callValue = script.call(funcToCall, args);
			if(callValue != null)
			{
				var myValue:Dynamic = callValue.returnValue;

				if((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll) && !isScriptValueExcluded(myValue, excludeValues) && !ignoreStops)
				{
					returnVal = myValue;
					break;
				}

				if(myValue != null && myValue != LuaUtils.Function_Continue && !isScriptValueExcluded(myValue, excludeValues))
					returnVal = myValue;
			}
		}
		#end

		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		if(exclusions == null) exclusions = [];
		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
	}

	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in hscriptArray) {
			if(exclusions.contains(script.origin))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	function strumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = opponentStrums.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	var lastScoreRefreshTime:Float = -9999;

	inline function perfectBonusHit(name:String):Bool
		return ClientPrefs.data.useFlawlessRating ? name == 'flawless' : name == 'sick';

	function lockAccuracyBonus():Void
	{
		if (bonusLocked)
			return;

		bonusLocked = true;
		bonusLimit = AccuracyTools.progress(totalPlayed, totalNotes);
	}

	public function RecalculateRating(badHit:Bool = false, scoreBop:Bool = true) {
		#if android
		var refreshScore:Bool = badHit || (Conductor.songPosition - lastScoreRefreshTime) >= 50;
		#else
		var refreshScore:Bool = true;
		#end

		if (refreshScore)
		{
			setOnScripts('score', songScore);
			setOnScripts('misses', songMisses);
			setOnScripts('hits', songHits);
			setOnScripts('combo', combo);
		}

		var ret:Dynamic = refreshScore ? callOnScripts('onRecalculateRating', null, true) : null;
		if(ret != LuaUtils.Function_Stop)
		{
			ratingName = '?';
			if(totalPlayed != 0) //Prevent divide by 0
			{
				// Rating Percent
				ratingPercent = AccuracyTools.withBonus(totalNotesHit / totalPlayed, totalPlayed, totalNotes, bonusLimit);
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				var stuff = getRatingStuff();
				ratingName = stuff[stuff.length - 1][0];
				for (i in 0...stuff.length - 1)
					if (ratingPercent < stuff[i][1])
					{
						ratingName = stuff[i][0];
						break;
					}
			}
			fullComboFunction();
		}
		if (refreshScore)
		{
			lastScoreRefreshTime = Conductor.songPosition;
			setOnScripts('rating', ratingPercent);
			setOnScripts('ratingName', ratingName);
			setOnScripts('ratingFC', ratingFC);
			setOnScripts('totalPlayed', totalPlayed);
			setOnScripts('totalNotesHit', totalNotesHit);
			updateScore(badHit, scoreBop); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null)
	{
		if(chartingMode) return;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice') || ClientPrefs.getGameplaySetting('botplay'));
		if(cpuControlled) return;

		for (name in achievesToCheck) {
			if(!Achievements.exists(name)) continue;

			var unlock:Bool = false;
			if (name != WeekData.getWeekFileName() + '_nomiss') // common achievements
			{
				switch(name)
				{
					case 'ur_bad':
						unlock = (ratingPercent < 0.2 && !practiceMode);

					case 'ur_good':
						unlock = (ratingPercent >= 1 && !usedPractice);

					case 'oversinging':
						unlock = (playerChar().holdTimer >= 10 && !usedPractice);

					case 'hype':
						unlock = (!boyfriendIdled && !usedPractice);

					case 'two_keys':
						unlock = (!usedPractice && keysPressed.length <= 2);

					case 'toastie':
						unlock = (!ClientPrefs.data.cacheOnGPU && !ClientPrefs.data.shaders && ClientPrefs.data.lowQuality && !ClientPrefs.data.antialiasing);

					#if BASE_GAME_FILES
					case 'debugger':
						unlock = (songName == 'test' && !usedPractice);
					#end
				}
			}
			else // any FC achievements, name should be "weekFileName_nomiss", e.g: "week3_nomiss";
			{
				if(isStoryMode && campaignMisses + songMisses < 1 && Difficulty.getString().toUpperCase() == 'HARD'
					&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
					unlock = true;
			}

			if(unlock) Achievements.unlock(name);
		}
	}
	#end

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	#end
	public function createRuntimeShader(shaderName:String):ErrorHandledRuntimeShader
	{
		#if (!flash && sys)
		if(!ClientPrefs.data.shaders) return new ErrorHandledRuntimeShader(shaderName);

		if(!runtimeShaders.exists(shaderName) && !initLuaShader(shaderName))
		{
			FlxG.log.warn('Shader $shaderName is missing!');
			return new ErrorHandledRuntimeShader(shaderName);
		}

		var arr:Array<String> = runtimeShaders.get(shaderName);
		return new ErrorHandledRuntimeShader(shaderName, arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!ClientPrefs.data.shaders) return false;

		#if (!flash && sys)
		if(runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'shaders/'))
		{
			var frag:String = folder + name + '.frag';
			var vert:String = folder + name + '.vert';
			var found:Bool = false;
			if(FileSystem.exists(frag))
			{
				frag = File.getContent(frag);
				found = true;
			}
			else frag = null;

			if(FileSystem.exists(vert))
			{
				vert = File.getContent(vert);
				found = true;
			}
			else vert = null;

			if(found)
			{
				runtimeShaders.set(name, [frag, vert]);
				//trace('Found shader $name!');
				return true;
			}
		}
			#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
			addTextToDebug('Missing shader $name .frag AND .vert files!', FlxColor.RED);
			#else
			FlxG.log.warn('Missing shader $name .frag AND .vert files!');
			#end
		#else
		FlxG.log.warn('This platform doesn\'t support Runtime Shaders!');
		#end
		return false;
	}

	public function makeLuaTouchPad(DPadMode:String, ActionMode:String) {
		if(members.contains(luaTouchPad)) return;

		if(!variables.exists("luaTouchPad"))
			variables.set("luaTouchPad", luaTouchPad);

		luaTouchPad = new TouchPad(DPadMode, ActionMode, NONE);
		luaTouchPad.alpha = ClientPrefs.data.controlsAlpha;
	}

	public function addLuaTouchPad() {
		if(luaTouchPad == null || members.contains(luaTouchPad)) return;

		var target = LuaUtils.getTargetInstance();
		target.insert(target.members.length + 1, luaTouchPad);
	}

	public function addLuaTouchPadCamera() {
		if(luaTouchPad != null)
			luaTouchPad.cameras = [luaTpadCam];
	}

	public function removeLuaTouchPad() {
		if (luaTouchPad != null) {
			luaTouchPad.kill();
			luaTouchPad.destroy();
			remove(luaTouchPad);
			luaTouchPad = null;
		}
	}

	public function luaTouchPadPressed(button:Dynamic):Bool {
		if(luaTouchPad != null) {
			if(Std.isOfType(button, String))
				return luaTouchPad.buttonPressed(MobileInputID.fromString(button));
			else if(Std.isOfType(button, Array)){
				var FUCK:Array<String> = button; // haxe said "You Can't Iterate On A Dyanmic Value Please Specificy Iterator or Iterable *insert nerd emoji*" so that's the only i foud to fix
				var idArray:Array<MobileInputID> = [];
				for(strId in FUCK)
					idArray.push(MobileInputID.fromString(strId));
				return luaTouchPad.anyPressed(idArray);
			} else
				return false;
		}
		return false;
	}

	public function luaTouchPadJustPressed(button:Dynamic):Bool {
		if(luaTouchPad != null) {
			if(Std.isOfType(button, String))
				return luaTouchPad.buttonJustPressed(MobileInputID.fromString(button));
			else if(Std.isOfType(button, Array)){
				var FUCK:Array<String> = button;
				var idArray:Array<MobileInputID> = [];
				for(strId in FUCK)
					idArray.push(MobileInputID.fromString(strId));
				return luaTouchPad.anyJustPressed(idArray);
			} else
				return false;
		}
		return false;
	}

	public function luaTouchPadJustReleased(button:Dynamic):Bool {
		if(luaTouchPad != null) {
			if(Std.isOfType(button, String))
				return luaTouchPad.buttonJustReleased(MobileInputID.fromString(button));
			else if(Std.isOfType(button, Array)){
				var FUCK:Array<String> = button;
				var idArray:Array<MobileInputID> = [];
				for(strId in FUCK)
					idArray.push(MobileInputID.fromString(strId));
				return luaTouchPad.anyJustReleased(idArray);
			} else
				return false;
		}
		return false;
	}

	public function luaTouchPadReleased(button:Dynamic):Bool {
		if(luaTouchPad != null) {
			if(Std.isOfType(button, String))
				return luaTouchPad.buttonJustReleased(MobileInputID.fromString(button));
			else if(Std.isOfType(button, Array)){
				var FUCK:Array<String> = button;
				var idArray:Array<MobileInputID> = [];
				for(strId in FUCK)
					idArray.push(MobileInputID.fromString(strId));
				return luaTouchPad.anyReleased(idArray);
			} else
				return false;
		}
		return false;
	}

	function checkForResync()
	{
		if (endingSong || paused || shutdownThread)
			return;

		if (requiresSyncing)
		{
			requiresSyncing = false;
			setSongTime(lastCorrectSongPos);
		}

		gameFroze = false;
	}

	public function runSongSyncThread()
	{
		if (songSyncThreadRunning)
			return;
		songSyncThreadRunning = true;
		Thread.create(function()
		{
			while (!endingSong && !paused && !shutdownThread)
			{
				Sys.sleep(0.25);
				if (endingSong || paused || shutdownThread)
					break;
				if (!requiresSyncing && gameFroze)
				{
					lastCorrectSongPos = Conductor.songPosition;
					requiresSyncing = true;
				}
				else if (!requiresSyncing)
					gameFroze = true;
			}
			songSyncThreadRunning = false;
		});

		if (!FlxG.signals.preUpdate.has(checkForResync))
			FlxG.signals.preUpdate.add(checkForResync);
	}
}
