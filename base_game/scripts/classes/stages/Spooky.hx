package stages;

import backend.BaseStage;
import backend.ClientPrefs;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.display.BlendMode;
import states.PlayState;

/**
	Week 2. Ported from the compiled `states.stages.Spooky`.

	Two things the compiler does for a compiled stage that the interpreter does not, so both are
	written out here: optional arguments are never skipped (`backdrop`'s `1, 1` scroll, and
	`scrollFactor.set(0, 0)`), and an enum abstract is never inferred from the field it is assigned
	to (`BlendMode.ADD`, not a bare `ADD`).
**/
class Spooky extends BaseStage {
	var halloweenBG:FlxSprite;
	var halloweenWhite:FlxSprite;

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	override function create():Void {
		if (!ClientPrefs.data.lowQuality) {
			halloweenBG = animProp('halloween_bg', -200, -100, 1, 1, ['halloweem bg0', 'halloweem bg lightning strike']);
		} else {
			halloweenBG = backdrop('halloween_bg_low', -200, -100);
		}
		add(halloweenBG);

		Paths.sound('thunder_1');
		Paths.sound('thunder_2');

		if (isStoryMode && !seenCutscene && songName == 'monster') {
			setStartCallback(monsterCutscene);
		}
	}

	override function createPost():Void {
		halloweenWhite = backdrop(null, -800, -400, 0, 0);
		halloweenWhite.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
		halloweenWhite.alpha = 0;
		halloweenWhite.blend = BlendMode.ADD;
		add(halloweenWhite);
	}

	override function beatHit():Void {
		if (FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset) {
			lightningStrikeShit();
		}
	}

	function lightningStrikeShit():Void {
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if (!ClientPrefs.data.lowQuality) {
			halloweenBG.animation.play('halloweem bg lightning strike');
		}

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if (boyfriend.hasAnimation('scared')) {
			boyfriend.playAnim('scared', true);
		}
		if (dad.hasAnimation('scared')) {
			dad.playAnim('scared', true);
		}
		if (gf != null && gf.hasAnimation('scared')) {
			gf.playAnim('scared', true);
		}

		if (ClientPrefs.data.camZooms) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			// Without this it stays zoomed in until Skid & Pump hit a note.
			if (!PlayState.instance.camZooming) {
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}

		if (ClientPrefs.data.flashing) {
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

	function monsterCutscene():Void {
		inCutscene = true;
		camHUD.visible = false;

		FlxG.camera.focusOn(new FlxPoint(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100));

		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if (gf != null) {
			gf.playAnim('scared', true);
		}
		boyfriend.playAnim('scared', true);

		var whiteScreen:FlxSprite = new FlxSprite();
		whiteScreen.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
		whiteScreen.scrollFactor.set(0, 0);
		whiteScreen.blend = BlendMode.ADD;
		add(whiteScreen);

		FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
			startDelay: 0.1,
			ease: FlxEase.linear,
			onComplete: function(twn:FlxTween):Void {
				remove(whiteScreen);
				whiteScreen.destroy();

				camHUD.visible = true;
				startCountdown();
			}
		});
	}

	/**
		A static backdrop at a scroll factor, inert because it never animates. This is what the
		engine's old `BGSprite` constructor did; the class is gone, so each stage does it itself.
	**/
	function backdrop(image:String, x:Float, y:Float, scrollX:Float = 1, scrollY:Float = 1):FlxSprite {
		var spr:FlxSprite = new FlxSprite(x, y);
		if (image != null) {
			spr.loadGraphic(Paths.image(image));
		}
		spr.scrollFactor.set(scrollX, scrollY);
		spr.active = false;
		spr.antialiasing = ClientPrefs.data.antialiasing;
		return spr;
	}

	/** An animated backdrop: one animation per prefix, the first playing as the idle. **/
	function animProp(image:String, x:Float, y:Float, scrollX:Float, scrollY:Float, anims:Array<String>, loop:Bool = false):FlxSprite {
		var spr:FlxSprite = new FlxSprite(x, y);
		spr.frames = Paths.getSparrowAtlas(image);
		for (anim in anims) {
			spr.animation.addByPrefix(anim, anim, 24, loop);
		}
		spr.animation.play(anims[0]);
		spr.scrollFactor.set(scrollX, scrollY);
		spr.antialiasing = ClientPrefs.data.antialiasing;
		return spr;
	}
}
