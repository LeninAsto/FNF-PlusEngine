package options;

import objects.Note;
import objects.StrumNote;
import objects.NoteSplash;

class VisualsSettingsSubState extends BaseOptionsMenu
{
	var noteOptionID:Int = -1;
	var noteSkinOption:Option = null;
	var splashSkinOption:Option = null;
	var themeModeOption:Option = null;
	var accentColorOption:Option = null;
	var notes:FlxTypedGroup<StrumNote>;
	var splashes:FlxTypedGroup<NoteSplash>;
	var noteY:Float = 90;
	var lastNonCustomAccent:String = 'Purple';

	public function new()
	{
		title = Language.getPhrase('visuals_menu', 'Visuals Settings');
		rpcTitle = 'Visuals Settings Menu'; // for Discord Rich Presence
		lastNonCustomAccent = OptionsMenuTheme.normalizeAccent(ClientPrefs.data.menuAccentColor);
		if (lastNonCustomAccent == 'Custom')
			lastNonCustomAccent = 'Purple';

		// for note skins and splash skins
		notes = new FlxTypedGroup<StrumNote>();
		splashes = new FlxTypedGroup<NoteSplash>();
		for (i in 0...Note.colArray.length)
		{
			var note:StrumNote = new StrumNote(370 + (560 / Note.colArray.length) * i, -200, i, 0);
			changeNoteSkin(note);
			notes.add(note);

			var splash:NoteSplash = new NoteSplash(0, 0, NoteSplash.resolveNoteSplashPath(null, PlayState.isPixelStage));
			splash.inEditor = true;
			splash.babyArrow = note;
			splash.ID = i;
			splash.kill();
			splashes.add(splash);
		}

		// options
		var noteRgbOption:Option = new Option('Use Note RGB', 'If enabled, notes use RGB palette colors. If disabled, note colors use HSL offsets.',
			'noteRGB', BOOL);
		addOption(noteRgbOption);
		noteRgbOption.onChange = onChangeNoteRGBMode;

		var noteSkins:Array<String> = getNoteSkinsList();
		if (noteSkins.length > 0)
		{
			ClientPrefs.data.noteSkin = resolveStringOptionValue(noteSkins, ClientPrefs.data.noteSkin, ClientPrefs.defaultData.noteSkin);
			var option:Option = new Option('Note Skins:', "Select your prefered Note skin.", 'noteSkin', STRING, noteSkins);
			addOption(option);
			option.onChange = onChangeNoteSkin;
			noteSkinOption = option;
			noteOptionID = optionsArray.length - 1;
		}

		var noteSplashes:Array<String> = getSplashSkinsList();
		if (noteSplashes.length > 0)
		{
			ClientPrefs.data.splashSkin = resolveStringOptionValue(noteSplashes, ClientPrefs.data.splashSkin, ClientPrefs.defaultData.splashSkin);
			var option:Option = new Option('Note Splashes:', "Select your prefered Note Splash variation.", 'splashSkin', STRING, noteSplashes);
			addOption(option);
			option.onChange = onChangeSplashSkin;
			splashSkinOption = option;
		}

		var option:Option = new Option('Note Splash Opacity', 'How much transparent should the Note Splashes be.', 'splashAlpha', PERCENT);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);
		option.onChange = playNoteSplashes;

		var option:Option = new Option('Hide HUD', 'If checked, hides most HUD elements.', 'hideHud', BOOL);
		addOption(option);

		var option:Option = new Option('Hide Sustain Splash', 'If checked, hides Sustain Splash', 'hideSustainSplash', BOOL);
		addOption(option);

		var option:Option = new Option('Show Key Viewer', 'If checked, shows a key viewer displaying which keys are being pressed.', 'showKeyViewer', BOOL);
		addOption(option);

		var option:Option = new Option('Key Viewer Color:', 'Select the color for the key viewer buttons.', 'keyViewerColor', STRING, [
			'Gray', 'Red', 'Blue', 'Green', 'Purple', 'Orange', 'Pink', 'Cyan', 'White', 'Black'
		]);
		addOption(option);
		option.onChange = onChangeKeyViewerColor;

		var option:Option = new Option('Accent Color:', 'Choose a preset accent color or open the custom color picker.', 'menuAccentColor', STRING,
			OptionsMenuTheme.ACCENT_CHOICES.copy(), 'accent_color');
		addOption(option);
		option.onChange = onChangeAccentColor;
		accentColorOption = option;

