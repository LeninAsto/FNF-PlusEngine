package options;

import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.util.FlxSpriteUtil;
import openfl.utils.Assets;

class LanguageSubState extends MusicBeatSubstate
{
	#if TRANSLATIONS_ALLOWED
	private static inline var OPTION_SPAWN_X:Float = -520;
	private static inline var INTRO_DURATION:Float = 0.32;
	private static inline var OUTRO_DURATION:Float = 0.26;
	private static inline var CARD_W:Float = 960;
	private static inline var CARD_H:Float = 78;
	private static inline var CARD_GAP:Float = 12;
	private static inline var CARD_SELECTED_Y:Float = 150;
	private static inline var CARD_X:Float = 160;

	var grpLanguages:FlxTypedGroup<LanguageCard>;
	var languages:Array<String> = [];
	var displayLanguages:Map<String, String> = [];
	var curSelected:Int = 0;

	private var bg:FlxSprite;
	private var titleText:FlxText;
	private var hintText:FlxText;
	private var lastThemeSignature:String = "";
	private var playingIntroTransition:Bool = false;
	private var closingTransition:Bool = false;

	public var title:String;
	public var rpcTitle:String;

	public function new()
	{
		title = Language.getPhrase('language_menu', 'Language');
		rpcTitle = 'Language Menu';

		super();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence(rpcTitle, null);
		#end

		OptionsMenuTheme.syncAccent();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.alpha = OptionsMenuTheme.menuBackgroundAlpha();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		titleText = new FlxText(64, 38, 700, title, 34);
		titleText.setFormat(Paths.font("vcr.ttf"), 34, OptionsMenuTheme.titleColor(), LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleText.borderSize = 1.5;
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		hintText = new FlxText(66, 80, 780, Language.getPhrase('language_substate_hint', 'ACCEPT applies the selected language.'), 16);
		hintText.setFormat(Paths.font("vcr.ttf"), 16, OptionsMenuTheme.bodyTextColor(), LEFT);
		hintText.antialiasing = ClientPrefs.data.antialiasing;
		add(hintText);

		grpLanguages = new FlxTypedGroup<LanguageCard>();
		add(grpLanguages);

		loadLanguages();

		curSelected = languages.indexOf(ClientPrefs.data.language);
		if (curSelected < 0)
		{
			ClientPrefs.data.language = ClientPrefs.defaultData.language;
			curSelected = Std.int(Math.max(0, languages.indexOf(ClientPrefs.data.language)));
		}

		rebuildLanguageCards();
		changeSelected();
		layoutCards(0, true);
		refreshThemeVisuals(true);
		setupIntroTransition();

		addTouchPad('LEFT_FULL', 'A_B');
	}

	var changedLanguage:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (lastThemeSignature != OptionsMenuTheme.signature())
			refreshThemeVisuals(true);

		if (playingIntroTransition || closingTransition)
			return;

		layoutCards(elapsed);

		var mult:Int = (FlxG.keys.pressed.SHIFT) ? 4 : 1;
		if (controls.UI_UP_P)
			changeSelected(-1 * mult);
		if (controls.UI_DOWN_P)
			changeSelected(1 * mult);
		if (FlxG.mouse.wheel != 0)
			changeSelected(FlxG.mouse.wheel * mult);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			startCloseTransition(changedLanguage);
			return;
		}

