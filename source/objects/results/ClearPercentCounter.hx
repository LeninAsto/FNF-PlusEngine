package objects.results;

import backend.Paths;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxColor;

/**
 * Numerical counter used to display the clear percent on the Results screen.
 */
class ClearPercentCounter extends FlxTypedSpriteGroup<FlxSprite>
{
	public var curNumber(default, set):Int = 0;

	var numberChanged:Bool = false;
	var isSmall:Bool = false;

	function set_curNumber(val:Int):Int
	{
		numberChanged = true;
		return curNumber = val;
	}

	public function new(x:Float, y:Float, startingNumber:Int = 0, isSmall:Bool = false)
	{
		super(x, y);

		curNumber = startingNumber;
		this.isSmall = isSmall;

		var clearPercentText:FlxSprite = new FlxSprite(isSmall ? 40 : 0, 0);
		clearPercentText.loadGraphic(Paths.image('resultScreen/clearPercent/clearPercentText${isSmall ? 'Small' : ''}'));
		add(clearPercentText);

		drawNumbers();
	}

	public function flash(enabled:Bool):Void
	{
		forEachAlive(sprite -> sprite.color = FlxColor.WHITE);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (numberChanged)
			drawNumbers();
	}

	function drawNumbers():Void
	{
		numberChanged = false;

		var separatedScore:Array<Int> = [];
		var tempCombo:Int = Math.round(curNumber);

		while (tempCombo > 0)
		{
			separatedScore.push(tempCombo % 10);
			tempCombo = Math.floor(tempCombo / 10);
		}

		if (separatedScore.length == 0)
			separatedScore.push(0);

		separatedScore.reverse();

		for (ind => num in separatedScore)
		{
			var digitIndex:Int = ind + 1;
			var digitOffset:Int = separatedScore.length == 1 ? 1 : separatedScore.length == 3 ? -1 : 0;
			var digitSize:Int = isSmall ? 32 : 72;
			var digitHeightOffset:Int = isSmall ? -4 : 0;
			var xPos:Float = (digitIndex - 1 + digitOffset) * (digitSize * scale.x);
			var yPos:Float = (digitIndex - 1 + digitOffset) * (digitHeightOffset * scale.y);
			xPos += isSmall ? -24 : 0;
			yPos += isSmall ? 0 : 72;

			if (digitIndex >= members.length)
			{
				var variant:Bool = separatedScore.length == 3 ? digitIndex >= 2 : digitIndex >= 1;
				var numb:ClearPercentNumber = new ClearPercentNumber(xPos, yPos, num, variant, isSmall);
				numb.scale.set(scale.x, scale.y);
				numb.visible = true;
				add(numb);
			}
			else if (members[digitIndex] != null)
			{
				members[digitIndex].animation.play(Std.string(num));
				members[digitIndex].x = xPos + x;
				members[digitIndex].y = yPos + y;
				members[digitIndex].visible = true;
			}
		}

		for (ind in (separatedScore.length + 1)...members.length)
		{
			if (members[ind] != null)
				members[ind].visible = false;
		}
	}
}

class ClearPercentNumber extends FlxSprite
{
	public function new(x:Float, y:Float, digit:Int, variant:Bool, isSmall:Bool)
	{
		super(x, y);

		frames = Paths.getSparrowAtlas('resultScreen/clearPercent/clearPercentNumber${isSmall ? 'Small' : variant ? 'Right' : 'Left'}');

		for (i in 0...10)
			animation.addByPrefix('$i', 'number $i 0', 24, false);

		animation.play('$digit');
		updateHitbox();
	}
}
