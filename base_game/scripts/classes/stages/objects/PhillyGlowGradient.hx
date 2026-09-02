package stages.objects;

import backend.ClientPrefs;
import backend.Paths;
import flixel.FlxSprite;

/** The rising light gradient behind Blammed's glow event. Ported from the compiled version. **/
class PhillyGlowGradient extends FlxSprite {
	public var originalY:Float;
	public var originalHeight:Int = 400;
	public var intendedAlpha:Float = 1;

	public function new(x:Float, y:Float) {
		super(x, y);
		originalY = y;

		// FlxGradient refused to load properly, hence a plain image.
		loadGraphic(Paths.image('philly/gradient'));
		scrollFactor.set(0, 0.75);
		setGraphicSize(2000, originalHeight);
		updateHitbox();
		antialiasing = ClientPrefs.data.antialiasing;
	}

	override function update(elapsed:Float):Void {
		var newHeight:Int = Math.round(height - 1000 * elapsed);
		if (newHeight > 0) {
			alpha = intendedAlpha;
			setGraphicSize(2000, newHeight);
			updateHitbox();
			y = originalY + (originalHeight - height);
		} else {
			alpha = 0;
			y = -5000;
		}

		super.update(elapsed);
	}

	public function bop():Void {
		setGraphicSize(2000, originalHeight);
		updateHitbox();
		y = originalY;
		alpha = intendedAlpha;
	}
}