		if (controls.ACCEPT && languages.length > 0)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);
			ClientPrefs.data.language = languages[curSelected];
			ClientPrefs.saveSettings();
			Language.reloadPhrases();
			changedLanguage = true;
			refreshLanguageText();
			refreshThemeVisuals(true);
		}
	}

	function loadLanguages():Void
	{
		var hardcodedLanguages = Language.getAvailableLanguages();
		for (lang in hardcodedLanguages)
		{
			if (!languages.contains(lang.code))
			{
				languages.push(lang.code);
				displayLanguages.set(lang.code, lang.name);
			}
		}

		var directories:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'data/');
		for (directory in directories)
		{
			for (file in FileSystem.readDirectory(directory))
			{
				if (!file.toLowerCase().endsWith('.lang'))
					continue;

				var langFile:String = file.substring(0, file.length - '.lang'.length).trim();
				if (!languages.contains(langFile))
					languages.push(langFile);

				if (!displayLanguages.exists(langFile))
				{
					var path:String = '$directory/$file';
					#if MODS_ALLOWED
					var txt:String = File.getContent(path);
					#else
					var txt:String = Assets.getText(path);
					#end

					var id:Int = txt.indexOf('\n');
					if (id > 0)
					{
						var name:String = txt.substr(0, id).trim();
						if (!name.contains(':'))
							displayLanguages.set(langFile, name);
					}
					else if (txt.trim().length > 0 && !txt.contains(':'))
						displayLanguages.set(langFile, txt.trim());
				}
			}
		}

		languages.sort(function(a:String, b:String)
		{
			a = getLanguageName(a).toLowerCase();
			b = getLanguageName(b).toLowerCase();
			if (a < b)
				return -1;
			else if (a > b)
				return 1;
			return 0;
		});
	}

	function rebuildLanguageCards():Void
	{
		while (grpLanguages.members.length > 0)
		{
			var card = grpLanguages.members[0];
			if (card != null)
			{
				card.kill();
				grpLanguages.remove(card, true);
				card.destroy();
			}
			else
				grpLanguages.members.shift();
		}

		for (num => lang in languages)
		{
			var card = new LanguageCard(num, getLanguageName(lang), lang, getLanguageExample(lang), getLanguageFont(lang), CARD_W, CARD_H);
			grpLanguages.add(card);
		}
	}

	function refreshLanguageText():Void
	{
		title = Language.getPhrase('language_menu', 'Language');
		if (titleText != null)
			titleText.text = title;
		if (hintText != null)
			hintText.text = Language.getPhrase('language_substate_hint', 'ACCEPT applies the selected language.');

		for (card in grpLanguages.members)
		{
			if (card == null)
				continue;
			var lang = getLanguageAt(card.index);
			card.setContent(getLanguageName(lang), lang, getLanguageExample(lang), getLanguageFont(lang));
		}
	}

	function refreshThemeVisuals(force:Bool = false):Void
	{
		lastThemeSignature = OptionsMenuTheme.signature();
		OptionsMenuTheme.syncAccent();
		if (bg != null)
		{
			bg.alpha = OptionsMenuTheme.menuBackgroundAlpha();
			bg.color = OptionsMenuTheme.current().accent;
		}
		if (titleText != null)
			titleText.color = OptionsMenuTheme.titleColor();
		if (hintText != null)
			hintText.color = OptionsMenuTheme.bodyTextColor();
		if (force)
			refreshCardVisuals(true);
	}

	function refreshCardVisuals(force:Bool = false):Void
	{
		if (grpLanguages == null)
			return;

		for (card in grpLanguages.members)
		{
			if (card == null)
				continue;
			var selected:Bool = card.index == curSelected;
			card.alpha = selected ? 1 : 0.62;
			card.applyTheme(selected, force);
			card.setApplied(getLanguageAt(card.index) == ClientPrefs.data.language);
		}
	}

	function setupIntroTransition():Void
	{
		if (!Std.isOfType(FlxG.state, OptionsState) || !OptionsState.substateVisualActive)
			return;

		playingIntroTransition = true;

		if (titleText != null)
		{
			titleText.visible = false;
			titleText.active = false;
			titleText.alpha = 0;
		}
		if (hintText != null)
		{
			hintText.visible = false;
			hintText.active = false;
			hintText.alpha = 0;
		}

		for (card in grpLanguages.members)
		{
			if (card == null)
				continue;
			var targetX:Float = card.x;
			card.x = Math.min(OPTION_SPAWN_X, -card.cardWidth - 140);
			card.alpha = 0;
			FlxTween.tween(card, {x: targetX}, INTRO_DURATION, {ease: FlxEase.cubeInOut, startDelay: 0.02 * Math.max(0, card.index + 1)});
			FlxTween.tween(card, {alpha: card.index == curSelected ? 1 : 0.62}, INTRO_DURATION,
				{ease: FlxEase.cubeInOut, startDelay: 0.02 * Math.max(0, card.index + 1)});
		}

		new FlxTimer().start(0.4, function(_) playingIntroTransition = false);
	}

	function startCloseTransition(reloadState:Bool):Void
	{
		if (closingTransition)
			return;

		closingTransition = true;

		for (card in grpLanguages.members)
		{
			if (card == null)
				continue;
			FlxTween.cancelTweensOf(card);
			FlxTween.tween(card, {x: Math.min(OPTION_SPAWN_X, -card.cardWidth - 140), alpha: 0}, OUTRO_DURATION, {ease: FlxEase.cubeInOut});
		}

		new FlxTimer().start(OUTRO_DURATION + 0.04, function(_)
		{
			closingTransition = false;
			if (reloadState)
			{
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				MusicBeatState.resetState();
			}
			else
				close();
		});
	}

	function changeSelected(change:Int = 0):Void
	{
		if (languages.length < 1)
			return;

		curSelected = FlxMath.wrap(curSelected + change, 0, languages.length - 1);
		refreshCardVisuals();
		layoutCards(FlxG.elapsed);
		if (change != 0)
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	function layoutCards(elapsed:Float, instant:Bool = false):Void
	{
		if (grpLanguages == null)
			return;

		var moveLerp:Float = elapsed <= 0 ? 0 : Math.exp(-elapsed * 12);
		for (card in grpLanguages.members)
		{
			if (card == null)
				continue;

			var selected:Bool = card.index == curSelected;
			var targetX:Float = CARD_X + (selected ? 0 : 18);
			var targetY:Float = cardTargetY(card.index);
			var targetScale:Float = selected ? 1.02 : 0.96;

			if (instant)
			{
				card.x = targetX;
				card.y = targetY;
				card.scale.set(targetScale, targetScale);
			}
			else
			{
				card.x = FlxMath.lerp(targetX, card.x, moveLerp);
				card.y = FlxMath.lerp(targetY, card.y, moveLerp);
				card.scale.set(FlxMath.lerp(targetScale, card.scale.x, moveLerp), FlxMath.lerp(targetScale, card.scale.y, moveLerp));
			}
			card.syncLayout();
		}
	}

	function cardTargetY(index:Int):Float
	{
		var desiredScroll:Float = cardStackY(curSelected);
		var maxScroll:Float = Math.max(0, cardsTotalHeight() + CARD_SELECTED_Y - (FlxG.height - 40));
		var scroll:Float = FlxMath.bound(desiredScroll, 0, maxScroll);
		return CARD_SELECTED_Y + cardStackY(index) - scroll;
	}

	function cardStackY(index:Int):Float
	{
		var y:Float = 0;
		var max:Int = Std.int(Math.min(index, grpLanguages.members.length));
		for (i in 0...max)
		{
			var card = getCardAt(i);
			y += (card != null ? card.cardHeight : CARD_H) + CARD_GAP;
		}
		return y;
	}

	function cardsTotalHeight():Float
	{
		if (grpLanguages == null || grpLanguages.members.length == 0)
			return 0;

		var total:Float = 0;
		for (i in 0...grpLanguages.members.length)
		{
			var card = getCardAt(i);
			total += card != null ? card.cardHeight : CARD_H;
			if (i < grpLanguages.members.length - 1)
				total += CARD_GAP;
		}
		return total;
	}

	function getCardAt(index:Int):LanguageCard
		return (grpLanguages != null && index >= 0 && index < grpLanguages.members.length) ? grpLanguages.members[index] : null;

	function getLanguageAt(index:Int):String
		return (languages != null && index >= 0 && index < languages.length) ? languages[index] : '';

	function getLanguageName(lang:String):String
	{
		var name:String = displayLanguages.get(lang);
		return name != null ? name : lang;
	}

	function getLanguageExample(lang:String):String
		return Language.getPhraseForLanguage(lang, 'language_example_text', getExampleTextForLanguage(lang));

	function getLanguageFont(lang:String):String
		return Language.getPhraseForLanguage(lang, 'language_font', getFontForLanguage(lang));

	function getExampleTextForLanguage(langCode:String):String
		return 'This is an example text in the selected language';

	function getFontForLanguage(langCode:String):String
	{
		return switch (langCode)
		{
			case 'ja-JP': 'NotoSansJP-Medium.ttf';
			case 'ko-KR': 'NotoSansKR-Medium.ttf';
			case 'zh-CN': 'NotoSansSC-Medium.ttf';
			case 'zh-HK' | 'zh-TW': 'NotoSansTC-Medium.ttf';
			default: 'vcr.ttf';
		}
	}
	#end
}

