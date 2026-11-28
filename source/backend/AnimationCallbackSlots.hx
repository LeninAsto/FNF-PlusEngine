package backend;

import flixel.animation.FlxAnimationController;
import haxe.ds.ObjectMap;

class AnimationCallbackSlots
{
    final finishes:ObjectMap<FlxAnimationController, String->Void> = new ObjectMap();
    final frames:ObjectMap<FlxAnimationController, (String, Int, Int)->Void> = new ObjectMap();

    public function new() {}

    public function setFinish(animation:FlxAnimationController, callback:String->Void):Void
    {
        var previous = finishes.get(animation);
        if (previous != null) animation.onFinish.remove(previous);
        if (callback == null) finishes.remove(animation);
        else
        {
            finishes.set(animation, callback);
            animation.onFinish.add(callback);
        }
    }

    public function setFrame(animation:FlxAnimationController, callback:(String, Int, Int)->Void):Void
    {
        var previous = frames.get(animation);
        if (previous != null) animation.onFrameChange.remove(previous);
        if (callback == null) frames.remove(animation);
        else
        {
            frames.set(animation, callback);
            animation.onFrameChange.add(callback);
        }
    }
}
