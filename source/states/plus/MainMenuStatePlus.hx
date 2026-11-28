package states.plus;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import states.AchievementsMenuState;
import states.CreditsState;
import states.FreeplayStateSelector;
import states.ModsMenuState;
import states.PlayState;
import states.StoryMenuState;
import states.TitleState;
import states.editors.MasterEditorMenu;
import options.OptionsState;
#if funkin.vis
import funkin.vis.dsp.SpectralAnalyzer;
#end
#if mobile
import mobile.backend.MobileScaleMode;
#end

/** Dedicated Plus menu, composed around the Nova layout rather than Psych's menu. */
class MainMenuStatePlus extends MusicBeatState
{
	public static var fnfVersion:String = '0.2.8';
	public static var plusEngineVersion:String = '1.3';
	public static var psychEngineVersion:String = '1.0.4 (' + plusEngineVersion + ')';
	public static var curSelected:Int = 0;

	static inline var MENU_SCALE:Float = 0.56;
	static inline var MENU_GAP:Float = 114;
	static inline var VIZ_COUNT:Int = 72;
	static inline var VIZ_MIN_HEIGHT:Float = 8;
	static inline var VIZ_MAX_HEIGHT:Float = 106;

	var optionShit:Array<String> = ['story_mode', 'freeplay', #if MODS_ALLOWED 'mods', #end 'credits'];
	var menuItems:FlxTypedGroup<FlxSprite>;
	var achievementItem:FlxSprite;
	var optionsItem:FlxSprite;
	var achievementCenterX:Float = 0;
	var optionsCenterX:Float = 0;
	var secondaryCenterY:Float = 0;
	var plusLogo:FlxSprite;
	var visualizer:FlxTypedGroup<FlxSprite>;
	var menuBg:FlxSprite;
	var selectionShade:FlxSprite;
	var selectedSomethin:Bool = false;
	var inputIndex:Int = 0;
	var inputIdleTime:Float = 0;
	var beatPulse:Float = 0;
	#if funkin.vis
	var analyzer:SpectralAnalyzer;
	var analyzerLevels:Array<funkin.vis.dsp.SpectralAnalyzer.Bar>;
	var analyzerSource:lime.media.AudioSource;
	var analyzerMusic:FlxSound;
	var analyzerPending:Bool = true;
	#end
	var vizCurrent:Array<Float> = [];
	var vizTarget:Array<Float> = [];

	override function create()
	{
		super.create();
		FlxG.camera.zoom = 1;
		FlxG.camera.angle = 0;
		Mods.loadTopMod();
		persistentUpdate = persistentDraw = true;
		#if DISCORD_ALLOWED
		DiscordClient.changePresence(Language.getPhrase('states.main_menu.presence', 'In the Menus'), null);
		#end

		menuBg = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		menuBg.antialiasing = ClientPrefs.data.antialiasing;
		menuBg.scrollFactor.set();
		menuBg.setGraphicSize(Std.int(menuBg.width * 1.175));
		menuBg.updateHitbox();
		menuBg.screenCenter();
		menuBg.color = FlxColor.WHITE;
		add(menuBg);
		selectionShade = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		selectionShade.scrollFactor.set();
		selectionShade.alpha = 0;
		add(selectionShade);

		createVisualizer();
		createLogo();
		createMenuItems();
		createWatermarks();
		changeItem(0, false);
		animateEntrance();

		#if ACHIEVEMENTS_ALLOWED
		var date = Date.now();
		if (date.getDay() == 5 && date.getHours() >= 18)
			Achievements.unlock('friday_night_play');
		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end
		#if !mobile
		FlxG.mouse.visible = true;
		#else
		FlxG.mouse.visible = false;
		#end
		addTouchPad('NONE', 'E_X');
	}

	function createLogo():Void
	{
		plusLogo = new FlxSprite();
		plusLogo.frames = Paths.getSparrowAtlas('logoBumpin');
		plusLogo.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		plusLogo.animation.play('bump');
		plusLogo.antialiasing = ClientPrefs.data.antialiasing;
		plusLogo.setGraphicSize(Std.int(Math.min(660, FlxG.width * 0.51)));
		plusLogo.updateHitbox();
		plusLogo.x = FlxG.width - plusLogo.width - 46;
		plusLogo.y = (FlxG.height - plusLogo.height) * 0.5 - 8;
		add(plusLogo);
	}

	function createMenuItems():Void
	{
		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);
		for (i in 0...optionShit.length)
		{
			var item = createItem(optionShit[i]);
			item.scale.set(MENU_SCALE, MENU_SCALE);
			item.updateHitbox();
			item.x = 92;
			item.y = 108 + i * MENU_GAP;
			item.ID = i;
			menuItems.add(item);
		}
		#if ACHIEVEMENTS_ALLOWED
		achievementItem = createItem('achievements');
		achievementItem.scale.set(0.58, 0.58);
		achievementItem.updateHitbox();
		achievementItem.x = 92;
		achievementItem.y = 108 + optionShit.length * MENU_GAP + 6;
		achievementCenterX = achievementItem.x + achievementItem.width * 0.5;
		secondaryCenterY = achievementItem.y + achievementItem.height * 0.5;
		add(achievementItem);
		#end
		optionsItem = createItem('options');
		optionsItem.scale.set(0.58, 0.58);
		optionsItem.updateHitbox();
		optionsItem.x = 92 + (achievementItem != null ? achievementItem.width + 20 : 0);
		optionsItem.y = 108 + optionShit.length * MENU_GAP + 6;
		optionsCenterX = optionsItem.x + optionsItem.width * 0.5;
		if (achievementItem == null)
			secondaryCenterY = optionsItem.y + optionsItem.height * 0.5;
		add(optionsItem);
	}

