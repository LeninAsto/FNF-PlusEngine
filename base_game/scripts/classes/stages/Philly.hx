package stages;

import backend.BaseStage;
import backend.ClientPrefs;
import backend.Conductor;
import backend.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import objects.Character;
import stages.objects.PhillyGlowGradient;
import stages.objects.PhillyGlowParticle;
import stages.objects.PhillyTrain;

/**
	Week 3. Ported from the compiled `states.stages.Philly`.

	The particle pool is hand-rolled rather than `FlxTypedGroup.recycle(PhillyGlowParticle)`: recycle
	takes a compiled `Class<T>` to instantiate, and a scripted class is not one. `spawnParticle` keeps
	recycle's actual semantics -- reuse a dead one, otherwise build one.
**/
class Philly extends BaseStage {
	var phillyLightsColors:Array<FlxColor>;
	var phillyWindow:FlxSprite;
	var phillyStreet:FlxSprite;
	var phillyTrain:PhillyTrain;
	var curLight:Int = -1;

	// For Philly Glow events
	var blammedLightsBlack:FlxSprite;
	var phillyGlowGradient:PhillyGlowGradient;
	var phillyGlowParticles:FlxGroup;
	var particlePool:Array<PhillyGlowParticle> = [];
	var phillyWindowEvent:FlxSprite;
	var curLightEvent:Int = -1;

	override function create():Void {
		if (!ClientPrefs.data.lowQuality) {
			var bg:FlxSprite = backdrop('philly/sky', -100, 0, 0.1, 0.1);
			add(bg);
		}

		var city:FlxSprite = backdrop('philly/city', -10, 0, 0.3, 0.3);
		city.setGraphicSize(Std.int(city.width * 0.85));
		city.updateHitbox();
		add(city);

		phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
		phillyWindow = backdrop('philly/window', city.x, city.y, 0.3, 0.3);
		phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
		phillyWindow.updateHitbox();
		add(phillyWindow);
		phillyWindow.alpha = 0;

		if (!ClientPrefs.data.lowQuality) {
			var streetBehind:FlxSprite = backdrop('philly/behindTrain', -40, 50);
			add(streetBehind);
		}

		phillyTrain = new PhillyTrain(2000, 360);
		add(phillyTrain);

		phillyStreet = backdrop('philly/street', -40, 50);
		add(phillyStreet);
	}

	override function eventPushed(event:Dynamic):Void {
		if (event.event != 'Philly Glow') {
			return;
		}

		blammedLightsBlack = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5);
		blammedLightsBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
		blammedLightsBlack.visible = false;
		insert(members.indexOf(phillyStreet), blammedLightsBlack);

		phillyWindowEvent = backdrop('philly/window', phillyWindow.x, phillyWindow.y, 0.3, 0.3);
		phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
		phillyWindowEvent.updateHitbox();
		phillyWindowEvent.visible = false;
		insert(members.indexOf(blammedLightsBlack) + 1, phillyWindowEvent);

		phillyGlowGradient = new PhillyGlowGradient(-400, 225);
		phillyGlowGradient.visible = false;
		insert(members.indexOf(blammedLightsBlack) + 1, phillyGlowGradient);
		if (!ClientPrefs.data.flashing) {
			phillyGlowGradient.intendedAlpha = 0.7;
		}

