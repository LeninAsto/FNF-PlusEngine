package states;

import backend.AssetLoader;
import backend.ClientPrefs;
import backend.MusicBeatState;
import backend.Paths;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.text.FlxBitmapText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import objects.results.ClearPercentCounter;
import objects.results.LeftMaskShader;
import objects.results.ResultScore;
import objects.results.TallyCounter;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.utils.AssetType;
import substates.StickerSubState;
#if flxanimate
import backend.PsychFlxAnimate;
#end
#if mobile
import mobile.backend.TouchUtil;
#end
#if MODS_ALLOWED
import backend.Mods;
#end

class ResultsState extends MusicBeatState
{
	final params:Dynamic;
	final scoreData:ResultScoreData;
	final rank:ResultRank;

	final songName:FlxBitmapText;
	final difficulty:FlxSprite;
	final clearPercentSmall:ClearPercentCounter;
	final maskShaderSongName:LeftMaskShader = new LeftMaskShader();
	final maskShaderDifficulty:LeftMaskShader = new LeftMaskShader();

	final resultsAnim:FlxSprite;
	final ratingsPopin:FlxSprite;
	final scorePopin:FlxSprite;
	final bgFlash:FlxSprite;
	final highscoreNew:FlxSprite;
	final score:ResultScore;
	final rankBg:FlxSprite;

	final cameraBG:FlxCamera;
	final cameraScroll:FlxCamera;
	final cameraEverything:FlxCamera;

	var blackTopBar:FlxSprite = new FlxSprite();
	var characterAnimations:Array<ResultCharacterAnimation> = [];
	var introMusicAudio:FlxSound = null;
	var resultsMusic:FlxSound = null;
	var movingSongStuff:Bool = false;
	var speedOfTween:FlxPoint = FlxPoint.get(-1, 1);
	var clearPercentTarget:Int = 100;
	var clearPercentLerp:Int = 0;
	var busy:Bool = false;