	function createItem(name:String):FlxSprite
	{
		var item = new FlxSprite();
		item.frames = Paths.getSparrowAtlas('mainmenu/menu_$name');
		item.animation.addByPrefix('idle', '$name idle', 24, true);
		item.animation.addByPrefix('selected', '$name selected', 24, true);
		item.animation.play('idle');
		item.antialiasing = ClientPrefs.data.antialiasing;
		item.scrollFactor.set();
		item.updateHitbox();
		return item;
	}

	function createVisualizer():Void
	{
		visualizer = new FlxTypedGroup<FlxSprite>();
		var slotWidth:Float = FlxG.width / VIZ_COUNT;
		var barWidth:Int = Std.int(Math.max(2, slotWidth - 10));
		for (i in 0...VIZ_COUNT)
		{
			var bar = new FlxSprite(i * slotWidth + (slotWidth - barWidth) * 0.5, FlxG.height - 2).makeGraphic(barWidth, 1, FlxColor.WHITE);
			bar.origin.set(0, 1);
			bar.alpha = 0.70;
			visualizer.add(bar);
			vizCurrent.push(VIZ_MIN_HEIGHT);
			vizTarget.push(VIZ_MIN_HEIGHT);
		}
		add(visualizer);
	}

	function createWatermarks():Void
	{
		var plusVer = new FlxText(safeX(12), FlxG.height - 66, 0, 'Plus Engine v' + plusEngineVersion, 16);
		plusVer.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		plusVer.scrollFactor.set();
		add(plusVer);
		var fnfVer = new FlxText(safeX(16), FlxG.height - 42, 0, "Friday Night Funkin' v" + fnfVersion, 16);
		fnfVer.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		fnfVer.scrollFactor.set();
		add(fnfVer);
	}

	function animateEntrance():Void
	{
		for (i in 0...menuItems.length)
		{
			var item = menuItems.members[i];
			var targetX = item.x;
			item.x = -item.width - 30;
			item.alpha = 0;
			FlxTween.tween(item, {x: targetX, alpha: 1}, 0.46 + i * 0.08, {ease: FlxEase.backOut});
		}
		for (item in [achievementItem, optionsItem])
		{
			if (item == null) continue;
			var targetX = item.x;
			item.x = -item.width - 30;
			item.alpha = 0;
			FlxTween.tween(item, {x: targetX, alpha: 1}, 0.58, {ease: FlxEase.cubeOut});
		}
		var targetLogoX = plusLogo.x;
		plusLogo.x = FlxG.width + 60;
		plusLogo.alpha = 0;
		FlxTween.tween(plusLogo, {x: targetLogoX, alpha: 1}, 0.62, {ease: FlxEase.backOut});
	}

