package mobile.backend;

import flixel.input.touch.FlxTouch;
import flixel.math.FlxPoint;

/**
 * Touch scroll/swipe handler with tap detection
 * Differentiates between tap (quick touch) and scroll/swipe (drag gesture)
 * 
 * Based on implementations from NovaFlare Engine and Psych-Slice
 * @author Lenin
 */
class TouchScroll
{
    // Swipe detection thresholds
    public static inline var TAP_DISTANCE_THRESHOLD:Float = 32.0; // Pixels - if movement < this, it's a tap
    public static inline var TAP_TIME_THRESHOLD:Float = 0.45; // Seconds - max duration for a tap
    public static inline var SWIPE_VELOCITY_THRESHOLD:Float = 50.0; // Pixels/second - minimum for swipe
    public static inline var AXIS_LOCK_RATIO:Float = 1.08; // Primary axis must exceed secondary axis by this ratio
    public static inline var MAX_VELOCITY:Float = 4200.0; // Clamp velocity to avoid huge spikes
    public static inline var VELOCITY_SMOOTHING:Float = 0.35; // Blend factor for stable velocity
    public static inline var MIN_DELTA:Float = 0.05; // Ignore tiny jitter deltas
    
    // Momentum/inertia settings
    public static inline var MOMENTUM_FRICTION:Float = 0.92; // Deceleration multiplier (0-1)
    public static inline var MOMENTUM_MIN_VELOCITY:Float = 5.0; // Stop momentum below this velocity
    
    // Touch tracking
    private var touchStartPos:FlxPoint;
    private var touchCurrentPos:FlxPoint;
    private var touchStartTime:Float;
    private var lastTouchPos:FlxPoint;
    private var lastMoveTime:Float;
    private var justReleasedScroll:Bool = false;
    
    // State
    public var isScrolling(default, null):Bool = false;
    public var isTap(default, null):Bool = false;
    public var scrollVelocity:Float = 0;
    public var totalDelta:Float = 0;
    
    // Axis (vertical or horizontal)
    public var vertical:Bool = true;
    
    private var activeTouch:FlxTouch = null;
    
    public function new(vertical:Bool = true)
    {
        this.vertical = vertical;
        touchStartPos = FlxPoint.get();
        touchCurrentPos = FlxPoint.get();
        lastTouchPos = FlxPoint.get();
        reset();
    }
    
    public function reset():Void
    {
        isScrolling = false;
        isTap = false;
        scrollVelocity = 0;
        totalDelta = 0;
        justReleasedScroll = false;
        activeTouch = null;
        touchStartTime = 0;
        lastMoveTime = 0;
    }
    
