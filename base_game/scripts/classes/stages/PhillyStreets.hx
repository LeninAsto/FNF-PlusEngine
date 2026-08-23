package stages;

import backend.BaseStage;
import backend.ClientPrefs;
import backend.Conductor;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.display.BlendMode;
import states.PlayState;
import flixel.addons.display.FlxTiledSprite;
// Imported as the MODULE, which brings every type declared in it (`FlxBasePoint`, used below) in as a
// bare name. Neither `flixel.math.FlxBasePoint` nor `flixel.math.FlxPoint.FlxBasePoint` resolves: the
// first is the compile path the type index does not key, and in the second the trailing segment is
// read as a FIELD of FlxPoint.
import flixel.math.FlxPoint;
import cutscenes.CutsceneHandler;
import openfl.filters.ShaderFilter;
import shaders.RainShader;
import stages.objects.ABotSpeaker;
import stages.objects.PicoDeathOverlay;
import stages.objects.SpraycanAtlasSprite;
import substates.GameOverSubstate;

/**
	Weekend 1: Darnell, Lit Up, 2Hot. Ported from the compiled `states.stages.PhillyStreets`.

	Three things differ from the compiled version, all forced by the script boundary:

	- Nene's state machine was a module-level `enum`; it is Int instance fields compared with
	  `if`/`else` here (a scripted class cannot reach its own statics, and a capitalised `case` pattern
	  is rejected as a pattern variable).
	- Car paths are built as `FlxBasePoint`, not `FlxPoint`. A script holds an abstract as a wrapper
	  object, and while a wrapper unwraps when passed as an argument, an ARRAY of them does not --
	  `FlxTween.quadPath` would receive wrappers. Annotating each point with the type `FlxPoint`
	  converts to (`to FlxBasePoint`) hands back the raw value, which is what the array must hold.
	- `setStartCallback(videoCutscene.bind(...))` became a closure, since `bind` is a compiler feature.
**/
class PhillyStreets extends BaseStage {
	// Plain instance fields, not statics: a scripted class's statics live on the class interpreter and
	// are not reachable from instance scope. Lower-case so they are never mistaken for the enum
	// constants they replace, and compared with `if`/`else` -- the parser reads a capitalised
	// identifier in a `case` pattern as a pattern variable and rejects it.
	var stDefault:Int = 0;
	var stPreRaise:Int = 1;
	var stRaise:Int = 2;
	var stReady:Int = 3;
	var stLower:Int = 4;

	var MIN_BLINK_DELAY:Int = 3;
	var MAX_BLINK_DELAY:Int = 7;
	var VULTURE_THRESHOLD:Float = 0.5;
	var blinkCountdown:Int = 3;

	var rainShader:RainShader;
	var rainShaderStartIntensity:Float = 0;
	var rainShaderEndIntensity:Float = 0;

	var scrollingSky:FlxTiledSprite;
	var phillyTraffic:FlxSprite;

	var phillyCars:FlxSprite;
	var phillyCars2:FlxSprite;

	var picoFade:FlxSprite;
	var spraycan:SpraycanAtlasSprite;
	var spraycanPile:FlxSprite;

	var darkenable:Array<FlxSprite> = [];
	var abot:ABotSpeaker;

	var noteTypes:Array<String> = [];
	var videoEnded:Bool = false;
	var cutsceneHandler:CutsceneHandler;

	/** One of the `st*` values above; starts at `stDefault`, written as its value. **/
	var currentNeneState:Int = 0;
	var animationFinished:Bool = false;

	var casingGroup:FlxSpriteGroup;
	var casingFrames:Dynamic;
	var gunPrepSnd:FlxSound;
	var bonkSnd:FlxSound;
	var lightCanSnd:FlxSound;
	var kickCanSnd:FlxSound;
	var kneeCanSnd:FlxSound;

	var lightsStop:Bool = false;
	var lastChange:Int = 0;
	var changeInterval:Int = 8;

	var carWaiting:Bool = false;
	var carInterruptable:Bool = true;
	var car2Interruptable:Bool = true;

	var picoFlicker:FlxTimer = null;

