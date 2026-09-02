package stages;

import backend.BaseStage;
import backend.ClientPrefs;
import backend.Conductor;
import backend.Paths;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import objects.Character;
import states.PlayState;
import backend.PsychFlxAnimate;
import cutscenes.CutsceneHandler;
import stages.objects.BackgroundTank;
import stages.objects.TankmenBG;
import substates.GameOverSubstate;

/**
	Week 7. Ported from the compiled `states.stages.Tank`.

	Two departures from the compiled version, both forced:

	- The henchman pool is hand-rolled instead of `FlxTypedGroup.recycle(TankmenBG)`, which needs a
	  compiled `Class<T>` to instantiate.
	- The pico-speaker note list is read off the character (`gf.animationNotes`) rather than a static
	  on `TankmenBG`, which is what let `objects.Character` stop reaching into a stage helper.
**/
class Tank extends BaseStage {
	var tankWatchtower:FlxSprite;
	var tankGround:BackgroundTank;
	var tankmanRun:FlxGroup;
	var tankmanPool:Array<TankmenBG> = [];
	var foregroundSprites:FlxGroup;

	// Cutscenes
	var cutsceneHandler:CutsceneHandler;
	var tankman:Dynamic;
	var pico:Dynamic;
	var boyfriendCutscene:FlxSprite;
	var audioPlaying:FlxSound;

