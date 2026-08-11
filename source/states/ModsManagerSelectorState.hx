package states;

import backend.ClientPrefs;
import backend.MusicBeatState;
import backend.Paths;
import backend.Language;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.util.FlxColor;

class ModsManagerSelectorState extends MusicBeatState
{
	var options:Array<ModManagerOption> = [];
	var optionTexts:FlxTypedGroup<FlxText>;
	var curSelected:Int = 0;
	var selected:Bool = false;

	override function create():Void
	{
		super.create();

		options = [
			{
				label: Language.getPhrase('mods_manager_plus', 'Plus / Psych Mods'),
				description: Language.getPhrase('mods_manager_plus_desc', 'Classic mods from the mods folder.'),
				vsliceMode: false
			},
			{
				label: Language.getPhrase('mods_manager_vslice', 'VSlice Mods'),
				description: Language.getPhrase('mods_manager_vslice_desc', 'Official Funkin/Polymod mods from vslice_mods.'),
				vsliceMode: true
			}
		];

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF4A5BE8;
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.screenCenter();
		add(bg);

		var title:FlxText = new FlxText(0, 82, FlxG.width, Language.getPhrase('mods_manager_title', 'Choose Mod Manager'), 44);
		title.setFormat(Paths.font('vcr.ttf'), 44, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		title.borderSize = 2;
		title.scrollFactor.set();
		add(title);

		optionTexts = new FlxTypedGroup<FlxText>();
		add(optionTexts);

		for (i in 0...options.length)
		{
			var option = options[i];
			var text:FlxText = new FlxText(0, 225 + i * 110, FlxG.width, option.label + '\n' + option.description, 32);
			text.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.borderSize = 2;
			text.scrollFactor.set();
			text.ID = i;
			optionTexts.add(text);
		}

		var hint:String = controls.mobileC ? 'A / B' : 'ENTER / BACKSPACE';
		var bottom:FlxText = new FlxText(0, FlxG.height - 54, FlxG.width, Language.getPhrase('mods_manager_hint', '{1} Select / Back', [hint]), 18);
		bottom.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		bottom.borderSize = 1.5;
		bottom.scrollFactor.set();
		add(bottom);

		#if mobile
		addTouchPad('UP_DOWN', 'A_B');
		addTouchPadCamera();
		#end

		changeSelection();
	}

	override function update(elapsed:Float):Void
	{
		if (!selected)
		{
			if (controls.UI_UP_P) changeSelection(-1);
			if (controls.UI_DOWN_P) changeSelection(1);

			if (controls.BACK)
			{
				selected = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}
			else if (controls.ACCEPT)
			{
				openSelectedManager();
			}
		}

		super.update(elapsed);
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = (curSelected + change + options.length) % options.length;
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		for (text in optionTexts.members)
		{
			if (text == null) continue;
			var isSelected:Bool = text.ID == curSelected;
			text.color = isSelected ? 0xFF00FFFF : FlxColor.WHITE;
			text.alpha = isSelected ? 1 : 0.55;
			text.scale.set(isSelected ? 1.08 : 1, isSelected ? 1.08 : 1);
		}
	}

	function openSelectedManager():Void
	{
		selected = true;
		FlxG.sound.play(Paths.sound('confirmMenu'));

		var option:ModManagerOption = options[curSelected];
		if (option.vsliceMode)
			MusicBeatState.switchState(backend.ScriptableState.tryCreate('ModsMenuState', new ModsMenuState(null, true, true)));
		else
			MusicBeatState.switchState(backend.ScriptableState.tryCreate('ModsMenuState', new ModsMenuState(null, false, true)));
	}
}

typedef ModManagerOption =
{
	var label:String;
	var description:String;
	var vsliceMode:Bool;
}
