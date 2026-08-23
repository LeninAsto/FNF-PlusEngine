package options;

import states.MainMenuState;
import backend.StageData;

class OptionsState extends MusicBeatState
{
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
		'VSlice',
		#if MODCHARTS_NOTITG_ALLOWED 'Modchart' #end
		#if TRANSLATIONS_ALLOWED, 'Language' #end,
		#if mobile 'Mobile' #end
	];
	#if vslice
	var vsliceOptionCategories:Map<String, Dynamic> = [];
	#end
	private var grpOptions:FlxTypedGroup<Alphabet>;

	private static var curSelected:Int = 0;

	var lerpSelected:Float = 0;

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
		var item:Alphabet = (grpOptions != null && curSelected >= 0 && curSelected < grpOptions.members.length) ? grpOptions.members[curSelected] : null;
		substateVisualActive = true;
		substateReturning = false;
		substateAnchorLabel = label;
		substateAnchorX = item != null ? item.x : SUBSTATE_TITLE_X;
		substateAnchorY = item != null ? item.y : SUBSTATE_TITLE_Y;
		substateInputBlocked = true;
		if (item != null)
		{
			item.text = getDisplayLabel(label);
			item.setScale(SUBSTATE_TITLE_SCALE);
			item.x = SUBSTATE_TITLE_X - SUBSTATE_TITLE_SPAWN_OFFSET;
			item.y = SUBSTATE_TITLE_Y;
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
				openSubState(ScriptableSubstate.tryCreate('MobileSettingsSubState', new mobile.options.MobileSettingsSubState()));
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

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		#if vslice
		appendVSliceOptionCategories();
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = 0xFFea71fd;
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

		for (num => option in options)
		{
			var optionText:Alphabet = new Alphabet(0, 0, Language.getPhrase('options_$option', option), true);
			optionText.targetY = num;
			optionText.isMenuItem = false;
			optionText.changeX = false;
			optionText.changeY = false;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		add(selectorRight);

		lerpSelected = curSelected;
		changeSelection();
		ClientPrefs.saveSettings();

		// Posicionar elementos sin animación inicial
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
		restoreOptionTexts();
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

			if (touchPad.buttonC.justPressed || FlxG.keys.justPressed.CONTROL && controls.mobileC)
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

	function changeSelection(change:Int = 0)
	{
		if (options == null || options.length == 0)
			return;

		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

		for (num => item in grpOptions.members)
		{
			item.targetY = num;
		}

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

		for (i in 0...grpOptions.members.length)
		{
			var item = grpOptions.members[0];
			item.kill();
			grpOptions.remove(item, true);
			item.destroy();
		}

		if (options == null)
			options = [];

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

