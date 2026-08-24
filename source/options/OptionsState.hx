package options;

import backend.StageData;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.util.FlxSpriteUtil;
import states.MainMenuState;

class OptionsState extends MusicBeatState
{
	static inline var CARD_W:Float = 500;
	static inline var CARD_H:Float = 86;
	static inline var CARD_GAP_X:Float = 24;
	static inline var CARD_GAP_Y:Float = 18;
	static inline var GRID_TOP:Float = 82;
	static inline var INTRO_DURATION:Float = 0.42;

	var options:Array<String> = [
		'Note Colors',
		'Controls',
		'Adjust Delay and Combo',
		'Graphics',
		'Visuals',
		'Gameplay',
		'Legacy',
		#if MODS_ALLOWED 'Mod Security', #end
		'VSlice',
		#if MODCHARTS_NOTITG_ALLOWED 'Modchart' #end
		#if TRANSLATIONS_ALLOWED, 'Language' #end,
		#if mobile 'Mobile' #end
	];
	#if vslice
	var vsliceOptionCategories:Map<String, Dynamic> = [];
	#end

	private var grpOptions:FlxTypedGroup<OptionCard>;
	private static var curSelected:Int = 0;

	var gridScroll:Float = 0;
	var targetScroll:Float = 0;
	var optionsIntroActive:Bool = true;
	var substateInputBlocked:Bool = false;
	var lastThemeSignature:String = "";
	var mobileTipText:FlxText;

	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;
	public static var substateVisualActive:Bool = false;
	public static var substateReturning:Bool = false;
	public static var substateAnchorX:Float = 0;
	public static var substateAnchorY:Float = 0;
	public static var substateAnchorLabel:String = null;
	public static inline var SUBSTATE_TITLE_X:Float = 75;
	public static inline var SUBSTATE_TITLE_Y:Float = 45;

	public static function clearSubstateTransition():Void
	{
		substateVisualActive = false;
		substateReturning = false;
		substateAnchorX = 0;
		substateAnchorY = 0;
		substateAnchorLabel = null;
	}

	function getDisplayLabel(label:String):String
	{
		#if vslice
		if (vsliceOptionCategories != null && vsliceOptionCategories.exists(label))
			return label;
		#end

		return switch (label)
		{
			case 'Note Colors': Language.getPhrase('notes', 'Note Colors');
			case 'Controls': Language.getPhrase('controls', 'Controls');
			case 'Graphics': Language.getPhrase('graphics_menu', 'Graphics Settings');
			case 'Visuals': Language.getPhrase('visuals_menu', 'Visual Settings');
			case 'Gameplay': Language.getPhrase('gameplay_menu', 'Gameplay Settings');
			case 'Legacy': Language.getPhrase('legacy_menu', 'Legacy Settings');
			case 'Mod Security': Language.getPhrase('mod_security_checks_menu', 'Mod Security Checks');
			case 'VSlice': Language.getPhrase('vslice_menu', 'VSlice Settings');
			case 'Modchart': Language.getPhrase('modchart_menu', 'Modchart Settings');
			case 'Language': Language.getPhrase('language_menu', 'Language');
			case 'Mobile': Language.getPhrase('mobile_settings', 'Mobile Settings');
			default: Language.getPhrase('options_$label', label);
		}
	}