    /**
     * Update scroll state - call this every frame
     * @return The scroll delta for this frame
     */
    public function update():Float
    {
        var currentTouch:FlxTouch = null;
        justReleasedScroll = false;
        
        // Prioritize the currently active touch.
        if (activeTouch != null)
        {
            if (activeTouch.pressed || activeTouch.justReleased)
            {
                currentTouch = activeTouch;
            }
            else
            {
                activeTouch = null;
            }
        }

        // Fallback: find a new touch.
        if (currentTouch == null)
        {
            for (touch in FlxG.touches.list)
            {
                if (touch != null && (touch.justPressed || touch.pressed))
                {
                    currentTouch = touch;
                    break;
                }
            }
        }
        
        // Touch just started
        if (currentTouch != null && currentTouch.justPressed)
        {
            touchStartPos.set(currentTouch.screenX, currentTouch.screenY);
            touchCurrentPos.set(currentTouch.screenX, currentTouch.screenY);
            lastTouchPos.set(currentTouch.screenX, currentTouch.screenY);
            touchStartTime = haxe.Timer.stamp();
            lastMoveTime = touchStartTime;
            activeTouch = currentTouch;
            isScrolling = false;
            isTap = false;
            scrollVelocity = 0;
            totalDelta = 0;
        }
        // Touch is moving
        else if (currentTouch != null && currentTouch.pressed && activeTouch == currentTouch)
        {
            touchCurrentPos.set(currentTouch.screenX, currentTouch.screenY);
            
            var primaryDistance = getDistance();
            var secondaryDistance = getSecondaryDistance();
            
            // Determine if this is a scroll or still could be a tap
            if (!isScrolling && primaryDistance > TAP_DISTANCE_THRESHOLD && primaryDistance > secondaryDistance * AXIS_LOCK_RATIO)
            {
                isScrolling = true;
                isTap = false;
            }

            if (isScrolling)
            {
                // Calculate velocity for momentum
                var currentTime = haxe.Timer.stamp();
                var deltaTime = currentTime - lastMoveTime;
                
                if (deltaTime > 0)
                {
                    var delta = vertical ?
                        (touchCurrentPos.y - lastTouchPos.y) : 
                        (touchCurrentPos.x - lastTouchPos.x);

                    var instantVelocity = FlxMath.bound(delta / deltaTime, -MAX_VELOCITY, MAX_VELOCITY);
                    scrollVelocity = (scrollVelocity * (1 - VELOCITY_SMOOTHING)) + (instantVelocity * VELOCITY_SMOOTHING);
                    totalDelta += delta;
                    
                    lastTouchPos.set(touchCurrentPos.x, touchCurrentPos.y);
                    lastMoveTime = currentTime;

                    if (Math.abs(delta) >= MIN_DELTA)
                    {
                        return delta;
                    }
                }
            }
        }
        // Touch ended
        else if (activeTouch != null && activeTouch.justReleased)
        {
            var primaryDistance = getDistance();
            var secondaryDistance = getSecondaryDistance();
            var duration = haxe.Timer.stamp() - touchStartTime;
            var totalDistance = Math.sqrt((primaryDistance * primaryDistance) + (secondaryDistance * secondaryDistance));
            
            // Determine if it was a tap
            if (!isScrolling && totalDistance < TAP_DISTANCE_THRESHOLD && duration < TAP_TIME_THRESHOLD)
            {
                isTap = true;
                isScrolling = false;
                scrollVelocity = 0;
            }
            else
            {
                isTap = false;
                if (Math.abs(scrollVelocity) < SWIPE_VELOCITY_THRESHOLD)
                {
                    scrollVelocity = 0;
                }
                if (isScrolling)
                {
                    justReleasedScroll = true;
                }
                isScrolling = false;
            }
            
            activeTouch = null;
        }
        // No touch - apply momentum if scrolling ended
        else if (activeTouch == null && Math.abs(scrollVelocity) > MOMENTUM_MIN_VELOCITY)
        {
            var frameAdjustedFriction = Math.pow(MOMENTUM_FRICTION, FlxG.elapsed * 60);
            scrollVelocity *= frameAdjustedFriction;
            
            if (Math.abs(scrollVelocity) < MOMENTUM_MIN_VELOCITY)
            {
                scrollVelocity = 0;
            }
            
            var delta = scrollVelocity * FlxG.elapsed;
            totalDelta += delta;
            return delta;
        }
        else
        {
            scrollVelocity = 0;
        }
        
        return 0;
    }
    
    /**
     * Get distance from touch start to current position
     */
    private function getDistance():Float
    {
        if (vertical)
        {
            return Math.abs(touchCurrentPos.y - touchStartPos.y);
        }
        else
        {
            return Math.abs(touchCurrentPos.x - touchStartPos.x);
        }
    }

    private function getSecondaryDistance():Float
    {
        if (vertical)
        {
            return Math.abs(touchCurrentPos.x - touchStartPos.x);
        }
        else
        {
            return Math.abs(touchCurrentPos.y - touchStartPos.y);
        }
    }
    
    /**
     * Get the touch position for tap detection
     * This consumes the tap event, returning the position once and then null
     */
    public function getTapPosition():FlxPoint
    {
        if (isTap)
        {
            isTap = false; // Consume the tap event - only return position once
            return touchStartPos;
        }
        return null;
    }
    
    /**
     * Check if a specific point was tapped (not scrolled)
     */
    public function wasTapped():Bool
    {
        return isTap;
    }
    
    /**
     * Check if currently scrolling
     */
    public function isCurrentlyScrolling():Bool
    {
        return isScrolling || Math.abs(scrollVelocity) > MOMENTUM_MIN_VELOCITY;
    }

    /**
     * Check if a scroll gesture ended this frame.
     */
    public function didReleaseScroll():Bool
    {
        return justReleasedScroll;
    }

    /**
     * Check if finger is currently down.
     */
    public function isTouchActive():Bool
    {
        return activeTouch != null;
    }
    
    /**
     * Force stop scrolling and momentum
     */
    public function stopScroll():Void
    {
        scrollVelocity = 0;
        isScrolling = false;
        justReleasedScroll = false;
    }
    
    public function destroy():Void
    {
        touchStartPos.put();
        touchCurrentPos.put();
        lastTouchPos.put();
        touchStartPos = null;
        touchCurrentPos = null;
        lastTouchPos = null;
        activeTouch = null;
    }
}
