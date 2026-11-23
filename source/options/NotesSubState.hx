package options;

import objects.Note;
import shaders.ColorSwap;

class NotesSubState extends MusicBeatSubstate
{
	static var curSelected:Int = 0;
	static var typeSelected:Int = 0;

	var nums:FlxTypedGroup<Alphabet>;
	var notes:FlxTypedGroup<FlxSprite>;
	var shaders:Array<ColorSwap> = [];
	var curValue:Float = 0;
	var holdTime:Float = 0;
	var nextAccept:Int = 5;
	var changingNote:Bool = false;

	var blackBG:FlxSprite;
	var hsbText:Alphabet;
	var posX:Float = 120;
	var valueX:Float = 370;
	var valueGap:Float = 210;

	public function new()
	{
		super();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence(Language.getPhrase('options.menus.classic_note_colors.presence', 'Classic Note Colors Menu'), null);
		#end

		ensureHSV();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFEA71FD;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		blackBG = new FlxSprite(posX - 25).makeGraphic(1030, 200, FlxColor.BLACK);
		blackBG.alpha = 0.4;
		add(blackBG);

		notes = new FlxTypedGroup<FlxSprite>();
		add(notes);
		nums = new FlxTypedGroup<Alphabet>();
		add(nums);

		var skin:String = Note.resolveNoteSkinPath(null, false);
		for (i in 0...ClientPrefs.data.arrowHSV.length)
		{
			var yPos:Float = (165 * i) + 35;
			for (j in 0...3)
			{
				var num:Alphabet = new Alphabet(valueX + (valueGap * j), yPos + 60, Std.string(Math.round(hsv(i)[j])), true);
				nums.add(num);
			}

			var note:FlxSprite = new FlxSprite(posX, yPos);
			note.frames = Paths.getSparrowAtlas(skin);
			note.animation.addByPrefix('idle', Note.colArray[i] + '0');
			note.animation.play('idle');
			note.antialiasing = ClientPrefs.data.antialiasing;
			notes.add(note);

			var shader:ColorSwap = new ColorSwap();
			note.shader = shader.shader;
			shaders.push(shader);
			applyShader(i);
		}

		hsbText = new Alphabet(valueX, -20,
			Language.getPhrase('options.menus.classic_note_colors.channels', 'Hue        Saturation   Brightness'), false);
		hsbText.scaleX = 0.5;
		hsbText.scaleY = 0.5;
		add(hsbText);

		changeSelection();
		addTouchPad('UP_DOWN', 'A_B_C');
	}

	override function update(elapsed:Float)
	{
		if (changingNote)
		{
			if (holdTime < 0.5)
			{
				if (controls.UI_LEFT_P)
				{
					updateValue(-1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				else if (controls.UI_RIGHT_P)
				{
					updateValue(1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				else if (controls.RESET)
				{
					resetValue(curSelected, typeSelected);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}

				if (controls.UI_LEFT_R || controls.UI_RIGHT_R)
					holdTime = 0;
				else if (controls.UI_LEFT || controls.UI_RIGHT)
					holdTime += elapsed;
			}
			else
			{
				var add:Float = typeSelected == 0 ? 90 : 50;
				if (controls.UI_LEFT)
					updateValue(elapsed * -add);
				else if (controls.UI_RIGHT)
					updateValue(elapsed * add);

				if (controls.UI_LEFT_R || controls.UI_RIGHT_R)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					holdTime = 0;
				}
			}
		}
		else
		{
			if (controls.UI_UP_P)
			{
				changeSelection(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_DOWN_P)
			{
				changeSelection(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_LEFT_P)
			{
				changeType(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_RIGHT_P)
			{
				changeType(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.RESET)
			{
				for (i in 0...3)
					resetValue(curSelected, i);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.ACCEPT && nextAccept <= 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changingNote = true;
				holdTime = 0;
				for (i in 0...nums.length)
				{
					var item:Alphabet = nums.members[i];
					item.alpha = (curSelected * 3) + typeSelected == i ? 1 : 0;
				}
				for (i in 0...notes.length)
				{
					var item:FlxSprite = notes.members[i];
					item.alpha = curSelected == i ? 1 : 0;
				}
				super.update(elapsed);
				return;
			}
		}

		if (controls.BACK || (changingNote && controls.ACCEPT))
		{
			if (!changingNote)
			{
				removeTouchPad();
				close();
			}
			else
				changeSelection();
			changingNote = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if (nextAccept > 0)
			nextAccept--;

		super.update(elapsed);
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0)
			curSelected = ClientPrefs.data.arrowHSV.length - 1;
		if (curSelected >= ClientPrefs.data.arrowHSV.length)
			curSelected = 0;

		curValue = hsv(curSelected)[typeSelected];
		updateValue();

		for (i in 0...nums.length)
		{
			var item:Alphabet = nums.members[i];
			item.alpha = (curSelected * 3) + typeSelected == i ? 1 : 0.6;
		}
		for (i in 0...notes.length)
		{
			var item:FlxSprite = notes.members[i];
			item.alpha = curSelected == i ? 1 : 0.6;
			item.scale.set(0.75, 0.75);
			if (curSelected == i)
			{
				item.scale.set(1, 1);
				hsbText.y = item.y - 30;
				blackBG.y = item.y - 20;
			}
		}
	}

	function changeType(change:Int = 0)
	{
		typeSelected += change;
		if (typeSelected < 0)
			typeSelected = 2;
		if (typeSelected > 2)
			typeSelected = 0;

		curValue = hsv(curSelected)[typeSelected];
		updateValue();

		for (i in 0...nums.length)
		{
			var item:Alphabet = nums.members[i];
			item.alpha = (curSelected * 3) + typeSelected == i ? 1 : 0.6;
		}
	}

	function resetValue(selected:Int, type:Int)
	{
		curValue = 0;
		hsv(selected)[type] = 0;
		applyShader(selected);
		updateNumber(selected, type, 0);
	}

	function updateValue(change:Float = 0)
	{
		curValue += change;
		var rounded:Int = Math.round(curValue);
		var max:Float = typeSelected == 0 ? 180 : 100;

		if (rounded < -max)
			curValue = -max;
		else if (rounded > max)
			curValue = max;

		rounded = Math.round(curValue);
		hsv(curSelected)[typeSelected] = rounded;
		applyShader(curSelected);
		updateNumber(curSelected, typeSelected, rounded);
	}

	function updateNumber(note:Int, type:Int, value:Int)
	{
		var item:Alphabet = nums.members[(note * 3) + type];
		item.text = Std.string(value);

		var add:Float = (40 * (item.letters.length - 1)) / 2;
		for (letter in item.letters)
		{
			letter.offset.x += add;
			if (value < 0)
				letter.offset.x += 10;
		}
	}

	function applyShader(note:Int)
	{
		if (note < 0 || note >= shaders.length)
			return;
		var values:Array<Float> = hsv(note);
		var shader:ColorSwap = shaders[note];
		shader.hue = values[0] / 360;
		shader.saturation = values[1] / 100;
		shader.brightness = values[2] / 100;
	}

	function ensureHSV()
	{
		if (ClientPrefs.data.arrowHSV == null)
			ClientPrefs.data.arrowHSV = [];
		while (ClientPrefs.data.arrowHSV.length < Note.colArray.length)
			ClientPrefs.data.arrowHSV.push([0, 0, 0]);
	}

	function hsv(note:Int):Array<Float>
	{
		ensureHSV();
		var values:Array<Float> = ClientPrefs.data.arrowHSV[note];
		while (values.length < 3)
			values.push(0);
		return values;
	}
}