		var option:Option = new Option('Time Bar:', "What should the Time Bar display?", 'timeBarType', STRING,
			['Time Left', 'Time Elapsed', 'Song Name', 'Disabled']);
		addOption(option);

		var option:Option = new Option('Gradient Time Bar', "If checked, the time bar will be shaded according to the color of the character icon.",
			'shadedTimeBar', BOOL);
		addOption(option);

		var option:Option = new Option('Flashing Lights', "Uncheck this if you're sensitive to flashing lights!", 'flashing', BOOL);
		addOption(option);

		var option:Option = new Option('Camera Zooms', "If unchecked, the camera won't zoom in on a beat hit.", 'camZooms', BOOL);
		addOption(option);

		var option:Option = new Option('Score Text Grow on Hit', "If unchecked, disables the Score text growing\neverytime you hit a note.", 'scoreZoom', BOOL);
		addOption(option);

		var option:Option = new Option('Icon Bounce Type', "Changes the way the health icons bounce.", 'iconBounceType', STRING,
			['Old', 'D&B', 'NF', 'Default']);
		addOption(option);

		var option:Option = new Option('Time Text Bump', 'If unchecked, disables the time text bump animation on beat.', 'timeBump', BOOL);
		addOption(option);

		var option:Option = new Option('Show Version Text on Gameplay', 'If checked, shows the version text during gameplay.', 'versionTextOnGameplay', BOOL);
		addOption(option);

		var option:Option = new Option('Abbreviate Score', 'If enabled, the score will be abbreviated (e.g. 10.00K, 1.00M).', 'abbreviateScore', BOOL);
		addOption(option);

		var option:Option = new Option('Dynamic Combo Digits',
			'If checked, the combo will appear with two digits in first combo, and only\nwhen it reaches 100 combo will it become three digits.',
			'dynamicComboDigits', BOOL);
		addOption(option);

		var option:Option = new Option('NF Rating Style', 'If checked, ratings and combo numbers bop in place instead of flying/fading.', 'nfRatingStyle',
			BOOL);
		addOption(option);

		var option:Option = new Option('Health Bar Opacity', 'How much transparent should the health bar and icons be.', 'healthBarAlpha', PERCENT);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		var option:Option = new Option('Smooth Health Bar', 'If checked, the health bar will move smoothly instead of instantly.', 'smoothHealthBar', BOOL);
		addOption(option);

		var option:Option = new Option('Health Bar Overflow', 'If checked, health can exceed the bar limit and icons can move outside the edges.',
			'smoothHPBug', BOOL);
		addOption(option);

		var option:Option = new Option('Show Watermark', 'If checked, shows the watermark on screen.', 'showWatermark', BOOL);
		addOption(option);
		option.onChange = onChangeWatermark;

		var option:Option = new Option('Pause Music:', "What song do you prefer for the Pause Screen?", 'pauseMusic', STRING,
			['None', 'Tea Time', 'Breakfast', 'Breakfast (Pico)']);
		addOption(option);
		option.onChange = onChangePauseMusic;

		#if CHECK_FOR_UPDATES
		var option:Option = new Option('Check for Updates', 'On Release builds, turn this on to check for updates when you start the game.',
			'checkForUpdates', BOOL);
		addOption(option);
		#end

		#if DISCORD_ALLOWED
		var option:Option = new Option('Discord Rich Presence',
			"Uncheck this to prevent accidental leaks, it will hide the Application from your \"Playing\" box on Discord", 'discordRPC', BOOL);
		addOption(option);
		#end

		var option:Option = new Option('Combo Stacking',
			"If unchecked, Ratings and Combo won't stack, saving on System Memory and making them easier to read", 'comboStacking', BOOL);
		addOption(option);

		var option:Option = new Option('Show Rating Sprite', 'If unchecked, hides the rating sprite popup when hitting notes.', 'showRating', BOOL);
		addOption(option);
		option.onChange = syncPopupVisibility;

		var option:Option = new Option('Show Combo Sprite', 'If unchecked, hides the COMBO sprite popup when hitting notes.', 'showCombo', BOOL);
		addOption(option);
		option.onChange = syncPopupVisibility;

		var option:Option = new Option('Show Combo Numbers', 'If unchecked, hides combo number popups when hitting notes.', 'showComboNum', BOOL);
		addOption(option);
		option.onChange = syncPopupVisibility;

		var option:Option = new Option('Show Early/Late Sprites',
			'Shows Early or Late tags on the top corners of the rating sprite depending on hit timing.', 'showEarlyLateSprites', BOOL);
		addOption(option);
		option.onChange = syncPopupVisibility;

