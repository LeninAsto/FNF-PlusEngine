package stages.objects;

import backend.ClientPrefs;
import backend.Conductor;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;

/**
	A henchman running across the field to be shot. Ported from the compiled version.

	The compiled one held the pico-speaker note list in its own static, assigned to it by
	`objects.Character`. That coupling is gone: the notes live on the character that loaded them
	(`gf.animationNotes`), and `Tank` reads them from there.
**/
class TankmenBG extends FlxSprite {
	var tankSpeed:Float = 0.7;
	var endingOffset:Float = 0;
	var goingRight:Bool = false;

	public var strumTime:Float = 0;

	public function new(x:Float, y:Float, facingRight:Bool) {
		super(x, y);
		goingRight = facingRight;

		frames = Paths.getSparrowAtlas('tankmanKilled1');
		animation.addByPrefix('run', 'tankman running', 24, true);
		animation.addByPrefix('shot', 'John Shot ' + FlxG.random.int(1, 2), 24, false);
		animation.play('run');
		animation.curAnim.curFrame = FlxG.random.int(0, animation.curAnim.frames.length - 1);
		antialiasing = ClientPrefs.data.antialiasing;

		scale.set(0.8, 0.8);
		updateHitbox();
	}

	public function resetShit(x:Float, y:Float, goingRight:Bool):Void {
		this.x = x;
		this.y = y;
		this.goingRight = goingRight;
		endingOffset = FlxG.random.float(50, 200);
		tankSpeed = FlxG.random.float(0.6, 1);
		flipX = goingRight;
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		visible = (x > -0.5 * FlxG.width && x < 1.2 * FlxG.width);

		if (animation.curAnim.name == 'run') {
			var speed:Float = (Conductor.songPosition - strumTime) * tankSpeed;
			if (goingRight) {
				x = (0.02 * FlxG.width - endingOffset) + speed;
			} else {
				x = (0.74 * FlxG.width + endingOffset) - speed;
			}
		} else if (animation.curAnim.finished) {
			kill();
		}

		if (Conductor.songPosition > strumTime) {
			animation.play('shot');
			if (goingRight) {
				offset.x = 300;
				offset.y = 200;
			}
		}
	}
}
