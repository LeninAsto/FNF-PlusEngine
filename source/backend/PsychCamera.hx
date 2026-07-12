package backend;

// PsychCamera handles followLerp based on elapsed
// and stops camera from snapping at higher framerates

class PsychCamera extends FlxCamera
{
	var _previousScroll:FlxPoint = FlxPoint.get();
	var _simulationScroll:FlxPoint = FlxPoint.get();
	var _interpolationReady:Bool = false;
	var _interpolationApplied:Bool = false;

	override public function update(elapsed:Float):Void
	{
		if (!_interpolationReady)
		{
			syncInterpolationState();
			_interpolationReady = true;
		}

		_previousScroll.copyFrom(scroll);
		_interpolationApplied = false;

		// follow the target, if there is one
		if (target != null)
		{
			updateFollowDelta(elapsed);
		}

		updateScroll();
		updateFlash(elapsed);
		updateFade(elapsed);

		flashSprite.filters = filtersEnabled ? filters : null;

		updateFlashSpritePosition();
		updateShake(elapsed);
		_simulationScroll.copyFrom(scroll);
	}

	public function applyRenderInterpolation(alpha:Float):Void
	{
		if (!_interpolationReady || _interpolationApplied)
			return;

		var clampedAlpha:Float = FlxMath.bound(alpha, 0, 1);
		scroll.x = _previousScroll.x + (_simulationScroll.x - _previousScroll.x) * clampedAlpha;
		scroll.y = _previousScroll.y + (_simulationScroll.y - _previousScroll.y) * clampedAlpha;
		_interpolationApplied = true;
	}

	public function restoreSimulationState():Void
	{
		if (!_interpolationApplied)
			return;

		scroll.copyFrom(_simulationScroll);
		_interpolationApplied = false;
	}

	public function syncInterpolationState():Void
	{
		_previousScroll.copyFrom(scroll);
		_simulationScroll.copyFrom(scroll);
		_interpolationApplied = false;
	}

	public function updateFollowDelta(?elapsed:Float = 0):Void
	{
		// Either follow the object closely,
		// or double check our deadzone and update accordingly.
		if (deadzone == null)
		{
			target.getMidpoint(_point);
			_point.addPoint(targetOffset);
			_scrollTarget.set(_point.x - width * 0.5, _point.y - height * 0.5);
		}
		else
		{
			var edge:Float;
			var targetX:Float = target.x + targetOffset.x;
			var targetY:Float = target.y + targetOffset.y;

			if (style == SCREEN_BY_SCREEN)
			{
				if (targetX >= viewRight)
				{
					_scrollTarget.x += viewWidth;
				}
				else if (targetX + target.width < viewLeft)
				{
					_scrollTarget.x -= viewWidth;
				}

				if (targetY >= viewBottom)
				{
					_scrollTarget.y += viewHeight;
				}
				else if (targetY + target.height < viewTop)
				{
					_scrollTarget.y -= viewHeight;
				}
				
				// without this we see weird behavior when switching to SCREEN_BY_SCREEN at arbitrary scroll positions
				bindScrollPos(_scrollTarget);
			}
			else
			{
				edge = targetX - deadzone.x;
				if (_scrollTarget.x > edge)
				{
					_scrollTarget.x = edge;
				}
				edge = targetX + target.width - deadzone.x - deadzone.width;
				if (_scrollTarget.x < edge)
				{
					_scrollTarget.x = edge;
				}

				edge = targetY - deadzone.y;
				if (_scrollTarget.y > edge)
				{
					_scrollTarget.y = edge;
				}
				edge = targetY + target.height - deadzone.y - deadzone.height;
				if (_scrollTarget.y < edge)
				{
					_scrollTarget.y = edge;
				}
			}

			if ((target is FlxSprite))
			{
				if (_lastTargetPosition == null)
				{
					_lastTargetPosition = FlxPoint.get(target.x, target.y); // Creates this point.
				}
				_scrollTarget.x += (target.x - _lastTargetPosition.x) * followLead.x;
				_scrollTarget.y += (target.y - _lastTargetPosition.y) * followLead.y;

				_lastTargetPosition.x = target.x;
				_lastTargetPosition.y = target.y;
			}
		}

		var mult:Float = 1 - Math.exp(-elapsed * followLerp / (1/60));
		scroll.x += (_scrollTarget.x - scroll.x) * mult;
		scroll.y += (_scrollTarget.y - scroll.y) * mult;
		//trace('lerp on this frame: $mult');
	}

	override function set_followLerp(value:Float)
	{
		return followLerp = value;
	}

	override public function snapToTarget():Void
	{
		super.snapToTarget();
		syncInterpolationState();
	}
}
