package backend;

import flixel.FlxState;
import flixel.FlxSubState;
import backend.PsychCamera;
import debug.TraceDisplay;
import objects.GlobalLoadingOverlay;
import objects.MaterialVolumeTray;

// Base class for all rhythm-game states.
//
// Contains only pure beat/step tracking, mobile controls, camera setup and
// stage utilities — no scripting machinery.  Script support is added by the
// child class MusicBeatState.
//
// Hierarchy (inspired by ALE-Psych — https://github.com/ALE-Psych-Crew/ALE-Psych):
//   FlxState
//   └── BaseMusicBeatState   (this file — pure beat/camera/mobile/stages)
//       └── MusicBeatState   (+ GlobalScript, HScript/Lua infrastructure)
//           ├── TitleState / PlayState / etc.
//           └── CustomState

class BaseMusicBeatState extends FlxState
{
	// ─── Beat/step counters ───────────────────────────────────────────────────
	public var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	public var curStep:Int = 0;
	public var curBeat:Int = 0;

	public var curDecStep:Float = 0;
	public var curDecBeat:Float = 0;

	// ─── Controls ─────────────────────────────────────────────────────────────
	public var controls(get, never):Controls;
	private function get_controls():Controls return Controls.instance;

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
			trace('Warning: Failed to create mobile controls! extraButtons: ${ClientPrefs.data.extraButtons}, mode: ${MobileData.mode}');
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

	// ─── Camera ───────────────────────────────────────────────────────────────
	var _psychCameraInitialized:Bool = false;

	public function initPsychCamera():PsychCamera
	{
		var camera = new PsychCamera();
		FlxG.cameras.reset(camera);
		FlxG.cameras.setDefaultDrawTarget(camera, true);
		_psychCameraInitialized = true;
		return camera;
	}

	// ─── Script-accessible state variables ────────────────────────────────────
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public var videoHandlers:Map<String, Dynamic> = new Map<String, Dynamic>();

	// ─── Static helpers ───────────────────────────────────────────────────────
	public static function getVariables():Map<String, Dynamic>
		return getState().variables;

	public static function getVideoHandlers():Map<String, Dynamic>
		return getState().videoHandlers;

	// Returns the current state cast to BaseMusicBeatState.
	// MusicBeatState shadows this with a version returning MusicBeatState.
	public static function getState():BaseMusicBeatState
		return cast(FlxG.state, BaseMusicBeatState);

	public function getSubstate():flixel.FlxSubState
		return subState;

	// ─── Stages ───────────────────────────────────────────────────────────────
	public var stages:Array<BaseStage> = [];

	function stagesFunc(func:BaseStage->Void):Void
	{
		for (stage in stages)
			if (stage != null && stage.exists && stage.active)
				func(stage);
	}

	function getBeatsOnSection():Float
	{
		var val:Null<Float> = 4;
		if (PlayState.SONG != null && PlayState.SONG.notes[curSection] != null)
			val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}

	// ─── Beat/step update helpers ─────────────────────────────────────────────
	function updateSection():Void
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

	function rollbackSection():Void
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

	function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);
		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	// ─── Lifecycle ────────────────────────────────────────────────────────────
	override function create():Void
	{
		super.create();
		GlobalLoadingOverlay.stateReady();
	}

	override function openSubState(SubState:FlxSubState):Void
	{
		if (!(SubState is CustomFadeTransition))
			GlobalLoadingOverlay.pulse();
		super.openSubState(SubState);
	}

	override function closeSubState():Void
	{
		super.closeSubState();
		GlobalLoadingOverlay.hide();
	}

	override function destroy():Void
	{
		removeTouchPad();
		removeMobileControls();
		super.destroy();
	}

	// ─── Beat/section callbacks (no scripts — used directly or overridden) ────
	public function stepHit():Void
	{
		stagesFunc(function(stage:BaseStage)
		{
			stage.curStep = curStep;
			stage.curDecStep = curDecStep;
			stage.stepHit();
		});
		if (curStep % 4 == 0) beatHit();
	}

	public function beatHit():Void
	{
		stagesFunc(function(stage:BaseStage)
		{
			stage.curBeat = curBeat;
			stage.curDecBeat = curDecBeat;
			stage.beatHit();
		});
	}

	public function sectionHit():Void
	{
		stagesFunc(function(stage:BaseStage)
		{
			stage.curSection = curSection;
			stage.sectionHit();
		});
	}

	// ─── Transitions (no script hooks — MusicBeatState shadows these) ─────────
	public static function switchState(nextState:FlxState = null):Void
	{
		if (nextState == null) nextState = FlxG.state;
		if (nextState == FlxG.state)
		{
			resetState();
			return;
		}
		if (FlxTransitionableState.skipNextTransIn) FlxG.switchState(nextState);
		else startTransition(nextState);
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function resetState():Void
	{
		if (FlxTransitionableState.skipNextTransIn) FlxG.switchState(_makeCurrentStateReset());
		else startTransition();
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function startTransition(nextState:FlxState = null):Void
	{
		if (nextState == null) nextState = FlxG.state;
		GlobalLoadingOverlay.showPersistent();
		FlxG.state.openSubState(new CustomFadeTransition(0.7, false));
		if (nextState == FlxG.state) {
			var resetFn = _makeCurrentStateReset();
			CustomFadeTransition.finishCallback = function() FlxG.switchState(resetFn);
		} else {
			CustomFadeTransition.finishCallback = function() FlxG.switchState(nextState);
		}
	}

	/** Builds a factory lambda that recreates the current state correctly.
	 *  Avoids `FlxG.resetState()` breaking on states with constructor args (e.g. ScriptableState). */
	static function _makeCurrentStateReset():()->flixel.FlxState {
		#if (HSCRIPT_ALLOWED && sys)
		var cs = FlxG.state;
		if (cs is backend.ScriptableState) {
			var name:String = (cast cs : backend.ScriptableState).stateName;
			return () -> new backend.ScriptableState(name);
		}
		#end
		var cls = Type.getClass(FlxG.state);
		return () -> Type.createInstance(cls, []);
	}
}