	public function new(params:Dynamic)
	{
		super();
		this.params = params;
		scoreData = makeScoreData();
		rank = ResultRankTools.calculateRank(scoreData);

		cameraBG = new FlxCamera(0, 0, FlxG.width, FlxG.height);
		cameraScroll = new FlxCamera(0, 0, FlxG.width, Math.round(FlxG.height * 1.2));
		cameraEverything = new FlxCamera(0, 0, FlxG.width, FlxG.height);

		var fontLetters:String = "AaBbCcDdEeFfGgHhiIJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz:1234567890().-";
		songName = new FlxBitmapText(FlxBitmapFont.fromMonospace(Paths.image("resultScreen/tardlingSpritesheet"), fontLetters, FlxPoint.get(49, 61)));
		songName.text = stringParam('songName', 'Song');
		songName.letterSpacing = -15;
		songName.angle = -4.4;
		songName.visible = false;

		difficulty = new FlxSprite(555);
		clearPercentSmall = new ClearPercentCounter(FlxG.width / 2 + 300, FlxG.height / 2 - 100, 100, true);
		clearPercentSmall.visible = false;

		bgFlash = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFFF1A6, 0xFFFFF1BE], 90);
		resultsAnim = createSparrow(FlxG.width - 1480, -10, "resultScreen/results");
		ratingsPopin = createSparrow(-135, 135, "resultScreen/ratingsPopin");
		scorePopin = createSparrow(-180, 515, "resultScreen/scorePopin");
		highscoreNew = new FlxSprite(44, 557);
		score = new ResultScore(35, 305, 10, scoreData.score);
		rankBg = new FlxSprite();
	}

	override function create():Void
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		#if MODS_ALLOWED
		if (boolParam('isMod') && stringParam('modFolder').length > 0)
			Mods.currentModDirectory = stringParam('modFolder');
		#end

		cameraScroll.canvas.rotation = -3.8;
		cameraBG.bgColor = FlxColor.MAGENTA;
		cameraScroll.bgColor = FlxColor.TRANSPARENT;
		cameraEverything.bgColor = FlxColor.TRANSPARENT;

		FlxG.cameras.add(cameraBG, false);
		FlxG.cameras.add(cameraScroll, false);
		FlxG.cameras.add(cameraEverything, false);
		FlxG.cameras.setDefaultDrawTarget(cameraEverything, true);
		camera = cameraEverything;
		FlxG.camera.zoom = 1.0;

		addZ(FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFECC5C, 0xFFFDC05C], 90), 10, [cameraBG]);
		bgFlash.scrollFactor.set();
		bgFlash.visible = false;
		addZ(bgFlash, 20);

		var soundSystem:FlxSprite = createSparrow(-15, -180, 'resultScreen/soundSystem');
		soundSystem.animation.addByPrefix("idle", "sound system", 24, false);
		soundSystem.visible = false;
		new FlxTimer().start(8 / 24, _ ->
		{
			soundSystem.animation.play("idle");
			soundSystem.visible = true;
		});
		addZ(soundSystem, 1100);

		for (animData in getBFResultsAnimations(rank))
			buildCharacterAnimation(animData);

		var diffSpr:String = 'diff_${Paths.formatToSongPath(stringParam('difficulty', 'normal'))}';
		if (!Paths.fileExists('images/resultScreen/$diffSpr.png', AssetType.IMAGE, true))
			diffSpr = 'diff_normal';
		difficulty.loadGraphic(Paths.image("resultScreen/" + diffSpr));
		addZ(difficulty, 1000);
		addZ(songName, 1000);

		blackTopBar.loadGraphic(createResultsBar());
		blackTopBar.y = -blackTopBar.height;
		FlxTween.tween(blackTopBar, {y: 0}, 7 / 24, {ease: FlxEase.quartOut, startDelay: 3 / 24, onComplete: _ -> songName.visible = true});
		addZ(blackTopBar, 1010);

		difficulty.y += (blackTopBar.height - 148);
		clearPercentSmall.y += (blackTopBar.height - 148);
		songName.y += (blackTopBar.height - 148);

		var angleRad = songName.angle * Math.PI / 180;
		speedOfTween.x = -1.0 * Math.cos(angleRad);
		speedOfTween.y = -1.0 * Math.sin(angleRad);
		timerThenSongName(1.0, false);

		songName.shader = maskShaderSongName;
		difficulty.shader = maskShaderDifficulty;
		maskShaderDifficulty.swagMaskX = difficulty.x - 30;

		resultsAnim.animation.addByPrefix("result", "results instance 1", 24, false);
		resultsAnim.visible = false;
		new FlxTimer().start(6 / 24, _ ->
		{
			resultsAnim.visible = true;
			resultsAnim.animation.play("result");
		});
		addZ(resultsAnim, 1200);

		ratingsPopin.animation.addByPrefix("idle", "Categories", 24, false);
		ratingsPopin.visible = false;
		new FlxTimer().start(21 / 24, _ ->
		{
			ratingsPopin.visible = true;
			ratingsPopin.animation.play("idle");
		});
		addZ(ratingsPopin, 1200);

		scorePopin.animation.addByPrefix("score", "tally score", 24, false);
		scorePopin.visible = false;
		new FlxTimer().start(36 / 24, _ ->
		{
			scorePopin.visible = true;
			scorePopin.animation.play("score");
		});
		addZ(scorePopin, 1200);

		new FlxTimer().start(37 / 24, _ ->
		{
			score.visible = true;
			score.animateNumbers();
			startRankTallySequence();
		});
		new FlxTimer().start(rank.getBFDelay(), _ -> afterRankTallySequence());
		new FlxTimer().start(rank.getFlashDelay(), _ -> displayRankText());

		highscoreNew.frames = Paths.getSparrowAtlas("resultScreen/highscoreNew");
		highscoreNew.animation.addByPrefix("new", "highscoreAnim0", 24, false);
		highscoreNew.visible = false;
		new FlxTimer().start(rank.getHighscoreDelay(), _ ->
		{
			if (boolParam('isNewHighscore') || isNewHighscore())
			{
				highscoreNew.visible = true;
				highscoreNew.animation.play("new");
				highscoreNew.animation.onFinish.add(_ -> highscoreNew.animation.play("new", true, false, 16));
			}
		});
		addZ(highscoreNew, 1200);

		addTallies();
		score.visible = false;
		addZ(score, 1200);

		new FlxTimer().start(rank.getMusicDelay(), _ -> playResultsMusic(rank));

		rankBg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		rankBg.alpha = 0;
		addZ(rankBg, 99999);
		sortByZ();

		super.create();
	}

	function addTallies():Void
	{
		var ratingGrp:FlxTypedGroup<TallyCounter> = new FlxTypedGroup<TallyCounter>();
		ratingGrp.zIndex = 1200;
		add(ratingGrp);
		var hStuf:Int = 50;
		var extraYOffset:Float = 7;
		ratingGrp.add(new TallyCounter(375, hStuf * 3, scoreData.tallies.totalNotesHit));
		ratingGrp.add(new TallyCounter(375, hStuf * 4, scoreData.tallies.maxCombo));
		hStuf += 4;
		ratingGrp.add(new TallyCounter(230, (hStuf * 5) + extraYOffset, scoreData.tallies.sick, 0xFF89E59E));
		ratingGrp.add(new TallyCounter(210, (hStuf * 6) + extraYOffset, scoreData.tallies.good, 0xFF89C9E5));
		ratingGrp.add(new TallyCounter(190, (hStuf * 7) + extraYOffset, scoreData.tallies.bad, 0xFFE6CF8A));
		ratingGrp.add(new TallyCounter(220, (hStuf * 8) + extraYOffset, scoreData.tallies.shit, 0xFFE68AE6));
		ratingGrp.add(new TallyCounter(260, (hStuf * 9) + extraYOffset, scoreData.tallies.missed, 0xFFC68AE6));

		for (ind => rating in ratingGrp.members)
		{
			rating.visible = false;
			new FlxTimer().start((0.3 * ind) + 1.20, _ ->
			{
				rating.visible = true;
				FlxTween.tween(rating, {curNumber: rating.neededNumber}, 0.5, {ease: FlxEase.quartOut});
			});
		}
	}

	function startRankTallySequence():Void
	{
		bgFlash.visible = true;
		bgFlash.alpha = 1;
		FlxTween.tween(bgFlash, {alpha: 0}, 5 / 24);

		var clearPercentFloat = scoreData.tallies.totalNotes == 0 ? 0.0 : ResultRankTools.tallyCompletion(scoreData.tallies) * 100;
		clearPercentTarget = Math.floor(clearPercentFloat);
		clearPercentLerp = Std.int(Math.max(0, clearPercentTarget - 36));

		var clearPercentCounter = new ClearPercentCounter(FlxG.width / 2 + 190, FlxG.height / 2 - 70, clearPercentLerp);
		addZ(clearPercentCounter, 450);
		FlxTween.tween(clearPercentCounter, {curNumber: clearPercentTarget}, 58 / 24, {
			ease: FlxEase.quartOut,
			onUpdate: _ ->
			{
				clearPercentCounter.curNumber = Math.round(clearPercentCounter.curNumber);
				if (clearPercentLerp != clearPercentCounter.curNumber)
				{
					clearPercentLerp = clearPercentCounter.curNumber;
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.75);
				}
			},
			onComplete: _ ->
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				clearPercentCounter.curNumber = clearPercentTarget;
				clearPercentCounter.flash(true);
				new FlxTimer().start(0.4, _ -> clearPercentCounter.flash(false));
				new FlxTimer().start(0.25, _ ->
				{
					FlxTween.tween(clearPercentCounter, {alpha: 0}, 0.5, {
						startDelay: 0.5,
						ease: FlxEase.quartOut,
						onComplete: _ -> remove(clearPercentCounter)
					});
				});
			}
		});
		sortByZ();
	}

	function displayRankText():Void
	{
		bgFlash.visible = true;
		bgFlash.alpha = 1;
		FlxTween.tween(bgFlash, {alpha: 0}, 14 / 24);

		var rankTextVert = new FlxBackdrop(Paths.image(rank.getVerTextAsset()), Y, 0, 30);
		rankTextVert.x = FlxG.width - 44;
		rankTextVert.y = 100;
		addZ(rankTextVert, 990);
		FlxFlicker.flicker(rankTextVert, 2 / 24 * 3, 2 / 24, true);
		new FlxTimer().start(30 / 24, _ -> rankTextVert.velocity.y = -80);

		for (i in 0...12)
		{
			var rankTextBack = new FlxBackdrop(Paths.image(rank.getHorTextAsset()), X, 10, 0);
			rankTextBack.x = FlxG.width / 2 - 320;
			rankTextBack.y = 50 + (135 * i / 2) + 10;
			rankTextBack.cameras = [cameraScroll];
			rankTextBack.velocity.x = (i % 2 == 0) ? -7.0 : 7.0;
			addZ(rankTextBack, 100);
		}
		sortByZ();
	}

	function afterRankTallySequence():Void
	{
		showSmallClearPercent();
		for (anim in characterAnimations)
		{
			new FlxTimer().start(anim.delay, _ ->
			{
				anim.sprite.visible = true;
				playCharacterAnim(anim);
				if (anim.sound != null && anim.sound.length > 0)
					FlxG.sound.play(Paths.sound(anim.sound), 1.0);
			});
		}
	}

	function showSmallClearPercent():Void
	{
		addZ(clearPercentSmall, 1000);
		clearPercentSmall.visible = true;
		clearPercentSmall.flash(true);
		new FlxTimer().start(0.4, _ -> clearPercentSmall.flash(false));
		clearPercentSmall.curNumber = clearPercentTarget;
		new FlxTimer().start(2.5, _ -> movingSongStuff = true);
		sortByZ();
	}

	function timerThenSongName(timerLength:Float = 3.0, autoScroll:Bool = true):Void
	{
		movingSongStuff = false;
		difficulty.x = 555;
		var diffYTween:Float = 122;
		difficulty.y = -difficulty.height;
		FlxTween.tween(difficulty, {y: diffYTween + (blackTopBar.height - 148)}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.8});

		clearPercentSmall.x = (difficulty.x + difficulty.width) + 60;
		clearPercentSmall.y = -clearPercentSmall.height;
		FlxTween.tween(clearPercentSmall, {y: (122 - 5) + (blackTopBar.height - 148)}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.85});

		songName.y = -songName.height;
		var offset:Float = -(songName.width * 0.5) * Math.sin(songName.angle * FlxAngle.TO_RAD) - 10;
		FlxTween.tween(songName, {y: (diffYTween - 25 - offset) + (blackTopBar.height - 148)}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.9});
		songName.x = clearPercentSmall.x + 94;

		new FlxTimer().start(timerLength, _ ->
		{
			var tempSpeed = FlxPoint.get(speedOfTween.x, speedOfTween.y);
			speedOfTween.set(0, 0);
			FlxTween.tween(speedOfTween, {x: tempSpeed.x, y: tempSpeed.y}, 0.7, {ease: FlxEase.quadIn});
			movingSongStuff = autoScroll;
		});
	}

	override function draw():Void
	{
		super.draw();
		songName.clipRect = FlxRect.get(Math.max(0, 520 - songName.x), 0, FlxG.width, songName.height);
		clearPercentSmall.forEachAlive(spr -> spr.clipRect = FlxRect.get(Math.max(0, 520 - spr.x), 0, FlxG.width, spr.height));
	}

	override function update(elapsed:Float):Void
	{
		maskShaderDifficulty.swagSprX = difficulty.x;
		if (movingSongStuff)
		{
			var speedX:Float = speedOfTween.x * 60 * elapsed;
			var speedY:Float = speedOfTween.y * 60 * elapsed;
			songName.x += speedX;
			difficulty.x += speedX;
			clearPercentSmall.x += speedX;
			songName.y += speedY;
			difficulty.y += speedY;
			clearPercentSmall.y += speedY;
			if (songName.x + songName.width < 100)
				timerThenSongName();
		}

		var shouldContinue:Bool = controls.ACCEPT || FlxG.keys.justPressed.ENTER;
		#if mobile
		shouldContinue = shouldContinue || TouchUtil.justPressed || (FlxG.touches.getFirst() != null && FlxG.touches.getFirst().justPressed);
		#end

		if (shouldContinue && !busy)
			acceptResults();

		super.update(elapsed);
	}

	function acceptResults():Void
	{
		busy = true;
		fadeOutResultsAudio();
		var target = boolParam('isWeek') ? () -> new states.StoryMenuState() : () -> states.FreeplayStateSelector.create();
		openSubState(new StickerSubState({
			targetState: _ -> target(),
			stickerPack: 'default',
			playOutOnTarget: true
		}));
	}

	function fadeOutResultsAudio():Void
	{
		for (sound in [introMusicAudio, resultsMusic, FlxG.sound.music])
		{
			if (sound == null)
				continue;
			FlxTween.tween(sound, {volume: 0}, 0.8, {onComplete: _ -> sound.stop()});
		}
	}

	function playResultsMusic(rank:ResultRank):Void
	{
		var musicPath:String = rank.getMusicPath();
		var introKey:String = '$musicPath/$musicPath-intro';
		var loopKey:String = '$musicPath/$musicPath';
		if (assetExists('music/$introKey.${Paths.SOUND_EXT}', AssetType.SOUND))
		{
			introMusicAudio = FlxG.sound.load(Paths.music(introKey), 1.0, false);
			introMusicAudio.onComplete = () -> FlxG.sound.playMusic(Paths.music(loopKey), 1.0, true);
			introMusicAudio.play();
		}
		else
			FlxG.sound.playMusic(Paths.music(loopKey), 1.0, true);
	}

	function buildCharacterAnimation(animData:ResultAnimationData):Void
	{
		var sprite:FlxSprite = null;
		if (animData.renderType == 'sparrow')
		{
			sprite = createSparrow(animData.offsets[0], animData.offsets[1], animData.assetPath);
			sprite.animation.addByPrefix('idle', '', 24, false);
			if (animData.loopFrame != null)
				sprite.animation.onFinish.add(_ -> sprite.animation.play('idle', true, false, animData.loopFrame));
		}
		else
			sprite = createAnimate(animData.offsets[0], animData.offsets[1], animData.assetPath);

		if (sprite == null)
			return;

		sprite.visible = false;
		sprite.scale.set(animData.scale, animData.scale);
		sprite.updateHitbox();
		characterAnimations.push({sprite: sprite, data: animData, delay: animData.delay, sound: animData.sound});
		addZ(sprite, animData.zIndex);
	}

	function playCharacterAnim(anim:ResultCharacterAnimation):Void
	{
		#if flxanimate
		if (Std.isOfType(anim.sprite, PsychFlxAnimate))
		{
			var atlas:PsychFlxAnimate = cast anim.sprite;
			var start:String = anim.data.startFrameLabel == null ? '' : anim.data.startFrameLabel;
			atlas.anim.play(start, true);
			if (anim.data.loopFrameLabel != null)
				atlas.anim.onComplete.add(() -> atlas.anim.play(anim.data.loopFrameLabel, true));
			else if (anim.data.loopFrame != null)
				atlas.anim.onComplete.add(() -> atlas.anim.play('', true, false, anim.data.loopFrame));
			return;
		}
		#end
		anim.sprite.animation.play('idle', true);
	}

	function createSparrow(x:Float, y:Float, key:String):FlxSprite
	{
		var spr = new FlxSprite(x, y);
		spr.frames = Paths.getSparrowAtlas(key);
		return spr;
	}

	function createAnimate(x:Float, y:Float, key:String):FlxSprite
	{
		#if flxanimate
		var spr = new PsychFlxAnimate(x, y);
		spr.showPivot = false;
		try
		{
			Paths.loadAnimateAtlas(spr, key);
		}
		catch (e:Dynamic)
		{
			trace('[ResultsState] Could not load AnimateAtlas "$key": $e');
			return null;
		}
		return spr;
		#else
		return null;
		#end
	}

	function getBFResultsAnimations(rank:ResultRank):Array<ResultAnimationData>
	{
		var naughty:Bool = ClientPrefs.data.vsliceNaughtyness;
		return switch (rank)
		{
			case PERFECT_GOLD | PERFECT:
				naughty ? [
					anim('animateatlas', 'resultScreen/results-bf/resultsPERFECT/bed', [403, -305], 500, 0, 1, 'INTRO', null, 'LOOP START'),
					anim('animateatlas', 'resultScreen/results-bf/resultsPERFECT/hearts', [630, 300], 501, 4.41, 1, '', 43)
				] : [
					anim('animateatlas', 'resultScreen/results-bf/resultsPERFECT/bed', [403, -305], 500, 0, 1, 'INTRO 2', null, 'LOOP 2'),
					anim('animateatlas', 'resultScreen/results-bf/resultsPERFECT/tickleFight', [413, 314], 501, 4.41, 0.6, '', null, 'LOOP', 'tickleFight')
				];
			case EXCELLENT:
				[anim('animateatlas', 'resultScreen/results-bf/resultsEXCELLENT', [560.85, -410.35], 500, 0, 1, '', 29)];
			case GREAT:
				[
					anim('animateatlas', 'resultScreen/results-bf/resultsGREAT/gf', [563.364, -123.186], 499, 0.25, 0.93, '', 9),
					anim('animateatlas', 'resultScreen/results-bf/resultsGREAT/bf', [655.3, -247.95], 500, 0, 0.93, '', 15)
				];
			case GOOD:
				[
					anim('animateatlas', 'resultScreen/results-bf/resultsGOOD/bf', [645.4, -214.8], 501, 0, 1, '', 14),
					anim('sparrow', 'resultScreen/results-bf/resultsGOOD/resultGirlfriendGOOD', [629, 323], 500, 0.91, 1, '', 9)
				];
			case SHIT:
				[anim('animateatlas', 'resultScreen/results-bf/resultsSHIT', [570.5, -390.5], 500, 0, 1, '', null, 'Loop Start')];
		}
	}

	function anim(renderType:String, assetPath:String, offsets:Array<Float>, zIndex:Int, delay:Float = 0, scale:Float = 1, startFrameLabel:String = '',
			?loopFrame:Int, ?loopFrameLabel:String, ?sound:String):ResultAnimationData
	{
		return {
			renderType: renderType,
			assetPath: assetPath,
			offsets: offsets,
			zIndex: zIndex,
			delay: delay,
			scale: scale,
			startFrameLabel: startFrameLabel,
			loopFrame: loopFrame,
			loopFrameLabel: loopFrameLabel,
			sound: sound
		};
	}

	function addZ(obj:FlxBasic, z:Int, ?cameras:Array<FlxCamera>):FlxBasic
	{
		if (Std.isOfType(obj, FlxSprite))
			(cast obj:FlxSprite).scrollFactor.set();
		obj.zIndex = z;
		if (cameras != null)
			obj.cameras = cameras;
		add(obj);
		return obj;
	}

	function sortByZ():Void
		members.sort((a, b) -> FlxSort.byValues(FlxSort.ASCENDING, a == null ? 0 : a.zIndex, b == null ? 0 : b.zIndex));

	function createResultsBar():BitmapData
	{
		final width:Int = Math.ceil(FlxG.width * 1.011);
		final mainBitmap = new BitmapData(width, Math.ceil(width / 8.7), true, 0xFF000000);
		final bitmap = new BitmapData(width, Math.ceil(width / 8.7), true, 0);
		final rect = mainBitmap.rect.clone();
		final matrix = new Matrix();
		matrix.rotate(-3.8 * Math.PI / 180);
		matrix.translate(-15, 0);
		rect.width -= 15;
		bitmap.draw(mainBitmap, matrix, rect, true);
		return bitmap;
	}

	function assetExists(key:String, type:AssetType):Bool
		return AssetLoader.exists(Paths.getPath(key, type, null, false), type);

	function makeScoreData():ResultScoreData
	{
		var missed:Int = intParam('misses');
		var totalNotes:Int = intParam('totalNotes');
		var sick:Int = intParam('flawlesss') + intParam('sicks');
		var good:Int = intParam('goods');
		var bad:Int = intParam('bads');
		var shit:Int = intParam('shits');
		var totalNotesHit:Int = totalNotes > 0 ? Std.int(Math.max(0, totalNotes - missed)) : sick + good + bad + shit;
		return {
			score: intParam('score'),
			tallies: {
				sick: sick,
				good: good,
				bad: bad,
				shit: shit,
				missed: missed,
				combo: intParam('maxCombo'),
				maxCombo: intParam('maxCombo'),
				totalNotesHit: totalNotesHit,
				totalNotes: totalNotes > 0 ? totalNotes : totalNotesHit + missed
			}
		};
	}

	function isNewHighscore():Bool
	{
		var previous:Int = intParam('prevHighScore', -1);
		return previous >= 0 && intParam('score') > previous;
	}

	function fieldParam(name:String):Dynamic
		return params != null && Reflect.hasField(params, name) ? Reflect.field(params, name) : null;

	function stringParam(name:String, fallback:String = ''):String
	{
		var value:Dynamic = fieldParam(name);
		return value == null ? fallback : Std.string(value);
	}

	function intParam(name:String, fallback:Int = 0):Int
	{
		var value:Dynamic = fieldParam(name);
		if (value == null)
			return fallback;
		if (Std.isOfType(value, Int))
			return value;
		if (Std.isOfType(value, Float))
			return Std.int(value);
		var parsed:Null<Int> = Std.parseInt(Std.string(value));
		return parsed == null ? fallback : parsed;
	}

	function boolParam(name:String):Bool
	{
		var value:Dynamic = fieldParam(name);
		if (value == null)
			return false;
		if (Std.isOfType(value, Bool))
			return value;
		return Std.string(value).toLowerCase() == 'true';
	}
}

