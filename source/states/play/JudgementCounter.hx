package states.play;

import backend.Rating;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class JudgementCounter extends FlxSpriteGroup
{
	var rows:Map<String, FlxText> = [];
	var labels:Map<String, String> = [];
	var tweens:Map<String, FlxTween> = [];

	public function new(ratings:Array<Rating>)
	{
		super();
		var names:Array<String> = [];
		for (rating in ratings)
			if (rating != null) names.push(rating.name);
		names.push('miss');

		var startY:Float = HudSafeZone.y() + (HudSafeZone.height() - names.length * 25) / 2;
		for (i in 0...names.length)
		{
			var name:String = names[i];
			var label:String = name == 'miss' ? 'Misses' : name.charAt(0).toUpperCase() + name.substr(1);
			var row = new FlxText(HudSafeZone.x() + 20, startY + i * 25, 180, '', 18);
			row.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			row.borderSize = 1.25;
			row.scrollFactor.set();
			labels.set(name, label);
			rows.set(name, row);
			add(row);
		}
		refresh(ratings, 0);
	}

	public function refresh(ratings:Array<Rating>, misses:Int):Void
	{
		for (rating in ratings)
			if (rating != null) setCount(rating.name, rating.hits);
		setCount('miss', misses);
	}

	function setCount(name:String, count:Int):Void
	{
		var row = rows.get(name);
		if (row != null) row.text = labels.get(name) + ': ' + count;
	}

	public function record(name:String, count:Int):Void
	{
		setCount(name, count);
		var row = rows.get(name);
		if (row == null || !visible) return;
		var previous = tweens.get(name);
		if (previous != null) previous.cancel();
		row.scale.set(1.15, 1.15);
		tweens.set(name, FlxTween.tween(row.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.quadOut}));
	}
}
