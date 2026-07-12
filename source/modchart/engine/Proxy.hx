package modchart.engine;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import openfl.geom.Matrix;

// TODO: ahcer esto xd lololololololo pornopornoporn
class Proxy extends FlxSprite {
	public var source:PlayField;
	public var playerSrc:Int = -1;

	public var skew(default, null):FlxPoint = FlxPoint.get();

	var _skewMatrix:Matrix = new Matrix();

	public function new(source:PlayField) {
		this.source = source;

		super();

		moves = false;

		frameWidth = FlxG.width;
		frameHeight = FlxG.height;

		updateHitbox();
	}
}