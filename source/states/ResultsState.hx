package states;

import backend.MusicBeatState;
import backend.Paths;
import backend.LocaleUtils;
import backend.Language;
import backend.ClientPrefs;
import states.FreeplayState;
import states.StoryMenuState;
import states.MainMenuState;
#if FEATURE_POLYMOD_MODS
import funkin.play.ResultState;
import funkin.save.Save.SaveScoreData;
#end
#if mobile
import mobile.backend.TouchUtil;
#end
#if MODS_ALLOWED
import backend.Mods;
#end

class ResultsState extends MusicBeatState
{
	public var menuBG:FlxSprite;
	public var backdropImage:FlxSprite;
	public var flxGroupImage:FlxSprite;
	public var songInstrumental:String = "";
	public var canRetry:Bool = true;
	public var params:Dynamic;

	public var animatedScore:Int = 0;
	public var animatedFlawlesss:Int = 0;
	public var animatedSicks:Int = 0;
	public var animatedGoods:Int = 0;
	public var animatedBads:Int = 0;
	public var animatedShits:Int = 0;
	public var animatedMisses:Int = 0;
	public var animatedCombo:Int = 0;
	public var animatedAccuracy:Float = 0;
	var usingFunkinResultState:Bool = false;

	public var scoreText:FlxText;
	public var flawlesss:FlxText;
	public var sicks:FlxText;
	public var goods:FlxText;
	public var bads:FlxText;
	public var shits:FlxText;
	public var misses:FlxText;
	public var comboText:FlxText;
	public var accText:FlxText;

	public static var use24HourFormat:Null<Bool> = true;
	public static var dateFormat:String = "MM/DD/YYYY";

	public function new(params:Dynamic)
	{
		super();
		this.params = params;

		LocaleUtils.loadDeviceDateTimeSettings();
	}