	override function create():Void {
		if (!ClientPrefs.data.lowQuality) {
			var skyImage:Dynamic = Paths.image('phillyStreets/phillySkybox');
			scrollingSky = new FlxTiledSprite(skyImage, skyImage.width + 400, skyImage.height, true, false);
			scrollingSky.antialiasing = ClientPrefs.data.antialiasing;
			scrollingSky.setPosition(-650, -375);
			scrollingSky.scrollFactor.set(0.1, 0.1);
			scrollingSky.scale.set(0.65, 0.65);
			add(scrollingSky);
			darkenable.push(scrollingSky);

			var phillySkyline:FlxSprite = backdrop('phillyStreets/phillySkyline', -545, -273, 0.2, 0.2);
			add(phillySkyline);
			darkenable.push(phillySkyline);

			var phillyForegroundCity:FlxSprite = backdrop('phillyStreets/phillyForegroundCity', 625, 94, 0.3, 0.3);
			add(phillyForegroundCity);
			darkenable.push(phillyForegroundCity);
		}

		var phillyConstruction:FlxSprite = backdrop('phillyStreets/phillyConstruction', 1800, 364, 0.7, 1);
		add(phillyConstruction);
		darkenable.push(phillyConstruction);

		var phillyHighwayLights:FlxSprite = backdrop('phillyStreets/phillyHighwayLights', 284, 305, 1, 1);
		add(phillyHighwayLights);
		darkenable.push(phillyHighwayLights);

		if (!ClientPrefs.data.lowQuality) {
			var phillyHighwayLightsLightmap:FlxSprite = backdrop('phillyStreets/phillyHighwayLights_lightmap', 284, 305, 1, 1);
			phillyHighwayLightsLightmap.blend = BlendMode.ADD;
			phillyHighwayLightsLightmap.alpha = 0.6;
			add(phillyHighwayLightsLightmap);
			darkenable.push(phillyHighwayLightsLightmap);
		}

		var phillyHighway:FlxSprite = backdrop('phillyStreets/phillyHighway', 139, 209, 1, 1);
		add(phillyHighway);
		darkenable.push(phillyHighway);

		if (!ClientPrefs.data.lowQuality) {
			var phillySmog:FlxSprite = backdrop('phillyStreets/phillySmog', -6, 245, 0.8, 1);
			add(phillySmog);
			darkenable.push(phillySmog);

			for (i in 0...2) {
				var car:FlxSprite = animProp('phillyStreets/phillyCars', 1200, 818, 0.9, 1, ['car1', 'car2', 'car3', 'car4'], false);
				add(car);
				if (i == 0) {
					phillyCars = car;
				} else {
					phillyCars2 = car;
				}
				darkenable.push(car);
			}
			phillyCars2.flipX = true;

			phillyTraffic = animProp('phillyStreets/phillyTraffic', 1840, 608, 0.9, 1, ['redtogreen', 'greentored'], false);
			add(phillyTraffic);
			darkenable.push(phillyTraffic);

			var phillyTrafficLightmap:FlxSprite = backdrop('phillyStreets/phillyTraffic_lightmap', 1840, 608, 0.9, 1);
			phillyTrafficLightmap.blend = BlendMode.ADD;
			phillyTrafficLightmap.alpha = 0.6;
			add(phillyTrafficLightmap);
			darkenable.push(phillyTrafficLightmap);
		}

		var phillyForeground:FlxSprite = backdrop('phillyStreets/phillyForeground', 88, 317, 1, 1);
		add(phillyForeground);
		darkenable.push(phillyForeground);

		if (!ClientPrefs.data.lowQuality) {
			picoFade = new FlxSprite();
			picoFade.antialiasing = ClientPrefs.data.antialiasing;
			picoFade.alpha = 0;
			add(picoFade);
			darkenable.push(picoFade);
		}

		abot = new ABotSpeaker(gfGroup.x, gfGroup.y + 525);
		updateABotEye(true);
		add(abot);

		if (ClientPrefs.data.shaders) {
			setupRainShader();
		}

		var song:Dynamic = PlayState.SONG;
		if (song.gameOverSound == null || song.gameOverSound.trim().length < 1) {
			GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pico';
		}
		if (song.gameOverLoop == null || song.gameOverLoop.trim().length < 1) {
			GameOverSubstate.loopSoundName = 'gameOver-pico';
		}
		if (song.gameOverEnd == null || song.gameOverEnd.trim().length < 1) {
			GameOverSubstate.endSoundName = 'gameOverEnd-pico';
		}
		if (song.gameOverChar == null || song.gameOverChar.trim().length < 1) {
			GameOverSubstate.characterName = 'pico-dead';
		}
		setDefaultGF('nene');

		if (!isStoryMode) {
			return;
		}

		if (songName == 'darnell') {
			if (!seenCutscene) {
				setStartCallback(function():Void {
					videoCutscene('darnellCutscene');
				});
			}
		} else if (songName == '2hot') {
			setEndCallback(function():Void {
				PlayState.instance.endingSong = true;
				inCutscene = true;
				canPause = false;
				FlxTransitionableState.skipNextTransIn = true;
				FlxG.camera.visible = false;
				camHUD.visible = false;
				PlayState.instance.startVideo('2hotCutscene');
			});
		}
	}

