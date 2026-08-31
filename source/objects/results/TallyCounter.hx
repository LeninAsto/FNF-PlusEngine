package objects.results;

import backend.Paths;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.text.FlxText.FlxTextAlign;

/**
 * Numerical counters used next to each judgement in the Results screen.
 */
class TallyCounter extends FlxTypedSpriteGroup<FlxSprite>
{
	public var curNumber:Float = 0;
	public var neededNumber:Int = 0;
	public var flavour:Int = 0xFFFFFFFF;
	public var align:FlxTextAlign = FlxTextAlign.LEFT;

	public function new(x:Float, y:Float, neededNumber:Int = 0, ?flavour:Int, align:FlxTextAlign = FlxTextAlign.LEFT)
	{
		super(x, y);
		this.align = align;
		this.flavour = flavour == null ? 0xFFFFFFFF : flavour;
		this.neededNumber = neededNumber;

		if (curNumber == neededNumber)
			drawNumbers();
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (curNumber < neededNumber)
			drawNumbers();
	}

	function drawNumbers():Void
	{
		var separatedScore:Array<Int> = [];
		var tempCombo:Int = Math.round(curNumber);
		var fullNumberDigits:Int = Std.int(Math.max(1, Math.ceil(logBase(10, neededNumber))));

		while (tempCombo != 0)
		{
			separatedScore.push(tempCombo % 10);
			tempCombo = Math.floor(tempCombo / 10);
		}

		if (separatedScore.length == 0)
			separatedScore.push(0);

		separatedScore.reverse();

		for (ind => num in separatedScore)
		{
			if (ind >= members.length)
			{
				var xPos = ind * (43 * scale.x);
				if (align == FlxTextAlign.RIGHT)
					xPos -= fullNumberDigits * (43 * scale.x);

				var numb:TallyNumber = new TallyNumber(xPos, 0, num);
				numb.scale.set(scale.x, scale.y);
				numb.color = flavour;
				add(numb);
			}
			else if (members[ind] != null)
			{
				members[ind].animation.play(Std.string(num));
				members[ind].color = flavour;
			}
		}
	}

	static inline function logBase(base:Float, value:Float):Float
		return value <= 0 ? 1 : Math.log(value) / Math.log(base);
}

class TallyNumber extends FlxSprite
{
	public function new(x:Float, y:Float, digit:Int)
	{
		super(x, y);

		frames = Paths.getSparrowAtlas("resultScreen/tallieNumber");

		for (i in 0...10)
			animation.addByPrefix(Std.string(i), i + " small", 24, false);

		animation.play(Std.string(digit));
		updateHitbox();
	}
}
