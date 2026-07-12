package backend;

import flixel.FlxSubState;

// Base substate class — pure beat/step tracking, mobile controls, no scripts.
//
// Hierarchy:
//   FlxSubState
//   └── BaseMusicBeatSubstate   (this file — pure beat/mobile)
//       └── MusicBeatSubstate   (+ script hooks)

class BaseMusicBeatSubstate extends FlxSubState
{
	// ─── Beat/step counters ───────────────────────────────────────────────────
	public var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	public var curStep:Int = 0;
	public var curBeat:Int = 0;

	public var curDecStep:Float = 0;
	public var curDecBeat:Float = 0;

	// ─── Controls ─────────────────────────────────────────────────────────────
	private var controls(get, never):Controls;
	inline function get_controls():Controls return Controls.instance;

	// ─── Mobile controls ──────────────────────────────────────────────────────
	public var touchPad:TouchPad;
	public var touchPadCam:FlxCamera;
	public var mobileControls:IMobileControls;
	public var mobileControlsCam:FlxCamera;

	public function addTouchPad(DPad:String, Action:String):Void
	{
		touchPad = new TouchPad(DPad, Action);
		add(touchPad);
	}

	public function removeTouchPad():Void
	{
		if (touchPad != null)
		{
			remove(touchPad);
			touchPad = FlxDestroyUtil.destroy(touchPad);
		}
		if (touchPadCam != null)
		{
			FlxG.cameras.remove(touchPadCam);
			touchPadCam = FlxDestroyUtil.destroy(touchPadCam);
		}
	}

	public function addMobileControls(defaultDrawTarget:Bool = false):Void
	{
		var extraMode = MobileData.extraActions.get(ClientPrefs.data.extraButtons);
		if (extraMode == null) extraMode = NONE;

		switch (MobileData.mode)
		{
			case 0: mobileControls = new TouchPad('RIGHT_FULL', 'NONE', extraMode);
			case 1: mobileControls = new TouchPad('LEFT_FULL', 'NONE', extraMode);
			case 2: mobileControls = MobileData.getTouchPadCustom(new TouchPad('RIGHT_FULL', 'NONE', extraMode));
			case 3: mobileControls = new Hitbox(extraMode);
			case 4: mobileControls = new Hitbox(NONE, true);
		}

		if (mobileControls != null && mobileControls.instance != null)
		{
			mobileControls.instance = MobileData.setButtonsColors(mobileControls.instance);
			mobileControlsCam = new FlxCamera();
			mobileControlsCam.bgColor.alpha = 0;
			FlxG.cameras.add(mobileControlsCam, defaultDrawTarget);
			mobileControls.instance.cameras = [mobileControlsCam];
			mobileControls.instance.visible = false;
			add(mobileControls.instance);
		}
		else
		{
			trace('Warning: BaseMusicBeatSubstate - Failed to create mobile controls!');
		}
	}

	public function removeMobileControls():Void
	{
		if (mobileControls != null)
		{
			remove(mobileControls.instance);
			mobileControls.instance = FlxDestroyUtil.destroy(mobileControls.instance);
			mobileControls = null;
		}
		if (mobileControlsCam != null)
		{
			FlxG.cameras.remove(mobileControlsCam);
			mobileControlsCam = FlxDestroyUtil.destroy(mobileControlsCam);
		}
	}

	public function addTouchPadCamera(defaultDrawTarget:Bool = false):Void
	{
		if (touchPad != null)
		{
			touchPadCam = new FlxCamera();
			touchPadCam.bgColor.alpha = 0;
			FlxG.cameras.add(touchPadCam, defaultDrawTarget);
			touchPad.cameras = [touchPadCam];
		}
	}

	// ─── Lifecycle ────────────────────────────────────────────────────────────
	override function destroy():Void
	{
		controls.isInSubstate = false;
		removeTouchPad();
		removeMobileControls();
		super.destroy();
	}

	override function update(elapsed:Float):Void
	{
		// Only track time here if the parent state is NOT also updating to avoid double-counting
		if (!persistentUpdate && (FlxG.state == null || !FlxG.state.persistentUpdate))
			MusicBeatState.timePassedOnState += elapsed;

		var oldStep:Int = curStep;
		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if (curStep > 0) stepHit();
			if (PlayState.SONG != null)
			{
				if (oldStep < curStep) updateSection();
				else rollbackSection();
			}
		}

		super.update(elapsed);
	}

	// ─── Beat/step helpers ────────────────────────────────────────────────────
	private function updateSection():Void
	{
		if (stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while (curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if (curStep < 0) return;
		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if (stepsToDo > curStep) break;
				curSection++;
			}
		}
		if (curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);
		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	private function getBeatsOnSection():Float
	{
		var val:Null<Float> = 4;
		if (PlayState.SONG != null && PlayState.SONG.notes[curSection] != null)
			val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}

	// ─── Beat callbacks (no script calls) ─────────────────────────────────────
	public function stepHit():Void
	{
		if (curStep % 4 == 0) beatHit();
	}

	public function beatHit():Void {}

	public function sectionHit():Void {}
}