#if TRANSLATIONS_ALLOWED
private class LanguageCard extends FlxSpriteGroup
{
	static inline var MAX_EXAMPLE_CHARS:Int = 148;
	static inline var MAX_CARD_HEIGHT:Float = 98;
	static inline var DOT_W:Float = 14;
	static inline var DOT_H:Float = 34;
	static inline var DOT_X:Float = 18;
	static inline var CONTENT_X:Float = 46;
	static inline var TITLE_Y:Float = 12;
	static inline var EXAMPLE_Y:Float = 43;
	static inline var RIGHT_MARGIN:Float = 34;

	public var index(default, null):Int;
	public var cardWidth(default, null):Float;
	public var cardHeight(default, null):Float;

	var minCardHeight:Float;
	var bg:FlxSprite;
	var title:FlxText;
	var codeText:FlxText;
	var exampleText:FlxText;
	var appliedText:FlxText;
	var lastSelected:Null<Bool> = null;
	var lastTheme:String = "";
	var applied:Bool = false;

	public function new(index:Int, label:String, code:String, example:String, fontName:String, w:Float, h:Float)
	{
		super();
		this.index = index;
		cardWidth = w;
		minCardHeight = h;
		cardHeight = h;

		bg = new FlxSprite().makeGraphic(Std.int(cardWidth), Std.int(cardHeight), FlxColor.TRANSPARENT, true);
		add(bg);

		title = new FlxText(CONTENT_X, 12, 540, label, 22);
		title.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, LEFT);
		title.antialiasing = ClientPrefs.data.antialiasing;
		add(title);