	override function create():Void {
		var sky:FlxSprite = backdrop('tankSky', -400, -400, 0, 0);
		add(sky);

		if (!ClientPrefs.data.lowQuality) {
			var clouds:FlxSprite = backdrop('tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
			clouds.active = true;
			clouds.velocity.x = FlxG.random.float(5, 15);
			add(clouds);

			var mountains:FlxSprite = backdrop('tankMountains', -300, -20, 0.2, 0.2);
			mountains.setGraphicSize(Std.int(1.2 * mountains.width));
			mountains.updateHitbox();
			add(mountains);

			var buildings:FlxSprite = backdrop('tankBuildings', -200, 0, 0.3, 0.3);
			buildings.setGraphicSize(Std.int(1.1 * buildings.width));
			buildings.updateHitbox();
			add(buildings);
		}

		var ruins:FlxSprite = backdrop('tankRuins', -200, 0, 0.35, 0.35);
		ruins.setGraphicSize(Std.int(1.1 * ruins.width));
		ruins.updateHitbox();
		add(ruins);

		if (!ClientPrefs.data.lowQuality) {
			var smokeLeft:FlxSprite = animProp('smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
			add(smokeLeft);
			var smokeRight:FlxSprite = animProp('smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
			add(smokeRight);

			tankWatchtower = animProp('tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
			add(tankWatchtower);
		}

		tankGround = new BackgroundTank();
		add(tankGround);

		tankmanRun = new FlxGroup();
		add(tankmanRun);

		var ground:FlxSprite = backdrop('tankGround', -420, -150);
		ground.setGraphicSize(Std.int(1.15 * ground.width));
		ground.updateHitbox();
		add(ground);

		foregroundSprites = new FlxGroup();
		foregroundSprites.add(animProp('tank0', -500, 650, 1.7, 1.5, ['fg']));
		if (!ClientPrefs.data.lowQuality) {
			foregroundSprites.add(animProp('tank1', -300, 750, 2, 0.2, ['fg']));
		}
		foregroundSprites.add(animProp('tank2', 450, 940, 1.5, 1.5, ['foreground']));
		if (!ClientPrefs.data.lowQuality) {
			foregroundSprites.add(animProp('tank4', 1300, 900, 1.5, 1.5, ['fg']));
		}
		foregroundSprites.add(animProp('tank5', 1620, 700, 1.5, 1.5, ['fg']));
		if (!ClientPrefs.data.lowQuality) {
			foregroundSprites.add(animProp('tank3', 1300, 1200, 3.5, 2.5, ['fg']));
		}

		// Default GFs
		if (songName == 'stress') {
			setDefaultGF('pico-speaker');
		} else {
			setDefaultGF('gf-tankmen');
		}

		if (isStoryMode && !seenCutscene) {
			if (songName == 'ugh') {
				setStartCallback(ughIntro);
			} else if (songName == 'guns') {
				setStartCallback(gunsIntro);
			} else if (songName == 'stress') {
				setStartCallback(stressIntro);
			}
		}
	}

	override function createPost():Void {
		add(foregroundSprites);

		if (ClientPrefs.data.lowQuality) {
			return;
		}

		for (daGf in gfGroup.members) {
			var speaker:Character = cast daGf;
			if (speaker == null || speaker.curCharacter != 'pico-speaker') {
				continue;
			}

			var firstTank:TankmenBG = new TankmenBG(20, 500, true);
			firstTank.resetShit(20, 1500, true);
			firstTank.strumTime = 10;
			firstTank.visible = false;
			tankmanRun.add(firstTank);
			tankmanPool.push(firstTank);

			var notes:Array<Dynamic> = speaker.animationNotes;
			for (i in 0...notes.length) {
				if (FlxG.random.bool(16)) {
					var tankBih:TankmenBG = recycleTankman();
					tankBih.strumTime = notes[i][0];
					tankBih.resetShit(500, 200 + FlxG.random.int(50, 100), notes[i][1] < 2);
				}
			}
			break;
		}
	}

	/** A dead henchman brought back, or a new one added to the group. **/
	function recycleTankman():TankmenBG {
		for (tankman in tankmanPool) {
			if (!tankman.alive) {
				tankman.revive();
				return tankman;
			}
		}

		var tankman:TankmenBG = new TankmenBG(0, 0, false);
		tankmanPool.push(tankman);
		tankmanRun.add(tankman);
		return tankman;
	}

	override function countdownTick(count:Countdown, num:Int):Void {
		if (num % 2 == 0) {
			everyoneDance();
		}
	}

	override function beatHit():Void {
		everyoneDance();
	}

	/**
		Jeff heckles you over the death screen, so the loop starts quiet and fades up once he is done.
		Returning `true` tells the substate the music is already handled.
	**/
	override function gameOverLoopStart(gameOver:GameOverSubstate):Bool {
		gameOver.coolStartDeath(0.2);

		var line:String = 'jeffGameover/jeffGameover-' + FlxG.random.int(1, 25, []);
		FlxG.sound.play(Paths.sound(line), 1, false, null, true, function():Void {
			if (!gameOver.isEnding) {
				FlxG.sound.music.fadeIn(0.2, 1, 4);
			}
		});
		return true;
	}

	function everyoneDance():Void {
		if (!ClientPrefs.data.lowQuality) {
			tankWatchtower.animation.play('watchtower gradient color');
		}
		foregroundSprites.forEach(function(basic:FlxBasic):Void {
			// Each prop has exactly one animation, so replaying curAnim is what dance() did.
			var spr:FlxSprite = cast basic;
			if (spr.animation.curAnim != null) {
				spr.animation.play(spr.animation.curAnim.name);
			}
		});
	}

	function prepareCutscene():Void {
		cutsceneHandler = new CutsceneHandler();

		dadGroup.alpha = 0.00001;
		camHUD.visible = false;

		tankman = new PsychFlxAnimate(dad.x + 419, dad.y + 225);
		Paths.loadAnimateAtlas(tankman, 'cutscenes/tankman');
		tankman.antialiasing = ClientPrefs.data.antialiasing;
		addBehindDad(tankman);
		cutsceneHandler.push(tankman);

		cutsceneHandler.finishCallback = function():Void {
			var timeForStuff:Float = Conductor.crochet / 1000 * 4.5;
			FlxG.sound.music.fadeOut(timeForStuff);
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});
			startCountdown();

			dadGroup.alpha = 1;
			camHUD.visible = true;
			boyfriend.animation.finishCallback = null;
			gf.animation.finishCallback = null;
			gf.dance();
		};

		cutsceneHandler.skipCallback = function():Void {
			dadGroup.alpha = 1;
			gfGroup.alpha = 1;
			boyfriendGroup.alpha = 1;
			camHUD.visible = true;

			if (audioPlaying != null) {
				audioPlaying.stop();
			}

			boyfriend.animation.finishCallback = null;
			gf.animation.finishCallback = null;
			gf.dance();
			dad.dance();
			boyfriend.dance();

			FlxTween.cancelTweensOf(FlxG.camera);
			FlxTween.cancelTweensOf(camFollow);
			moveCameraSection();
			FlxG.camera.scroll.set(camFollow.x - FlxG.width / 2, camFollow.y - FlxG.height / 2);
			FlxG.camera.zoom = defaultCamZoom;
			startCountdown();
		};
		camFollow.setPosition(dad.x + 280, dad.y + 170);
	}

	function ughIntro():Void {
		prepareCutscene();
		cutsceneHandler.endTime = 12;
		cutsceneHandler.music = 'DISTORTO';
		Paths.sound('wellWellWell');
		Paths.sound('killYou');
		Paths.sound('bfBeep');

		var wellWellWell:FlxSound = new FlxSound();
		wellWellWell.loadEmbedded(Paths.sound('wellWellWell'));
		FlxG.sound.list.add(wellWellWell);
		var killYou:FlxSound = new FlxSound();
		killYou.loadEmbedded(Paths.sound('killYou'));
		FlxG.sound.list.add(killYou);

		tankman.anim.addBySymbol('wellWell', 'TANK TALK 1 P1', 24, false);
		tankman.anim.addBySymbol('killYou', 'TANK TALK 1 P2', 24, false);
		tankman.anim.play('wellWell', true);
		FlxG.camera.zoom *= 1.2;

		// Well well well, what do we got here?
		cutsceneHandler.timer(0.1, function():Void {
			wellWellWell.play(true);
			audioPlaying = wellWellWell;
		});

		// Move camera to BF
		cutsceneHandler.timer(3, function():Void {
			camFollow.x += 750;
			camFollow.y += 100;
		});

		// Beep!
		cutsceneHandler.timer(4.5, function():Void {
			boyfriend.playAnim('singUP', true);
			boyfriend.specialAnim = true;
			FlxG.sound.play(Paths.sound('bfBeep'));
		});

		// Move camera to Tankman
		cutsceneHandler.timer(6, function():Void {
			camFollow.x -= 750;
			camFollow.y -= 100;

			// We should just kill you but... what the hell, it's been a boring day... let's see what you've got!
			tankman.anim.play('killYou', true);
			killYou.play(true);
			audioPlaying = killYou;
		});
	}

	function gunsIntro():Void {
		prepareCutscene();
		cutsceneHandler.endTime = 11.5;
		cutsceneHandler.music = 'DISTORTO';
		Paths.sound('tankSong2');

		var tightBars:FlxSound = new FlxSound();
		tightBars.loadEmbedded(Paths.sound('tankSong2'));
		FlxG.sound.list.add(tightBars);

		tankman.anim.addBySymbol('tightBars', 'TANK TALK 2', 24, false);
		tankman.anim.play('tightBars', true);
		boyfriend.animation.curAnim.finish();

		cutsceneHandler.onStart = function():Void {
			tightBars.play(true);
			audioPlaying = tightBars;
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 4, {ease: FlxEase.quadInOut});
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2 * 1.2}, 0.5, {ease: FlxEase.quadInOut, startDelay: 4});
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 1, {ease: FlxEase.quadInOut, startDelay: 4.5});
		};

		cutsceneHandler.timer(4, function():Void {
			gf.playAnim('sad', true);
			gf.animation.finishCallback = function(name:String):Void {
				gf.playAnim('sad', true);
			};
		});
	}

	function stressIntro():Void {
		prepareCutscene();

		cutsceneHandler.endTime = 35.5;
		gfGroup.alpha = 0.00001;
		boyfriendGroup.alpha = 0.00001;
		camFollow.setPosition(dad.x + 400, dad.y + 170);
		FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});
		foregroundSprites.forEach(function(spr:Dynamic):Void {
			spr.y += 100;
		});
		Paths.sound('stressCutscene');

		pico = new PsychFlxAnimate(gf.x + 150, gf.y + 450);
		Paths.loadAnimateAtlas(pico, 'cutscenes/picoAppears');
		pico.antialiasing = ClientPrefs.data.antialiasing;
		pico.anim.addBySymbol('dance', 'GF Dancing at Gunpoint', 24, true);
		pico.anim.addBySymbol('dieBitch', 'GF Time to Die sequence', 24, false);
		pico.anim.addBySymbol('picoAppears', 'Pico Saves them sequence', 24, false);
		pico.anim.addBySymbol('picoEnd', 'Pico Dual Wield on Speaker idle', 24, false);
		pico.anim.play('dance', true);
		addBehindGF(pico);
		cutsceneHandler.push(pico);

		// Held in a var so the signal can find the same function again to remove it.
		var picoStressCycle:Dynamic = null;
		picoStressCycle = function(_:String):Void {
			// flixel-animate exposes the currently playing animation name via `anim.name` (the value
			// last passed to `play()`).
			var playing:String = pico.anim.name;
			if (playing == 'dieBitch') {
				pico.anim.play('picoAppears', true);
				boyfriendGroup.alpha = 1;
				boyfriendCutscene.visible = false;
				boyfriend.playAnim('bfCatch', true);
				boyfriend.animation.finishCallback = function(name:String):Void {
					if (name != 'idle') {
						boyfriend.playAnim('idle', true);
						boyfriend.animation.curAnim.finish(); // Instantly goes to last frame
					}
				};
			} else if (playing == 'picoAppears') {
				pico.anim.play('picoEnd', true);
			} else if (playing == 'picoEnd') {
				gfGroup.alpha = 1;
				pico.visible = false;
				if (pico.anim.onFinish.has(picoStressCycle)) { // for safety
					pico.anim.onFinish.remove(picoStressCycle);
				}
			}
		};
		pico.anim.onFinish.add(picoStressCycle);

		boyfriendCutscene = new FlxSprite(boyfriend.x + 5, boyfriend.y + 20);
		boyfriendCutscene.antialiasing = ClientPrefs.data.antialiasing;
		boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
		boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
		boyfriendCutscene.animation.play('idle', true);
		boyfriendCutscene.animation.curAnim.finish();
		addBehindBF(boyfriendCutscene);
		cutsceneHandler.push(boyfriendCutscene);

		var cutsceneSnd:FlxSound = new FlxSound();
		cutsceneSnd.loadEmbedded(Paths.sound('stressCutscene'));
		FlxG.sound.list.add(cutsceneSnd);

		tankman.anim.addBySymbol('godEffingDamnIt', 'TANK TALK 3 P1 UNCUT', 24, false);
		tankman.anim.addBySymbol('lookWhoItIs', 'TANK TALK 3 P2 UNCUT', 24, false);
		tankman.anim.play('godEffingDamnIt', true);

		cutsceneHandler.onStart = function():Void {
			cutsceneSnd.play(true);
			audioPlaying = cutsceneSnd;
		};

		cutsceneHandler.timer(15.2, function():Void {
			FlxTween.tween(camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut});
			FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut});
			pico.anim.play('dieBitch', true);
		});

		cutsceneHandler.timer(17.5, function():Void {
			zoomBack();
		});

		cutsceneHandler.timer(19.5, function():Void {
			tankman.anim.play('lookWhoItIs', true);
		});

		cutsceneHandler.timer(20, function():Void {
			camFollow.setPosition(dad.x + 500, dad.y + 170);
		});

		cutsceneHandler.timer(31.2, function():Void {
			boyfriend.playAnim('singUPmiss', true);
			boyfriend.animation.finishCallback = function(name:String):Void {
				if (name == 'singUPmiss') {
					boyfriend.playAnim('idle', true);
					boyfriend.animation.curAnim.finish(); // Instantly goes to last frame
				}
			};

			camFollow.setPosition(boyfriend.x + 280, boyfriend.y + 200);
			FlxG.camera.snapToTarget();
			PlayState.instance.cameraSpeed = 12;
			FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 0.25, {ease: FlxEase.elasticOut});
		});

		cutsceneHandler.timer(32.2, function():Void {
			zoomBack();
		});
	}

	function zoomBack():Void {
		var calledTimes:Int = 0;
		camFollow.setPosition(630, 425);
		FlxG.camera.snapToTarget();
		FlxG.camera.zoom = 0.8;
		PlayState.instance.cameraSpeed = 1;

		calledTimes++;
		if (calledTimes > 1) {
			foregroundSprites.forEach(function(spr:Dynamic):Void {
				spr.y -= 100;
			});
		}
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
