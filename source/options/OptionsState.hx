package options;

import states.MainMenuState;
import backend.StageData;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = [
		'Note Colors',
		'Controls',
		'Adjust Delay and Combo',
		'Graphics',
		'Visuals',
		'Gameplay',
		'Legacy',
		#if MODCHARTS_NOTITG_ALLOWED 'Modchart' #end
		#if TRANSLATIONS_ALLOWED , 'Language' #end,
		#if mobile 'Mobile Options' #end
	];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;

	function openSelectedSubstate(label:String) {
		if (label != "Adjust Delay and Combo"){
			removeTouchPad();
			persistentUpdate = false;
		}
		switch(label)
		{
			case 'Note Colors':
				if(ClientPrefs.data.noteRGB) openSubState(new options.NotesColorSubState());
				else openSubState(new options.NotesColorLegacySubState());
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals':
				openSubState(new options.VisualsSettingsSubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Legacy':
				openSubState(new options.LegacySettingsSubState());
			case 'Modchart':
				openSubState(new options.ModchartSettingsSubState());
			case 'Adjust Delay and Combo':
				MusicBeatState.switchState(new options.NoteOffsetState());
			case 'Mobile Options':
				openSubState(new mobile.options.MobileSettingsSubState());
			case 'Language':
				openSubState(new options.LanguageSubState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = 0xFFea71fd;
		bg.updateHitbox();

		bg.screenCenter();
		add(bg);

		if (controls.mobileC)
		{
			var tipText:FlxText = new FlxText(150, FlxG.height - 24, 0, Language.getPhrase('mobile_controls_tip', 'Press {1} to Go Mobile Controls Menu', [(FlxG.onMobile ? 'C' : 'CTRL or C')]), 16);
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
			optionText.isMenuItem = true;
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
			item.screenCenter(X);
			item.y = (FlxG.height * 0.2) + (targetY * 50);
			
			item.alpha = 0.6;
			if (item.targetY == curSelected)
			{
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}

		addTouchPad('UP_DOWN', 'A_B_C');

		super.create();
	}

	override function closeSubState()
	{
		super.closeSubState();
		ClientPrefs.saveSettings();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
		controls.isInSubstate = false;
		removeTouchPad();
		addTouchPad('UP_DOWN', 'A_B_C');
		persistentUpdate = true;
	}

	var exiting = false;
	override function update(elapsed:Float) {
		super.update(elapsed);

		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));

		for (num => item in grpOptions.members)
		{
			var targetY:Float = item.targetY - lerpSelected;
			item.screenCenter(X);
			item.y = FlxMath.lerp((FlxG.height * 0.2) + (targetY * 50), item.y, Math.exp(-elapsed * 10.2));
			
			item.alpha = 0.6;
			if (item.targetY == curSelected)
			{
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}

		if(!exiting) {
			if (controls.UI_UP_P)
				changeSelection(-1);
			if (controls.UI_DOWN_P)
				changeSelection(1);
			
			if (touchPad.buttonC.justPressed || FlxG.keys.justPressed.CONTROL && controls.mobileC)
			{
				persistentUpdate = false;
				openSubState(new mobile.substates.MobileControlSelectSubState());
			}

			if (controls.BACK)
			{
				exiting = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				if(onPlayState)
				{
					StageData.loadDirectory(PlayState.SONG);
					LoadingState.loadAndSwitchState(new PlayState());
					FlxG.sound.music.volume = 0;
				}
				else 
				{
					MusicBeatState.switchState(new MainMenuState());
				}
			}
			else if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);
		}
	}
	
	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

		for (num => item in grpOptions.members)
		{
			item.targetY = num;
		}
		
		if(change != 0) FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}