		var option:Option = new Option('Show Hit MS', 'Shows the millisecond timing error next to judgement popups.', 'showHitMs', BOOL);
		addOption(option);
		option.onChange = syncPopupVisibility;

		var option:Option = new Option('Combo and Rating in camGame',
			'If enabled, Combo and Ratings will be rendered in the camGame layer instead of camHUD.', 'comboInGame', BOOL);
		addOption(option);
		option.onChange = function()
		{
			// Cambia la cámara en tiempo real si el usuario cambia la opción desde el menú
			if (PlayState.instance != null && PlayState.instance.comboGroup != null)
			{
				PlayState.instance.comboGroup.cameras = [
					ClientPrefs.data.comboInGame ? PlayState.instance.camGame : PlayState.instance.camHUD
				];
			}
		};

		var option:Option = new Option('Judgement Counter', 'Show the judgement counter during gameplay.', 'judgementCounter', BOOL);
		addOption(option);

		var option:Option = new Option('Show End Countdown', 'If checked, shows a countdown in the last seconds of the song.', 'showEndCountdown', BOOL);
		addOption(option);

		var option:Option = new Option('End Countdown Seconds', 'How many seconds before the song ends the countdown appears (10-30).', 'endCountdownSeconds',
			INT);
		option.displayFormat = '%vs';
		option.scrollSpeed = 1;
		option.minValue = 10;
		option.maxValue = 30;
		option.changeValue = 1;
		option.decimals = 0;
		addOption(option);

		var option:Option = new Option('Pause Countdown', 'If checked, resuming from pause plays a countdown similar to the intro countdown.',
			'pauseCountdown', BOOL);
		addOption(option);

		var option:Option = new Option('Hey Intro', 'If checked, BF and GF automatically do the Hey! animation when the countdown says Go!', 'heyIntro', BOOL);
		addOption(option);

		var option:Option = new Option('Break Timer', 'If checked, a timer appears when the next notes are still far away.', 'breakTimer', BOOL);
		addOption(option);

		#if windows
		var option:Option = new Option('Change Window Border Color With Note Hit',
			'Can change the color of the window border when you hit a note.\\n(Only for Windows 11, sry)', 'changeWindowBorderColorWithNoteHit', BOOL);
		addOption(option);
		#end

