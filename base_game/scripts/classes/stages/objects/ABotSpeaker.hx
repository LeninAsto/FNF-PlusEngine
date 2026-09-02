package stages.objects;

import backend.ClientPrefs;
import backend.Paths;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import lime.system.System;
import backend.PsychFlxAnimate;
import objects.ABotSpectrum;

/**
	Pico's A-Bot speaker, bars reacting to the song. Ported from the compiled version.

	The spectrum analysis is the one part that stays compiled: `objects.ABotSpectrum` wraps
	`funkin.vis` against the sound's audio source and hands back plain per-band levels, which is
	something a script cannot reach on its own. Everything above that -- the sprites, the frame
	mapping, the eyes -- lives here.
**/
class ABotSpeaker extends FlxSpriteGroup {
	var VIZ_MAX:Int = 7; // ranges from viz1 to viz7
	var VIZ_POS_X:Array<Float> = [0, 59, 56, 66, 54, 52, 51];
	var VIZ_POS_Y:Array<Float> = [0, -8, -3.5, -0.4, 0.5, 4.7, 7];

	public var bg:FlxSprite;
	public var vizSprites:Array<FlxSprite> = [];
	public var eyeBg:FlxSprite;
	public var eyes:Dynamic;
	public var speaker:Dynamic;

	public var snd(default, set):FlxSound;

	var spectrum:ABotSpectrum;
	var levelMax:Int = 0;
	var lookingAtRight:Bool = true;

	function set_snd(changed:FlxSound):FlxSound {
		snd = changed;
		spectrum.bind(snd);
		return snd;
	}

	public function new(x:Float = 0, y:Float = 0) {
		super(x, y);

		spectrum = new ABotSpectrum(VIZ_MAX);

		var antialias:Bool = ClientPrefs.data.antialiasing;

		bg = new FlxSprite(90, 20);
		bg.loadGraphic(Paths.image('abot/stereoBG'));
		bg.antialiasing = antialias;
		add(bg);

		var vizX:Float = 0;
		var vizY:Float = 0;
		var vizFrames:Dynamic = Paths.getSparrowAtlas('abot/aBotViz');
		for (i in 1...VIZ_MAX + 1) {
			vizX += VIZ_POS_X[i - 1];
			vizY += VIZ_POS_Y[i - 1];
			var viz:FlxSprite = new FlxSprite(vizX + 140, vizY + 74);
			viz.frames = vizFrames;
			viz.animation.addByPrefix('VIZ', 'viz' + i, 0);
			viz.animation.play('VIZ', true);
			viz.animation.curAnim.finish(); // make it go to the lowest point
			viz.antialiasing = antialias;
			vizSprites.push(viz);
			viz.updateHitbox();
			viz.centerOffsets();
			add(viz);
		}

		eyeBg = new FlxSprite(-30, 215);
		eyeBg.makeGraphic(1, 1, FlxColor.WHITE);
		eyeBg.scale.set(160, 60);
		eyeBg.updateHitbox();
		add(eyeBg);

		eyes = new PsychFlxAnimate(-10, 230);
		Paths.loadAnimateAtlas(eyes, 'abot/systemEyes');
		eyes.anim.addBySymbolIndices('lookleft', 'a bot eyes lookin', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17], 24, false);
		eyes.anim.addBySymbolIndices('lookright', 'a bot eyes lookin', [18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35], 24,
			false);
		eyes.anim.play('lookright', true);
		if (eyes.anim.curAnim != null) {
			eyes.anim.curAnim.curFrame = eyes.anim.curAnim.numFrames - 1;
		}
		add(eyes);

		speaker = new PsychFlxAnimate(-65, -10);
		Paths.loadAnimateAtlas(speaker, 'abot/abotSystem');
		speaker.anim.addBySymbol('anim', 'Abot System', 24, false);
		speaker.anim.play('anim', true);
		if (speaker.anim.curAnim != null) {
			speaker.anim.curAnim.curFrame = speaker.anim.curAnim.numFrames - 1;
		}
		speaker.antialiasing = antialias;
		add(speaker);
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);
		if (spectrum == null || !spectrum.ready) {
			return;
		}

		var levels:Array<Float> = spectrum.levels();
		var oldLevelMax:Int = levelMax;
		levelMax = 0;

		var count:Int = (vizSprites.length < levels.length) ? vizSprites.length : levels.length;
		for (i in 0...count) {
			var animFrame:Int = Math.round(levels[i] * 5);
			// Flipped, because the sheet runs the other way round.
			animFrame = Std.int(Math.abs(FlxMath.bound(animFrame, 0, 5) - 5));

			vizSprites[i].animation.curAnim.curFrame = animFrame;
			levelMax = Std.int(Math.max(levelMax, 5 - animFrame));
		}

		if (levelMax >= 4) {
			if (oldLevelMax <= levelMax && (levelMax >= 5 || (speaker.anim.curAnim != null && speaker.anim.curAnim.curFrame >= 3))) {
				beatHit();
			}
		}
	}

	public function beatHit():Void {
		speaker.anim.play('anim', true);
	}

	public function lookLeft():Void {
		if (lookingAtRight) {
			eyes.anim.play('lookleft', true);
		}
		lookingAtRight = false;
	}

	public function lookRight():Void {
		if (!lookingAtRight) {
			eyes.anim.play('lookright', true);
		}
		lookingAtRight = true;
	}
}