	function getDescription(label:String):String
	{
		return switch (label)
		{
			case 'Note Colors': Language.getPhrase('options_desc_note_colors', 'Customize note, splash and pixel colors.');
			case 'Controls': Language.getPhrase('options_desc_controls', 'Edit keyboard, controller and mobile binds.');
			case 'Adjust Delay and Combo': Language.getPhrase('options_desc_delay_combo', 'Calibrate note offset and combo placement.');
			case 'Graphics': Language.getPhrase('options_desc_graphics', 'Tune rendering, shaders and performance.');
			case 'Visuals': Language.getPhrase('options_desc_visuals', 'Change HUD, counters, FPS and presentation.');
			case 'Gameplay': Language.getPhrase('options_desc_gameplay', 'Adjust play rules, scrolling and assist options.');
			case 'Legacy': Language.getPhrase('options_desc_legacy', 'Psych compatibility, warnings and classic behavior.');
			case 'Mod Security': Language.getPhrase('options_desc_mod_security', 'Choose which sensitive script checks are enabled.');
			case 'VSlice': Language.getPhrase('options_desc_vslice', 'Configure VSlice compatibility features.');
			case 'Modchart': Language.getPhrase('options_desc_modchart', 'Configure NotITG-style modchart behavior.');
			case 'Language': Language.getPhrase('options_desc_language', 'Choose the engine language.');
			case 'Mobile': Language.getPhrase('options_desc_mobile', 'Edit mobile controls and touch settings.');
			default: Language.getPhrase('options_desc_$label', 'Open this settings page.');
		}
	}

	function beginSubstateTransition(label:String):Void
	{
		var item:OptionCard = getSelectedCard();
		substateVisualActive = true;
		substateReturning = false;
		substateAnchorLabel = label;
		substateAnchorX = item != null ? item.x : SUBSTATE_TITLE_X;
		substateAnchorY = item != null ? item.y : SUBSTATE_TITLE_Y;
		substateInputBlocked = true;
		if (item != null)
		{
			item.setLabel(getDisplayLabel(label), getDescription(label));
			item.alpha = 0;
		}
	}

	function openSelectedSubstate(label:String)
	{
		var stop = callOnCompanionScript('onOptionsMenuAccept', [label, curSelected]);
		if (stop == Function_Stop)
			return;

		if (label != "Adjust Delay and Combo")
		{
			removeTouchPad();
			persistentUpdate = true;
			beginSubstateTransition(label);
		}

		#if vslice
		if (openVSliceOptionCategory(label))
			return;
		#end

		switch (label)
		{
			case 'Note Colors':
				if (ClientPrefs.data.noteRGB)
					openSubState(ScriptableSubstate.tryCreate('NotesColorSubState', new options.NotesColorSubState()));
				else
					openSubState(ScriptableSubstate.tryCreate('NotesColorLegacySubState', new options.NotesColorLegacySubState()));
			case 'Controls':
				openSubState(ScriptableSubstate.tryCreate('ControlsSubState', new options.ControlsSubState()));
			case 'Graphics':
				openSubState(ScriptableSubstate.tryCreate('GraphicsSettingsSubState', new options.GraphicsSettingsSubState()));
			case 'Visuals':
				openSubState(ScriptableSubstate.tryCreate('VisualsSettingsSubState', new options.VisualsSettingsSubState()));
			case 'Gameplay':
				openSubState(ScriptableSubstate.tryCreate('GameplaySettingsSubState', new options.GameplaySettingsSubState()));
			case 'Legacy':
				openSubState(ScriptableSubstate.tryCreate('LegacySettingsSubState', new options.LegacySettingsSubState()));
			case 'Mod Security':
				#if MODS_ALLOWED
				openSubState(ScriptableSubstate.tryCreate('ModSecurityChecksSubState', new options.ModSecurityChecksSubState()));
				#end
			case 'VSlice':
				openSubState(ScriptableSubstate.tryCreate('VSliceSettingsSubState', new options.VSliceSettingsSubState()));
			case 'Modchart':
				openSubState(ScriptableSubstate.tryCreate('ModchartSettingsSubState', new options.ModchartSettingsSubState()));
			case 'Adjust Delay and Combo':
				clearSubstateTransition();
				MusicBeatState.switchState(ScriptableState.tryCreate('NoteOffsetState', new options.NoteOffsetState()));
			case 'Mobile':
				#if mobile
				openSubState(ScriptableSubstate.tryCreate('MobileSettingsSubState', new mobile.options.MobileSettingsSubState()));
				#end
			case 'Language':
				openSubState(ScriptableSubstate.tryCreate('LanguageSubState', new options.LanguageSubState()));
		}
	}

