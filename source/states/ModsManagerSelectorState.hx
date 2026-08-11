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
import objects.Alphabet;

class ModsManagerSelectorState extends MusicBeatState
{
	var options:Array<ModManagerOption> = [];
	var optionTexts:FlxTypedGroup<Alphabet>;
	var optionDescriptions:FlxTypedGroup<FlxText>;
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

		optionTexts = new FlxTypedGroup<Alphabet>();
		optionDescriptions = new FlxTypedGroup<FlxText>();
		add(optionTexts);
		add(optionDescriptions);

		for (i in 0...options.length)
		{
			var option = options[i];
			var text:Alphabet = new Alphabet(0, 212 + i * 126, option.label, true);
			text.setScale(0.82);
			text.x = (FlxG.width - text.width) / 2;
			text.scrollFactor.set();
			text.ID = i;
			optionTexts.add(text);

			var description:FlxText = new FlxText(0, text.y + 54, FlxG.width, option.description, 20);
			description.setFormat(Paths.font('vcr.ttf'), 20, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			description.borderSize = 1.5;
			description.scrollFactor.set();
			description.ID = i;
			optionDescriptions.add(description);
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
			text.setScale(isSelected ? 0.92 : 0.82);
			text.x = (FlxG.width - text.width) / 2;
		}

		for (description in optionDescriptions.members)
		{
			if (description == null) continue;
			var isSelected:Bool = description.ID == curSelected;
			description.color = isSelected ? 0xFFBFFFFF : FlxColor.WHITE;
			description.alpha = isSelected ? 0.95 : 0.5;
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