		codeText = new FlxText(cardWidth - RIGHT_MARGIN - 250, 15, 170, code, 16);
		codeText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT);
		codeText.antialiasing = ClientPrefs.data.antialiasing;
		add(codeText);

		appliedText = new FlxText(cardWidth - RIGHT_MARGIN - 72, 15, 72, "", 16);
		appliedText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT);
		appliedText.antialiasing = ClientPrefs.data.antialiasing;
		add(appliedText);

		exampleText = new FlxText(CONTENT_X, 43, 760, formatExample(example), 14);
		exampleText.setFormat(Paths.font(fontName), 14, FlxColor.WHITE, LEFT);
		exampleText.antialiasing = ClientPrefs.data.antialiasing;
		add(exampleText);

		resizeToContent();
		applyTheme(false, true);
	}

	public function setContent(label:String, code:String, example:String, fontName:String):Void
	{
		title.text = label;
		codeText.text = code;
		exampleText.setFormat(Paths.font(fontName), 14, exampleText.color, LEFT);
		exampleText.text = formatExample(example);
		resizeToContent();
		lastTheme = "";
	}

	public function setApplied(value:Bool):Void
	{
		applied = value;
		appliedText.text = applied ? Language.getPhrase('language_applied_badge', 'Active') : '';
		positionMetaText();
	}

	function resizeToContent():Void
	{
		exampleText.updateHitbox();
		cardHeight = FlxMath.bound(EXAMPLE_Y + exampleText.height + 14, minCardHeight, MAX_CARD_HEIGHT);
		bg.makeGraphic(Std.int(cardWidth), Std.int(cardHeight), FlxColor.TRANSPARENT, true);
		syncLayout();
	}

	function positionMetaText():Void
	{
		codeText.updateHitbox();
		appliedText.updateHitbox();
		codeText.x = x + cardWidth - RIGHT_MARGIN - 250;
		appliedText.x = x + cardWidth - RIGHT_MARGIN - 72;
		codeText.y = y + cardHeight * 0.5 - (codeText.height * codeText.scale.y) * 0.5 - 1;
		appliedText.y = y + cardHeight * 0.5 - (appliedText.height * appliedText.scale.y) * 0.5 - 1;
	}

	public function syncLayout():Void
	{
		if (bg != null)
			bg.setPosition(x, y);
		if (title != null)
		{
			title.x = x + CONTENT_X;
			title.y = y + TITLE_Y;
		}
		if (exampleText != null)
		{
			exampleText.x = x + CONTENT_X;
			exampleText.y = y + EXAMPLE_Y;
		}
		positionMetaText();
	}

	function formatExample(value:String):String
	{
		if (value == null)
			return '';

		var text:String = value.trim();
		if (text.length <= MAX_EXAMPLE_CHARS)
			return text;

		return text.substr(0, MAX_EXAMPLE_CHARS - 3).trim() + '...';
	}

	public function applyTheme(selected:Bool, force:Bool = false):Void
	{
		var signature = OptionsMenuTheme.signature();
		if (!force && lastSelected == selected && lastTheme == signature)
			return;
		lastSelected = selected;
		lastTheme = signature;

		var fill:Int = selected ? OptionsMenuTheme.difficultyCardFill(OptionsMenuTheme.current().accent, true) : OptionsMenuTheme.cardFill(false);
		var stroke:Int = selected ? OptionsMenuTheme.current().accent : OptionsMenuTheme.panelOutlineColor();
		bg.makeGraphic(Std.int(cardWidth), Std.int(cardHeight), FlxColor.TRANSPARENT, true);
		bg.setPosition(x, y);
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, cardWidth, cardHeight, 8, 8, fill);
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, cardWidth, cardHeight, 8, 8, FlxColor.TRANSPARENT, {thickness: selected ? 2 : 1, color: stroke});
		FlxSpriteUtil.drawRoundRect(bg, DOT_X, (cardHeight - DOT_H) * 0.5, DOT_W, DOT_H, DOT_W * 0.5, DOT_W * 0.5,
			selected ? OptionsMenuTheme.current().accent : OptionsMenuTheme.cardAccent(false));

		title.color = OptionsMenuTheme.cardTitleColor(selected);
		codeText.color = selected ? OptionsMenuTheme.current().accent : OptionsMenuTheme.footerTextColor();
		exampleText.color = OptionsMenuTheme.cardDescriptionColor(selected);
		appliedText.color = selected ? OptionsMenuTheme.current().accent : OptionsMenuTheme.cardValueColor(false);
		syncLayout();
	}
}
#end