	#if vslice
	function openVSliceOptionCategory(label:String):Bool
	{
		if (vsliceOptionCategories == null || !vsliceOptionCategories.exists(label))
			return false;

		var category:Dynamic = vsliceOptionCategories.get(label);
		clearSubstateTransition();
		MusicBeatState.switchState(funkin.plus.VSliceRuntime.createOptionsState(category.pageId));
		return true;
	}
	#end

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		#if vslice
		appendVSliceOptionCategories();
		#end

		OptionsMenuTheme.syncAccent();

		menuBG = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		menuBG.antialiasing = ClientPrefs.data.antialiasing;
		menuBG.setGraphicSize(FlxG.width, FlxG.height);
		menuBG.updateHitbox();
		menuBG.screenCenter();
		add(menuBG);

		if (controls.mobileC)
		{
			mobileTipText = new FlxText(150, FlxG.height - 24, 0,
				Language.getPhrase('mobile_controls_tip', 'Press {1} to Go Mobile Controls Menu', [(FlxG.onMobile ? 'C' : 'CTRL or C')]), 16);
			mobileTipText.setFormat("VCR OSD Mono", 17, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			mobileTipText.borderSize = 1.25;
			mobileTipText.scrollFactor.set();
			mobileTipText.antialiasing = ClientPrefs.data.antialiasing;
			add(mobileTipText);
		}

		grpOptions = new FlxTypedGroup<OptionCard>();
		add(grpOptions);
		rebuildOptionsVisuals();
		gridScroll = targetScroll = computeTargetScroll();
		refreshThemeVisuals(true);
		layoutCards(0, true);
		ClientPrefs.saveSettings();

		addTouchPad('UP_DOWN', 'A_B_C');

		super.create();
		callOnCompanionScript('onOptionsMenuCreatePost', [getOptionsCopy()]);
		new FlxTimer().start(INTRO_DURATION + 0.06, function(_) optionsIntroActive = false);
	}

	#if vslice
	function appendVSliceOptionCategories():Void
	{
		vsliceOptionCategories = [];
		for (category in funkin.plus.VSliceRuntime.listOptionCategories())
		{
			var label:String = 'VSlice: ${category.label}';
			if (options.contains(label))
				continue;
			options.push(label);
			vsliceOptionCategories.set(label, category);
		}
	}
	#end

	override function closeSubState()
	{
		super.closeSubState();
		ClientPrefs.saveSettings();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
		controls.isInSubstate = false;
		substateInputBlocked = false;
		substateVisualActive = false;
		substateReturning = true;
		restoreCards();
		for (item in grpOptions.members)
		{
			if (item == null)
				continue;
			item.x -= 180;
			item.alpha = 0;
		}
		removeTouchPad();
		addTouchPad('UP_DOWN', 'A_B_C');
		persistentUpdate = true;
	}

	var exiting = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (lastThemeSignature != OptionsMenuTheme.signature())
			refreshThemeVisuals(true);

		targetScroll = computeTargetScroll();
		gridScroll = FlxMath.lerp(targetScroll, gridScroll, Math.exp(-elapsed * 10.2));
		layoutCards(elapsed, false);

		var selected = getSelectedCard();
		if (substateReturning && selected != null && Math.abs(selected.x - cardTargetX(curSelected)) < 4)
			substateReturning = false;

