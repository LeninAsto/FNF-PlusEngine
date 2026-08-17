package options;

import openfl.utils.Assets;

class LanguageSubState extends MusicBeatSubstate
{
	#if TRANSLATIONS_ALLOWED
	private static inline var INTRO_DURATION:Float = 0.32;
	private static inline var INTRO_DESC_DURATION:Float = 0.24;
	private static inline var OUTRO_DURATION:Float = 0.26;

	var grpLanguages:FlxTypedGroup<Alphabet> = new FlxTypedGroup<Alphabet>();
	var languages:Array<String> = [];
	var displayLanguages:Map<String, String> = [];
	var curSelected:Int = 0;

	// Usando el mismo sistema de descText que BaseOptionsMenu
	private var descBox:FlxSprite;
	private var descText:FlxText;
	private var bg:FlxSprite;
	private var lastThemeSignature:String = "";
	private var titleText:Alphabet;
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

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.alpha = OptionsMenuTheme.menuBackgroundAlpha();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		add(grpLanguages);

		// Crear el sistema de descripción como en BaseOptionsMenu
		descBox = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.6;
		add(descBox);

		titleText = new Alphabet(75, 45, title, true);
		titleText.setScale(0.6);
		titleText.alpha = 0.4;
		add(titleText);

		descText = new FlxText(50, 600, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, OptionsMenuTheme.readableTextOn(OptionsMenuTheme.cardFill(false)), CENTER, FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);
		refreshThemeVisuals();

		// ← NUEVO: Cargar idiomas hardcodeados primero
		var hardcodedLanguages = Language.getAvailableLanguages();
		for (lang in hardcodedLanguages)
		{
			if (!languages.contains(lang.code))
			{
				languages.push(lang.code);
				displayLanguages.set(lang.code, lang.name);
			}
		}

