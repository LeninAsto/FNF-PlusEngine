package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;
import flixel.group.FlxGroup;
import flixel.graphics.FlxGraphic;
import objects.MenuItem;
import objects.MenuCharacter;
import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;
import backend.StageData;
#if vslice
import funkin.data.story.level.LevelRegistry;
import funkin.play.PlayStatePlaylist;
import funkin.play.song.Song as VSliceSong;
import funkin.ui.story.Level;
import funkin.ui.story.LevelProp;
#end
#if mobile
import mobile.backend.MobileScaleMode;
#end

class StoryMenuState extends MusicBeatState
{
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();

	public var scoreText:FlxText;

	public static var lastDifficultyName:String = '';

	public var curDifficulty:Int = 1;

	public var txtWeekTitle:FlxText;
	public var bgSprite:FlxSprite;

	public static var curWeek:Int = 0;

	public var txtTracklist:FlxText;

	public var grpWeekText:FlxTypedGroup<MenuItem>;
	public var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;
	#if vslice
	public var grpVSliceWeekProps:FlxTypedGroup<LevelProp>;
	#end

	public var grpLocks:FlxTypedGroup<FlxSprite>;

	public var difficultySelectors:FlxGroup;
	public var sprDifficulty:FlxSprite;
	public var leftArrow:FlxSprite;
	public var rightArrow:FlxSprite;

	public var loadedWeeks:Array<WeekData> = [];

	#if vslice
	var vsliceWeeks:Map<String, Level> = new Map<String, Level>();
	var currentVSliceProps:Array<LevelProp> = [];
	#end

	inline function safeX(x:Float):Float
	{
		#if mobile
		return MobileScaleMode.getHorizontalOffset() + x;
		#else
		return x;
		#end
	}