	override public function create()
	{
		super.create();

		#if FEATURE_POLYMOD_MODS
		usingFunkinResultState = true;
		openFunkinResultState();
		return;
		#end

		#if MODS_ALLOWED
		if (params.isMod && params.modFolder != null && params.modFolder != "")
		{
			Mods.currentModDirectory = params.modFolder;
		}
		#end

		menuBG = new FlxSprite();
		menuBG.loadGraphic(Paths.image('menuBG'));
		menuBG.setGraphicSize(FlxG.width, FlxG.height);
		menuBG.updateHitbox();
		menuBG.alpha = 1.0;
		add(menuBG);

		backdropImage = new FlxSprite();
		backdropImage.loadGraphic(Paths.image('ui/results/backdrop'));
		backdropImage.setGraphicSize(FlxG.width, FlxG.height + 1);
		backdropImage.updateHitbox();
		backdropImage.alpha = 0.8;
		add(backdropImage);

		flxGroupImage = new FlxSprite();
		flxGroupImage.loadGraphic(Paths.image('ui/results/flxgroup'));
		flxGroupImage.setGraphicSize(FlxG.width, FlxG.height + 1);
		flxGroupImage.updateHitbox();
		flxGroupImage.alpha = 0.4;
		add(flxGroupImage);

		if (!FlxG.sound.music.playing || FlxG.sound.music.length <= 0)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7, true);
		}

		var infoWidth = 700;
		var songAndDiff = '${params.songName} [${params.difficulty}]';
		var modOrGame = params.isMod && params.modFolder != null && params.modFolder != "" ? params.modFolder : "Friday Night Funkin'";
		var now = Date.now();

		var dateStr = LocaleUtils.formatDateTimeAccordingToDevice(now);

		var resulText = new FlxText(500, 12, infoWidth, Language.getPhrase('results_title', 'Results'), 60);
		resulText.setFormat(Paths.font("NotoSans-Medium.ttf"), 60, FlxColor.WHITE, "right");
		add(resulText);

		var topText = new FlxText(10, 5, infoWidth, songAndDiff, 28);
		topText.setFormat(Paths.font("NotoSans-Medium.ttf"), 28, FlxColor.WHITE, "left");
		add(topText);

		var modText = new FlxText(10, 39, infoWidth, modOrGame, 22);
		modText.setFormat(Paths.font("NotoSans-Medium.ttf"), 22, FlxColor.WHITE, "left");
		add(modText);

		var playedText = new FlxText(10, 65, infoWidth, Language.getPhrase('results_played_on', 'Played on') + ' $dateStr', 18);
		playedText.setFormat(Paths.font("NotoSans-Medium.ttf"), 18, FlxColor.WHITE, "left");
		add(playedText);

		var scoreY = 130;
		var scoreStr = StringTools.lpad("0", "0", 8);
		var scoreLabel = new FlxText(60, scoreY, 400, Language.getPhrase('results_score', 'Score') + ':', 34);
		scoreLabel.setFormat(Paths.font("NotoSans-Medium.ttf"), 34, FlxColor.WHITE, "left");
		add(scoreLabel);

		scoreText = new FlxText(240, scoreY - 10, 400, scoreStr, 44);
		scoreText.setFormat(Paths.font("NotoSans-Medium.ttf"), 44, FlxColor.WHITE, "left");
		add(scoreText);

		var leftX = 30;
		var rightX = 300;
		var judgY = 235;
		var judgSpacing = 90; // More space

		flawlesss = new FlxText(leftX, judgY, 340, Language.getPhrase('judgement_flawlesss', 'flawlesss') + ': 0', 32);
		flawlesss.setFormat(Paths.font("NotoSans-Medium.ttf"), 32, 0xFFA17FFF, "left");
		flawlesss.visible = ClientPrefs.data.useFlawlessRating;
		add(flawlesss);

		sicks = new FlxText(rightX, judgY, 340, Language.getPhrase('judgement_sicks', 'Sicks') + ': 0', 32);
		sicks.setFormat(Paths.font("NotoSans-Medium.ttf"), 32, 0xFF7FC9FF, "left");
		add(sicks);

		goods = new FlxText(leftX, judgY + judgSpacing, 340, Language.getPhrase('judgement_goods', 'Goods') + ': 0', 32);
		goods.setFormat(Paths.font("NotoSans-Medium.ttf"), 32, 0xFF7FFF8E, "left");
		add(goods);

		bads = new FlxText(rightX, judgY + judgSpacing, 340, Language.getPhrase('judgement_bads', 'Bads') + ': 0', 32);
		bads.setFormat(Paths.font("NotoSans-Medium.ttf"), 32, 0xFF888888, "left");
		add(bads);

		shits = new FlxText(leftX, judgY + judgSpacing * 2, 340, Language.getPhrase('judgement_shits', 'Shits') + ': 0', 32);
		shits.setFormat(Paths.font("NotoSans-Medium.ttf"), 32, 0xFFFF7F7F, "left");
		add(shits);

		misses = new FlxText(rightX, judgY + judgSpacing * 2, 340, Language.getPhrase('judgement_misses', 'Misses') + ': 0', 32);
		misses.setFormat(Paths.font("NotoSans-Medium.ttf"), 32, FlxColor.RED, "left");
		add(misses);

		comboText = new FlxText(leftX, judgY + judgSpacing * 3 - 14, 700, Language.getPhrase('judgement_max_combo', 'Highest Combo') + ': 0', 26);
		comboText.setFormat(Paths.font("NotoSans-Medium.ttf"), 32, FlxColor.WHITE, "left");
		add(comboText);

		accText = new FlxText(leftX, judgY + judgSpacing * 3 + 20, 700, Language.getPhrase('results_accuracy', 'Accuracy') + ': 0%', 26);
		accText.setFormat(Paths.font("NotoSans-Medium.ttf"), 32, FlxColor.WHITE, "left");
		add(accText);

		if (!ClientPrefs.data.useFlawlessRating)
		{
			sicks.setPosition(leftX, judgY);
			goods.setPosition(rightX, judgY);
			bads.setPosition(leftX, judgY + judgSpacing);
			shits.setPosition(rightX, judgY + judgSpacing);
			misses.setPosition(leftX, judgY + judgSpacing * 2);
		}

		var ratingLetter = params.ratingName != null ? params.ratingName : "";
		var ratingFC = params.ratingFC != null ? params.ratingFC : "";
		var ratingW = 400;
		var ratingX = FlxG.width - 525;
		var ratingY = judgY + 25;
		var ratingText = new FlxText(ratingX, ratingY, ratingW, ratingLetter, 70);
		ratingText.setFormat(Paths.font("NotoSans-Medium.ttf"), 70, FlxColor.YELLOW, "center");
		add(ratingText);

		var fcText = new FlxText(ratingX, ratingY + 90, ratingW, ratingFC, 54);
		fcText.setFormat(Paths.font("NotoSans-Medium.ttf"), 54, FlxColor.CYAN, "center");
		add(fcText);

		var yBottom = FlxG.height - 110;
		if (params.isPractice != null && params.isPractice)
		{
			var practiceText = new FlxText(0, yBottom, FlxG.width, Language.getPhrase('results_practice_mode', 'Played in practice mode'), 22);
			practiceText.setFormat(Paths.font("NotoSans-Medium.ttf"), 22, FlxColor.YELLOW, "center");
			add(practiceText);
			yBottom += 28;
		}

		var engineInfo = Language.getPhrase('psych_engine_version', 'Psych Engine v')
			+ MainMenuState.psychEngineVersion
			+ "\nFNF API v"
			+ MainMenuState.fnfApiVersion;
		var engineText = new FlxText(0, FlxG.height - 100, FlxG.width, engineInfo, 25);
		engineText.setFormat(Paths.font("NotoSans-Medium.ttf"), 25, FlxColor.CYAN, "center");
		add(engineText);

		#if mobile
		var continueText = new FlxText(50, FlxG.height - 75, 0, Language.getPhrase('results_press_enter_mobile', 'Press A\nto Continue'), 26);
		#else
		var continueText = new FlxText(50, FlxG.height - 75, 0, Language.getPhrase('results_press_enter', 'Press Enter\nto Continue'), 26);
		#end
		continueText.setFormat(Paths.font("NotoSans-Medium.ttf"), 26, FlxColor.WHITE, "center");
		add(continueText);

		#if mobile
		addTouchPad('NONE', 'A');
		#end
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (usingFunkinResultState)
			return;

		if (animatedScore < params.score)
		{
			animatedScore += Math.ceil((params.score - animatedScore) * 0.2 + 1);
			if (animatedScore > params.score)
				animatedScore = params.score;
			scoreText.text = StringTools.lpad(Std.string(animatedScore), "0", 8);
			return;
		}
		scoreText.text = StringTools.lpad(Std.string(animatedScore), "0", 8);

		if (ClientPrefs.data.useFlawlessRating && animatedFlawlesss < params.flawlesss)
		{
			animatedFlawlesss = animateInt(animatedFlawlesss, params.flawlesss);
			flawlesss.text = Language.getPhrase('judgement_flawlesss', 'Flawlesss') + ': $animatedFlawlesss';
			return;
		}
		if (ClientPrefs.data.useFlawlessRating)
			flawlesss.text = Language.getPhrase('judgement_flawlesss', 'Flawlesss') + ': $animatedFlawlesss';
		if (animatedSicks < params.sicks)
		{
			animatedSicks = animateInt(animatedSicks, params.sicks);
			sicks.text = Language.getPhrase('judgement_sicks', 'Sicks') + ': $animatedSicks';
			return;
		}
		sicks.text = Language.getPhrase('judgement_sicks', 'Sicks') + ': $animatedSicks';

		if (animatedGoods < params.goods)
		{
			animatedGoods = animateInt(animatedGoods, params.goods);
			goods.text = Language.getPhrase('judgement_goods', 'Goods') + ': $animatedGoods';
			return;
		}
		goods.text = Language.getPhrase('judgement_goods', 'Goods') + ': $animatedGoods';

		if (animatedBads < params.bads)
		{
			animatedBads = animateInt(animatedBads, params.bads);
			bads.text = Language.getPhrase('judgement_bads', 'Bads') + ': $animatedBads';
			return;
		}
		bads.text = Language.getPhrase('judgement_bads', 'Bads') + ': $animatedBads';

		if (animatedShits < params.shits)
		{
			animatedShits = animateInt(animatedShits, params.shits);
			shits.text = Language.getPhrase('judgement_shits', 'Shits') + ': $animatedShits';
			return;
		}
		shits.text = Language.getPhrase('judgement_shits', 'Shits') + ': $animatedShits';

		if (animatedMisses < params.misses)
		{
			animatedMisses = animateInt(animatedMisses, params.misses);
			misses.text = Language.getPhrase('judgement_misses', 'Misses') + ': $animatedMisses';
			return;
		}
		misses.text = Language.getPhrase('judgement_misses', 'Misses') + ': $animatedMisses';

		if (animatedCombo < params.maxCombo)
		{
			animatedCombo = animateInt(animatedCombo, params.maxCombo);
			comboText.text = Language.getPhrase('judgement_max_combo', 'Highest Combo') + ': $animatedCombo';
			return;
		}
		comboText.text = Language.getPhrase('judgement_max_combo', 'Highest Combo') + ': $animatedCombo';

		if (animatedAccuracy < params.accuracy)
		{
			animatedAccuracy += (params.accuracy - animatedAccuracy) * 0.2 + 0.1;
			if (animatedAccuracy > params.accuracy)
				animatedAccuracy = params.accuracy;

			var accPercent:Float = Math.round(animatedAccuracy * 1000) / 10;
			accText.text = Language.getPhrase('results_accuracy', 'Accuracy') + ': ' + Std.string(accPercent) + '%';
			return;
		}

		var accPercent:Float = Math.round(animatedAccuracy * 1000) / 10;
		accText.text = Language.getPhrase('results_accuracy', 'Accuracy') + ': ' + Std.string(accPercent) + '%';

		var shouldContinue:Bool = false;

		if (FlxG.keys.justPressed.ENTER)
			shouldContinue = true;

		if (controls.ACCEPT)
			shouldContinue = true;

		#if mobile
		if (TouchUtil.justPressed)
			shouldContinue = true;

		if (FlxG.touches.getFirst() != null && FlxG.touches.getFirst().justPressed)
			shouldContinue = true;
		#end

		if (shouldContinue)
		{
			#if MODS_ALLOWED
			Mods.currentModDirectory = '';
			#end

			// If it's a full week, return to the Story Menu; otherwise, return to Freeplay
			if (params.isWeek != null && params.isWeek == true)
			{
				MusicBeatState.switchState(backend.ScriptableState.tryCreate('StoryMenuState', new StoryMenuState()));
			}
			else
			{
				MusicBeatState.switchState(FreeplayStateSelector.create());
			}
		}
	}

	function animateInt(current:Int, target:Int):Int
	{
		if (current < target)
			return current + Math.ceil((target - current) * 0.2 + 1);
		return target;
	}

	#if FEATURE_POLYMOD_MODS
	function openFunkinResultState():Void
	{
		persistentUpdate = false;
		persistentDraw = true;

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		funkin.plus.VSliceRuntime.ensureBaseReady();

		openSubState(new ResultState({
			storyMode: boolParam('isWeek'),
			title: stringParam('songName', 'Song'),
			songId: Paths.formatToSongPath(stringParam('songName', 'song')),
			characterId: 'bf',
			difficultyId: Paths.formatToSongPath(stringParam('difficulty', 'normal')),
			scoreData: makeFunkinScoreData(intParam('score')),
			prevScoreData: makePreviousFunkinScoreData(),
			isNewHighscore: isNewHighscore(),
			isPracticeMode: boolParam('isPractice'),
			isBotPlayMode: boolParam('isBotPlay'),
			fromPlusPlayState: true
		}));
	}

	function makeFunkinScoreData(score:Int):SaveScoreData
	{
		var missed:Int = intParam('misses');
		var totalNotes:Int = intParam('totalNotes');
		var sick:Int = intParam('flawlesss') + intParam('sicks');
		var good:Int = intParam('goods');
		var bad:Int = intParam('bads');
		var shit:Int = intParam('shits');
		var totalNotesHit:Int = totalNotes > 0 ? Std.int(Math.max(0, totalNotes - missed)) : sick + good + bad + shit;

		return {
			score: score,
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

	function makePreviousFunkinScoreData():Null<SaveScoreData>
	{
		var previous:Int = intParam('prevHighScore', -1);
		if (previous < 0)
			return null;

		var previousData:SaveScoreData = makeFunkinScoreData(previous);
		return previousData;
	}

	function isNewHighscore():Bool
	{
		var previous:Int = intParam('prevHighScore', -1);
		return previous >= 0 && intParam('score') > previous;
	}

	function fieldParam(name:String):Dynamic
	{
		if (params == null || !Reflect.hasField(params, name))
			return null;
		return Reflect.field(params, name);
	}

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
	#end
}

