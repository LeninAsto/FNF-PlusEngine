package states.editors;

import backend.WeekData;

import objects.Character;

import states.MainMenuState;
import states.FreeplayState;

class MasterEditorMenu extends MusicBeatState
{
    // ← CAMBIO: Usar índices en lugar de strings traducidos
    var options:Array<String> = [];
    
    // ← NUEVO: Array con las claves de traducción
    var optionKeys:Array<String> = [
        'chart_editor',
        'character_editor', 
        'stage_editor',
        'week_editor',
        'menu_character_editor',
        'dialogue_editor',
        'dialogue_portrait_editor',
        'note_splash_editor'
	];
	private var grpTexts:FlxTypedGroup<Alphabet>;
	private var directories:Array<String> = [null];

	private var curSelected = 0;
	private var curDirectory = 0;
	private var directoryTxt:FlxText;

	override function create()
	{
		FlxG.camera.bgColor = FlxColor.BLACK;
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Editors Main Menu", null);
		#end

        // ← NUEVO: Construir array de opciones traducidas
        buildOptions();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF353535;
		add(bg);

		grpTexts = new FlxTypedGroup<Alphabet>();
		add(grpTexts);

		for (i in 0...options.length)
		{
			var leText:Alphabet = new Alphabet(90, 320, options[i], true);
			leText.isMenuItem = true;
			leText.targetY = i;
			grpTexts.add(leText);
			leText.snapToPosition();
		}
		
		#if MODS_ALLOWED
		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 42).makeGraphic(FlxG.width, 42, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		directoryTxt = new FlxText(textBG.x, textBG.y + 4, FlxG.width, '', 32);
		directoryTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		directoryTxt.scrollFactor.set();
		add(directoryTxt);
		
		for (folder in Mods.getModDirectories())
		{
			directories.push(folder);
		}

		var found:Int = directories.indexOf(Mods.currentModDirectory);
		if(found > -1) curDirectory = found;
		changeDirectory();
		#end
		changeSelection();

		FlxG.mouse.visible = false;

		addTouchPad(#if MODS_ALLOWED 'LEFT_FULL' #else 'UP_DOWN' #end, 'A_B');

		super.create();
	}

    // ← NUEVO: Función para construir opciones traducidas
    function buildOptions():Void
    {
        options = [
            Language.getPhrase('chart_editor', 'Chart Editor'),
            Language.getPhrase('character_editor', 'Character Editor'),
            Language.getPhrase('stage_editor', 'Stage Editor'),
            Language.getPhrase('week_editor', 'Week Editor'),
            Language.getPhrase('menu_character_editor', 'Menu Character Editor'),
            Language.getPhrase('dialogue_editor', 'Dialogue Editor'),
            Language.getPhrase('dialogue_portrait_editor', 'Dialogue Portrait Editor'),
            Language.getPhrase('note_splash_editor', 'Note Splash Editor')
        ];
    }

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (controls.UI_UP_P || (touchPad != null && touchPad.buttonUp.justPressed))
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P || (touchPad != null && touchPad.buttonDown.justPressed))
		{
			changeSelection(1);
		}
		#if MODS_ALLOWED
		if(controls.UI_LEFT_P || (touchPad != null && touchPad.buttonLeft.justPressed))
		{
			changeDirectory(-1);
		}
		if(controls.UI_RIGHT_P || (touchPad != null && touchPad.buttonRight.justPressed))
		{
			changeDirectory(1);
		}
		#end

		if (controls.BACK || (touchPad != null && touchPad.buttonB.justPressed))
		{
			MusicBeatState.switchState(new MainMenuState());
		}

		if (controls.ACCEPT || (touchPad != null && touchPad.buttonA.justPressed))
		{
            // ← SOLUCION: Usar índice en lugar de string traducido
            switch(curSelected) {
                case 0: // Chart Editor
					LoadingState.loadAndSwitchState(new ChartingState(), false);
                case 1: // Character Editor
					LoadingState.loadAndSwitchState(new CharacterEditorState(Character.DEFAULT_CHARACTER, false));
                case 2: // Stage Editor
					LoadingState.loadAndSwitchState(new StageEditorState());
                case 3: // Week Editor
					MusicBeatState.switchState(new WeekEditorState());
                case 4: // Menu Character Editor
					MusicBeatState.switchState(new MenuCharacterEditorState());
                case 5: // Dialogue Editor
					LoadingState.loadAndSwitchState(new DialogueEditorState(), false);
                case 6: // Dialogue Portrait Editor
					LoadingState.loadAndSwitchState(new DialogueCharacterEditorState(), false);
                case 7: // Note Splash Editor
					MusicBeatState.switchState(new NoteSplashEditorState());
			}
			FlxG.sound.music.volume = 0;
			FreeplayState.destroyFreeplayVocals();
		}
		
		for (num => item in grpTexts.members)
		{
			item.targetY = num - curSelected;
			item.alpha = 0.6;
			if (item.targetY == 0)
				item.alpha = 1;
		}
	}
	
	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);
	}
	
	#if MODS_ALLOWED
	function changeDirectory(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curDirectory += change;

		if(curDirectory < 0)
			curDirectory = directories.length - 1;
		if(curDirectory >= directories.length)
			curDirectory = 0;
	
		WeekData.setDirectoryFromWeek();
		if(directories[curDirectory] == null || directories[curDirectory].length < 1)
            directoryTxt.text = Language.getPhrase('no_mod_directory_loaded', '< No Mod Directory Loaded >');
		else
		{
			Mods.currentModDirectory = directories[curDirectory];
            directoryTxt.text = Language.getPhrase('loaded_mod_directory', '< Loaded Mod Directory: {1} >', [Mods.currentModDirectory]);
		}
		directoryTxt.text = directoryTxt.text.toUpperCase();
	}
	#end
}
