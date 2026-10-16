package debug;

import backend.ClientPrefs;
import backend.MusicBeatState;
import backend.MusicBeatSubstate;
import backend.Paths;
import flixel.FlxG;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.TouchEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import states.ModsMenuState;

/**
 * Small mobile button that exits a scripted/custom state back to ModsMenuState.
 */
class ModsButton extends Sprite
{
	private var buttonShape:Shape;
	private var buttonText:TextField;
	private var isPressed:Bool = false;
	private var buttonSize:Float = 40;
	private var padding:Float = 10;
	private var spacing:Float = 8;

	public function new()
	{
		super();

		buttonShape = new Shape();
		addChild(buttonShape);

		buttonText = new TextField();
		buttonText.text = "M";
		buttonText.selectable = false;
		buttonText.mouseEnabled = false;
		buttonText.defaultTextFormat = new TextFormat(Paths.font("aller.ttf"), 20, 0xFFFFFF, true);
		buttonText.width = buttonSize;
		buttonText.height = buttonSize;
		buttonText.y = (buttonSize - 20) / 2;
		var fmt = new TextFormat();
		fmt.align = TextFormatAlign.CENTER;
		buttonText.setTextFormat(fmt);
		addChild(buttonText);

		redrawButton();
		positionButton();

		#if mobile
		refreshVisibility();
		addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
		addEventListener(TouchEvent.TOUCH_END, onTouchEnd);
		addEventListener(Event.ENTER_FRAME, onEnterFrame);

		#if debug
		addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		#end
		#else
		visible = false;
		#end
	}

	private function onEnterFrame(_:Event):Void
	{
		refreshVisibility();
	}

	private function refreshVisibility():Void
	{
		#if mobile
		visible = ClientPrefs.data.showMobileDebugButtons && isInsideCustomState();
		#else
		visible = false;
		#end
	}

	private function isInsideCustomState():Bool
	{
		if (FlxG.state == null || Std.isOfType(FlxG.state, ModsMenuState))
			return false;

		if (Std.isOfType(FlxG.state, MusicBeatState))
		{
			var musicState:MusicBeatState = cast FlxG.state;
			if (musicState.isScriptedState || (musicState.scriptOwnerMod != null && musicState.scriptOwnerMod.length > 0))
				return true;
		}

		var subState:Dynamic = Reflect.field(FlxG.state, "subState");
		if (subState != null && Std.isOfType(subState, MusicBeatSubstate))
		{
			var musicSubstate:MusicBeatSubstate = cast subState;
			if (musicSubstate.isScriptedSubstate || (musicSubstate.scriptOwnerMod != null && musicSubstate.scriptOwnerMod.length > 0))
				return true;
		}

		return false;
	}

	private function onTouchBegin(event:TouchEvent):Void
	{
		isPressed = true;
		redrawButton(true);
	}

	private function onTouchEnd(event:TouchEvent):Void
	{
		if (!isPressed)
			return;

		isPressed = false;
		redrawButton();
		if (visible)
			openModsMenu();
	}

	#if debug
	private function onMouseDown(event:MouseEvent):Void
	{
		isPressed = true;
		redrawButton(true);
	}

	private function onMouseUp(event:MouseEvent):Void
	{
		if (!isPressed)
			return;

		isPressed = false;
		redrawButton();
		if (visible)
			openModsMenu();
	}
	#end

	private function redrawButton(pressed:Bool = false):Void
	{
		buttonShape.graphics.clear();
		buttonShape.graphics.beginFill(pressed ? 0x226622 : 0x33AA55, pressed ? 0.9 : 0.7);
		buttonShape.graphics.drawRect(0, 0, buttonSize, buttonSize);
		buttonShape.graphics.lineStyle(2, 0xFFFFFF, pressed ? 1.0 : 0.9);
		buttonShape.graphics.drawRect(0, 0, buttonSize, buttonSize);
		buttonShape.graphics.endFill();
	}

	private function openModsMenu():Void
	{
		if (FlxG.state == null || Std.isOfType(FlxG.state, ModsMenuState))
			return;

		if (Std.isOfType(FlxG.state, MusicBeatState))
		{
			var musicState:MusicBeatState = cast FlxG.state;
			musicState.persistentUpdate = true;
			musicState.persistentDraw = true;
		}

		#if HSCRIPT_ALLOWED
		scripting.ScriptedStates.exitToEngine();
		#else
		#if MODS_ALLOWED
		backend.Mods.launchedMod = null;
		backend.Mods.currentModDirectory = '';
		if (FlxG.save != null && FlxG.save.data != null)
		{
			FlxG.save.data.launchedMod = null;
			FlxG.save.flush();
		}
		backend.Mods.pushGlobalMods();
		backend.Mods.resetWindowBrand();
		backend.Language.reloadPhrases();
		#end
		MusicBeatState.switchState(new ModsMenuState());
		#end
	}

	private function positionButton():Void
	{
		if (FlxG.stage != null)
		{
			x = FlxG.stage.stageWidth - buttonSize - padding;
			y = padding + buttonSize + spacing;
		}
	}

	public function updatePosition():Void
	{
		positionButton();
		refreshVisibility();
	}

	public function destroy():Void
	{
		removeEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
		removeEventListener(TouchEvent.TOUCH_END, onTouchEnd);
		removeEventListener(Event.ENTER_FRAME, onEnterFrame);

		#if debug
		removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		#end

		if (buttonText.parent != null)
			buttonText.parent.removeChild(buttonText);
		if (buttonShape.parent != null)
			buttonShape.parent.removeChild(buttonShape);
		if (parent != null)
			parent.removeChild(this);
	}
}