		super();
		add(notes);
		add(splashes);
		setPreviewActive(false);
	}

	var notesShown:Bool = false;
	var lastPreviewVariable:String = null;

	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);

		var previewVariable:String = curOption != null ? curOption.variable : null;
		var shouldShowPreview:Bool = previewVariable == 'noteSkin' || previewVariable == 'splashSkin' || previewVariable == 'splashAlpha';

		if (shouldShowPreview)
		{
			setPreviewActive(true);
			if (!notesShown)
			{
				for (note in notes.members)
				{
					if (note == null)
						continue;
					FlxTween.cancelTweensOf(note);
					FlxTween.tween(note, {y: noteY}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
				}
			}
			notesShown = true;
			if (previewVariable != lastPreviewVariable && previewVariable.startsWith('splash') && notes.members[0] != null && Math.abs(notes.members[0].y - noteY) < 25)
				playNoteSplashes();
		}
		else
		{
			if (notesShown)
			{
				for (note in notes.members)
				{
					if (note == null)
						continue;
					FlxTween.cancelTweensOf(note);
					FlxTween.tween(note, {y: -200}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
				}
				hideNoteSplashes();
			}
			notesShown = false;
		}

		lastPreviewVariable = previewVariable;
	}

	var changedMusic:Bool = false;

	function onChangePauseMusic()
	{
		if (ClientPrefs.data.pauseMusic == 'None')
			FlxG.sound.music.volume = 0;
		else
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)));

		changedMusic = true;
	}

	function onChangeNoteSkin()
	{
		notes.forEachAlive(function(note:StrumNote)
		{
			changeNoteSkin(note);
			note.centerOffsets();
			note.centerOrigin();
		});
	}

	function onChangeNoteRGBMode()
	{
		Note.globalRgbShaders = [];
		refreshNoteSkinOptionList();
		refreshSplashSkinOptionList();
		onChangeNoteSkin();
		onChangeSplashSkin();
	}

	function changeNoteSkin(note:StrumNote)
	{
		var skin:String = Note.resolveNoteSkinPath(null, PlayState.isPixelStage);

		note.texture = skin; // Load texture and anims (setter calls reloadNote automatically)
		note.playAnim('static');

		// Verificar si el skin es NotITG
		note.checkNotITGSkin();
	}

	function getNoteSkinsList():Array<String>
	{
		var preferred:String = ClientPrefs.data.noteRGB ? 'images/noteSkins/list.txt' : 'images/noteSkinsNoRGB/list.txt';
		var fallback:String = ClientPrefs.data.noteRGB ? 'images/noteSkinsNoRGB/list.txt' : 'images/noteSkins/list.txt';
		return buildSkinOptionList(preferred, fallback, ClientPrefs.defaultData.noteSkin);
	}

	function getSplashSkinsList():Array<String>
	{
		var preferred:String = ClientPrefs.data.noteRGB ? 'images/noteSplashes/list.txt' : 'images/noteSplashesNoRGB/list.txt';
		var fallback:String = ClientPrefs.data.noteRGB ? 'images/noteSplashesNoRGB/list.txt' : 'images/noteSplashes/list.txt';
		return buildSkinOptionList(preferred, fallback, ClientPrefs.defaultData.splashSkin);
	}

	function buildSkinOptionList(preferredPath:String, fallbackPath:String, defaultValue:String):Array<String>
	{
		var list:Array<String> = [];
		addSkinOption(list, defaultValue);

		var preferred:Array<String> = Mods.mergeAllTextsNamed(preferredPath);
		for (value in preferred)
			addSkinOption(list, value);

		if (list.length <= 1)
		{
			var fallback:Array<String> = Mods.mergeAllTextsNamed(fallbackPath);
			for (value in fallback)
				addSkinOption(list, value);
		}
		return list;
	}

	function addSkinOption(list:Array<String>, value:String):Void
	{
		if (value == null)
			return;
		value = value.trim();
		if (value.length > 0 && !list.contains(value))
			list.push(value);
	}

	function resolveStringOptionValue(list:Array<String>, current:String, defaultValue:String):String
	{
		if (list.contains(current))
			return current;
		if (list.contains(defaultValue))
			return defaultValue;
		return list.length > 0 ? list[0] : defaultValue;
	}

	function refreshStringOptionVisual(option:Option)
	{
		if (option == null || option.child == null)
			return;
		option.text = option.displayFormat.replace('%v', option.getValue()).replace('%d', option.defaultValue);
	}

	function refreshNoteSkinOptionList()
	{
		if (noteSkinOption == null)
			return;
		var noteSkins:Array<String> = getNoteSkinsList();
		if (noteSkins.length <= 0)
			return;
		noteSkinOption.options = noteSkins;
		var resolved:String = resolveStringOptionValue(noteSkins, ClientPrefs.data.noteSkin, ClientPrefs.defaultData.noteSkin);
		noteSkinOption.curOption = noteSkins.indexOf(resolved);
		if (noteSkinOption.curOption < 0)
			noteSkinOption.curOption = 0;
		noteSkinOption.setValue(resolved);
		refreshStringOptionVisual(noteSkinOption);
	}

	function refreshSplashSkinOptionList()
	{
		if (splashSkinOption == null)
			return;
		var splashSkins:Array<String> = getSplashSkinsList();
		if (splashSkins.length <= 0)
			return;
		splashSkinOption.options = splashSkins;
		var resolved:String = resolveStringOptionValue(splashSkins, ClientPrefs.data.splashSkin, ClientPrefs.defaultData.splashSkin);
		splashSkinOption.curOption = splashSkins.indexOf(resolved);
		if (splashSkinOption.curOption < 0)
			splashSkinOption.curOption = 0;
		splashSkinOption.setValue(resolved);
		refreshStringOptionVisual(splashSkinOption);
	}

	function onChangeSplashSkin()
	{
		var skin:String = NoteSplash.resolveNoteSplashPath(null, PlayState.isPixelStage);
		for (splash in splashes)
			splash.loadSplash(skin);

		playNoteSplashes();
	}

	function playNoteSplashes()
	{
		if (!notesShown)
			return;

		var rand:Int = 0;
		if (splashes.members[0] != null && splashes.members[0].maxAnims > 1)
			rand = FlxG.random.int(0, splashes.members[0].maxAnims - 1); // For playing the same random animation on all 4 splashes

		for (splash in splashes)
		{
			splash.revive();

			splash.spawnSplashNote(0, 0, splash.ID, null, false);
			if (splash.maxAnims > 1)
				splash.noteData = splash.noteData % Note.colArray.length + (rand * Note.colArray.length);

			var anim:String = splash.playDefaultAnim();
			var conf = splash.config.animations.get(anim);
			var offsets:Array<Float> = [0, 0];

			var minFps:Int = 22;
			var maxFps:Int = 26;
			if (conf != null)
			{
				offsets = conf.offsets;

				minFps = conf.fps[0];
				if (minFps < 0)
					minFps = 0;

				maxFps = conf.fps[1];
				if (maxFps < 0)
					maxFps = 0;
			}

			splash.offset.set(10, 10);
			if (offsets != null)
			{
				splash.offset.x += offsets[0];
				splash.offset.y += offsets[1];
			}

			if (splash.animation.curAnim != null)
				splash.animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);
		}
	}

	function hideNoteSplashes():Void
	{
		for (splash in splashes)
		{
			if (splash == null)
				continue;
			FlxTween.cancelTweensOf(splash);
			splash.kill();
		}
		splashes.visible = false;
		splashes.active = false;
	}

	function setPreviewActive(value:Bool):Void
	{
		if (notes != null)
		{
			notes.visible = value;
			notes.active = false;
		}
		if (splashes != null)
		{
			splashes.visible = value;
			splashes.active = value;
		}
	}

	function syncPopupVisibility()
	{
		if (PlayState.instance != null)
		{
			PlayState.instance.showRating = ClientPrefs.data.showRating;
			PlayState.instance.showCombo = ClientPrefs.data.showCombo;
			PlayState.instance.showComboNum = ClientPrefs.data.showComboNum;
		}
		ClientPrefs.saveSettings();
	}

	override function destroy()
	{
		if (changedMusic && !OptionsState.onPlayState)
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 1, true);
		Note.globalRgbShaders = [];
		super.destroy();
	}

	// function onChangeFPSCounter() eliminado: FPSCounter ahora siempre visible, control solo por F2

	function onChangeWatermark()
	{
		if (Main.watermarkSprite != null)
			Main.watermarkSprite.visible = ClientPrefs.data.showWatermark;
		if (Main.watermark != null)
			Main.watermark.visible = ClientPrefs.data.showWatermark;
	}

	function onChangeKeyViewerColor()
	{
		// Si estamos en PlayState, actualizar el color del keyViewer
		if (PlayState.instance != null && PlayState.instance.keyViewer != null)
		{
			PlayState.instance.keyViewer.updateKeyColors();
		}
	}

	function onChangeThemeMode()
	{
		ClientPrefs.syncThemeModeFlags();
		OptionsMenuTheme.syncAccent();
		ClientPrefs.saveSettings();
	}

	function onChangeAccentColor()
	{
		ClientPrefs.data.menuAccentColor = OptionsMenuTheme.normalizeAccent(ClientPrefs.data.menuAccentColor);
		if (ClientPrefs.data.menuAccentColor != 'Custom')
		{
			lastNonCustomAccent = ClientPrefs.data.menuAccentColor;
			OptionsMenuTheme.syncAccent();
			ClientPrefs.saveSettings();
			return;
		}

		var previousAccentChoice = lastNonCustomAccent;
		var previousCustomColor = ClientPrefs.data.menuAccentColorCustom;
		openSubState(backend.ScriptableSubstate.tryCreate('ThemeAccentColorSubState',
			new ThemeAccentColorSubState(ClientPrefs.data.menuAccentColorCustom, function(color:Int)
			{
				ClientPrefs.data.menuAccentColor = 'Custom';
				ClientPrefs.data.menuAccentColorCustom = color;
				OptionsMenuTheme.syncAccent();
			}, function()
			{
				ClientPrefs.data.menuAccentColor = 'Custom';
				OptionsMenuTheme.syncAccent();
				ClientPrefs.saveSettings();
				refreshAccentOptionVisual();
			}, function()
			{
				ClientPrefs.data.menuAccentColor = previousAccentChoice;
				ClientPrefs.data.menuAccentColorCustom = previousCustomColor;
				OptionsMenuTheme.syncAccent();
				refreshAccentOptionVisual();
				ClientPrefs.saveSettings();
			})));
	}

	function refreshAccentOptionVisual():Void
	{
		if (accentColorOption == null)
			return;
		accentColorOption.curOption = accentColorOption.options.indexOf(ClientPrefs.data.menuAccentColor);
		if (accentColorOption.curOption < 0)
			accentColorOption.curOption = 0;
		refreshStringOptionVisual(accentColorOption);
	}
}

