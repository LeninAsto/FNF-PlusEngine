package stages.objects;

import backend.ClientPrefs;
import backend.Paths;
import flixel.FlxSprite;

/**
	The mall's bopping crowd, which can throw a "hey". Ported from the compiled version.

	Sets itself up in its own constructor rather than inheriting a prop base, like every other stage
	object here.
**/
class MallCrowd extends FlxSprite {
	public var heyTimer:Float = 0;

	var idleAnim:String;

	public function new(x:Float = 0, y:Float = 0, sprite:String = 'christmas/bottomBop', idle:String = 'Bottom Level Boppers Idle',
			hey:String = 'Bottom Level Boppers HEY') {
		super(x, y);

		idleAnim = idle;
		frames = Paths.getSparrowAtlas(sprite);
		animation.addByPrefix(idle, idle, 24, false);
		animation.addByPrefix('hey', hey, 24, false);
		animation.play(idle);

		scrollFactor.set(0.9, 0.9);
		antialiasing = ClientPrefs.data.antialiasing;
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (heyTimer > 0) {
			heyTimer -= elapsed;
			if (heyTimer <= 0) {
				dance(true);
				heyTimer = 0;
			}
		}
	}

	public function dance(forceplay:Bool = false):Void {
		if (heyTimer > 0) {
			return;
		}
		animation.play(idleAnim, forceplay);
	}
}
