package stages.objects;

import backend.ClientPrefs;
import backend.Paths;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import backend.PsychFlxAnimate;

/**
	Darnell's spray can, kicked into the air and shot down. Ported from the compiled version, with its
	module-level `SpraycanState` enum replaced by inline Int constants.
**/
class SpraycanAtlasSprite extends FlxSpriteGroup {
	// Plain instance fields, not statics: a scripted class's statics live on the class interpreter and
	// are not reachable from instance scope, and a class cannot even name itself to qualify them.
	// Lower-case so they are never mistaken for the enum constants they replace.
	var stWaiting:Int = 0;
	var stArcing:Int = 1; // In the air.
	var stShot:Int = 2; // Hit by the player.
	var stImpacted:Int = 3; // Impacted the player.

	/** One of the `st*` values above; starts at `stWaiting`, written as its value. **/
	public var currentState:Int = 0;

	public var canAtlas:Dynamic;
	public var explosion:FlxSprite;

	public var cutscene:Bool = false;

	var playingAnim:String;
	var waitingForFinish:Bool = false;

	public function new(x:Float = 0, y:Float = 0) {
		super(0, 0);

		canAtlas = new PsychFlxAnimate(x, y);
		Paths.loadAnimateAtlas(canAtlas, 'spraycanAtlas');
		canAtlas.anim.addBySymbolIndices('Can Start', 'Can with Labels', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 24, false);
		canAtlas.anim.addBySymbolIndices('Hit Pico', 'Can with Labels', [19, 20, 21, 22, 23, 24, 25], 24, false);
		canAtlas.anim.addBySymbolIndices('Can Shot', 'Can with Labels', [26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42], 24, false);
		canAtlas.visible = false;
		canAtlas.active = false;
		canAtlas.antialiasing = ClientPrefs.data.antialiasing;
		group.add(canAtlas);

		explosion = new FlxSprite(x - 25, y - 450);
		explosion.frames = Paths.getSparrowAtlas('spraypaintExplosionEZ');
		explosion.animation.addByPrefix('idle', 'explosion round 1 short0', 24, false);
		explosion.animation.finishCallback = function(name:String):Void {
			explosion.visible = false;
			explosion.active = false;
		};
		explosion.visible = false;
		explosion.active = false;
		explosion.antialiasing = ClientPrefs.data.antialiasing;
		group.add(explosion);
	}

	override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (waitingForFinish && canAtlas != null && canAtlas.anim != null && canAtlas.anim.finished) {
			waitingForFinish = false;
			finishCanAnimation();
		}
	}

	public function finishCanAnimation():Void {
		if (playingAnim == 'Can Start') {
			playHitPico();
		} else if (playingAnim == 'Can Shot') {
			canAtlas.visible = false;
			canAtlas.active = false;
			currentState = stWaiting;
		} else if (playingAnim == 'Hit Pico') {
			if (!cutscene) {
				playHitExplosion();
			}
			canAtlas.visible = false;
			canAtlas.active = false;
			currentState = stWaiting;
		}
	}

	public function playHitExplosion():Void {
		explosion.visible = true;
		explosion.active = true;
		explosion.animation.play('idle', true);
	}

	public function playCanStart():Void {
		playAnimation('Can Start');
		canAtlas.visible = true;
		canAtlas.active = true;
		currentState = stArcing;
	}

	public function playCanShot():Void {
		playAnimation('Can Shot');
		currentState = stShot;
	}

	public function playHitPico():Void {
		playAnimation('Hit Pico');
		currentState = stImpacted;
	}

	public function playAnimation(name:String):Void {
		canAtlas.anim.play(name, true);
		playingAnim = name;
		waitingForFinish = true;
	}
}
