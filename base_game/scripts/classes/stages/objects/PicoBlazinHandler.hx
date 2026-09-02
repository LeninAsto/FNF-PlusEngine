package stages.objects;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import objects.Character;
import states.PlayState;

/**
	Pico's side of the Blazin' fight: which animation answers each note type, hit or missed. Ported
	from the compiled version.

	The compiled class carried `movePicoToBack`/`movePicoToFront` alongside identical
	`moveToBack`/`moveToFront`; only the latter pair was ever called, so the duplicates are gone.
**/
class PicoBlazinHandler {
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
		if (wasNoteHitPoorly(note.rating) && isPlayerLowHealth() && isDarnellPreppingUppercut()) {
			playPunchHighAnim();
			return;
		}

		if (cantUppercut) {
			playBlockAnim();
			cantUppercut = false;
			return;
		}

		switch (note.type) {
			case 'weekend-1-punchlow', 'weekend-1-punchlowblocked', 'weekend-1-punchlowdodged', 'weekend-1-punchlowspin':
				playPunchLowAnim();

			case 'weekend-1-punchhigh', 'weekend-1-punchhighblocked', 'weekend-1-punchhighdodged', 'weekend-1-punchhighspin':
				playPunchHighAnim();

			case 'weekend-1-blockhigh', 'weekend-1-blocklow', 'weekend-1-blockspin':
				playBlockAnim();

			case 'weekend-1-dodgehigh', 'weekend-1-dodgelow', 'weekend-1-dodgespin':
				playDodgeAnim();

			// Pico ALWAYS gets punched.
			case 'weekend-1-hithigh':
				playHitHighAnim();
			case 'weekend-1-hitlow':
				playHitLowAnim();
			case 'weekend-1-hitspin':
				playHitSpinAnim();

			case 'weekend-1-picouppercutprep':
				playUppercutPrepAnim();
			case 'weekend-1-picouppercut':
				playUppercutAnim(true);

			case 'weekend-1-darnelluppercutprep':
				playIdleAnim();
			case 'weekend-1-darnelluppercut':
				playUppercutHitAnim();

			case 'weekend-1-idle':
				playIdleAnim();
			case 'weekend-1-fakeout':
				playFakeoutAnim();
			case 'weekend-1-taunt':
				playTauntConditionalAnim();
			case 'weekend-1-tauntforce':
				playTauntAnim();
			case 'weekend-1-reversefakeout':
				playIdleAnim();
		}
	}

	public function noteMiss(note:Dynamic):Void {
		if (isDarnellInUppercut()) {
			playUppercutHitAnim();
			return;
		}

		if (willMissBeLethal()) {
			playHitLowAnim();
			return;
		}

		if (cantUppercut) {
			playHitHighAnim();
			return;
		}

		switch (note.type) {
			// Pico fails to punch, and instead gets hit!
			case 'weekend-1-punchlow', 'weekend-1-punchlowblocked', 'weekend-1-punchlowdodged':
				playHitLowAnim();
			case 'weekend-1-punchlowspin':
				playHitSpinAnim();

			case 'weekend-1-punchhigh', 'weekend-1-punchhighblocked', 'weekend-1-punchhighdodged':
				playHitHighAnim();
			case 'weekend-1-punchhighspin':
				playHitSpinAnim();

			// Pico fails to block, and instead gets hit!
			case 'weekend-1-blockhigh':
				playHitHighAnim();
			case 'weekend-1-blocklow':
				playHitLowAnim();
			case 'weekend-1-blockspin':
				playHitSpinAnim();

			// Pico fails to dodge, and instead gets hit!
			case 'weekend-1-dodgehigh':
				playHitHighAnim();
			case 'weekend-1-dodgelow':
				playHitLowAnim();
			case 'weekend-1-dodgespin':
				playHitSpinAnim();

			// Pico ALWAYS gets punched.
			case 'weekend-1-hithigh':
				playHitHighAnim();
			case 'weekend-1-hitlow':
				playHitLowAnim();
			case 'weekend-1-hitspin':
				playHitSpinAnim();

			// Fail to dodge the uppercut.
			case 'weekend-1-picouppercutprep':
				playPunchHighAnim();
				cantUppercut = true;
			case 'weekend-1-picouppercut':
				playUppercutAnim(false);

			// Darnell's attempt to uppercut, Pico dodges or gets hit.
			case 'weekend-1-darnelluppercutprep':
				playIdleAnim();
			case 'weekend-1-darnelluppercut':
				playUppercutHitAnim();

			case 'weekend-1-idle':
				playIdleAnim();
			case 'weekend-1-fakeout':
				playHitHighAnim();
			case 'weekend-1-taunt':
				playTauntConditionalAnim();
			case 'weekend-1-tauntforce':
				playTauntAnim();
			case 'weekend-1-reversefakeout':
				playIdleAnim();
		}
	}

	public function noteMissPress(direction:Int):Void {
		if (willMissBeLethal()) {
			playHitLowAnim(); // Darnell throws a punch so that Pico dies.
		} else {
			playPunchHighAnim(); // Pico wildly throws punches but Darnell dodges.
		}
	}

	function doAlternate():String {
		alternate = !alternate;
		return alternate ? '1' : '2';
	}

	function playBlockAnim():Void {
		boyfriend.playAnim('block', true);
		FlxG.camera.shake(0.002, 0.1);
		moveToBack();
	}

	function playCringeAnim():Void {
		boyfriend.playAnim('cringe', true);
		moveToBack();
	}

	function playDodgeAnim():Void {
		boyfriend.playAnim('dodge', true);
		moveToBack();
	}

	function playIdleAnim():Void {
		boyfriend.playAnim('idle', false);
		moveToBack();
	}

	function playFakeoutAnim():Void {
		boyfriend.playAnim('fakeout', true);
		moveToBack();
	}

	function playUppercutPrepAnim():Void {
		boyfriend.playAnim('uppercutPrep', true);
		moveToFront();
	}

	function playUppercutAnim(hit:Bool):Void {
		boyfriend.playAnim('uppercut', true);
		if (hit) {
			FlxG.camera.shake(0.005, 0.25);
		}
		moveToFront();
	}

	function playUppercutHitAnim():Void {
		boyfriend.playAnim('uppercutHit', true);
		FlxG.camera.shake(0.005, 0.25);
		moveToBack();
	}

	function playHitHighAnim():Void {
		boyfriend.playAnim('hitHigh', true);
		FlxG.camera.shake(0.0025, 0.15);
		moveToBack();
	}

	function playHitLowAnim():Void {
		boyfriend.playAnim('hitLow', true);
		FlxG.camera.shake(0.0025, 0.15);
		moveToBack();
	}

	function playHitSpinAnim():Void {
		boyfriend.playAnim('hitSpin', true);
		FlxG.camera.shake(0.0025, 0.15);
		moveToBack();
	}

	function playPunchHighAnim():Void {
		boyfriend.playAnim('punchHigh' + doAlternate(), true);
		moveToFront();
	}

	function playPunchLowAnim():Void {
		boyfriend.playAnim('punchLow' + doAlternate(), true);
		moveToFront();
	}

	function playTauntConditionalAnim():Void {
		if (boyfriend.getAnimationName() == 'fakeout') {
			playTauntAnim();
		} else {
			playIdleAnim();
		}
	}

	function playTauntAnim():Void {
		boyfriend.playAnim('taunt', true);
		moveToBack();
	}

	function willMissBeLethal():Bool {
		return PlayState.instance.health <= 0.0 && !PlayState.instance.practiceMode;
	}

	function isDarnellPreppingUppercut():Bool {
		return dad.getAnimationName() == 'uppercutPrep';
	}

	function isDarnellInUppercut():Bool {
		return dad.getAnimationName() == 'uppercut' || dad.getAnimationName() == 'uppercut-hold';
	}

	function wasNoteHitPoorly(rating:String):Bool {
		return (rating == 'bad' || rating == 'shit');
	}

	function isPlayerLowHealth():Bool {
		return PlayState.instance.health <= 0.3 * 2;
	}

	function moveToBack():Void {
		var members:Array<Dynamic> = FlxG.state.members;
		var bfPos:Int = members.indexOf(boyfriendGroup);
		var dadPos:Int = members.indexOf(dadGroup);
		if (bfPos < dadPos) {
			return;
		}

		members[dadPos] = boyfriendGroup;
		members[bfPos] = dadGroup;
	}

	function moveToFront():Void {
		var members:Array<Dynamic> = FlxG.state.members;
		var bfPos:Int = members.indexOf(boyfriendGroup);
		var dadPos:Int = members.indexOf(dadGroup);
		if (bfPos > dadPos) {
			return;
		}

		members[dadPos] = boyfriendGroup;
		members[bfPos] = dadGroup;
	}
}