typedef ResultScoreData =
{
	var score:Int;
	var tallies:ResultTallyData;
}

typedef ResultTallyData =
{
	var sick:Int;
	var good:Int;
	var bad:Int;
	var shit:Int;
	var missed:Int;
	var combo:Int;
	var maxCombo:Int;
	var totalNotesHit:Int;
	var totalNotes:Int;
}

typedef ResultAnimationData =
{
	var renderType:String;
	var assetPath:String;
	var offsets:Array<Float>;
	var zIndex:Int;
	var delay:Float;
	var scale:Float;
	var startFrameLabel:String;
	var ?loopFrame:Null<Int>;
	var ?loopFrameLabel:Null<String>;
	var ?sound:Null<String>;
}

typedef ResultCharacterAnimation =
{
	var sprite:FlxSprite;
	var data:ResultAnimationData;
	var delay:Float;
	var ?sound:Null<String>;
}

enum abstract ResultRank(String)
{
	var PERFECT_GOLD;
	var PERFECT;
	var EXCELLENT;
	var GREAT;
	var GOOD;
	var SHIT;

	public function getMusicPath():String
	{
		return switch (abstract)
		{
			case PERFECT_GOLD | PERFECT: 'resultsPERFECT';
			case EXCELLENT: 'resultsEXCELLENT';
			case GREAT | GOOD: 'resultsNORMAL';
			case SHIT: 'resultsSHIT';
		}
	}

