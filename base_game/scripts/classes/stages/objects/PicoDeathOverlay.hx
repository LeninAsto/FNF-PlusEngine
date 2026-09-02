package stages.objects;

import backend.ClientPrefs;
import backend.Paths;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import objects.Character;
import states.PlayState;
import substates.GameOverSubstate;

/**
	Pico's "retry" text on the death screen, and Nene's knife toss behind it.

	The substate owns nothing here beyond the `overlay` slot: it plays whatever `deathLoop` and
	`deathConfirm` the sprite has, in step with the character, so this only has to build the sprite,
	hand it over, and reveal it on the frame Pico's head hits the floor.
**/
class PicoDeathOverlay {
	public function new(gameOver:GameOverSubstate) {
		var boyfriend:Character = gameOver.boyfriend;

		var overlay:FlxSprite = new FlxSprite(boyfriend.x + 205, boyfriend.y - 80);
		overlay.frames = Paths.getSparrowAtlas('Pico_Death_Retry');
		overlay.animation.addByPrefix('deathLoop', 'Retry Text Loop', 24, true);
		overlay.animation.addByPrefix('deathConfirm', 'Retry Text Confirm', 24, false);
		overlay.antialiasing = ClientPrefs.data.antialiasing;
		overlay.visible = false;
		gameOver.add(overlay);

		gameOver.overlay = overlay;
		gameOver.overlayConfirmOffsets.set(250, 200);

		boyfriend.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int):Void {
			if (name != 'firstDeath') {
				boyfriend.animation.callback = null;
			} else if (frameNumber >= 36 - 1) {
				overlay.visible = true;
				overlay.animation.play('deathLoop');
				boyfriend.animation.callback = null;
			}
		}

		var gf:Character = PlayState.instance.gf;
		if (gf != null && gf.curCharacter == 'nene' && Paths.getSparrowAtlas('NeneKnifeToss') != null)
			tossKnife(gameOver, boyfriend);
	}

	function tossKnife(gameOver:GameOverSubstate, boyfriend:Character):Void {
		var knife:FlxSprite = new FlxSprite(boyfriend.x - 450, boyfriend.y - 250);
		knife.frames = Paths.getSparrowAtlas('NeneKnifeToss');
		knife.animation.addByPrefix('anim', 'knife toss', 24, false);
		knife.antialiasing = ClientPrefs.data.antialiasing;

		knife.animation.finishCallback = function(name:String):Void {
			// Don't destroy mid-dispatch: flixel's fireFinishCallback runs this and then calls
			// onFinish.dispatch(), so destroying here nukes the signal it is about to dispatch.
			knife.visible = false;
			new FlxTimer().start(0.001, function(tmr:FlxTimer):Void {
				gameOver.remove(knife);
				knife.destroy();
			});
		}

		gameOver.insert(0, knife);
		knife.animation.play('anim', true);
	}
}
