package stages.objects;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import objects.Character;
import states.PlayState;

/**
	Darnell's side of the Blazin' fight: which animation answers each note type, hit or missed. Ported
	from the compiled version.
**/
class DarnellBlazinHandler {
	var cantUppercut:Bool = false;
	var alternate:Bool = false;

	var boyfriend(get, never):Character;
	var dad(get, never):Character;
	var boyfriendGroup(get, never):FlxSpriteGroup;
	var dadGroup(get, never):FlxSpriteGroup;

	public function new() {}

	function get_boyfriend():Character {
		return PlayState.instance.boyfriend;
	}

	function get_dad():Character {
		return PlayState.instance.dad;
	}

	function get_boyfriendGroup():FlxSpriteGroup {
		return PlayState.instance.boyfriendGroup;
	}

	function get_dadGroup():FlxSpriteGroup {
		return PlayState.instance.dadGroup;
	}

	public function noteHit(note:Dynamic):Void {
		// SPECIAL CASE: If Pico hits a poor note at low health (at 30% chance), Darnell may duck below
		// Pico's punch to attempt an uppercut.
		if (wasNoteHitPoorly(note.rating) && isPlayerLowHealth() && FlxG.random.bool(30)) {
			playUppercutPrepAnim();
			return;
		}

		if (cantUppercut) {
			playPunchHighAnim();
			return;
		}

		// Override the hit note animation.
		switch (note.type) {
			case 'weekend-1-punchlow':
				playHitLowAnim();
			case 'weekend-1-punchlowblocked':
				playBlockAnim();
			case 'weekend-1-punchlowdodged':
				playDodgeAnim();
			case 'weekend-1-punchlowspin':
				playSpinAnim();

			case 'weekend-1-punchhigh':
				playHitHighAnim();
			case 'weekend-1-punchhighblocked':
				playBlockAnim();
			case 'weekend-1-punchhighdodged':
				playDodgeAnim();
			case 'weekend-1-punchhighspin':
				playSpinAnim();

			// Attempt to punch, Pico dodges or gets hit.
			case 'weekend-1-blockhigh', 'weekend-1-blockspin':
				playPunchHighAnim();
			case 'weekend-1-blocklow':
				playPunchLowAnim();

			case 'weekend-1-dodgehigh', 'weekend-1-dodgespin':
				playPunchHighAnim();
			case 'weekend-1-dodgelow':
				playPunchLowAnim();

			// Attempt to punch, Pico ALWAYS gets hit.
			case 'weekend-1-hithigh', 'weekend-1-hitspin':
				playPunchHighAnim();
			case 'weekend-1-hitlow':
				playPunchLowAnim();

			// Fail to dodge the uppercut. Continues whatever animation was playing before.
			case 'weekend-1-picouppercutprep':
			case 'weekend-1-picouppercut':
				playUppercutHitAnim();

			// Attempt to punch, Pico dodges or gets hit.
			case 'weekend-1-darnelluppercutprep':
				playUppercutPrepAnim();
			case 'weekend-1-darnelluppercut':
				playUppercutAnim();

			case 'weekend-1-idle':
				playIdleAnim();
			case 'weekend-1-fakeout':
				playCringeAnim();
			case 'weekend-1-taunt':
				playPissedConditionalAnim();
			case 'weekend-1-tauntforce':
				playPissedAnim();
			case 'weekend-1-reversefakeout':
				playFakeoutAnim();
		}

		cantUppercut = false;
	}

	public function noteMiss(note:Dynamic):Void {
		// SPECIAL CASE: Darnell prepared to uppercut last time and Pico missed! FINISH HIM!
		if (dad.getAnimationName() == 'uppercutPrep') {
			playUppercutAnim();
			return;
		}

		if (willMissBeLethal()) {
			playPunchLowAnim();
			return;
		}

		if (cantUppercut) {
			playPunchHighAnim();
			return;
		}

		// Override the hit note animation.
		switch (note.type) {
			// Pico tried and failed to punch, punch back!
			case 'weekend-1-punchlow', 'weekend-1-punchlowblocked', 'weekend-1-punchlowdodged', 'weekend-1-punchlowspin':
				playPunchLowAnim();

			case 'weekend-1-punchhigh', 'weekend-1-punchhighblocked', 'weekend-1-punchhighdodged', 'weekend-1-punchhighspin':
				playPunchHighAnim();

			// Attempt to punch, Pico dodges or gets hit.
			case 'weekend-1-blockhigh', 'weekend-1-blockspin':
				playPunchHighAnim();
			case 'weekend-1-blocklow':
				playPunchLowAnim();

			case 'weekend-1-dodgehigh', 'weekend-1-dodgespin':
				playPunchHighAnim();
			case 'weekend-1-dodgelow':
				playPunchLowAnim();

			// Attempt to punch, Pico ALWAYS gets hit.
			case 'weekend-1-hithigh', 'weekend-1-hitspin':
				playPunchHighAnim();
			case 'weekend-1-hitlow':
				playPunchLowAnim();

			// Successfully dodge the uppercut.
			case 'weekend-1-picouppercutprep':
				playHitHighAnim();
				cantUppercut = true;
			case 'weekend-1-picouppercut':
				playDodgeAnim();

			// Attempt to punch, Pico dodges or gets hit.
			case 'weekend-1-darnelluppercutprep':
				playUppercutPrepAnim();
			case 'weekend-1-darnelluppercut':
				playUppercutAnim();

			case 'weekend-1-idle':
				playIdleAnim();
			case 'weekend-1-fakeout':
				playCringeAnim();
			case 'weekend-1-taunt':
				playPissedConditionalAnim();
			case 'weekend-1-tauntforce':
				playPissedAnim();
			case 'weekend-1-reversefakeout':
				playFakeoutAnim();
		}
		cantUppercut = false;
	}