	public function getBFDelay():Float
	{
		return switch (abstract)
		{
			case PERFECT_GOLD | PERFECT: 95 / 24;
			case EXCELLENT: 97 / 24;
			case GREAT | GOOD | SHIT: 95 / 24;
		}
	}

	public function getFlashDelay():Float
	{
		return switch (abstract)
		{
			case PERFECT_GOLD | PERFECT: 129 / 24;
			case EXCELLENT: 122 / 24;
			case GREAT: 109 / 24;
			case GOOD: 107 / 24;
			case SHIT: 186 / 24;
		}
	}

	public function getHighscoreDelay():Float
	{
		return switch (abstract)
		{
			case PERFECT_GOLD | PERFECT | EXCELLENT: 140 / 24;
			case GREAT: 129 / 24;
			case GOOD: 127 / 24;
			case SHIT: 207 / 24;
		}
	}

	public function getMusicDelay():Float
	{
		return switch (abstract)
		{
			case PERFECT_GOLD | PERFECT: 95 / 24;
			case EXCELLENT: 0;
			case GREAT: 5 / 24;
			case GOOD: 3 / 24;
			case SHIT: 2 / 24;
		}
	}

	public function getHorTextAsset():String
	{
		return switch (abstract)
		{
			case PERFECT_GOLD | PERFECT: 'resultScreen/rankText/rankScrollPERFECT';
			case EXCELLENT: 'resultScreen/rankText/rankScrollEXCELLENT';
			case GREAT: 'resultScreen/rankText/rankScrollGREAT';
			case GOOD: 'resultScreen/rankText/rankScrollGOOD';
			case SHIT: 'resultScreen/rankText/rankScrollLOSS';
		}
	}

