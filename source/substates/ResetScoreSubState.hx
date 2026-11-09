package substates;

import backend.WeekData;
import backend.Highscore;
import objects.HealthIcon;
import mobile.input.TouchScrollHandler;

class ResetScoreSubState extends MusicBeatSubstate
{
	public var bg:FlxSprite;
	public var alphabetArray:Array<Alphabet> = [];
	public var icon:HealthIcon;
	public var onYes:Bool = false;
	public var yesText:Alphabet;
	public var noText:Alphabet;

	public var song:String;
	public var difficulty:Int;
	public var week:Int;
	var touchHandler:TouchScrollHandler = new TouchScrollHandler();

	// Week -1 = Freeplay
	public function new(song:String, difficulty:Int, character:String, week:Int = -1)
	{
		this.song = song;
		this.difficulty = difficulty;
		this.week = week;

		controls.isInSubstate = true;

		super();

		var name:String = song;
		if (week > -1)
		{
			name = WeekData.weeksLoaded.get(WeekData.weeksList[week]).weekName;
		}
		name += ' (' + Difficulty.getString(difficulty) + ')?';

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var tooLong:Float = (name.length > 18) ? 0.8 : 1; // Fucking Winter Horrorland
		var text:Alphabet = new Alphabet(0, 180, Language.getPhrase('substates.reset_score.title',
			Language.getPhrase('reset_score', 'Reset the score of')), true);
		text.screenCenter(X);
		alphabetArray.push(text);
		text.alpha = 0;
		add(text);
		var text:Alphabet = new Alphabet(0, text.y + 90, name, true);
		text.scaleX = tooLong;
		text.screenCenter(X);
		if (week == -1)
			text.x += 60 * tooLong;
		alphabetArray.push(text);
		text.alpha = 0;
		add(text);
		if (week == -1)
		{
			icon = new HealthIcon(character);
			icon.setGraphicSize(Std.int(icon.width * tooLong));
			icon.updateHitbox();
			icon.setPosition(text.x - icon.width + (10 * tooLong), text.y - 30);
			icon.alpha = 0;
			add(icon);
		}

		yesText = new Alphabet(0, text.y + 150, Language.getPhrase('global.answers.yes', Language.getPhrase('Yes', 'Yes')), true);
		yesText.screenCenter(X);
		yesText.x -= 200;
		add(yesText);
		noText = new Alphabet(0, text.y + 150, Language.getPhrase('global.answers.no', Language.getPhrase('No', 'No')), true);
		noText.screenCenter(X);
		noText.x += 200;
		add(noText);

		for (letter in yesText.letters)
			letter.color = FlxColor.RED;
		updateOptions();

		addTouchPad('LEFT_RIGHT', 'A_B');
		addTouchPadCamera();
	}

	override function update(elapsed:Float)
	{
		var touchAccept:Bool = false;
		touchHandler.update(true, true, getTouchChoiceAt, function(index:Int, x:Float, y:Float)
		{
			if ((index == 0) == onYes)
				touchAccept = true;
			else
				setChoice(index == 0);
		}, function(direction:Int) setChoice(!onYes));

		bg.alpha += elapsed * 1.5;
		if (bg.alpha > 0.6)
			bg.alpha = 0.6;

		for (i in 0...alphabetArray.length)
		{
			var spr = alphabetArray[i];
			spr.alpha += elapsed * 2.5;
		}
		if (week == -1)
			icon.alpha += elapsed * 2.5;

		if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 1);
			onYes = !onYes;
			updateOptions();
		}
		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'), 1);
			ClientPrefs.saveSettings();
			close();
			controls.isInSubstate = false;
		}
		else if (controls.ACCEPT || touchAccept)
		{
			if (onYes)
			{
				if (week == -1)
				{
					Highscore.resetSong(song, difficulty);
				}
				else
				{
					Highscore.resetWeek(WeekData.weeksList[week], difficulty);
				}
			}
			FlxG.sound.play(Paths.sound('cancelMenu'), 1);
			ClientPrefs.saveSettings();
			controls.isInSubstate = false;
			close();
		}
		if (touchPad == null)
		{ // sometimes it dosent add the tpad, hopefully this fixes it
			addTouchPad('LEFT_RIGHT', 'A_B');
			addTouchPadCamera();
		}
		super.update(elapsed);
	}

	function updateOptions()
	{
		var scales:Array<Float> = [0.75, 1];
		var alphas:Array<Float> = [0.6, 1.25];
		var confirmInt:Int = onYes ? 1 : 0;

		yesText.alpha = alphas[confirmInt];
		yesText.scale.set(scales[confirmInt], scales[confirmInt]);
		noText.alpha = alphas[1 - confirmInt];
		noText.scale.set(scales[1 - confirmInt], scales[1 - confirmInt]);
		if (week == -1)
			icon.animation.curAnim.curFrame = confirmInt;
	}

	function setChoice(yes:Bool):Void
	{
		if (onYes == yes)
			return;
		FlxG.sound.play(Paths.sound('scrollMenu'), 1);
		onYes = yes;
		updateOptions();
	}

	function getTouchChoiceAt(x:Float, y:Float):Int
	{
		if (yesText != null && x >= yesText.x && x <= yesText.x + yesText.width && y >= yesText.y && y <= yesText.y + yesText.height)
			return 0;
		if (noText != null && x >= noText.x && x <= noText.x + noText.width && y >= noText.y && y <= noText.y + noText.height)
			return 1;
		return TouchScrollHandler.NO_TARGET;
	}

	override function destroy()
	{
		bg = FlxDestroyUtil.destroy(bg);
		alphabetArray = FlxDestroyUtil.destroyArray(alphabetArray);
		icon = FlxDestroyUtil.destroy(icon);
		yesText = FlxDestroyUtil.destroy(yesText);
		noText = FlxDestroyUtil.destroy(noText);

		super.destroy();
	}
}