		if (!exiting && !substateInputBlocked)
		{
			if (controls.UI_UP_P)
				changeSelection(-2);
			if (controls.UI_DOWN_P)
				changeSelection(2);
			if (controls.UI_LEFT_P)
				changeSelection(-1);
			if (controls.UI_RIGHT_P)
				changeSelection(1);

			if (touchPad.buttonC.justPressed || FlxG.keys.justPressed.CONTROL && controls.mobileC)
			{
				#if mobile
				persistentUpdate = false;
				openSubState(ScriptableSubstate.tryCreate('MobileControlSelectSubState', new mobile.substates.MobileControlSelectSubState()));
				#end
			}

			if (controls.BACK)
			{
				var stop = callOnCompanionScript('onOptionsMenuBack', [curSelected, getSelectedOptionLabel()]);
				if (stop == Function_Stop)
					return;
				exiting = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				if (onPlayState)
				{
					clearSubstateTransition();
					StageData.loadDirectory(PlayState.SONG);
					LoadingState.loadAndSwitchState(new PlayState());
					FlxG.sound.music.volume = 0;
				}
				else
				{
					clearSubstateTransition();
					MusicBeatState.switchState(new MainMenuState());
				}
			}
			else if (controls.ACCEPT && options != null && options.length > 0)
				openSelectedSubstate(options[curSelected]);
		}
	}

	function layoutCards(elapsed:Float, instant:Bool):Void
	{
		if (grpOptions == null)
			return;

		var moveLerp:Float = instant ? 0 : Math.exp(-elapsed * (optionsIntroActive ? 7.2 : 10.2));
		for (item in grpOptions.members)
		{
			if (item == null)
				continue;

			var selected:Bool = item.index == curSelected;
			var headerMode:Bool = substateVisualActive && selected;
			var targetX:Float = cardTargetX(item.index);
			var targetY:Float = cardTargetY(item.index) - gridScroll;
			var targetScale:Float = selected ? 1.035 : 1;
			var targetAlpha:Float = selected ? 1 : 0.68;

			if (substateVisualActive)
			{
				if (selected)
				{
					targetX = selectedCardTargetX();
					targetY = SUBSTATE_TITLE_Y;
					targetScale = 1;
					targetAlpha = 1;
				}
				else
				{
					targetX = -CARD_W - 120;
					targetAlpha = 0;
				}
			}
			else if (optionsIntroActive || substateReturning)
			{
				targetX = cardTargetX(item.index);
			}

			if (instant)
			{
				item.x = targetX;
				item.y = targetY;
				item.scale.set(targetScale, targetScale);
				item.alpha = optionsIntroActive ? 0 : targetAlpha;
			}
			else
			{
				item.x = FlxMath.lerp(targetX, item.x, moveLerp);
				item.y = FlxMath.lerp(targetY, item.y, moveLerp);
				item.scale.set(FlxMath.lerp(targetScale, item.scale.x, Math.exp(-elapsed * 10.2)),
					FlxMath.lerp(targetScale, item.scale.y, Math.exp(-elapsed * 10.2)));
				item.alpha = FlxMath.lerp(targetAlpha, item.alpha, moveLerp);
			}
			if (item.headerMode != headerMode)
				item.applyTheme(selected, false, headerMode);
			item.syncLayout(headerMode);
		}
	}

	function selectedCardTargetX():Float
		return (FlxG.width - CARD_W) * 0.5;

	function cardTargetX(index:Int):Float
	{
		var totalW:Float = CARD_W * 2 + CARD_GAP_X;
		var left:Float = (FlxG.width - totalW) * 0.5;
		return left + (index % 2) * (CARD_W + CARD_GAP_X);
	}

	function cardTargetY(index:Int):Float
		return GRID_TOP + Std.int(index / 2) * (CARD_H + CARD_GAP_Y);

	function computeTargetScroll():Float
	{
		var selectedY:Float = cardTargetY(curSelected);
		var target:Float = selectedY - 278;
		var rows:Int = Math.ceil(options.length / 2);
		var maxScroll:Float = Math.max(0, GRID_TOP + rows * (CARD_H + CARD_GAP_Y) - FlxG.height + 40);
		return FlxMath.bound(target, 0, maxScroll);
	}

	function changeSelection(change:Int = 0)
	{
		if (options == null || options.length == 0)
			return;

		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);
		refreshThemeVisuals(false);

		callOnCompanionScript('onOptionsMenuSelectionChange', [curSelected, getSelectedOptionLabel()]);
		if (change != 0)
			FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function refreshThemeVisuals(force:Bool = false):Void
	{
		lastThemeSignature = OptionsMenuTheme.signature();
		OptionsMenuTheme.syncAccent();

		var accent:Int = OptionsMenuTheme.current().accent;
		if (menuBG != null)
			menuBG.color = accent;

		if (grpOptions != null)
			for (item in grpOptions.members)
				if (item != null)
				{
					var selected:Bool = item.index == curSelected;
					item.applyTheme(selected, force, substateVisualActive && selected);
				}
	}

	function restoreCards():Void
	{
		if (grpOptions == null || options == null)
			return;
		for (i in 0...grpOptions.members.length)
		{
			var item = grpOptions.members[i];
			if (item != null && i < options.length)
				item.setLabel(getDisplayLabel(options[i]), getDescription(options[i]));
		}
		refreshThemeVisuals(true);
	}

	function getSelectedCard():OptionCard
		return (grpOptions != null && curSelected >= 0 && curSelected < grpOptions.members.length) ? grpOptions.members[curSelected] : null;

	public function getOptionsCopy():Array<String>
		return options != null ? options.copy() : [];

	public function getSelectedOptionIndex():Int
		return curSelected;

	public function getSelectedOptionLabel():String
		return (options != null && curSelected >= 0 && curSelected < options.length) ? options[curSelected] : null;

	public function getOptionAt(index:Int):String
		return (options != null && index >= 0 && index < options.length) ? options[index] : null;

	public function selectOption(index:Int):Void
	{
		if (options == null || options.length < 1)
			return;
		curSelected = FlxMath.wrap(index, 0, options.length - 1);
		changeSelection(0);
	}

	public function selectOptionByLabel(label:String):Bool
	{
		if (options == null || label == null)
			return false;
		var index = options.indexOf(label);
		if (index < 0)
			return false;
		selectOption(index);
		return true;
	}

	public function setOptionsList(newOptions:Array<String>):Void
	{
		options = (newOptions != null) ? newOptions.copy() : [];
		if (curSelected >= options.length)
			curSelected = Std.int(Math.max(0, options.length - 1));
		rebuildOptionsVisuals();
	}

	public function addOption(label:String):Void
	{
		if (label == null)
			return;
		if (options == null)
			options = [];
		options.push(label);
		rebuildOptionsVisuals();
	}

	public function removeOption(label:String):Bool
	{
		if (options == null || label == null)
			return false;
		var index = options.indexOf(label);
		if (index < 0)
			return false;
		options.splice(index, 1);
		if (curSelected >= options.length)
			curSelected = Std.int(Math.max(0, options.length - 1));
		rebuildOptionsVisuals();
		return true;
	}

	public function openCurrentOption():Void
	{
		var label = getSelectedOptionLabel();
		if (label != null)
			openSelectedSubstate(label);
	}

	public function rebuildOptionsVisuals():Void
	{
		if (grpOptions == null)
			return;

		while (grpOptions.members.length > 0)
		{
			var item = grpOptions.members[0];
			if (item != null)
			{
				item.kill();
				grpOptions.remove(item, true);
				item.destroy();
			}
			else
				grpOptions.members.shift();
		}

		if (options == null)
			options = [];

		for (num => option in options)
			grpOptions.add(new OptionCard(num, getDisplayLabel(option), getDescription(option), CARD_W, CARD_H));

		if (options.length > 0)
		{
			curSelected = Std.int(FlxMath.bound(curSelected, 0, options.length - 1));
			changeSelection(0);
		}
		else
			curSelected = 0;

		callOnCompanionScript('onOptionsMenuRebuild', [getOptionsCopy()]);
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}