	override function createPost():Void {
		for (n in PlayState.SONG.noteList) {
			var nt:String = (n.type != null) ? n.type : '';
			if (!noteTypes.contains(nt)) {
				noteTypes.push(nt);
			}
		}

		spraycanPile = backdrop('SpraycanPile', 920, 1045, 1, 1);
		precache();
		add(spraycanPile);
		darkenable.push(spraycanPile);

		if (gf != null) {
			gf.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int):Void {
				if (currentNeneState == stPreRaise && name == 'danceLeft' && frameNumber >= 14) {
					animationFinished = true;
					transitionState();
				}
			};
		}
	}

	// override animations for note types
	override function notesGenerated(notes:Array<Dynamic>):Void {
		for (note in notes) {
			if (note.type == 'weekend-1-firegun') {
				note.blockHit = true;
			}
		}
	}

	function videoCutscene(videoName:String = null):Void {
		PlayState.instance.inCutscene = true;
		if (!videoEnded && videoName != null) {
			PlayState.instance.startVideo(videoName);
			var onDone:Dynamic = function():Void {
				videoEnded = true;
				PlayState.instance.videoCutscene = null;
				videoCutscene(null);
			};
			PlayState.instance.videoCutscene.finishCallback = onDone;
			PlayState.instance.videoCutscene.onSkip = onDone;
			return;
		}

		if (isStoryMode && songName == 'darnell') {
			darnellCutscene();
		}
	}

	function darnellCutscene():Void {
		// The can is built by precache() during createPost. If that did not happen the cutscene cannot
		// run, and since this fires from the video's finish callback a null here would take the whole
		// session down rather than one cutscene.
		if (spraycan == null) {
			startCountdown();
			return;
		}

		moveCamera(false);
		camFollow.x += 250;
		FlxG.camera.snapToTarget();
		FlxG.camera.zoom = 1.3;
		spraycan.cutscene = true;

		cutsceneHandler = new CutsceneHandler();
		cutsceneHandler.endTime = 10;

		var cutsceneMusic:FlxSound = new FlxSound();
		cutsceneMusic.loadEmbedded(Paths.music('darnellCanCutscene'));
		cutsceneMusic.looped = true;
		FlxG.sound.list.add(cutsceneMusic);

		var darnellLaugh:FlxSound = new FlxSound();
		darnellLaugh.loadEmbedded(Paths.sound('cutscene/darnell_laugh'));
		darnellLaugh.volume = 0.6;
		FlxG.sound.list.add(darnellLaugh);

		var neneLaugh:FlxSound = new FlxSound();
		neneLaugh.loadEmbedded(Paths.sound('cutscene/nene_laugh'));
		neneLaugh.volume = 0.6;
		FlxG.sound.list.add(neneLaugh);

		camHUD.alpha = 0;
		gf.animation.finishCallback = function(name:String):Void {
			if (name == 'danceLeft' || name == 'danceRight') {
				gf.dance();
			}
		};
		gf.dance();

		dad.animation.finishCallback = function(name:String):Void {
			if (name == 'idle') {
				dad.dance();
			}
		};
		dad.dance();

		var cutsceneDelay:Float = 2.0;
		boyfriend.playAnim('intro1', true);

		// play music
		cutsceneHandler.timer(0.7, function():Void {
			cutsceneMusic.play();
		});

		// zoom out to show off everything
		cutsceneHandler.timer(cutsceneDelay, function():Void {
			moveCamera(true);
			camFollow.x += 100;
			FlxTween.tween(FlxG.camera.scroll, {x: camFollow.x + 100 - FlxG.width / 2, y: camFollow.y - FlxG.height / 2}, 2.5, {ease: FlxEase.quadInOut});
			FlxTween.tween(FlxG.camera, {zoom: 0.66}, 2.5, {ease: FlxEase.quadInOut});
		});

		// darnell lights can
		cutsceneHandler.timer(cutsceneDelay + 3, function():Void {
			dad.playAnim('lightCan', true);
			lightCanSnd.play(true);
		});

		// pico reloads
		cutsceneHandler.timer(cutsceneDelay + 4, function():Void {
			boyfriend.playAnim('cock', true);
			FlxTween.tween(FlxG.camera.scroll, {x: camFollow.x + 180 - FlxG.width / 2}, 0.4, {ease: FlxEase.backOut});
			gunPrepSnd.play(true);
		});

		cutsceneHandler.timer(cutsceneDelay + 4.166, function():Void {
			createCasing();
		});

		// darnell kicks can
		cutsceneHandler.timer(cutsceneDelay + 4.4, function():Void {
			dad.playAnim('kickCan', true);
			spraycan.playCanStart();
			kickCanSnd.play(true);
		});

		// darnell knees can
		cutsceneHandler.timer(cutsceneDelay + 4.8, function():Void {
			dad.playAnim('kneeCan', true);
			kneeCanSnd.play(true);
		});

		// pico fires at can
		cutsceneHandler.timer(cutsceneDelay + 5.1, function():Void {
			boyfriend.playAnim('intro2', true);
			boyfriend.specialAnim = true;

			FlxG.sound.play(Paths.soundRandom('shots/shot', 1, 4));

			FlxTween.tween(FlxG.camera.scroll, {x: camFollow.x + 100 - FlxG.width / 2}, 2.5, {ease: FlxEase.quadInOut});

			spraycan.playCanShot();
			new FlxTimer().start(1 / 24, function(tmr:FlxTimer):Void {
				darkenStageProps();
			});
		});

		// darnell laughs
		cutsceneHandler.timer(cutsceneDelay + 5.9, function():Void {
			dad.animation.finishCallback = null;
			dad.playAnim('laughCutscene', true);
			darnellLaugh.play(true);
		});

		// nene spits and laughs
		cutsceneHandler.timer(cutsceneDelay + 6.2, function():Void {
			gf.animation.finishCallback = null;
			gf.playAnim('laughCutscene', true);
			neneLaugh.play(true);
		});

		// cutscene ended, camera returns to normal, cutscene flags set and countdown starts.
		cutsceneHandler.finishCallback = function():Void {
			cutsceneMusic.stop();

			PlayState.instance.cameraSpeed = 0;
			FlxTween.tween(FlxG.camera, {zoom: 0.77}, 2, {ease: FlxEase.sineInOut});
			FlxTween.tween(FlxG.camera.scroll, {x: camFollow.x + 180 - FlxG.width / 2}, 2, {
				ease: FlxEase.sineInOut,
				onComplete: function(twn:FlxTween):Void {
					PlayState.instance.cameraSpeed = 1;
				}
			});
			PlayState.instance.inCutscene = false;

			spraycan.visible = false;
			spraycan.active = false;
			spraycan.cutscene = false;
			camHUD.alpha = 1;
			startCountdown();
		};

		cutsceneHandler.skipCallback = function():Void {
			cutsceneHandler.finishCallback();

			dad.dance();
			gf.dance();
			boyfriend.dance();
			dad.animation.finishCallback = null;
			gf.animation.finishCallback = null;

			moveCameraSection();
			PlayState.instance.cameraSpeed = 1;
			FlxTween.cancelTweensOf(FlxG.camera);
			FlxTween.cancelTweensOf(FlxG.camera.scroll);
			FlxG.camera.scroll.set(camFollow.x - FlxG.width / 2, camFollow.y - FlxG.height / 2);
			FlxG.camera.zoom = defaultCamZoom;
		};
		FlxG.camera.fade(FlxColor.BLACK, 2, true, null, true);
	}

	function updateABotEye(finishInstantly:Bool = false):Void {
		var sections:Array<Dynamic> = PlayState.SONG.notes;
		var index:Int = Std.int(FlxMath.bound(curSection, 0, sections.length - 1));
		if (sections[index].mustHitSection == true) {
			abot.lookRight();
		} else {
			abot.lookLeft();
		}

		if (finishInstantly && abot.eyes.anim.curAnim != null) {
			abot.eyes.anim.curAnim.curFrame = abot.eyes.anim.curAnim.numFrames - 1;
		}
	}

	override function startSong():Void {
		abot.snd = FlxG.sound.music;
		gf.animation.finishCallback = function(name:String):Void {
			onNeneAnimationFinished(name);
		};
	}

	function onNeneAnimationFinished(name:String):Void {
		if (!PlayState.instance.startedCountdown) {
			return;
		}

		if (currentNeneState == stRaise || currentNeneState == stLower) {
			if (name == 'raiseKnife' || name == 'lowerKnife') {
				animationFinished = true;
				transitionState();
			}
		}
	}

	function precache():Void {
		for (noteType in noteTypes) {
			if (noteType == 'weekend-1-kickcan') {
				createCan();
			} else if (noteType == 'weekend-1-cockgun') {
				precacheCasing();
			} else if (noteType == 'weekend-1-firegun') {
				bonkSnd = new FlxSound();
				FlxG.sound.list.add(bonkSnd);
				bonkSnd.loadEmbedded(Paths.sound('Pico_Bonk'));
			}
		}

		if (isStoryMode && !seenCutscene && songName == 'darnell') {
			createCan();
			precacheCasing();
		}

		for (i in 1...5) {
			Paths.sound('shots/shot' + i);
		}
	}

	var didCreateCan:Bool = false;

	function createCan():Void {
		if (didCreateCan) {
			return;
		}
		didCreateCan = true;

		spraycan = new SpraycanAtlasSprite(spraycanPile.x + 530, spraycanPile.y - 240);
		add(spraycan);

		lightCanSnd = new FlxSound();
		FlxG.sound.list.add(lightCanSnd);
		lightCanSnd.loadEmbedded(Paths.sound('Darnell_Lighter'));

		kickCanSnd = new FlxSound();
		FlxG.sound.list.add(kickCanSnd);
		kickCanSnd.loadEmbedded(Paths.sound('Kick_Can_UP'));

		kneeCanSnd = new FlxSound();
		FlxG.sound.list.add(kneeCanSnd);
		kneeCanSnd.loadEmbedded(Paths.sound('Kick_Can_FORWARD'));
	}

	var didCreateCasing:Bool = false;

	function precacheCasing():Void {
		if (didCreateCasing) {
			return;
		}
		didCreateCasing = true;

		if (!ClientPrefs.data.lowQuality) {
			casingFrames = Paths.getSparrowAtlas('PicoBullet'); // precache
			casingGroup = new FlxSpriteGroup(0, 0);
			add(casingGroup);
		}

		gunPrepSnd = new FlxSound();
		FlxG.sound.list.add(gunPrepSnd);
		gunPrepSnd.loadEmbedded(Paths.sound('Gun_Prep'));
	}

	function setupRainShader():Void {
		rainShader = new RainShader();
		rainShader.scale = FlxG.height / 200;
		if (songName == 'darnell') {
			rainShaderStartIntensity = 0;
			rainShaderEndIntensity = 0.1;
		} else if (songName == 'lit-up') {
			rainShaderStartIntensity = 0.1;
			rainShaderEndIntensity = 0.2;
		} else if (songName == '2hot') {
			rainShaderStartIntensity = 0.2;
			rainShaderEndIntensity = 0.4;
		}
		rainShader.intensity = rainShaderStartIntensity;
		FlxG.camera.filters = [new ShaderFilter(rainShader)];
	}

	override function update(elapsed:Float):Void {
		if (scrollingSky != null) {
			scrollingSky.scrollX -= elapsed * 22;
		}

		if (rainShader != null) {
			var length:Float = (FlxG.sound.music != null) ? FlxG.sound.music.length : 0;
			rainShader.intensity = FlxMath.remapToRange(Conductor.songPosition, 0, length, rainShaderStartIntensity, rainShaderEndIntensity);
			rainShader.updateViewInfo(FlxG.width, FlxG.height, FlxG.camera);
			rainShader.update(elapsed);
		}

		if (gf == null || !PlayState.instance.startedCountdown) {
			return;
		}

		animationFinished = gf.isAnimationFinished();
		transitionState();
	}

	function transitionState():Void {
		if (currentNeneState == stDefault) {
			if (PlayState.instance.health <= VULTURE_THRESHOLD) {
				currentNeneState = stPreRaise;
				gf.skipDance = true;
			}
		} else if (currentNeneState == stPreRaise) {
			if (PlayState.instance.health > VULTURE_THRESHOLD) {
				currentNeneState = stDefault;
				gf.skipDance = false;
			} else if (animationFinished) {
				currentNeneState = stRaise;
				gf.playAnim('raiseKnife');
				gf.skipDance = true;
				gf.danced = true;
				animationFinished = false;
			}
		} else if (currentNeneState == stRaise) {
			if (animationFinished) {
				currentNeneState = stReady;
				animationFinished = false;
			}
		} else if (currentNeneState == stReady) {
			if (PlayState.instance.health > VULTURE_THRESHOLD) {
				currentNeneState = stLower;
				gf.playAnim('lowerKnife');
			}
		} else if (currentNeneState == stLower) {
			if (animationFinished) {
				currentNeneState = stDefault;
				animationFinished = false;
				gf.skipDance = false;
			}
		}
	}

	override function sectionHit():Void {
		updateABotEye(false);
	}

	override function beatHit():Void {
		if (currentNeneState == stReady) {
			// In other states, don't interrupt the existing animation.
			if (blinkCountdown == 0) {
				gf.playAnim('idleKnife', false);
				blinkCountdown = FlxG.random.int(MIN_BLINK_DELAY, MAX_BLINK_DELAY);
			} else {
				blinkCountdown--;
			}
		}

		if (ClientPrefs.data.lowQuality) {
			return;
		}

		if (FlxG.random.bool(10) && curBeat != (lastChange + changeInterval) && carInterruptable == true) {
			if (lightsStop == false) {
				driveCar(phillyCars);
			} else {
				driveCarLights(phillyCars);
			}
		}

		if (FlxG.random.bool(10) && curBeat != (lastChange + changeInterval) && car2Interruptable == true && lightsStop == false) {
			driveCarBack(phillyCars2);
		}

		if (curBeat == (lastChange + changeInterval)) {
			changeLights(curBeat);
		}
	}

	function changeLights(beat:Int):Void {
		lastChange = beat;
		lightsStop = !lightsStop;

		if (lightsStop) {
			phillyTraffic.animation.play('greentored');
			changeInterval = 20;
		} else {
			phillyTraffic.animation.play('redtogreen');
			changeInterval = 30;

			if (carWaiting == true) {
				finishCarLights(phillyCars);
			}
		}
	}

	/** A raw point for a tween path: see the class note on why these are not `FlxPoint`. **/
	function point(x:Float, y:Float):FlxBasePoint {
		var p:FlxBasePoint = FlxPoint.get(x, y);
		return p;
	}

	function finishCarLights(sprite:FlxSprite):Void {
		carWaiting = false;
		var duration:Float = FlxG.random.float(1.8, 3);
		var rotations:Array<Int> = [-5, 18];
		var offset:Array<Float> = [306.6, 168.3];
		var startdelay:Float = FlxG.random.float(0.2, 1.2);

		var path:Array<FlxBasePoint> = [
			point(1950 - offset[0] - 80, 980 - offset[1] + 15),
			point(2400 - offset[0], 980 - offset[1] - 50),
			point(3102 - offset[0], 1127 - offset[1] + 40)
		];

		FlxTween.angle(sprite, rotations[0], rotations[1], duration, {ease: FlxEase.sineIn, startDelay: startdelay});
		FlxTween.quadPath(sprite, path, duration, true, {
			ease: FlxEase.sineIn,
			startDelay: startdelay,
			onComplete: function(twn:FlxTween):Void {
				carInterruptable = true;
			}
		});
	}

	function driveCarLights(sprite:FlxSprite):Void {
		carInterruptable = false;
		FlxTween.cancelTweensOf(sprite);
		var variant:Int = FlxG.random.int(1, 4);
		sprite.animation.play('car' + variant);
		var extraOffset:Array<Float> = [0, 0];
		var duration:Float = 2;

		if (variant == 1) {
			duration = FlxG.random.float(1, 1.7);
		} else if (variant == 2) {
			extraOffset = [20, -15];
			duration = FlxG.random.float(0.9, 1.5);
		} else if (variant == 3) {
			extraOffset = [30, 50];
			duration = FlxG.random.float(1.5, 2.5);
		} else if (variant == 4) {
			extraOffset = [10, 60];
			duration = FlxG.random.float(1.5, 2.5);
		}

		var rotations:Array<Int> = [-7, -5];
		var offset:Array<Float> = [306.6, 168.3];
		sprite.offset.set(extraOffset[0], extraOffset[1]);

		var path:Array<FlxBasePoint> = [
			point(1500 - offset[0] - 20, 1049 - offset[1] - 20),
			point(1770 - offset[0] - 80, 994 - offset[1] + 10),
			point(1950 - offset[0] - 80, 980 - offset[1] + 15)
		];

		FlxTween.angle(sprite, rotations[0], rotations[1], duration, {ease: FlxEase.cubeOut});
		FlxTween.quadPath(sprite, path, duration, true, {
			ease: FlxEase.cubeOut,
			onComplete: function(twn:FlxTween):Void {
				carWaiting = true;
				if (lightsStop == false) {
					finishCarLights(phillyCars);
				}
			}
		});
	}

	function driveCar(sprite:FlxSprite):Void {
		carInterruptable = false;
		FlxTween.cancelTweensOf(sprite);
		var variant:Int = FlxG.random.int(1, 4);
		sprite.animation.play('car' + variant);

		var extraOffset:Array<Float> = [0, 0];
		var duration:Float = 2;
		if (variant == 1) {
			duration = FlxG.random.float(1, 1.7);
		} else if (variant == 2) {
			extraOffset = [20, -15];
			duration = FlxG.random.float(0.6, 1.2);
		} else if (variant == 3) {
			extraOffset = [30, 50];
			duration = FlxG.random.float(1.5, 2.5);
		} else if (variant == 4) {
			extraOffset = [10, 60];
			duration = FlxG.random.float(1.5, 2.5);
		}

		var offset:Array<Float> = [306.6, 168.3];
		sprite.offset.set(extraOffset[0], extraOffset[1]);

		var rotations:Array<Int> = [-8, 18];
		var path:Array<FlxBasePoint> = [
			point(1570 - offset[0], 1049 - offset[1] - 30),
			point(2400 - offset[0], 980 - offset[1] - 50),
			point(3102 - offset[0], 1127 - offset[1] + 40)
		];

		FlxTween.angle(sprite, rotations[0], rotations[1], duration);
		FlxTween.quadPath(sprite, path, duration, true, {
			onComplete: function(twn:FlxTween):Void {
				carInterruptable = true;
			}
		});
	}

	function driveCarBack(sprite:FlxSprite):Void {
		car2Interruptable = false;
		FlxTween.cancelTweensOf(sprite);
		var variant:Int = FlxG.random.int(1, 4);
		sprite.animation.play('car' + variant);

		var extraOffset:Array<Float> = [0, 0];
		var duration:Float = 2;
		if (variant == 1) {
			duration = FlxG.random.float(1, 1.7);
		} else if (variant == 2) {
			extraOffset = [20, -15];
			duration = FlxG.random.float(0.6, 1.2);
		} else if (variant == 3) {
			extraOffset = [30, 50];
			duration = FlxG.random.float(1.5, 2.5);
		} else if (variant == 4) {
			extraOffset = [10, 60];
			duration = FlxG.random.float(1.5, 2.5);
		}

		var offset:Array<Float> = [306.6, 168.3];
		sprite.offset.set(extraOffset[0], extraOffset[1]);

		var rotations:Array<Int> = [18, -8];
		var path:Array<FlxBasePoint> = [
			point(3102 - offset[0], 1127 - offset[1] + 60),
			point(2400 - offset[0], 980 - offset[1] - 30),
			point(1570 - offset[0], 1049 - offset[1] - 10)
		];

		FlxTween.angle(sprite, rotations[0], rotations[1], duration);
		FlxTween.quadPath(sprite, path, duration, true, {
			onComplete: function(twn:FlxTween):Void {
				car2Interruptable = true;
			}
		});
	}

	override function goodNoteHit(note:Dynamic):Void {
		// 10% chance of playing combo50/combo100 animations for Nene
		if (FlxG.random.bool(10)) {
			var combo:Int = PlayState.instance.combo;
			if (combo == 50 || combo == 100) {
				var animToPlay:String = 'combo' + combo;
				if (gf.animation.exists(animToPlay)) {
					gf.playAnim(animToPlay);
					gf.specialAnim = true;
				}
			}
		}

		if (note.type == 'weekend-1-cockgun') { // HE'S PULLING HIS COCK OUT
			boyfriend.holdTimer = 0;
			boyfriend.playAnim('cock', true);
			boyfriend.specialAnim = true;
			gunPrepSnd.play();

			boyfriend.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int):Void {
				if (name == 'cock') {
					if (frameNumber == 3) {
						boyfriend.animation.callback = null;
						createCasing();
					}
				} else {
					boyfriend.animation.callback = null;
				}
			};

			for (field in PlayState.instance.noteFields) {
				for (active in field.active) {
					if (active.data.type == 'weekend-1-firegun') {
						active.data.blockHit = false;
					}
				}
			}
			showPicoFade();
		} else if (note.type == 'weekend-1-firegun') {
			boyfriend.holdTimer = 0;
			boyfriend.playAnim('shoot', true);
			boyfriend.specialAnim = true;
			FlxG.sound.play(Paths.soundRandom('shots/shot', 1, 4));
			spraycan.playCanShot();

			new FlxTimer().start(1 / 24, function(tmr:FlxTimer):Void {
				darkenStageProps();
			});
		}
	}

	function createCasing():Void {
		if (ClientPrefs.data.lowQuality) {
			return;
		}

		var casing:FlxSprite = new FlxSprite(boyfriend.x + 250, boyfriend.y + 100);
		casing.frames = casingFrames;
		casing.animation.addByPrefix('pop', 'Pop0', 24, false);
		casing.animation.addByPrefix('idle', 'Bullet0', 24, true);
		casing.animation.play('pop', true);

		casing.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int):Void {
			if (name == 'pop' && frameNumber == 40) {
				// Get the end position of the bullet dynamically.
				casing.x = casing.x + casing.frame.offset.x - 1;
				casing.y = casing.y + casing.frame.offset.y + 1;

				casing.angle = 125.1; // Copied from FLA

				// Velocity and angular acceleration make it roll without editing update().
				var randomFactorA:Float = FlxG.random.float(3, 10);
				var randomFactorB:Float = FlxG.random.float(1.0, 2.0);
				casing.velocity.x = 20 * randomFactorB;
				casing.drag.x = randomFactorA * randomFactorB;

				casing.angularVelocity = 100;
				// Calculated to ensure angular acceleration is maintained through the whole roll.
				casing.angularDrag = (casing.drag.x / casing.velocity.x) * 100;

				casing.animation.play('idle');
				casing.animation.callback = null; // Save performance.
			}
		};
		casingGroup.add(casing);
	}

	override function opponentNoteHit(note:Dynamic):Void {
		var sndTime:Float = note.time - Conductor.songPosition;

		if (note.type == 'weekend-1-lightcan') {
			dad.holdTimer = 0;
			dad.playAnim('lightCan', true);
			dad.specialAnim = true;
			lightCanSnd.play(true, sndTime - 65);

			PlayState.instance.isCameraOnForcedPos = true;
			PlayState.instance.defaultCamZoom += 0.1;
			moveCamera(true);
			PlayState.instance.cameraSpeed = 2;
			camFollow.x -= 100;
		} else if (note.type == 'weekend-1-kickcan') {
			dad.holdTimer = 0;
			dad.playAnim('kickCan', true);
			dad.specialAnim = true;
			kickCanSnd.play(true, sndTime - 50);
			spraycan.playCanStart();
			camFollow.x += 250;
			PlayState.instance.cameraSpeed = 1.5;
			PlayState.instance.defaultCamZoom -= 0.1;

			new FlxTimer().start(1.1, function(tmr:FlxTimer):Void {
				PlayState.instance.isCameraOnForcedPos = false;
				moveCameraSection();
				PlayState.instance.cameraSpeed = 1;
			});
		} else if (note.type == 'weekend-1-kneecan') {
			dad.holdTimer = 0;
			dad.playAnim('kneeCan', true);
			dad.specialAnim = true;
			kneeCanSnd.play(true, sndTime - 22);
		}
	}

	override function noteMiss(note:Dynamic):Void {
		if (note.type != 'weekend-1-firegun') {
			return;
		}

		boyfriend.playAnim('shootMISS', true);
		boyfriend.specialAnim = true;
		bonkSnd.play();

		if (picoFlicker != null) {
			picoFlicker.cancel();
			picoFlicker.destroy();
		}
		picoFlicker = null;

		boyfriend.animation.finishCallback = function(name:String):Void {
			if (name == 'shootMISS'
				&& PlayState.instance.health > 0.0
				&& !PlayState.instance.practiceMode
				&& PlayState.instance.gameOverTimer == null) {
				// FlxFlicker was crashing so fuck it, FlxTimer all the way
				picoFlicker = new FlxTimer().start(1 / 30, function(tmr:FlxTimer):Void {
					boyfriend.visible = !boyfriend.visible;
					if (tmr.loopsLeft == 0) {
						boyfriend.visible = true;
						picoFlicker = new FlxTimer().start(1 / 60, function(tmr2:FlxTimer):Void {
							boyfriend.visible = !boyfriend.visible;
							if (tmr2.loopsLeft == 0) {
								boyfriend.visible = true;
							}
						}, 30);
					}
				}, 30);
			}
			boyfriend.animation.finishCallback = null;
		};

		PlayState.instance.health -= 0.4;
		if (PlayState.instance.health <= 0.0 && !PlayState.instance.practiceMode) {
			GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pico-explode';
			GameOverSubstate.loopSoundName = 'gameOverStart-pico-explode';
			GameOverSubstate.characterName = 'pico-explosion-dead';
		}
	}

	/**
		Only the plain `pico-dead` death gets the retry text. The firegun explosion swaps the character
		out from under it (`pico-explosion-dead`), and that one has no overlay art.
	**/
	override function gameOverStart(gameOver:GameOverSubstate):Void {
		if (GameOverSubstate.characterName == 'pico-dead' && Paths.getSparrowAtlas('Pico_Death_Retry') != null) {
			new PicoDeathOverlay(gameOver);
		}
	}

	function showPicoFade():Void {
		if (ClientPrefs.data.lowQuality) {
			return;
		}

		picoFade.setPosition(boyfriend.x, boyfriend.y);
		picoFade.frames = boyfriend.frames;
		picoFade.frame = boyfriend.frame;
		picoFade.alpha = 0.3;
		picoFade.scale.set(1, 1);
		picoFade.updateHitbox();
		picoFade.visible = true;

		FlxTween.cancelTweensOf(picoFade.scale);
		FlxTween.cancelTweensOf(picoFade);
		FlxTween.tween(picoFade.scale, {x: 1.3, y: 1.3}, 0.4);
		FlxTween.tween(picoFade, {alpha: 0}, 0.4, {
			onComplete: function(twn:FlxTween):Void {
				picoFade.visible = false;
			}
		});
	}

	function darkenStageProps():Void {
		// Darken the background, then fade it back.
		for (sprite in darkenable) {
			// Copied into a block-scoped local so each timer closure captures its own sprite rather
			// than whatever the loop variable holds when the timers fire.
			var target:FlxSprite = sprite;
			target.color = 0xFF111111;
			new FlxTimer().start(1 / 24, function(tmr:FlxTimer):Void {
				target.color = 0xFF222222;
				FlxTween.color(target, 1.4, 0xFF222222, 0xFFFFFFFF);
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