		// ← MANTENER: Cargar idiomas desde archivos .lang como fallback
		var directories:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'data/');
		for (directory in directories)
		{
			for (file in FileSystem.readDirectory(directory))
			{
				if (file.toLowerCase().endsWith('.lang'))
				{
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
						if (id > 0) // language display name shouldnt be an empty string or null
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
		}

		languages.sort(function(a:String, b:String)
		{
			a = (displayLanguages.exists(a) ? displayLanguages.get(a) : a).toLowerCase();
			b = (displayLanguages.exists(b) ? displayLanguages.get(b) : b).toLowerCase();
			if (a < b)
				return -1;
			else if (a > b)
				return 1;
			return 0;
		});

		// trace(ClientPrefs.data.language);
		curSelected = languages.indexOf(ClientPrefs.data.language);
		if (curSelected < 0)
		{
			// trace('Language not found: ' + ClientPrefs.data.language);
			ClientPrefs.data.language = ClientPrefs.defaultData.language;
			curSelected = Std.int(Math.max(0, languages.indexOf(ClientPrefs.data.language)));
		}

		for (num => lang in languages)
		{
			var name:String = displayLanguages.get(lang);
			if (name == null)
				name = lang;

			var text:Alphabet = new Alphabet(0, 300, name, true);
			text.isMenuItem = true;
			text.targetY = num;
			text.changeX = false;
			text.distancePerItem.y = 100;
			if (languages.length < 7)
			{
				text.changeY = false;
				text.screenCenter(Y);
				text.y += (100 * (num - (languages.length / 2))) + 45;
			}
			text.screenCenter(X);
			grpLanguages.add(text);
		}
		changeSelected();
		updateExampleText();
		setupIntroTransition();

		addTouchPad('LEFT_FULL', 'A_B');
	}

	var changedLanguage:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (lastThemeSignature != OptionsMenuTheme.signature())
			refreshThemeVisuals();

		if (playingIntroTransition || closingTransition)
			return;

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
			if (changedLanguage)
			{
				startCloseTransition(true);
			}
			else
				startCloseTransition(false);
			return;
		}

		if (controls.ACCEPT)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);
			ClientPrefs.data.language = languages[curSelected];
			// trace(ClientPrefs.data.language);
			ClientPrefs.saveSettings();
			Language.reloadPhrases();
			changedLanguage = true;
		}
	}

	function refreshThemeVisuals():Void
	{
		lastThemeSignature = OptionsMenuTheme.signature();
		if (bg != null)
		{
			bg.alpha = OptionsMenuTheme.menuBackgroundAlpha();
		}
		if (descBox != null)
		{
			descBox.color = OptionsMenuTheme.cardFill(false);
			descBox.alpha = 0.84;
		}
		if (descText != null)
			descText.color = OptionsMenuTheme.readableTextOn(OptionsMenuTheme.cardFill(false));
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

		for (lang in grpLanguages.members)
		{
			if (lang == null)
				continue;
			var targetX:Float = lang.x;
			lang.x = -lang.width - 140;
			lang.alpha = 0;
			FlxTween.tween(lang, {x: targetX}, INTRO_DURATION, {ease: FlxEase.cubeInOut, startDelay: 0.02 * Math.max(0, lang.targetY + 1)});
			FlxTween.tween(lang, {alpha: lang.targetY == 0 ? 1 : 0.6}, INTRO_DURATION,
				{ease: FlxEase.cubeInOut, startDelay: 0.02 * Math.max(0, lang.targetY + 1)});
		}

		if (descBox != null)
		{
			descBox.alpha = 0;
			FlxTween.tween(descBox, {alpha: 0.84}, INTRO_DESC_DURATION, {ease: FlxEase.cubeInOut, startDelay: 0.08});
		}

		if (descText != null)
		{
			descText.alpha = 0;
			FlxTween.tween(descText, {alpha: 1}, INTRO_DESC_DURATION, {ease: FlxEase.cubeInOut, startDelay: 0.1});
		}

		new FlxTimer().start(0.4, function(_) playingIntroTransition = false);
	}

	function startCloseTransition(reloadState:Bool):Void
	{
		if (closingTransition)
			return;

		closingTransition = true;

		for (lang in grpLanguages.members)
		{
			if (lang == null)
				continue;
			FlxTween.cancelTweensOf(lang);
			FlxTween.tween(lang, {x: -lang.width - 140, alpha: 0}, OUTRO_DURATION, {ease: FlxEase.cubeInOut});
		}

		if (descBox != null)
		{
			FlxTween.cancelTweensOf(descBox);
			FlxTween.tween(descBox, {alpha: 0}, OUTRO_DURATION - 0.08, {ease: FlxEase.cubeInOut});
		}

		if (descText != null)
		{
			FlxTween.cancelTweensOf(descText);
			FlxTween.tween(descText, {alpha: 0}, OUTRO_DURATION - 0.08, {ease: FlxEase.cubeInOut});
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

	function changeSelected(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, languages.length - 1);
		for (num => lang in grpLanguages)
		{
			lang.targetY = num - curSelected;
			lang.alpha = 0.6;
			if (num == curSelected)
				lang.alpha = 1;
		}
		updateExampleText();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	function updateExampleText()
	{
		if (descText == null)
			return; // Verificación de seguridad

		if (languages.length > 0 && curSelected >= 0 && curSelected < languages.length)
		{
			var currentLang = languages[curSelected];
			var exampleString = Language.getPhraseForLanguage(currentLang, 'language_example_text', getExampleTextForLanguage(currentLang));
			var fontName = Language.getPhraseForLanguage(currentLang, 'language_font', getFontForLanguage(currentLang));
			descText.setFormat(Paths.font(fontName), 32, OptionsMenuTheme.readableTextOn(OptionsMenuTheme.cardFill(false)), CENTER,
				FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			descText.text = exampleString;

			// Centrar el texto como en BaseOptionsMenu
			descText.screenCenter(Y);
			descText.y += 270;

			// Actualizar el fondo
			descBox.setPosition(descText.x - 10, descText.y - 10);
			descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
			descBox.updateHitbox();
		}
	}

	function getExampleTextForLanguage(langCode:String):String
	{
		return 'This is an example text in the selected language';
	}

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

