package mobile.input;

import flixel.FlxG;

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
				startTarget = targetAt(touch.x, touch.y);
				moved = false;
			}

			if (allowScroll && touch.pressed)
			{
				var deltaY:Float = touch.y - startY;
				if (Math.abs(deltaY) >= swipeDistance)
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
}
