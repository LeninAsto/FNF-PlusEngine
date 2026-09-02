package stages;

import backend.BaseStage;
import backend.ClientPrefs;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import backend.Achievements;
import stages.objects.BackgroundDancer;

/**
	Week 4. Ported from the compiled `states.stages.Limo`.

	The henchmen-kill state machine was a module-level `enum` there. Here it is a set of Int instance
	fields compared with `if`/`else`: a scripted class's statics are not reachable from its instance
	methods, and a capitalised identifier in a `case` pattern is read as a pattern variable and
	rejected.
**/
class Limo extends BaseStage {
	// Plain instance fields, not statics: a scripted class's statics live on the class interpreter and
	// are not reachable from instance scope. Lower-case so they are never mistaken for the enum
	// constants they replace, and never used as `case` patterns -- the parser reads a capitalised
	// identifier there as a pattern variable and rejects it.
	var stWait:Int = 0;
	var stKilling:Int = 1;
	var stSpeedingOffscreen:Int = 2;
	var stSpeeding:Int = 3;
	var stStopping:Int = 4;

	var grpLimoDancers:FlxGroup;
	var fastCar:FlxSprite;
	var fastCarCanDrive:Bool = true;

	// event
	/** One of the `st*` values above; starts at `stWait`, written as its value. **/
	var limoKillingState:Int = 0;
	var limoMetalPole:FlxSprite;
	var limoLight:FlxSprite;
	var limoCorpse:FlxSprite;
	var limoCorpseTwo:FlxSprite;
	var bgLimo:FlxSprite;
	var grpLimoParticles:FlxGroup;
	var dancersDiff:Float = 320;

	var limoSpeed:Float = 0;
	var carTimer:FlxTimer;

