package psychlua;

#if HSCRIPT_ALLOWED
import backend.BaseStage;
import flixel.FlxBasic;
import flixel.FlxSubState;
import objects.Note;
import objects.Note.EventNote;
import psychlua.ScriptedClass.ScriptClassHandler;
import psychlua.ScriptedClass.ScriptTemplateBase;

class ScriptedStage extends BaseStage
{
	var handler:ScriptClassHandler;
	var scriptInstance:ScriptTemplateBase;
	var className:String;
	var file:String;
	var booting:Bool = true;

	public function new(handler:ScriptClassHandler, className:String, file:String)
	{
		this.handler = handler;
		this.className = className;
		this.file = file;
		super();
		booting = false;
		buildScriptInstance();
		callScript('create');
	}

	function buildScriptInstance():Void
	{
		var vars = handler.ogInterp.variables;
		var hadNativeSelf:Bool = vars.exists('__scriptedNativeSelf');
		var oldNativeSelf:Dynamic = hadNativeSelf ? vars.get('__scriptedNativeSelf') : null;

		vars.set('__scriptedNativeSelf', this);
		var created:Dynamic = handler.hnew([]);
		if (hadNativeSelf)
			vars.set('__scriptedNativeSelf', oldNativeSelf);
		else
			vars.remove('__scriptedNativeSelf');

		if (created != null && Std.isOfType(created, ScriptTemplateBase))
			scriptInstance = cast created;
		else
			trace('[ScriptedStage] $className did not create a ScriptTemplateBase instance.');
	}

	override public function create():Void
	{
		if (!booting)
			callScript('create');
	}

	override public function createPost():Void
		callScript('createPost');

	override public function countdownTick(count:Countdown, num:Int):Void
		callScript('countdownTick', [count, num]);

	override public function startSong():Void
		callScript('startSong');

	override public function beatHit():Void
		callScript('beatHit');

	override public function stepHit():Void
		callScript('stepHit');

	override public function sectionHit():Void
		callScript('sectionHit');

	override public function closeSubState():Void
		callScript('closeSubState');

	override public function openSubState(SubState:FlxSubState):Void
		callScript('openSubState', [SubState]);

	override public function eventCalled(eventName:String, value1:String, value2:String, value3:String, value4:String, flValue1:Null<Float> = null, flValue2:Null<Float> = null, flValue3:Null<Float> = null, flValue4:Null<Float> = null, strumTime:Float):Void
		callScript('eventCalled', [eventName, value1, value2, value3, value4, flValue1, flValue2, flValue3, flValue4, strumTime]);

	override public function eventPushed(event:EventNote):Void
		callScript('eventPushed', [event]);

	override public function eventPushedUnique(event:EventNote):Void
		callScript('eventPushedUnique', [event]);

	override public function goodNoteHit(note:Note):Void
		callScript('goodNoteHit', [note]);

	override public function opponentNoteHit(note:Note):Void
		callScript('opponentNoteHit', [note]);

	override public function noteMiss(note:Note):Void
		callScript('noteMiss', [note]);

	override public function noteMissPress(direction:Int):Void
		callScript('noteMissPress', [direction]);

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		callScript('update', [elapsed]);
	}

	override public function destroy():Void
	{
		callScript('destroy');
		scriptInstance = null;
		handler = null;
		super.destroy();
	}

	function callScript(name:String, ?args:Array<Dynamic>):Dynamic
	{
		if (scriptInstance == null || !scriptInstance.hasMethod(name))
			return null;

		try
		{
			return scriptInstance.callMethod(name, args);
		}
		catch (e:Dynamic)
		{
			trace('[ScriptedStage] $className.$name failed in $file: $e');
			return null;
		}
	}
}
#end
