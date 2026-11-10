package mobile.input;

import flixel.FlxG;
import backend.ClientPrefs;

/** Shared tap and drag navigation for touch-first menu screens. */
class TouchScrollHandler
{
	public static inline var NO_TARGET:Int = -1;

	var startY:Float = 0;
	var startTarget:Int = NO_TARGET;
	var moved:Bool = false;
	var swipeDistance:Float;

	public function new(swipeDistance:Float = 40)
	{
		this.swipeDistance = swipeDistance;
	}

	public function update(enabled:Bool, allowScroll:Bool, targetAt:Float->Float->Int, onTap:Int->Float->Float->Void,
			onScroll:Int->Void):Bool
	{
		if (!enabled)
			return false;

		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				startY = touch.y;
				// Touch pads own their visual area. Letting a menu inspect the same
				// touch caused button presses to activate whatever happened to be
				// underneath them (and could start a menu swipe too).
				if (isTouchPadPoint(touch.x, touch.y))
				{
					startTarget = NO_TARGET;
					moved = true;
				}
				else
				{
					startTarget = targetAt(touch.x, touch.y);
					moved = false;
				}
			}

			// Only a touch that began on this menu can scroll this menu. This
			// prevents a drag on a touch pad or empty background from hijacking it.
			if (allowScroll && startTarget != NO_TARGET && touch.pressed)
			{
				var deltaY:Float = touch.y - startY;
				var sensitivity:Float = Math.max(0.25, ClientPrefs.data.mobileScrollSensitivity);
				if (Math.abs(deltaY) >= swipeDistance / sensitivity)
				{
					onScroll(deltaY < 0 ? 1 : -1);
					startY = touch.y;
					moved = true;
					return true;
				}
			}

			if (touch.justReleased)
			{
				if (!moved && startTarget != NO_TARGET)
				{
					onTap(startTarget, touch.x, touch.y);
					startTarget = NO_TARGET;
					return true;
				}
				startTarget = NO_TARGET;
			}
		}
		return false;
	}

	static function isTouchPadPoint(x:Float, y:Float):Bool
	{
		var state:Dynamic = FlxG.state;
		if (state == null)
			return false;
		var subState:Dynamic = Reflect.field(state, 'subState');
		return touchPadContains(subState, x, y) || touchPadContains(state, x, y);
	}

	static function touchPadContains(owner:Dynamic, x:Float, y:Float):Bool
	{
		if (owner == null)
			return false;
		var pad:Dynamic = Reflect.field(owner, 'touchPad');
		if (pad == null || Reflect.field(pad, 'visible') == false)
			return false;
		var buttons:Array<Dynamic> = cast Reflect.field(pad, 'members');
		if (buttons == null)
			return false;
		for (button in buttons)
		{
			if (button == null || Reflect.field(button, 'exists') == false || Reflect.field(button, 'visible') == false)
				continue;
			var bx:Float = Reflect.field(button, 'x');
			var by:Float = Reflect.field(button, 'y');
			var bw:Float = Reflect.field(button, 'width');
			var bh:Float = Reflect.field(button, 'height');
			if (x >= bx && x <= bx + bw && y >= by && y <= by + bh)
				return true;
		}
		return false;
	}
}