	override function create():Void {
		var skyBG:FlxSprite = backdrop('limo/limoSunset', -120, -50, 0.1, 0.1);
		add(skyBG);

		if (!ClientPrefs.data.lowQuality) {
			limoMetalPole = backdrop('gore/metalPole', -500, 220, 0.4, 0.4);
			add(limoMetalPole);

			bgLimo = animProp('limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
			add(bgLimo);

			limoCorpse = animProp('gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
			add(limoCorpse);

			limoCorpseTwo = animProp('gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
			add(limoCorpseTwo);

			grpLimoDancers = new FlxGroup();
			add(grpLimoDancers);

			for (i in 0...5) {
				var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + dancersDiff + bgLimo.x, bgLimo.y - 400);
				dancer.scrollFactor.set(0.4, 0.4);
				grpLimoDancers.add(dancer);
			}

			limoLight = backdrop('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
			add(limoLight);

			grpLimoParticles = new FlxGroup();
			add(grpLimoParticles);

			// PRECACHE BLOOD
			var particle:FlxSprite = animProp('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
			particle.alpha = 0.01;
			grpLimoParticles.add(particle);
			resetLimoKill();

			// PRECACHE SOUND
			Paths.sound('dancerdeath');
			setDefaultGF('gf-car');
		}

		fastCar = backdrop('limo/fastCarLol', -300, 160);
		fastCar.active = true;
	}

	override function createPost():Void {
		resetFastCar();

		var limo:FlxSprite = animProp('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);
		addBehindDad(limo); // In front of GF (so she sits behind the limo), behind dad/bf

		add(fastCar); // In front of everything (characters + limo)
	}

	override function update(elapsed:Float):Void {
		if (ClientPrefs.data.lowQuality) {
			return;
		}

		grpLimoParticles.forEach(function(spr:Dynamic):Void {
			if (spr.animation.curAnim.finished) {
				spr.kill();
				grpLimoParticles.remove(spr, true);
				spr.destroy();
			}
		});

		if (limoKillingState == stKilling) {
			limoMetalPole.x += 5000 * elapsed;
			limoLight.x = limoMetalPole.x - 180;
			limoCorpse.x = limoLight.x - 50;
			limoCorpseTwo.x = limoLight.x + 35;

			var dancers:Array<Dynamic> = grpLimoDancers.members;
			for (i in 0...dancers.length) {
				if (dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 170) {
					// Note: nobody cares about the fifth dancer, he is mostly hidden offscreen.
					if (i == 0 || i == 3) {
						if (i == 0) {
							FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);
						}

						var diffStr:String = (i == 3) ? ' 2 ' : ' ';
						var leg:FlxSprite = animProp('gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin' + diffStr + 'PINK'], false);
						grpLimoParticles.add(leg);
						var arm:FlxSprite = animProp('gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin' + diffStr + 'PINK'], false);
						grpLimoParticles.add(arm);
						var head:FlxSprite = animProp('gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin' + diffStr + 'PINK'], false);
						grpLimoParticles.add(head);

						var blood:FlxSprite = animProp('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
						blood.flipX = true;
						blood.angle = -57.5;
						grpLimoParticles.add(blood);
					} else if (i == 1) {
						limoCorpse.visible = true;
					} else if (i == 2) {
						limoCorpseTwo.visible = true;
					}
					dancers[i].x += FlxG.width * 2;
				}
			}

			if (limoMetalPole.x > FlxG.width * 2) {
				resetLimoKill();
				limoSpeed = 800;
				limoKillingState = stSpeedingOffscreen;
			}
		} else if (limoKillingState == stSpeedingOffscreen) {
			limoSpeed -= 4000 * elapsed;
			bgLimo.x -= limoSpeed * elapsed;
			if (bgLimo.x > FlxG.width * 1.5) {
				limoSpeed = 3000;
				limoKillingState = stSpeeding;
			}
		} else if (limoKillingState == stSpeeding) {
			limoSpeed -= 2000 * elapsed;
			if (limoSpeed < 1000) {
				limoSpeed = 1000;
			}

			bgLimo.x -= limoSpeed * elapsed;
			if (bgLimo.x < -275) {
				limoKillingState = stStopping;
				limoSpeed = 800;
			}
			dancersParenting();
		} else if (limoKillingState == stStopping) {
			bgLimo.x = FlxMath.lerp(-150, bgLimo.x, Math.exp(-elapsed * 9));
			if (Math.round(bgLimo.x) == -150) {
				bgLimo.x = -150;
				limoKillingState = stWait;
			}
			dancersParenting();
		}
	}

	override function beatHit():Void {
		if (!ClientPrefs.data.lowQuality) {
			grpLimoDancers.forEach(function(dancer:Dynamic):Void {
				dancer.dance();
			});
		}

		if (FlxG.random.bool(10) && fastCarCanDrive) {
			fastCarDrive();
		}
	}

	// Substates for pausing/resuming tweens and timers
	override function closeSubState():Void {
		if (paused && carTimer != null) {
			carTimer.active = true;
		}
	}

	override function openSubState(SubState:Dynamic):Void {
		if (paused && carTimer != null) {
			carTimer.active = false;
		}
	}

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float):Void {
		if (eventName == 'Kill Henchmen') {
			killHenchmen();
		}
	}

	function dancersParenting():Void {
		var dancers:Array<Dynamic> = grpLimoDancers.members;
		for (i in 0...dancers.length) {
			dancers[i].x = (370 * i) + dancersDiff + bgLimo.x;
		}
	}

	function resetLimoKill():Void {
		limoMetalPole.x = -500;
		limoMetalPole.visible = false;
		limoLight.x = -500;
		limoLight.visible = false;
		limoCorpse.x = -500;
		limoCorpse.visible = false;
		limoCorpseTwo.x = -500;
		limoCorpseTwo.visible = false;
	}

	function resetFastCar():Void {
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	function fastCarDrive():Void {
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = FlxG.random.int(30600, 39600);
		fastCarCanDrive = false;
		carTimer = new FlxTimer().start(2, function(tmr:FlxTimer):Void {
			resetFastCar();
			carTimer = null;
		});
	}

	function killHenchmen():Void {
		if (ClientPrefs.data.lowQuality || limoKillingState != stWait) {
			return;
		}

		limoMetalPole.x = -400;
		limoMetalPole.visible = true;
		limoLight.visible = true;
		limoCorpse.visible = false;
		limoCorpseTwo.visible = false;
		limoKillingState = stKilling;

		var kills:Float = Achievements.addScore('roadkill_enthusiast');
		FlxG.log.add('Henchmen kills: ' + kills);
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
