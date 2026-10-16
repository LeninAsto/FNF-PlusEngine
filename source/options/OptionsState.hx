package options;

import states.MainMenuState;
import backend.StageData;
import flixel.util.FlxSpriteUtil;

class OptionsState extends MusicBeatState
{
	public static inline var STYLE_PLUS:String = 'Plus';
	public static inline var STYLE_PSYCH:String = 'Psych';
	public static inline var SUBSTATE_TITLE_X:Float = 75;
	public static inline var SUBSTATE_TITLE_Y:Float = 45;

	var options:Array<String> = [
		'Note Colors',
		'Controls',
		'Adjust Delay and Combo',
		'Graphics',
		'Visuals',
		'Gameplay',
		'Legacy',
		#if MODS_ALLOWED 'Mod Security', #end
		#if MODCHART_ALLOWED 'Modchart' #end
		#if TRANSLATIONS_ALLOWED, 'Language' #end,
		#if mobile 'Mobile' #end
	];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var plusCards:FlxTypedGroup<PlusOptionCard>;

	private static var curSelected:Int = 0;

	var lerpSelected:Float = 0;
	var menuStyle:String = STYLE_PSYCH;

	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;
	public static var substateVisualActive:Bool = false;
	public static var substateReturning:Bool = false;
	public static var substateAnchorX:Float = 0;
	public static var substateAnchorY:Float = 0;
	public static var substateAnchorLabel:String = null;
	public static inline var SUBSTATE_TITLE_SCALE:Float = 0.6;
	public static inline var SUBSTATE_TITLE_ALPHA:Float = 0.4;
	public static inline var SUBSTATE_TITLE_SPAWN_OFFSET:Float = 120;
	public static inline var OPTION_BASE_Y:Float = 274;
	public static inline var OPTION_SPACING_Y:Float = 90;
	public static inline var OPTION_INTRO_SPAWN_X:Float = -420;
	public static inline var OPTION_INTRO_DURATION:Float = 0.46;

	var optionsIntroActive:Bool = true;
	var substateInputBlocked:Bool = false;

	public static function normalizeMenuStyle(style:String):String
	{
		if (style == null)
			return STYLE_PLUS;

		return switch (style.toLowerCase().trim())
		{
			case 'psych' | 'psych mobile' | 'psych-mobile' | 'mobile': STYLE_PSYCH;
			default: STYLE_PLUS;
		}
	}

