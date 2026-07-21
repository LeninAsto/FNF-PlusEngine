package psychlua;

#if flxanimate
class ModchartAnimateSprite extends FlxAnimate
{
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();
	public var autoDeactivateOnFinish:Bool = true;
	public var destroyOnFinish:Bool = false;
	var _finishHandled:Bool = false;

	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
		antialiasing = ClientPrefs.data.antialiasing;
		anim.onComplete.add(_onAnimComplete);
	}

	public function playAnim(name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
	{
		_finishHandled = false;
		active = true;
		visible = true;
		anim.play(name, forced, reverse, startFrame);
		
		var daOffset = animOffsets.get(name);
		if (animOffsets.exists(name)) offset.set(daOffset[0], daOffset[1]);
	}

	public function addOffset(name:String, x:Float, y:Float)
	{
		animOffsets.set(name, [x, y]);
	}

	function _onAnimComplete():Void
	{
		if (_finishHandled || !autoDeactivateOnFinish)
			return;

		_finishHandled = true;
		active = false;

		if (destroyOnFinish)
		{
			visible = false;
			kill();
			destroy();
			return;
		}

		visible = false;
	}

	override function destroy():Void
	{
		if (anim != null)
			anim.onComplete.remove(_onAnimComplete);
		super.destroy();
	}
}
#end
