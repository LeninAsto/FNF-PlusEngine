package objects.results;

import backend.Paths;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

class ResultScore extends FlxTypedSpriteGroup<ScoreNum>
{
	public var scoreShit(default, set):Int = 0;
	public var scoreStart:Int = 0;

	public function new(x:Float, y:Float, digitCount:Int, scoreShit:Int = 100)
	{
		super(x, y);

		for (i in 0...digitCount)
			add(new ScoreNum(x + (65 * i), y));

		this.scoreShit = scoreShit;
	}

	function set_scoreShit(val:Int):Int
	{
		if (group == null || group.members == null)
			return val;

		var loopNum:Int = group.members.length - 1;
		var parsed:Null<Int> = Std.parseInt(Std.string(val));
		var dumbNumb:Int = parsed == null ? 0 : parsed;
		dumbNumb = Std.int(Math.min(dumbNumb, Math.pow(10, group.members.length) - 1));
		scoreStart = 0;

		while (dumbNumb > 0 && loopNum >= 0)
		{
			scoreStart += 1;
			group.members[loopNum].finalDigit = dumbNumb % 10;
			dumbNumb = Math.floor(dumbNumb / 10);
			loopNum--;
		}

		while (loopNum > 0)
		{
			group.members[loopNum].digit = 10;
			loopNum--;
		}

		return scoreShit = val;
	}

	public function animateNumbers():Void
	{
		var startIndex:Int = Std.int(Math.max(0, group.members.length - scoreStart));
		for (i in startIndex...group.members.length)
		{
			new FlxTimer().start((i - 1) / 24, _ ->
			{
				if (group == null || group.members[i] == null)
					return;
				group.members[i].finalDelay = scoreStart - (i - 1);
				group.members[i].playAnim();
				group.members[i].shuffle();
			});
		}
	}

	public function updateScore(scoreNew:Int):Void
		scoreShit = scoreNew;
}

class ScoreNum extends FlxSprite
{
	public var digit(default, set):Int = 10;
	public var finalDigit(default, set):Int = 10;
	public var glow:Bool = true;
	public var shuffleTimer:FlxTimer;
	public var finalTween:FlxTween;
	public var finalDelay:Float = 0;
	public var baseY:Float = 0;
	public var baseX:Float = 0;

	var numToString:Array<String> = ["ZERO", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "DISABLED"];

	public function new(x:Float, y:Float)
	{
		super(x, y);

		baseY = y;
		baseX = x;
		frames = Paths.getSparrowAtlas('resultScreen/score-digital-numbers');

		for (i in 0...10)
		{
			var stringNum:String = numToString[i];
			animation.addByPrefix(stringNum, '$stringNum DIGITAL', 24, false);
		}

		animation.addByPrefix('DISABLED', 'DISABLED', 24, false);
		animation.addByPrefix('GONE', 'GONE', 24, false);
		digit = 10;
		animation.play(numToString[digit], true);
		updateHitbox();
	}

	function set_finalDigit(val:Int):Int
	{
		animation.play('GONE', true, false, 0);
		return finalDigit = val;
	}

	function set_digit(val:Int):Int
	{
		if (val >= 0 && val < numToString.length && animation.curAnim != null && animation.curAnim.name != numToString[val])
		{
			if (glow)
			{
				animation.play(numToString[val], true, false, 0);
				glow = false;
			}
			else
				animation.play(numToString[val], true, false, 4);

			updateHitbox();
			switch (val)
			{
				case 1 | 5 | 7 | 4 | 9:
				default:
					centerOffsets(false);
			}
		}

		return digit = val;
	}

	public function playAnim():Void
		animation.play(numToString[digit], true, false, 0);

	public function shuffle():Void
	{
		var duration:Float = 41 / 24;
		var interval:Float = 1 / 24;
		shuffleTimer = new FlxTimer().start(interval, shuffleProgress, Std.int(duration / interval));
	}

	function shuffleProgress(shuffleTimer:FlxTimer):Void
	{
		var tempDigit:Int = digit + 1;
		if (tempDigit > 9)
			tempDigit = 0;
		if (tempDigit < 0)
			tempDigit = 0;
		digit = tempDigit;

		if (shuffleTimer.loops > 0 && shuffleTimer.loopsLeft == 0)
			finishShuffleTween();
	}

	function finishShuffleTween():Void
	{
		finalTween = FlxTween.num(0.0, finalDigit, 23 / 24, {
			ease: FlxEase.quadOut,
			onComplete: _ ->
			{
				new FlxTimer().start(finalDelay / 24, _ -> animation.play(animation.curAnim.name, true, false, 0));
			}
		}, value -> digit = Math.floor(value));
	}
}
