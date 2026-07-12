package backend;

import flixel.FlxSprite;
#if VIDEOS_ALLOWED
import hxvlc.flixel.FlxVideoSprite;
#end

/**
 * Compatibility wrapper for old Psych scripts that expect backend.VideoSpriteManager.
 *
 * Supports patterns such as:
 * createInstance('vid', 'backend.VideoSpriteManager', {0, 0, 1280, 720})
 * callMethod('vid.startVideo', {videoPath, isLooped, loopAmount})
 */
@:keep
#if VIDEOS_ALLOWED
class VideoSpriteManager extends FlxVideoSprite
{
	private var targetWidth:Int;
	private var targetHeight:Int;
	private var alreadyDestroyed:Bool = false;

	public function new(?x:Float = 0, ?y:Float = 0, ?width:Int = 1280, ?height:Int = 720)
	{
		super(x, y);
		antialiasing = ClientPrefs.data.antialiasing;
		targetWidth = width;
		targetHeight = height;

		bitmap.onFormatSetup.add(onFormatSetup);
		bitmap.onEndReached.add(onVideoEndReached);
	}

	private function onFormatSetup():Void
	{
		if(targetWidth > 0)
			setGraphicSize(targetWidth, targetHeight > 0 ? targetHeight : 0);
		updateHitbox();
	}

	private function onVideoEndReached():Void
	{
		cleanupAndDestroy();
	}

	private function cleanupAndDestroy():Void
	{
		if(alreadyDestroyed)
			return;

		alreadyDestroyed = true;

		if(bitmap != null)
		{
			bitmap.onEndReached.remove(onVideoEndReached);
			bitmap.onFormatSetup.remove(onFormatSetup);
		}

		if(FlxG.state != null)
		{
			if(FlxG.state.members != null && FlxG.state.members.contains(this))
				FlxG.state.remove(this, true);

			if(FlxG.state.subState != null && FlxG.state.subState.members != null && FlxG.state.subState.members.contains(this))
				FlxG.state.subState.remove(this, true);
		}

		destroy();
	}

	override public function destroy():Void
	{
		if(alreadyDestroyed && bitmap == null)
			return;

		if(bitmap != null)
		{
			bitmap.onEndReached.remove(onVideoEndReached);
			bitmap.onFormatSetup.remove(onFormatSetup);
		}

		super.destroy();
	}

	public function startVideo(path:Dynamic, ?isLooped:Dynamic = false, ?loopAmount:Dynamic = 0):Void
	{
		var resolvedPath = Std.string(path);
		if(resolvedPath == null || resolvedPath.trim().length == 0)
			return;

		var loop = isLooped == true;
		load(resolvedPath, loop ? ['input-repeat=65545'] : null);
		play();
	}
}
#else
class VideoSpriteManager extends FlxSprite
{
	public function new(?x:Float = 0, ?y:Float = 0, ?width:Int = 1280, ?height:Int = 720)
	{
		super(x, y);
		visible = false;
	}

	public function startVideo(path:Dynamic, ?isLooped:Dynamic = false, ?loopAmount:Dynamic = 0):Void {}
}
#end