		Paths.image('philly/particle'); // precache philly glow particle image
		phillyGlowParticles = new FlxGroup();
		phillyGlowParticles.visible = false;
		insert(members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);
	}

	override function update(elapsed:Float):Void {
		phillyWindow.alpha -= (Conductor.crochet / 1000) * elapsed * 1.5;
		if (phillyGlowParticles != null) {
			phillyGlowParticles.forEachAlive(function(particle:PhillyGlowParticle):Void {
				if (particle.alpha <= 0) {
					particle.kill();
				}
			});
		}
	}

	override function beatHit():Void {
		phillyTrain.beatHit(curBeat);
		if (curBeat % 4 == 0) {
			curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
			phillyWindow.color = phillyLightsColors[curLight];
			phillyWindow.alpha = 1;
		}
	}

	override function eventCalled(eventName:String, value1:String, value2:String, value3:String, value4:String, flValue1:Null<Float> = null, flValue2:Null<Float> = null, flValue3:Null<Float> = null, flValue4:Null<Float> = null, strumTime:Float):Void {
		if (eventName != 'Philly Glow') {
			return;
		}

		var value:Float = (flValue1 == null || flValue1 <= 0) ? 0 : flValue1;
		var lightId:Int = Math.round(value);
		var chars:Array<Character> = [boyfriend, gf, dad];

		switch (lightId) {
			case 0:
				if (phillyGlowGradient.visible) {
					doFlash();
					if (ClientPrefs.data.camZooms) {
						FlxG.camera.zoom += 0.5;
						camHUD.zoom += 0.1;
					}

					blammedLightsBlack.visible = false;
					phillyWindowEvent.visible = false;
					phillyGlowGradient.visible = false;
					phillyGlowParticles.visible = false;
					curLightEvent = -1;

					for (who in chars) {
						if (who != null) {
							who.color = FlxColor.WHITE;
						}
					}
					phillyStreet.color = FlxColor.WHITE;
				}

			case 1: // turn on
				curLightEvent = FlxG.random.int(0, phillyLightsColors.length - 1, [curLightEvent]);
				var color:FlxColor = phillyLightsColors[curLightEvent];

				if (!phillyGlowGradient.visible) {
					doFlash();
					if (ClientPrefs.data.camZooms) {
						FlxG.camera.zoom += 0.5;
						camHUD.zoom += 0.1;
					}

					blammedLightsBlack.visible = true;
					blammedLightsBlack.alpha = 1;
					phillyWindowEvent.visible = true;
					phillyGlowGradient.visible = true;
					phillyGlowParticles.visible = true;
				} else if (ClientPrefs.data.flashing) {
					var colorButLower:FlxColor = color;
					colorButLower.alphaFloat = 0.25;
					FlxG.camera.flash(colorButLower, 0.5, null, true);
				}

				var charColor:FlxColor = color;
				if (!ClientPrefs.data.flashing) {
					charColor.saturation *= 0.5;
				} else {
					charColor.saturation *= 0.75;
				}

				for (who in chars) {
					if (who != null) {
						who.color = charColor;
					}
				}
				phillyGlowParticles.forEachAlive(function(particle:PhillyGlowParticle):Void {
					particle.color = color;
				});
				phillyGlowGradient.color = color;
				phillyWindowEvent.color = color;

				var streetColor:FlxColor = color;
				streetColor.brightness *= 0.5;
				phillyStreet.color = streetColor;

			case 2: // spawn particles
				if (!ClientPrefs.data.lowQuality) {
					var particlesNum:Int = FlxG.random.int(8, 12);
					var width:Float = (2000 / particlesNum);
					var color:FlxColor = phillyLightsColors[curLightEvent];
					for (j in 0...3) {
						for (i in 0...particlesNum) {
							var particle:PhillyGlowParticle = spawnParticle();
							particle.x = -400 + width * i + FlxG.random.float(-width / 5, width / 5);
							particle.y = phillyGlowGradient.originalY + 200 + (FlxG.random.float(0, 125) + j * 40);
							particle.color = color;
							particle.start();
						}
					}
				}
				phillyGlowGradient.bop();
		}
	}

	/** A dead particle brought back, or a new one added to the group. **/
	function spawnParticle():PhillyGlowParticle {
		for (particle in particlePool) {
			if (!particle.alive) {
				particle.revive();
				return particle;
			}
		}

		var particle:PhillyGlowParticle = new PhillyGlowParticle();
		particlePool.push(particle);
		phillyGlowParticles.add(particle);
		return particle;
	}

	function doFlash():Void {
		var color:FlxColor = FlxColor.WHITE;
		if (!ClientPrefs.data.flashing) {
			color.alphaFloat = 0.5;
		}

		FlxG.camera.flash(color, 0.15, null, true);
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
}