	inline function safeWidth():Float
	{
		#if mobile
		return MobileScaleMode.getSafeWidth();
		#else
		return FlxG.width;
		#end
	}

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		persistentUpdate = persistentDraw = true;
		PlayState.isStoryMode = true;
		WeekData.reloadWeekFiles(true);
		#if vslice
		appendVSliceWeeks();
		#end

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
				new states.ErrorState("NO WEEKS ADDED FOR STORY MODE\n\nPress " + accept + " to go to the Week Editor Menu.\nPress " + reject
					+ " to return to Main Menu.",
					function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
					function() MusicBeatState.switchState(backend.ScriptableState.tryCreate('MainMenuState', new states.MainMenuState())))));
			return;
		}

		if (curWeek >= WeekData.weeksList.length)
			curWeek = 0;

		scoreText = new FlxText(safeX(10), 10, 0, Language.getPhrase('week_score', 'WEEK SCORE: {1}', [lerpScore]), 36);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32);

		txtWeekTitle = new FlxText(safeX(safeWidth() * 0.7), 10, 0, "", 32);
		txtWeekTitle.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		var bgYellow:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51);
		bgSprite = new FlxSprite(0, 56);

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();
		#if vslice
		grpVSliceWeekProps = new FlxTypedGroup<LevelProp>();
		#end

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		var num:Int = 0;
		var itemTargetY:Float = 0;
		for (i in 0...WeekData.weeksList.length)
		{
			var weekFile:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			if (weekFile == null)
				continue;
			var isLocked:Bool = weekIsLocked(WeekData.weeksList[i]);
			if (!isLocked || !weekFile.hiddenUntilUnlocked)
			{
				loadedWeeks.push(weekFile);
				WeekData.setDirectoryFromWeek(weekFile);
				#if vslice
				var isVSliceWeek:Bool = isVSliceWeekId(WeekData.weeksList[i]);
				var weekThing:MenuItem = new MenuItem(0, bgSprite.y + 396, isVSliceWeek ? 'week1' : WeekData.weeksList[i]);
				if (isVSliceWeek)
					applyVSliceWeekTitle(weekThing, WeekData.weeksList[i]);
				#else
				var weekThing:MenuItem = new MenuItem(0, bgSprite.y + 396, WeekData.weeksList[i]);
				#end
				weekThing.y += ((weekThing.height + 20) * num);
				weekThing.ID = num;
				weekThing.targetY = itemTargetY;
				itemTargetY += Math.max(weekThing.height, 110) + 10;
				grpWeekText.add(weekThing);

				weekThing.screenCenter(X);
				// weekThing.updateHitbox();

				// Needs an offset thingie
				if (isLocked)
				{
					var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x);
					lock.antialiasing = ClientPrefs.data.antialiasing;
					lock.frames = ui_tex;
					lock.animation.addByPrefix('lock', 'lock');
					lock.animation.play('lock');
					lock.ID = weekThing.ID;
					grpLocks.add(lock);
				}
				num++;
			}
		}

		if (loadedWeeks.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(backend.ScriptableState.tryCreate('ErrorState',
				new states.ErrorState("NO VISIBLE WEEKS AVAILABLE FOR STORY MODE\n\nPress " + reject + " to return to Main Menu.", null,
					function() MusicBeatState.switchState(backend.ScriptableState.tryCreate('MainMenuState', new states.MainMenuState())))));
			return;
		}

		WeekData.setDirectoryFromWeek(loadedWeeks[0]);
		var charArray:Array<String> = loadedWeeks[0].weekCharacters;
		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter(safeX((safeWidth() * 0.25) * (1 + char) - 150), charArray[char]);
			weekCharacterThing.y += 70;
			grpWeekCharacters.add(weekCharacterThing);
		}

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		leftArrow = new FlxSprite(850, grpWeekText.members[0].y + 10);
		leftArrow.antialiasing = ClientPrefs.data.antialiasing;
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		difficultySelectors.add(leftArrow);

		Difficulty.resetList();
		if (lastDifficultyName == '')
		{
			lastDifficultyName = Difficulty.getDefault();
		}
		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		sprDifficulty = new FlxSprite(0, leftArrow.y);
		sprDifficulty.antialiasing = ClientPrefs.data.antialiasing;
		difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(leftArrow.x + 376, leftArrow.y);
		rightArrow.antialiasing = ClientPrefs.data.antialiasing;
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		difficultySelectors.add(rightArrow);

		add(bgYellow);
		add(bgSprite);
		add(grpWeekCharacters);
		#if vslice
		add(grpVSliceWeekProps);
		#end

		var tracksSprite:FlxSprite = new FlxSprite(safeX(safeWidth() * 0.07 + 100), bgSprite.y + 425).loadGraphic(Paths.image('Menu_Tracks'));
		tracksSprite.antialiasing = ClientPrefs.data.antialiasing;
		tracksSprite.x -= tracksSprite.width / 2;
		add(tracksSprite);

		txtTracklist = new FlxText(safeX(safeWidth() * 0.05), tracksSprite.y + 60, 0, "", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = Paths.font("vcr.ttf");
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);
		add(scoreText);
		add(txtWeekTitle);

		changeWeek();
		changeDifficulty();

		addTouchPad('LEFT_FULL', 'A_B_X_Y');

		super.create();
	}

	override function closeSubState()
	{
		persistentUpdate = true;
		changeWeek();
		super.closeSubState();
		removeTouchPad();
		addTouchPad('LEFT_FULL', 'A_B_X_Y');
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (WeekData.weeksList.length < 1)
		{
			if (controls.BACK || (touchPad != null && touchPad.buttonB.justPressed) && !movedBack && !selectedWeek)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				movedBack = true;
				MusicBeatState.switchState(backend.ScriptableState.tryCreate('MainMenuState', new MainMenuState()));
			}
			return;
		}
		// scoreText.setFormat(Paths.font("vcr.ttf"), 32);
		if (intendedScore != lerpScore)
		{
			lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 30)));
			if (Math.abs(intendedScore - lerpScore) < 10)
				lerpScore = intendedScore;

			scoreText.text = Language.getPhrase('week_score', 'WEEK SCORE: {1}', [lerpScore]);
		}

		// FlxG.watch.addQuick('font', scoreText.font);

		if (!movedBack && !selectedWeek)
		{
			var changeDiff = false;
			if (controls.UI_UP_P || (touchPad != null && touchPad.buttonUp.justPressed))
			{
				changeWeek(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeDiff = true;
			}

			if (controls.UI_DOWN_P || (touchPad != null && touchPad.buttonDown.justPressed))
			{
				changeWeek(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeDiff = true;
			}

			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				changeWeek(-FlxG.mouse.wheel);
				changeDifficulty();
			}

			if (controls.UI_RIGHT || (touchPad != null && touchPad.buttonRight.pressed))
				rightArrow.animation.play('press')
			else
				rightArrow.animation.play('idle');

			if (controls.UI_LEFT || (touchPad != null && touchPad.buttonLeft.pressed))
				leftArrow.animation.play('press');
			else
				leftArrow.animation.play('idle');

			if (controls.UI_RIGHT_P || (touchPad != null && touchPad.buttonRight.justPressed))
				changeDifficulty(1);
			else if (controls.UI_LEFT_P || (touchPad != null && touchPad.buttonLeft.justPressed))
				changeDifficulty(-1);
			else if (changeDiff)
				changeDifficulty();

			if (FlxG.keys.justPressed.CONTROL || (touchPad != null && touchPad.buttonX.justPressed))
			{
				persistentUpdate = false;
				openSubState(backend.ScriptableSubstate.tryCreate('GameplayChangersSubstate', new GameplayChangersSubstate()));
				removeTouchPad();
			}
			else if (controls.RESET || (touchPad != null && touchPad.buttonY.justPressed))
			{
				persistentUpdate = false;
				openSubState(backend.ScriptableSubstate.tryCreate('ResetScoreSubState', new ResetScoreSubState('', curDifficulty, '', curWeek)));
				removeTouchPad();
			}
			else if (controls.ACCEPT || (touchPad != null && touchPad.buttonA.justPressed))
				selectWeek();
		}

		if ((controls.BACK || (touchPad != null && touchPad.buttonB.justPressed)) && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			MusicBeatState.switchState(backend.ScriptableState.tryCreate('MainMenuState', new MainMenuState()));
		}

		var selectedItem:MenuItem = grpWeekText.members[curWeek];
		if (selectedItem == null)
			return;

		var offY:Float = selectedItem.targetY;
		for (num => item in grpWeekText.members)
		{
			if (item != null)
				item.y = FlxMath.lerp(item.targetY - offY + 480, item.y, Math.exp(-elapsed * 10.2));
		}

		for (num => lock in grpLocks.members)
		{
			if (lock == null || lock.ID < 0 || lock.ID >= grpWeekText.members.length)
				continue;

			var weekItem:MenuItem = grpWeekText.members[lock.ID];
			if (weekItem != null)
				lock.y = weekItem.y + weekItem.height / 2 - lock.height / 2;
		}
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	#if vslice
	static inline var VSLICE_WEEK_PREFIX:String = '__vslice__';
	function appendVSliceWeeks():Void
	{
		if (!funkin.plus.VSliceRuntime.shouldUseVSliceRuntime())
			return;

		funkin.plus.VSliceRuntime.ensureReady();

		for (levelId in LevelRegistry.instance.listSortedLevelIds())
		{
			var level:Null<Level> = LevelRegistry.instance.fetchEntry(levelId);
			if (level == null || !level.isVisible())
				continue;

			var fileName:String = VSLICE_WEEK_PREFIX + levelId;
			if (WeekData.weeksLoaded.exists(fileName))
				continue;

			var weekFile:backend.WeekFile = WeekData.createWeekFile();
			weekFile.songs = [];
			for (songId in level.getSongs())
			{
				weekFile.songs.push([songId, 'face', [146, 113, 253]]);
			}
			weekFile.weekCharacters = ['', '', ''];
			weekFile.weekBackground = '';
			weekFile.weekBefore = '';
			weekFile.storyName = level.getTitle();
			weekFile.weekName = level.getCapsuleTitle() ?? level.getTitle();
			weekFile.startUnlocked = level.isUnlocked();
			weekFile.hiddenUntilUnlocked = false;
			weekFile.hideStoryMode = false;
			weekFile.hideFreeplay = true;
			weekFile.difficulties = level.getDifficulties().join(',');

			var weekData:WeekData = new WeekData(weekFile, fileName);
			WeekData.weeksLoaded.set(fileName, weekData);
			WeekData.weeksList.push(fileName);
			vsliceWeeks.set(fileName, level);
		}
	}

	inline function isVSliceWeekId(fileName:String):Bool
	{
		return fileName != null && vsliceWeeks.exists(fileName);
	}

	function getVSliceLevel(fileName:String):Null<Level>
	{
		return isVSliceWeekId(fileName) ? vsliceWeeks.get(fileName) : null;
	}

	function applyVSliceWeekTitle(weekThing:MenuItem, fileName:String):Void
	{
		var level:Null<Level> = getVSliceLevel(fileName);
		if (level == null || weekThing == null)
			return;

		try
		{
			var title:FlxSprite = level.buildTitleGraphic();
			if (title != null && title.graphic != null)
			{
				weekThing.loadGraphic(title.graphic);
				weekThing.antialiasing = ClientPrefs.data.antialiasing;
				weekThing.updateHitbox();
			}
		}
		catch (e:Dynamic)
		{
			trace('Failed to load VSlice story title "${level.id}": $e');
		}
	}
	#end

	function selectWeek()
	{
		if (!weekIsLocked(loadedWeeks[curWeek].fileName))
		{
			#if vslice
			if (selectVSliceWeek())
				return;
			#end

			// We can't use Dynamic Array .copy() because that crashes HTML5, here's a workaround.
			var songArray:Array<String> = [];
			var leWeek:Array<Dynamic> = loadedWeeks[curWeek].songs;
			for (i in 0...leWeek.length)
			{
				songArray.push(leWeek[i][0]);
			}

			// Nevermind that's stupid lmao
			try
			{
				PlayState.storyPlaylist = songArray;
				PlayState.isStoryMode = true;
				selectedWeek = true;

				var diffic = Difficulty.getFilePath(curDifficulty);
				if (diffic == null)
					diffic = '';

				PlayState.storyDifficulty = curDifficulty;

				Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
				PlayState.campaignScore = 0;
				PlayState.campaignMisses = 0;
				// Resetear estadísticas de la semana
				PlayState.campaignFlawlesss = 0;
				PlayState.campaignSicks = 0;
				PlayState.campaignGoods = 0;
				PlayState.campaignBads = 0;
				PlayState.campaignShits = 0;
				PlayState.campaignMaxCombo = 0;
				PlayState.campaignTotalNotes = 0;
				PlayState.campaignSongsPlayed = [];
				PlayState.campaignAccuracySum = 0;
				PlayState.campaignSongsCount = 0;
			}
			catch (e:Dynamic)
			{
				trace('ERROR! $e');
				return;
			}

			if (stopspamming == false)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));

				grpWeekText.members[curWeek].isFlashing = true;
				for (char in grpWeekCharacters.members)
				{
					if (char.character != '' && char.hasConfirmAnimation)
					{
						char.animation.play('confirm');
					}
				}
				stopspamming = true;
			}

			var directory = StageData.forceNextDirectory;
			LoadingState.loadNextDirectory();
			StageData.forceNextDirectory = directory;
			@:privateAccess
			if (PlayState._lastLoadedModDirectory != Mods.currentModDirectory)
			{
				trace('CHANGED MOD DIRECTORY, RELOADING STUFF');
				Paths.freeGraphicsFromMemory();
			}
			LoadingState.prepareToSong();
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
				LoadingState.returnState = new StoryMenuState(); // Establecer estado de retorno
				LoadingState.loadAndSwitchState(new PlayState(), true);
				FreeplayState.destroyFreeplayVocals();
			}); #if (MODS_ALLOWED && DISCORD_ALLOWED) DiscordClient.loadModRPC(); #end
		}
		else
			FlxG.sound.play(Paths.sound('cancelMenu'));
	}

	#if vslice
	function selectVSliceWeek():Bool
	{
		var leWeek:WeekData = loadedWeeks[curWeek];
		var level:Null<Level> = getVSliceLevel(leWeek.fileName);
		if (level == null)
			return false;

		if (!level.isUnlocked())
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			return true;
		}

		if (selectedWeek)
			return true;

		selectedWeek = true;
		PlayState.isStoryMode = true;

		FlxG.sound.play(Paths.sound('confirmMenu'));
		grpWeekText.members[curWeek].isFlashing = true;
		for (prop in currentVSliceProps)
		{
			if (prop != null)
				prop.playConfirm();
		}
		stopspamming = true;

		var songs:Array<String> = level.getSongs();
		PlayStatePlaylist.playlistSongIds = songs.copy();
		PlayStatePlaylist.isStoryMode = true;
		PlayStatePlaylist.campaignScore = 0;
		PlayStatePlaylist.campaignId = leWeek.fileName.substr(VSLICE_WEEK_PREFIX.length);
		PlayStatePlaylist.campaignTitle = level.getTitle();
		PlayStatePlaylist.campaignDifficulty = Difficulty.getString(curDifficulty, false).toLowerCase();
		funkin.Highscore.talliesLevel = new funkin.Highscore.Tallies();
		funkin.Paths.setCurrentLevel(PlayStatePlaylist.campaignId);

		var targetSongId:String = PlayStatePlaylist.playlistSongIds.shift();
		var targetSong:Null<VSliceSong> = funkin.data.song.SongRegistry.instance.fetchEntry(targetSongId, {variation: funkin.util.Constants.DEFAULT_VARIATION});
		if (targetSong == null)
		{
			trace('Failed to load VSlice story song "$targetSongId".');
			selectedWeek = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			return true;
		}

		var targetVariation:String = targetSong.getFirstValidVariation(PlayStatePlaylist.campaignDifficulty);
		if (targetVariation == null || targetVariation.length < 1)
			targetVariation = funkin.util.Constants.DEFAULT_VARIATION;

		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			#if !SHOW_LOADING_SCREEN
			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();
			#end

			funkin.ui.transition.LoadingState.loadPlayState({
				targetSong: targetSong,
				targetDifficulty: PlayStatePlaylist.campaignDifficulty,
				targetVariation: targetVariation,
				practiceMode: funkin.plus.VSlicePreferencesBridge.practiceMode(),
				botPlayMode: funkin.plus.VSlicePreferencesBridge.botPlayMode(),
				playbackRate: funkin.plus.VSlicePreferencesBridge.playbackRate()
			}, true);
			FreeplayState.destroyFreeplayVocals();
		});

		#if (MODS_ALLOWED && DISCORD_ALLOWED)
		DiscordClient.loadModRPC();
		#end

		return true;
	}

	function updateVSliceBackground(level:Level):Void
	{
		if (level == null)
		{
			bgSprite.visible = false;
			return;
		}

		try
		{
			var bg:FlxSprite = level.buildBackground();
			if (bg == null || bg.graphic == null)
			{
				bgSprite.visible = false;
				return;
			}

			bgSprite.visible = true;
			bgSprite.loadGraphic(bg.graphic);
			bgSprite.color = bg.color;
			bgSprite.alpha = bg.alpha;
			bgSprite.setPosition(0, 56);
			if (bgSprite.width != FlxG.width || bgSprite.height != 386)
				bgSprite.setGraphicSize(FlxG.width, 386);
			bgSprite.updateHitbox();
		}
		catch (e:Dynamic)
		{
			trace('Failed to build VSlice story background "${level.id}": $e');
			bgSprite.visible = false;
		}
	}

	function updateVSliceProps(level:Level):Void
	{
		if (level == null || grpVSliceWeekProps == null)
			return;

		try
		{
			currentVSliceProps = level.buildProps(currentVSliceProps);
			grpVSliceWeekProps.clear();
			for (prop in currentVSliceProps)
			{
				if (prop == null)
					continue;

				prop.y = (prop.propData?.offsets[1] ?? 0) + 70;
				grpVSliceWeekProps.add(prop);
			}
		}
		catch (e:Dynamic)
		{
			trace('Failed to build VSlice story props "${level.id}": $e');
			clearVSliceProps();
		}
	}

	function clearVSliceProps():Void
	{
		if (grpVSliceWeekProps != null)
			grpVSliceWeekProps.clear();

		for (prop in currentVSliceProps)
		{
			if (prop != null)
				prop.visible = false;
		}
	}
	#end

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = Difficulty.list.length - 1;
		if (curDifficulty >= Difficulty.list.length)
			curDifficulty = 0;

		WeekData.setDirectoryFromWeek(loadedWeeks[curWeek]);

		var diff:String = Difficulty.getString(curDifficulty, false);
		var newImage:FlxGraphic = Paths.image('menudifficulties/' + Paths.formatToSongPath(diff));
		// trace(Mods.currentModDirectory + ', menudifficulties/' + Paths.formatToSongPath(diff));

		if (sprDifficulty.graphic != newImage)
		{
			sprDifficulty.loadGraphic(newImage);
			sprDifficulty.x = leftArrow.x + 60;
			sprDifficulty.x += (308 - sprDifficulty.width) / 3;
			sprDifficulty.alpha = 0;
			sprDifficulty.y = leftArrow.y - sprDifficulty.height + 50;

			FlxTween.cancelTweensOf(sprDifficulty);
			FlxTween.tween(sprDifficulty, {y: sprDifficulty.y + 30, alpha: 1}, 0.07);
		}
		lastDifficultyName = diff;

		#if !switch
		#if vslice
		var vsliceLevel:Null<Level> = getVSliceLevel(loadedWeeks[curWeek].fileName);
		if (vsliceLevel != null)
			intendedScore = backend.Highscore.getVSliceWeekScore(loadedWeeks[curWeek].fileName.substr(VSLICE_WEEK_PREFIX.length), diff.toLowerCase());
		else
		#end
			intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
		#end
	}

	var lerpScore:Int = 49324858;
	var intendedScore:Int = 0;

	function changeWeek(change:Int = 0):Void
	{
		curWeek += change;

		if (curWeek >= loadedWeeks.length)
			curWeek = 0;
		if (curWeek < 0)
			curWeek = loadedWeeks.length - 1;

		var leWeek:WeekData = loadedWeeks[curWeek];
		WeekData.setDirectoryFromWeek(leWeek);

		var leName:String = Language.getPhrase('storyname_${leWeek.fileName}', leWeek.storyName);
		txtWeekTitle.text = leName.toUpperCase();
		txtWeekTitle.x = safeX(safeWidth() - (txtWeekTitle.width + 10));

		var unlocked:Bool = !weekIsLocked(leWeek.fileName);
		for (num => item in grpWeekText.members)
		{
			item.alpha = 0.6;
			if (num - curWeek == 0 && unlocked)
				item.alpha = 1;
		}

		bgSprite.visible = true;
		#if vslice
		var vsliceLevel:Null<Level> = getVSliceLevel(leWeek.fileName);
		if (vsliceLevel != null)
			updateVSliceBackground(vsliceLevel);
		else
		#end
		{
			var assetName:String = leWeek.weekBackground;
			if (assetName == null || assetName.length < 1)
			{
				bgSprite.visible = false;
			}
			else
			{
				bgSprite.loadGraphic(Paths.image('menubackgrounds/menu_' + assetName));
				bgSprite.color = FlxColor.WHITE;
			}
		}
		var storyWeekIndex:Int = WeekData.getWeekIndex(leWeek.fileName);
		PlayState.storyWeek = storyWeekIndex >= 0 ? storyWeekIndex : curWeek;

		#if vslice
		if (vsliceLevel != null)
			Difficulty.copyFrom(vsliceLevel.getDifficulties().map(function(diff:String) return diff.toLowerCase()));
		else
		#end
			Difficulty.loadFromWeek();
		difficultySelectors.visible = unlocked;

		if (Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		var newPos:Int = Difficulty.list.indexOf(lastDifficultyName);
		// trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
		if (newPos > -1)
		{
			curDifficulty = newPos;
		}
		updateText();
	}

	function weekIsLocked(name:String):Bool
	{
		#if vslice
		var vsliceLevel:Null<Level> = getVSliceLevel(name);
		if (vsliceLevel != null)
			return !vsliceLevel.isUnlocked();
		#end

		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		if (leWeek == null)
			return true;
		return (!leWeek.startUnlocked
			&& leWeek.weekBefore.length > 0
			&& (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore)));
	}

	function updateText()
	{
		var leWeek:WeekData = loadedWeeks[curWeek];
		#if vslice
		var vsliceLevel:Null<Level> = getVSliceLevel(leWeek.fileName);

		if (vsliceLevel != null)
		{
			grpWeekCharacters.visible = false;
			grpVSliceWeekProps.visible = true;
			updateVSliceProps(vsliceLevel);
		}
		else
		#end
		{
			grpWeekCharacters.visible = true;
			#if vslice
			grpVSliceWeekProps.visible = false;
			clearVSliceProps();
			#end
		}

		var weekArray:Array<String> = loadedWeeks[curWeek].weekCharacters;
		#if vslice
		if (vsliceLevel == null)
		#end
		{
			for (i in 0...grpWeekCharacters.length)
			{
				grpWeekCharacters.members[i].changeCharacter(weekArray[i]);
			}
		}

		var stringThing:Array<String> = [];
		#if vslice
		if (vsliceLevel != null)
		{
			stringThing = vsliceLevel.getSongDisplayNames(Difficulty.getString(curDifficulty, false).toLowerCase());
		}
		else
		#end
		{
			for (i in 0...leWeek.songs.length)
			{
				stringThing.push(leWeek.songs[i][0]);
			}
		}

		txtTracklist.text = '';
		for (i in 0...stringThing.length)
		{
			txtTracklist.text += stringThing[i] + '\n';
		}

		txtTracklist.text = txtTracklist.text.toUpperCase();

		txtTracklist.x = safeX((safeWidth() - txtTracklist.width) / 2 - safeWidth() * 0.35);

		#if !switch
		#if vslice
		if (vsliceLevel != null)
			intendedScore = backend.Highscore.getVSliceWeekScore(leWeek.fileName.substr(VSLICE_WEEK_PREFIX.length),
				Difficulty.getString(curDifficulty, false).toLowerCase());
		else
		#end
			intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
		#end
	}
}

