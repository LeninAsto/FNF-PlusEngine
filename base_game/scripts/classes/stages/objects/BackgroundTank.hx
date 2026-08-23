package stages.objects;

import backend.ClientPrefs;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;

/**
	The tank rolling along the horizon. Ported from the compiled version.

	Sets itself up in its own constructor rather than inheriting a prop base, like every other stage
	object here.
**/
class BackgroundTank extends FlxSprite {
	public var offsetX:Float = 400;
	public var offsetY:Float = 1300;
	public var tankSpeed:Float = 0;
	public var tankAngle:Float = 0;

	var idleAnim:String = 'BG tank w lighting';

	public function new() {
		super(0, 0);

		frames = Paths.getSparrowAtlas('tankRolling');
		animation.addByPrefix(idleAnim, idleAnim, 24, true);
		animation.play(idleAnim);
		scrollFactor.set(0.5, 0.5);

		tankSpeed = FlxG.random.float(5, 7);
		tankAngle = FlxG.random.int(-90, 45);
		antialiasing = ClientPrefs.data.antialiasing;
	}

	/** Replays the idle. `forceplay` restarts it even when it is already the current animation. **/
	public function dance(forceplay:Bool = false):Void {
		animation.play(idleAnim, forceplay);
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		tankAngle += elapsed * tankSpeed;
		angle = tankAngle - 90 + 15;
		x = offsetX + 1500 * Math.cos(Math.PI / 180 * (tankAngle + 180));
		y = offsetY + 1100 * Math.sin(Math.PI / 180 * (tankAngle + 180));
	}
}