	function isPlusStyle():Bool
		return menuStyle == STYLE_PLUS;

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
		return switch (label)
		{
			case 'Note Colors': Language.getPhrase('notes', 'Note Colors');
			case 'Controls': Language.getPhrase('controls', 'Controls');
			case 'Graphics': Language.getPhrase('graphics_menu', 'Graphics Settings');
			case 'Visuals': Language.getPhrase('visuals_menu', 'Visual Settings');
			case 'Gameplay': Language.getPhrase('gameplay_menu', 'Gameplay Settings');
			case 'Legacy': Language.getPhrase('legacy_menu', 'Legacy Settings');
			case 'Mod Security': Language.getPhrase('mod_security_checks_menu', 'Mod Security Checks');
			case 'Modchart': Language.getPhrase('modchart_menu', 'Modchart Settings');
			case 'Language': Language.getPhrase('language_menu', 'Language');
			case 'Mobile': Language.getPhrase('mobile_settings', 'Mobile Settings');
			default: Language.getPhrase('options_$label', label);
		}
	}

	function getOptionDescription(label:String):String
	{
		return switch (label)
		{
			case 'Note Colors': Language.getPhrase('description_notes', 'Change note colors and note splash colors.');
			case 'Controls': Language.getPhrase('description_controls', 'Change keyboard and gamepad binds.');
			case 'Adjust Delay and Combo': Language.getPhrase('description_adjust_delay', 'Adjust note delay, rating offset, and combo placement.');
			case 'Graphics': Language.getPhrase('description_graphics_menu', 'Change performance and rendering settings.');
			case 'Visuals': Language.getPhrase('description_visuals_menu', 'Change HUD, camera, and visual preferences.');
			case 'Gameplay': Language.getPhrase('description_gameplay_menu', 'Change gameplay modifiers and helpers.');
			case 'Legacy': Language.getPhrase('description_legacy_menu', 'Change compatibility settings for older Psych/Plus behavior.');
			case 'Mod Security': Language.getPhrase('description_mod_security_checks_menu', 'Change checks used when loading mods.');
			case 'Modchart': Language.getPhrase('description_modchart_menu', 'Change modchart behavior and compatibility.');
			case 'Language': Language.getPhrase('description_language_menu', 'Change the active language.');
			case 'Mobile': Language.getPhrase('description_mobile_settings', 'Change mobile controls and layout settings.');
			default: '';
		}
	}

	function restoreOptionTexts():Void
	{
		if (grpOptions == null || options == null)
			return;
		for (i in 0...grpOptions.members.length)
		{
			var item = grpOptions.members[i];
			if (item != null && i < options.length)
			{
				item.text = Language.getPhrase('options_${options[i]}', options[i]);
				item.setScale(1);
			}
		}
	}

	function beginSubstateTransition(label:String):Void
	{
		var item:Alphabet = (!isPlusStyle() && grpOptions != null && curSelected >= 0 && curSelected < grpOptions.members.length) ? grpOptions.members[curSelected] : null;
		var card:PlusOptionCard = (isPlusStyle() && plusCards != null && curSelected >= 0 && curSelected < plusCards.members.length) ? plusCards.members[curSelected] : null;
		substateVisualActive = true;
		substateReturning = false;
		substateAnchorLabel = label;
		substateAnchorX = item != null ? item.x : (card != null ? card.x : SUBSTATE_TITLE_X);
		substateAnchorY = item != null ? item.y : (card != null ? card.y : SUBSTATE_TITLE_Y);
		substateInputBlocked = true;
		if (item != null)
		{
			item.text = getDisplayLabel(label);
			item.setScale(SUBSTATE_TITLE_SCALE);
			item.x = SUBSTATE_TITLE_X - SUBSTATE_TITLE_SPAWN_OFFSET;
			item.y = SUBSTATE_TITLE_Y;
			item.alpha = 0;
		}
		if (card != null)
			card.alpha = 0;
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
		switch (label)
		{
			case 'Note Colors':
				if (ClientPrefs.data.noteRGB)
					openSubState(ScriptableSubstate.tryCreate('NotesColorSubState', new options.NotesColorSubState()));
				else
					openSubState(ScriptableSubstate.tryCreate('NotesSubState', new options.NotesSubState()));
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
			case 'Modchart':
				openSubState(ScriptableSubstate.tryCreate('ModchartSettingsSubState', new options.ModchartSettingsSubState()));
			case 'Adjust Delay and Combo':
				clearSubstateTransition();
				MusicBeatState.switchState(ScriptableState.tryCreate('NoteOffsetState', new options.NoteOffsetState()));
			case 'Mobile':
				openSubState(ScriptableSubstate.tryCreate('MobileSettingsSubState', new mobile.options.MobileSettingsSubState()));
			case 'Language':
				openSubState(ScriptableSubstate.tryCreate('LanguageSubState', new options.LanguageSubState()));
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
		OptionsMenuTheme.syncAccent();
		menuStyle = normalizeMenuStyle(ClientPrefs.data.optionsMenuStyle);

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = isPlusStyle() ? OptionsMenuTheme.current().accent : 0xFFea71fd;
		bg.updateHitbox();

		bg.screenCenter();
		add(bg);

		if (controls.mobileC)
		{
			var tipText:FlxText = new FlxText(150, FlxG.height - 24, 0,
				Language.getPhrase('mobile_controls_tip', 'Press {1} to Go Mobile Controls Menu', [(FlxG.onMobile ? 'C' : 'CTRL or C')]), 16);
			tipText.setFormat("VCR OSD Mono", 17, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			tipText.borderSize = 1.25;
			tipText.scrollFactor.set();
			tipText.antialiasing = ClientPrefs.data.antialiasing;
			add(tipText);
		}

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);
		plusCards = new FlxTypedGroup<PlusOptionCard>();
		add(plusCards);

		selectorLeft = new Alphabet(0, 0, '>', true);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		add(selectorRight);

		rebuildOptionsVisuals();
		lerpSelected = curSelected;
		changeSelection();
		ClientPrefs.saveSettings();

		// Posicionar elementos sin animación inicial
		if (isPlusStyle())
		{
			selectorLeft.visible = false;
			selectorRight.visible = false;
		}
		else
			for (num => item in grpOptions.members)
		{
			var targetY:Float = item.targetY - lerpSelected;
			var centeredX:Float = (FlxG.width - item.width) * 0.5;
			item.x = optionsIntroActive ? Math.min(OPTION_INTRO_SPAWN_X, -item.width - 140) : centeredX;
			item.y = OPTION_BASE_Y + (targetY * OPTION_SPACING_Y);
			item.alpha = 0;
			if (item.targetY == curSelected)
			{
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
			}

		addTouchPad('UP_DOWN', 'A_B_C');

		super.create();
		callOnCompanionScript('onOptionsMenuCreatePost', [getOptionsCopy()]);
		new FlxTimer().start(OPTION_INTRO_DURATION + 0.06, function(_) optionsIntroActive = false);
	}

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
		restoreOptionTexts();
		if (isPlusStyle())
			for (card in plusCards.members)
			{
				if (card == null)
					continue;
				card.x -= 180;
				card.alpha = 0;
			}
		else
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

		if (isPlusStyle())
		{
			updatePlusLayout(elapsed);
			handleInput();
			return;
		}

		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));

		for (num => item in grpOptions.members)
		{
			var targetY:Float = item.targetY - lerpSelected;
			var targetX:Float = (FlxG.width - item.width) * 0.5;
			var desiredY:Float = OPTION_BASE_Y + (targetY * OPTION_SPACING_Y);
			var targetScale:Float = 1;
			var targetAlpha:Float = 0.6;

			if (substateVisualActive)
			{
				if (item.targetY == curSelected)
				{
					targetX = SUBSTATE_TITLE_X;
					desiredY = SUBSTATE_TITLE_Y;
					targetScale = SUBSTATE_TITLE_SCALE;
					targetAlpha = SUBSTATE_TITLE_ALPHA;
				}
				else
				{
					targetX = -item.width - 80;
					desiredY -= 70;
					targetAlpha = 0;
				}
			}
			else if (substateReturning)
			{
				targetX = (FlxG.width - item.width) * 0.5;
			}
			else if (optionsIntroActive)
			{
				targetX = (FlxG.width - item.width) * 0.5;
			}
			if (item.targetY == curSelected && !substateVisualActive)
				targetAlpha = 1;

			var moveLerp:Float = Math.exp(-elapsed * (optionsIntroActive ? 7.2 : 10.2));
			item.x = FlxMath.lerp(targetX, item.x, moveLerp);
			item.y = FlxMath.lerp(desiredY, item.y, moveLerp);
			item.setScale(FlxMath.lerp(targetScale, item.scale.x, Math.exp(-elapsed * 10.2)));
			item.alpha = FlxMath.lerp(targetAlpha, item.alpha, moveLerp);
			if (item.targetY == curSelected && !substateVisualActive)
			{
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}

		selectorLeft.alpha = substateVisualActive ? 0 : 1;
		selectorRight.alpha = substateVisualActive ? 0 : 1;
		if (substateReturning
			&& Math.abs(grpOptions.members[curSelected].x - ((FlxG.width - grpOptions.members[curSelected].width) * 0.5)) < 4)
			substateReturning = false;

		if (!exiting && !substateInputBlocked)
		{
			if (controls.UI_UP_P)
				changeSelection(-1);
			if (controls.UI_DOWN_P)
				changeSelection(1);

			var touchC:Bool = touchPad != null && touchPad.buttonC != null && touchPad.buttonC.justPressed;
			if (touchC || FlxG.keys.justPressed.CONTROL && controls.mobileC)
			{
				persistentUpdate = false;
				openSubState(ScriptableSubstate.tryCreate('MobileControlSelectSubState', new mobile.substates.MobileControlSelectSubState()));
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

	function handleInput():Void
	{
		if (exiting || substateInputBlocked)
			return;

		if (controls.UI_UP_P)
			changeSelection(-2);
		if (controls.UI_DOWN_P)
			changeSelection(2);
		if (controls.UI_LEFT_P)
			changeSelection(-1);
		if (controls.UI_RIGHT_P)
			changeSelection(1);

		var touchC:Bool = touchPad != null && touchPad.buttonC != null && touchPad.buttonC.justPressed;
		if (touchC || FlxG.keys.justPressed.CONTROL && controls.mobileC)
		{
			persistentUpdate = false;
			openSubState(ScriptableSubstate.tryCreate('MobileControlSelectSubState', new mobile.substates.MobileControlSelectSubState()));
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

	function updatePlusLayout(elapsed:Float):Void
	{
		if (plusCards == null)
			return;

		var moveLerp:Float = Math.exp(-elapsed * (optionsIntroActive ? 7.2 : 10.2));
		var selectedRow:Int = Std.int(curSelected / 2);
		for (card in plusCards.members)
		{
			if (card == null)
				continue;

			var selected:Bool = card.index == curSelected;
			var col:Int = card.index % 2;
			var row:Int = Std.int(card.index / 2);
			var targetX:Float = (FlxG.width - 1024) * 0.5 + col * 524;
			var targetY:Float = 96 + (row - selectedRow) * 104;
			var targetScale:Float = selected ? 1.035 : 1;
			var targetAlpha:Float = selected ? 1 : 0.68;

			if (substateVisualActive)
			{
				if (selected)
				{
					targetX = SUBSTATE_TITLE_X;
					targetY = SUBSTATE_TITLE_Y;
					targetScale = SUBSTATE_TITLE_SCALE;
					targetAlpha = SUBSTATE_TITLE_ALPHA;
				}
				else
				{
					targetX = -card.cardWidth - 90;
					targetAlpha = 0;
				}
			}

			card.x = FlxMath.lerp(targetX, card.x, moveLerp);
			card.y = FlxMath.lerp(targetY, card.y, moveLerp);
			card.scale.set(FlxMath.lerp(targetScale, card.scale.x, moveLerp), FlxMath.lerp(targetScale, card.scale.y, moveLerp));
			card.alpha = FlxMath.lerp(targetAlpha, card.alpha, moveLerp);
			card.applyTheme(selected, substateVisualActive && selected);
		}

		if (substateReturning && plusCards.members[curSelected] != null && Math.abs(plusCards.members[curSelected].alpha - 1) < 0.05)
			substateReturning = false;
	}

	function changeSelection(change:Int = 0)
	{
		if (options == null || options.length == 0)
			return;

		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

		if (!isPlusStyle())
			for (num => item in grpOptions.members)
				item.targetY = num;
		else if (plusCards != null)
			for (card in plusCards.members)
				if (card != null)
					card.applyTheme(card.index == curSelected, false);

		callOnCompanionScript('onOptionsMenuSelectionChange', [curSelected, getSelectedOptionLabel()]);
		if (change != 0)
			FlxG.sound.play(Paths.sound('scrollMenu'));
	}

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
		lerpSelected = curSelected;
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
			item.kill();
			grpOptions.remove(item, true);
			item.destroy();
		}
		if (plusCards != null)
			while (plusCards.members.length > 0)
			{
				var card = plusCards.members[0];
				card.kill();
				plusCards.remove(card, true);
				card.destroy();
			}

		if (options == null)
			options = [];

		if (isPlusStyle())
			for (num => option in options)
			{
				var card = new PlusOptionCard(num, getDisplayLabel(option), getOptionDescription(option));
				card.x = Math.min(OPTION_INTRO_SPAWN_X, -card.cardWidth - 140);
				card.y = 96 + Std.int(num / 2) * 104;
				card.alpha = 0;
				plusCards.add(card);
			}
		else
			for (num => option in options)
			{
				var optionText:Alphabet = new Alphabet(0, 0, Language.getPhrase('options_$option', option), true);
				optionText.targetY = num;
				optionText.isMenuItem = false;
				optionText.changeX = false;
				optionText.changeY = false;
				grpOptions.add(optionText);
			}

		if (options.length > 0)
		{
			curSelected = Std.int(FlxMath.bound(curSelected, 0, options.length - 1));
			lerpSelected = curSelected;
			changeSelection(0);
		}
		else
		{
			curSelected = 0;
			lerpSelected = 0;
		}

		callOnCompanionScript('onOptionsMenuRebuild', [getOptionsCopy()]);
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}
private class PlusOptionCard extends FlxSpriteGroup
{
	static inline var CARD_W:Float = 500;
	static inline var CARD_H:Float = 86;
	static inline var DOT_W:Float = 14;
	static inline var DOT_H:Float = 34;
	static inline var DOT_X:Float = 18;
	static inline var CONTENT_X:Float = 46;

	public var index(default, null):Int;
	public var cardWidth(default, null):Float = CARD_W;
	var bg:FlxSprite;
	var title:FlxText;
	var desc:FlxText;
	var arrow:FlxText;
	var lastSelected:Null<Bool> = null;
	var lastHeader:Null<Bool> = null;
	var lastTheme:String = "";

	public function new(index:Int, label:String, description:String)
	{
		super();
		this.index = index;

		bg = new FlxSprite().makeGraphic(Std.int(CARD_W), Std.int(CARD_H), FlxColor.TRANSPARENT, true);
		add(bg);

		title = new FlxText(CONTENT_X, 14, CARD_W - 106, label, 22);
		title.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, LEFT);
		title.antialiasing = ClientPrefs.data.antialiasing;
		add(title);

		desc = new FlxText(CONTENT_X, 44, CARD_W - 106, compactDescription(description), 14);
		desc.setFormat(Paths.font("vcr.ttf"), 14, FlxColor.WHITE, LEFT);
		desc.antialiasing = ClientPrefs.data.antialiasing;
		add(desc);

		arrow = new FlxText(CARD_W - 48, 24, 32, ">", 26);
		arrow.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.WHITE, CENTER);
		arrow.antialiasing = ClientPrefs.data.antialiasing;
		add(arrow);
		applyTheme(false, false);
	}

	public function applyTheme(selected:Bool, headerMode:Bool):Void
	{
		var signature = OptionsMenuTheme.signature();
		if (lastSelected == selected && lastHeader == headerMode && lastTheme == signature)
			return;
		lastSelected = selected;
		lastHeader = headerMode;
		lastTheme = signature;

		var fill:Int = selected ? OptionsMenuTheme.difficultyCardFill(OptionsMenuTheme.current().accent, true) : OptionsMenuTheme.cardFill(false);
		var stroke:Int = selected ? OptionsMenuTheme.current().accent : OptionsMenuTheme.panelOutlineColor();
		bg.makeGraphic(Std.int(CARD_W), Std.int(CARD_H), FlxColor.TRANSPARENT, true);
		bg.setPosition(x, y);
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, CARD_W, CARD_H, 8, 8, fill);
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, CARD_W, CARD_H, 8, 8, FlxColor.TRANSPARENT, {thickness: selected ? 2 : 1, color: stroke});
		if (!headerMode)
			FlxSpriteUtil.drawRoundRect(bg, DOT_X, (CARD_H - DOT_H) * 0.5, DOT_W, DOT_H, DOT_W * 0.5, DOT_W * 0.5,
				selected ? OptionsMenuTheme.current().accent : OptionsMenuTheme.cardAccent(false));

		title.color = selected ? OptionsMenuTheme.cardTitleColor(true) : OptionsMenuTheme.cardTitleColor(false);
		desc.color = selected ? OptionsMenuTheme.cardDescriptionColor(true) : OptionsMenuTheme.cardDescriptionColor(false);
		arrow.color = selected ? OptionsMenuTheme.current().accent : OptionsMenuTheme.footerTextColor();
		arrow.visible = !headerMode;
		syncLayout(headerMode);
	}

	function syncLayout(headerMode:Bool):Void
	{
		bg.setPosition(x, y);
		if (headerMode)
		{
			title.x = x;
			title.y = y + 14;
			title.fieldWidth = CARD_W;
			title.alignment = CENTER;
			desc.visible = false;
			arrow.visible = false;
			return;
		}

		title.x = x + CONTENT_X;
		title.y = y + 14;
		title.fieldWidth = CARD_W - 106;
		title.alignment = LEFT;
		desc.visible = true;
		desc.x = x + CONTENT_X;
		desc.y = y + 44;
		desc.fieldWidth = CARD_W - 106;
		arrow.x = x + CARD_W - 48;
		arrow.y = y + 24;
	}

	static function compactDescription(value:String):String
	{
		if (value == null)
			return '';
		var text:String = value.trim();
		return text.length > 96 ? text.substr(0, 93).trim() + '...' : text;
	}
}