	public function noteMissPress(direction:Int):Void {
		if (willMissBeLethal()) {
			playPunchLowAnim(); // Darnell alternates a punch so that Pico dies.
		} else {
			// Pico wildly throws punches but Darnell alternates between dodges and blocks.
			if (FlxG.random.bool(50)) {
				playDodgeAnim();
			} else {
				playBlockAnim();
			}
		}
	}

	function doAlternate():String {
		alternate = !alternate;
		return alternate ? '1' : '2';
	}

	function playBlockAnim():Void {
		dad.playAnim('block', true);
		PlayState.instance.camGame.shake(0.002, 0.1);
		moveToBack();
	}

	function playCringeAnim():Void {
		dad.playAnim('cringe', true);
		moveToBack();
	}

	function playDodgeAnim():Void {
		dad.playAnim('dodge', true, false);
		moveToBack();
	}

	function playIdleAnim():Void {
		dad.playAnim('idle', false);
		moveToBack();
	}

	function playFakeoutAnim():Void {
		dad.playAnim('fakeout', true);
		moveToBack();
	}

	function playPissedConditionalAnim():Void {
		if (dad.getAnimationName() == 'cringe') {
			playPissedAnim();
		} else {
			playIdleAnim();
		}
	}

	function playPissedAnim():Void {
		dad.playAnim('pissed', true);
		moveToBack();
	}

	function playUppercutPrepAnim():Void {
		dad.playAnim('uppercutPrep', true);
		moveToFront();
	}

	function playUppercutAnim():Void {
		dad.playAnim('uppercut', true);
		moveToFront();
	}

	function playUppercutHitAnim():Void {
		dad.playAnim('uppercutHit', true);
		moveToBack();
	}

	function playHitHighAnim():Void {
		dad.playAnim('hitHigh', true);
		PlayState.instance.camGame.shake(0.0025, 0.15);
		moveToBack();
	}

	function playHitLowAnim():Void {
		dad.playAnim('hitLow', true);
		PlayState.instance.camGame.shake(0.0025, 0.15);
		moveToBack();
	}

	function playPunchHighAnim():Void {
		dad.playAnim('punchHigh' + doAlternate(), true);
		moveToFront();
	}

	function playPunchLowAnim():Void {
		dad.playAnim('punchLow' + doAlternate(), true);
		moveToFront();
	}

	function playSpinAnim():Void {
		dad.playAnim('hitSpin', true);
		PlayState.instance.camGame.shake(0.0025, 0.15);
		moveToBack();
	}

	function willMissBeLethal():Bool {
		return PlayState.instance.health <= 0.0 && !PlayState.instance.practiceMode;
	}

	function wasNoteHitPoorly(rating:String):Bool {
		return (rating == 'bad' || rating == 'shit');
	}

	function isPlayerLowHealth():Bool {
		return PlayState.instance.health <= 0.3 * 2;
	}

	function moveToBack():Void {
		var members:Array<Dynamic> = FlxG.state.members;
		var dadPos:Int = members.indexOf(dadGroup);
		var bfPos:Int = members.indexOf(boyfriendGroup);
		if (dadPos < bfPos) {
			return;
		}

		members[bfPos] = dadGroup;
		members[dadPos] = boyfriendGroup;
	}

	function moveToFront():Void {
		var members:Array<Dynamic> = FlxG.state.members;
		var dadPos:Int = members.indexOf(dadGroup);
		var bfPos:Int = members.indexOf(boyfriendGroup);
		if (dadPos > bfPos) {
			return;
		}

		members[bfPos] = dadGroup;
		members[dadPos] = boyfriendGroup;
	}
}