	override function update(elapsed:Float):Void
	{
		if (FlxG.sound.music != null)
		{
			Conductor.songPosition = FlxG.sound.music.time;
			if (FlxG.sound.music.volume < 0.8) FlxG.sound.music.volume = Math.min(0.8, FlxG.sound.music.volume + elapsed * 0.5);
		}
		updateVisualizer(elapsed);
		beatPulse = Math.max(0, beatPulse - elapsed * 2.8);
		if (!selectedSomethin)
		{
			updateMouseSelection(elapsed);
			if (controls.UI_UP_P) changeItem(-1);
			else if (controls.UI_DOWN_P) changeItem(1);
			if (controls.ACCEPT) selectCurrent();
			else if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(backend.ScriptableState.tryCreateLazy('TitleState', function() return new TitleState()));
			}
			else if (controls.justPressed('debug_1') || (touchPad != null && touchPad.buttonE.justPressed))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(backend.ScriptableState.tryCreate('MasterEditorMenu', new MasterEditorMenu()));
			}
		}
		super.update(elapsed);
	}

	function updateMouseSelection(elapsed:Float):Void
	{
		var moved = FlxG.mouse.deltaViewX != 0 || FlxG.mouse.deltaViewY != 0 || FlxG.mouse.justPressed;
		if (!moved)
		{
			inputIdleTime += elapsed;
			if (inputIdleTime > 2) FlxG.mouse.visible = false;
			return;
		}
		inputIdleTime = 0;
		FlxG.mouse.visible = true;
		for (item in menuItems)
			if (FlxG.mouse.overlaps(item) && inputIndex != item.ID) { inputIndex = item.ID; changeItem(0); }
		#if ACHIEVEMENTS_ALLOWED
		if (achievementItem != null && FlxG.mouse.overlaps(achievementItem) && inputIndex != optionShit.length)
		{
			inputIndex = optionShit.length;
			changeItem(0);
		}
		#end
		if (optionsItem != null && FlxG.mouse.overlaps(optionsItem) && inputIndex != navigationLength() - 1)
		{
			inputIndex = navigationLength() - 1;
			changeItem(0);
		}
		if (FlxG.mouse.justPressed) selectCurrent();
	}

	function navigationLength():Int return optionShit.length + 1 #if ACHIEVEMENTS_ALLOWED + 1 #end;

	function centerSecondaryItem(item:FlxSprite, centerX:Float):Void
	{
		if (item == null)
			return;
		item.updateHitbox();
		item.x = centerX - item.width * 0.5;
		item.y = secondaryCenterY - item.height * 0.5;
	}

	function selectedItem():FlxSprite
	{
		if (inputIndex < optionShit.length) return menuItems.members[inputIndex];
		#if ACHIEVEMENTS_ALLOWED
		if (inputIndex == optionShit.length) return achievementItem;
		#end
		return optionsItem;
	}

	function changeItem(change:Int, ?playSound:Bool = true):Void
	{
		inputIndex = FlxMath.wrap(inputIndex + change, 0, navigationLength() - 1);
		curSelected = FlxMath.wrap(inputIndex, 0, optionShit.length - 1);
		if (playSound) FlxG.sound.play(Paths.sound('scrollMenu'));
		for (item in menuItems)
		{
			item.animation.play(item.ID == inputIndex ? 'selected' : 'idle');
			item.alpha = item.ID == inputIndex ? 1 : 0.74;
		}
		#if ACHIEVEMENTS_ALLOWED
		if (achievementItem != null)
		{
			achievementItem.animation.play(inputIndex == optionShit.length ? 'selected' : 'idle');
			centerSecondaryItem(achievementItem, achievementCenterX);
		}
		#end
		if (optionsItem != null)
		{
			optionsItem.animation.play(inputIndex == navigationLength() - 1 ? 'selected' : 'idle');
			centerSecondaryItem(optionsItem, optionsCenterX);
		}
	}

	function currentOption():String
	{
		if (inputIndex < optionShit.length) return optionShit[inputIndex];
		#if ACHIEVEMENTS_ALLOWED
		if (inputIndex == optionShit.length) return 'achievements';
		#end
		return 'options';
	}

	function selectCurrent():Void
	{
		var item = selectedItem();
		if (item == null || selectedSomethin) return;
		selectedSomethin = true;
		FlxG.sound.play(Paths.sound('confirmMenu'));
		FlxTween.cancelTweensOf(selectionShade);
		FlxTween.tween(selectionShade, {alpha: 1}, 0.42, {ease: FlxEase.quadOut});
		for (candidate in menuItems)
			if (candidate != item) FlxTween.tween(candidate, {alpha: 0, x: -candidate.width - 40}, 0.34, {ease: FlxEase.cubeIn});
		for (candidate in [achievementItem, optionsItem])
			if (candidate != null && candidate != item) FlxTween.tween(candidate, {alpha: 0}, 0.22, {ease: FlxEase.quadOut});
		FlxTween.tween(plusLogo, {alpha: 0, x: FlxG.width + plusLogo.width}, 0.42, {ease: FlxEase.cubeIn});
		for (bar in visualizer)
			if (bar != null) FlxTween.tween(bar, {alpha: 0}, 0.28, {ease: FlxEase.quadOut});
		var isPrimaryOption:Bool = inputIndex < optionShit.length;
		if (isPrimaryOption)
		{
			FlxTween.tween(item.scale, {x: 0.94, y: 0.94}, 0.56, {ease: FlxEase.backInOut});
			FlxTween.tween(item, {x: FlxG.width * 0.5 - item.width * 0.5, y: FlxG.height * 0.5 - item.height * 0.5}, 0.56,
				{ease: FlxEase.backInOut});
		}
		if (isPrimaryOption)
		{
			FlxTween.cancelTweensOf(FlxG.camera);
			FlxTween.tween(FlxG.camera, {zoom: 1.28}, 0.56, {
				ease: FlxEase.cubeInOut,
				onComplete: function(_) switchOption(currentOption())
			});
		}
		else
			new FlxTimer().start(0.56, function(_) switchOption(currentOption()));
	}

	function switchOption(option:String):Void
	{
		switch (option)
		{
			case 'story_mode': MusicBeatState.switchState(backend.ScriptableState.tryCreateLazy('StoryMenuState', function() return new StoryMenuState()));
			case 'freeplay': MusicBeatState.switchState(FreeplayStateSelector.create());
			#if MODS_ALLOWED
			case 'mods': MusicBeatState.switchState(backend.ScriptableState.tryCreateLazy('ModsMenuState', function() return new ModsMenuState()));
			#end
			#if ACHIEVEMENTS_ALLOWED
			case 'achievements': MusicBeatState.switchState(backend.ScriptableState.tryCreateLazy('AchievementsMenuState', function() return new AchievementsMenuState()));
			#end
			case 'credits': MusicBeatState.switchState(backend.ScriptableState.tryCreateLazy('CreditsState', function() return new CreditsState()));
			case 'options':
				OptionsState.onPlayState = false;
				if (PlayState.SONG != null)
				{
					Reflect.setField(PlayState.SONG, 'arrowSkin', null);
					Reflect.setField(PlayState.SONG, 'splashSkin', null);
				}
				MusicBeatState.switchState(backend.ScriptableState.tryCreateLazy('OptionsState', function() return new OptionsState()));
			default: selectedSomethin = false;
		}
	}

	function updateVisualizer(elapsed:Float):Void
	{
		#if funkin.vis
		if (FlxG.sound.music != analyzerMusic)
		{
			analyzerMusic = FlxG.sound.music;
			analyzer = null;
			analyzerLevels = null;
			analyzerSource = null;
			analyzerPending = analyzerMusic != null;
		}
		if (analyzerPending && analyzerMusic != null && analyzerMusic.playing)
		{
			@:privateAccess if (analyzerMusic._channel != null && analyzerMusic._channel.__audioSource != null)
			{
				analyzerSource = backend.AssetLoader.analyzerSource(analyzerMusic._channel.__audioSource);
				if (analyzerSource != null)
				{
					analyzer = new SpectralAnalyzer(analyzerSource, VIZ_COUNT, 0.08, 25);
					analyzer.minFreq = 40;
					analyzer.maxFreq = 18000;
					analyzer.minDb = -80;
					analyzer.maxDb = -15;
					#if mobile
					analyzer.fftN = 256;
					#elseif !web
					analyzer.fftN = 512;
					#end
				}
				analyzerPending = false;
			}
		}
		if (analyzer != null)
		{
			try analyzerLevels = analyzer.getLevels(analyzerLevels) catch (_:Dynamic) analyzer = null;
			for (i in 0...VIZ_COUNT)
			{
				var level = analyzerLevels != null && i < analyzerLevels.length ? analyzerLevels[i].value : 0.0;
				vizTarget[i] = VIZ_MIN_HEIGHT + Math.pow(Math.max(0, level), 0.76) * (VIZ_MAX_HEIGHT - VIZ_MIN_HEIGHT);
			}
		}
		else
		#end
		{
			for (i in 0...VIZ_COUNT) vizTarget[i] = VIZ_MIN_HEIGHT + beatPulse * (20 + (i % 5) * 5);
		}
		var blend = 1 - Math.exp(-elapsed * 16);
		for (i in 0...VIZ_COUNT)
		{
			var bar = visualizer.members[i];
			vizCurrent[i] = FlxMath.lerp(vizTarget[i], vizCurrent[i], 1 - blend);
			bar.scale.y = Math.max(1, vizCurrent[i]);
			bar.y = FlxG.height - 2;
			bar.color = FlxColor.interpolate(0xFF9B7BFF, FlxColor.WHITE, i / (VIZ_COUNT - 1));
		}
	}

	override function beatHit():Void
	{
		super.beatHit();
		if (selectedSomethin)
			return;
		beatPulse = 1;
		if (plusLogo != null) plusLogo.animation.play('bump', true);
		for (item in menuItems)
		{
			if (item == null) continue;
			FlxTween.cancelTweensOf(item.scale);
			item.scale.set(MENU_SCALE + 0.025, MENU_SCALE + 0.025);
			FlxTween.tween(item.scale, {x: MENU_SCALE, y: MENU_SCALE}, 0.38, {ease: FlxEase.cubeOut});
		}
	}
}
