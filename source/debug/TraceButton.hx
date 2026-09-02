package debug;

import flixel.FlxG;
import openfl.display.Sprite;
import openfl.display.Shape;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.events.TouchEvent;
import openfl.events.MouseEvent;
import backend.Paths;
import backend.ClientPrefs;

/**
 * TraceButton - Small touch button for Android that opens/closes the TraceDisplay
 * It is positioned in the upper-right corner
 */
class TraceButton extends Sprite
{
	private var buttonShape:Shape;
	private var buttonText:TextField;
	private var isPressed:Bool = false;
	private var buttonSize:Float = 40;
	private var padding:Float = 10;

	public function new()
	{
		super();

		// Create the button background
		buttonShape = new Shape();
		buttonShape.graphics.beginFill(0x4488FF, 0.7);
		buttonShape.graphics.drawRect(0, 0, buttonSize, buttonSize);
		buttonShape.graphics.lineStyle(2, 0xFFFFFF, 0.9);
		buttonShape.graphics.drawRect(0, 0, buttonSize, buttonSize);
		buttonShape.graphics.endFill();
		addChild(buttonShape);

		// Create the button text
		buttonText = new TextField();
		buttonText.text = "T";
		buttonText.selectable = false;
		buttonText.mouseEnabled = false;
		buttonText.defaultTextFormat = new TextFormat(Paths.font("aller.ttf"), 20, 0xFFFFFF, true);
		buttonText.width = buttonSize;
		buttonText.height = buttonSize;
		buttonText.x = 0;
		buttonText.y = (buttonSize - 20) / 2;

		// Align text horizontally
		var fmt = new TextFormat();
		fmt.align = openfl.text.TextFormatAlign.CENTER;
		buttonText.setTextFormat(fmt);

		addChild(buttonText);

		// Position in the upper-right corner
		positionButton();

		// Make visible only on mobile
		#if mobile
		visible = ClientPrefs.data.showMobileDebugButtons;

		// Add touch listeners
		this.addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
		this.addEventListener(TouchEvent.TOUCH_END, onTouchEnd);

		// It should also support a mouse for desktop testing
		#if debug
		this.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		this.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		#end
		#else
		visible = false;
		#end
	}

	private function onTouchBegin(event:TouchEvent):Void
	{
		isPressed = true;
		buttonShape.graphics.clear();
		buttonShape.graphics.beginFill(0x2244FF, 0.9); // Darker when pressed
		buttonShape.graphics.drawRect(0, 0, buttonSize, buttonSize);
		buttonShape.graphics.lineStyle(2, 0xFFFFFF, 1.0);
		buttonShape.graphics.drawRect(0, 0, buttonSize, buttonSize);
		buttonShape.graphics.endFill();
	}

	private function onTouchEnd(event:TouchEvent):Void
	{
		if (isPressed)
		{
			toggleTraceDisplay();
			isPressed = false;
			redrawButton();
		}
	}

	#if debug
	private function onMouseDown(event:MouseEvent):Void
	{
		onTouchBegin(cast event);
	}

	private function onMouseUp(event:MouseEvent):Void
	{
		onTouchEnd(cast event);
	}
	#end

	private function redrawButton():Void
	{
		buttonShape.graphics.clear();
		buttonShape.graphics.beginFill(0x4488FF, 0.7);
		buttonShape.graphics.drawRect(0, 0, buttonSize, buttonSize);
		buttonShape.graphics.lineStyle(2, 0xFFFFFF, 0.9);
		buttonShape.graphics.drawRect(0, 0, buttonSize, buttonSize);
		buttonShape.graphics.endFill();
	}

	private function toggleTraceDisplay():Void
	{
		if (TraceDisplay.instance != null)
		{
			TraceDisplay.instance.toggleDisplay();
		}
	}

	private function positionButton():Void
	{
		if (FlxG.stage != null)
		{
			this.x = FlxG.stage.stageWidth - buttonSize - padding;
			this.y = padding;
		}
	}

	public function updatePosition():Void
	{
		positionButton();
		#if mobile
		visible = ClientPrefs.data.showMobileDebugButtons;
		#end
	}

	public function destroy():Void
	{
		this.removeEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
		this.removeEventListener(TouchEvent.TOUCH_END, onTouchEnd);

		#if debug
		this.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		this.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		#end

		if (buttonText.parent != null)
		{
			buttonText.parent.removeChild(buttonText);
		}
		if (buttonShape.parent != null)
		{
			buttonShape.parent.removeChild(buttonShape);
		}
		if (this.parent != null)
		{
			this.parent.removeChild(this);
		}
	}
}