	public function getVerTextAsset():String
	{
		return switch (abstract)
		{
			case PERFECT_GOLD | PERFECT: 'resultScreen/rankText/rankTextPERFECT';
			case EXCELLENT: 'resultScreen/rankText/rankTextEXCELLENT';
			case GREAT: 'resultScreen/rankText/rankTextGREAT';
			case GOOD: 'resultScreen/rankText/rankTextGOOD';
			case SHIT: 'resultScreen/rankText/rankTextLOSS';
		}
	}
}

class ResultRankTools
{
	static inline var RANK_PERFECT_THRESHOLD:Float = 1.00;
	static inline var RANK_EXCELLENT_THRESHOLD:Float = 0.90;
	static inline var RANK_GREAT_THRESHOLD:Float = 0.80;
	static inline var RANK_GOOD_THRESHOLD:Float = 0.60;

	public static function calculateRank(scoreData:Null<ResultScoreData>):ResultRank
	{
		if (scoreData == null || scoreData.tallies == null || scoreData.tallies.totalNotes <= 0)
			return SHIT;
		if (scoreData.tallies.sick == scoreData.tallies.totalNotes)
			return PERFECT_GOLD;
		var completionAmount:Float = tallyCompletion(scoreData.tallies);
		if (completionAmount == RANK_PERFECT_THRESHOLD)
			return PERFECT;
		if (completionAmount >= RANK_EXCELLENT_THRESHOLD)
			return EXCELLENT;
		if (completionAmount >= RANK_GREAT_THRESHOLD)
			return GREAT;
		if (completionAmount >= RANK_GOOD_THRESHOLD)
			return GOOD;
		return SHIT;
	}

	public static function tallyCompletion(tallies:ResultTallyData):Float
	{
		if (tallies == null || tallies.totalNotes <= 0)
			return 0.0;
		return FlxMath.bound((tallies.sick + tallies.good - tallies.missed) / tallies.totalNotes, 0, 1);
	}
}