private class OptionCard extends FlxSpriteGroup
{
	static inline var MAX_DESCRIPTION_CHARS:Int = 96;
	static inline var DOT_W:Float = 14;
	static inline var DOT_H:Float = 34;
	static inline var DOT_X:Float = 18;
	static inline var CONTENT_X:Float = 46;

	public var index(default, null):Int;
	var cardW:Float;
	var cardH:Float;
	var bg:FlxSprite;
	var title:FlxText;
	var desc:FlxText;
	var arrow:FlxText;
	public var headerMode(default, null):Bool = false;
	var lastSelected:Null<Bool> = null;
	var lastHeaderMode:Null<Bool> = null;
	var lastTheme:String = "";

	public function new(index:Int, label:String, description:String, w:Float, h:Float)
	{
		super();
		this.index = index;
		cardW = w;
		cardH = h;

		bg = new FlxSprite().makeGraphic(Std.int(cardW), Std.int(cardH), FlxColor.TRANSPARENT, true);
		add(bg);

		title = new FlxText(CONTENT_X, 14, cardW - 106, label, 22);
		title.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, LEFT);
		title.antialiasing = ClientPrefs.data.antialiasing;
		add(title);

		desc = new FlxText(CONTENT_X, 44, cardW - 106, formatDescription(description), 14);
		desc.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT);
		desc.antialiasing = ClientPrefs.data.antialiasing;
		add(desc);

		arrow = new FlxText(cardW - 48, 24, 32, ">", 26);
		arrow.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.WHITE, CENTER);
		arrow.antialiasing = ClientPrefs.data.antialiasing;
		add(arrow);
	}

	public function setLabel(label:String, description:String):Void
	{
		title.text = label;
		desc.text = formatDescription(description);
	}

	function formatDescription(value:String):String
	{
		if (value == null)
			return '';

		var text:String = value.trim();
		if (text.length <= MAX_DESCRIPTION_CHARS)
			return text;

		return text.substr(0, MAX_DESCRIPTION_CHARS - 3).trim() + '...';
	}

	public function applyTheme(selected:Bool, force:Bool = false, headerMode:Bool = false):Void
	{
		var signature = OptionsMenuTheme.signature();
		if (!force && lastSelected == selected && lastHeaderMode == headerMode && lastTheme == signature)
			return;
		lastSelected = selected;
		lastHeaderMode = headerMode;
		this.headerMode = headerMode;
		lastTheme = signature;

		var fill:Int = selected ? OptionsMenuTheme.difficultyCardFill(OptionsMenuTheme.current().accent, true) : OptionsMenuTheme.cardFill(false);
		var stroke:Int = selected ? OptionsMenuTheme.current().accent : OptionsMenuTheme.panelOutlineColor();
		bg.makeGraphic(Std.int(cardW), Std.int(cardH), FlxColor.TRANSPARENT, true);
		bg.setPosition(x, y);
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, cardW, cardH, 8, 8, fill);
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, cardW, cardH, 8, 8, FlxColor.TRANSPARENT, {thickness: selected ? 2 : 1, color: stroke});
		if (!headerMode)
			FlxSpriteUtil.drawRoundRect(bg, DOT_X, (cardH - DOT_H) * 0.5, DOT_W, DOT_H, DOT_W * 0.5, DOT_W * 0.5,
				selected ? OptionsMenuTheme.current().accent : OptionsMenuTheme.cardAccent(false));

		title.color = selected ? OptionsMenuTheme.cardTitleColor(true) : OptionsMenuTheme.cardTitleColor(false);
		desc.color = selected ? OptionsMenuTheme.cardDescriptionColor(true) : OptionsMenuTheme.cardDescriptionColor(false);
		arrow.color = selected ? OptionsMenuTheme.current().accent : OptionsMenuTheme.footerTextColor();
		syncLayout(headerMode);
	}

	public function syncLayout(headerMode:Bool):Void
	{
		if (bg != null)
			bg.setPosition(x, y);

		if (headerMode)
		{
			title.x = x;
			title.fieldWidth = cardW;
			title.alignment = CENTER;
			desc.x = x + 42;
			desc.fieldWidth = cardW - 84;
			desc.alignment = CENTER;
			arrow.visible = false;
		}
		else
		{
			title.x = x + CONTENT_X;
			title.fieldWidth = cardW - 106;
			title.alignment = LEFT;
			desc.x = x + CONTENT_X;
			desc.fieldWidth = cardW - 106;
			desc.alignment = LEFT;
			arrow.visible = true;
			arrow.x = x + cardW - 48;
		}

		title.y = y + 14;
		desc.y = y + 44;
		arrow.y = y + 24;
	}
}
