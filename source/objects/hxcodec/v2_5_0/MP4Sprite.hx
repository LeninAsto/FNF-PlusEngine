package objects.hxcodec.v2_5_0;

#if hxvlc
import flixel.FlxSprite;
import objects.hxcodec.v2_5_0.MP4Handler;
/**
 * Compatibility wrapper for hxCodec 3.x MP4Sprite using hxvlc 2.2.5
 * This class will play the video in the form of a FlxSprite, which you can control.
 */
class MP4Sprite extends FlxSprite
{
	public var readyCallback:Void->Void;
	public var finishCallback:Void->Void;

	private var video:MP4Handler;

	public function new(x:Float = 0, y:Float = 0, width:Float = 320, height:Float = 240, autoScale:Bool = true)
	{
		super(x, y);

		video = new MP4Handler(width, height, autoScale);
		video.alpha = 0;

		video.readyCallback = function()
		{
			if (video.bitmapData != null)
				loadGraphic(video.bitmapData);

			if (readyCallback != null)
				readyCallback();
		}

		video.finishCallback = function()
		{
			if (finishCallback != null)
				finishCallback();

			kill();
		};
	}

	/**
	 * Native video support for Flixel & OpenFL
	 * @param path Example: `your/video/here.mp4`
	 * @param repeat Repeat the video.
	 * @param pauseMusic Pause music until done video.
	 */
	public function playVideo(path:String, ?repeat:Bool = false, ?pauseMusic:Bool = false):Void
	{
		video.playVideo(path, repeat, pauseMusic);
	}

	public function pause():Void
	{
		video.pause();
	}

	public function resume():Void
	{
		video.resume();
	}

	override public function destroy():Void
	{
		if (video != null)
		{
			video.dispose();
			video = null;
		}

		super.destroy();
	}
}
#else
// Dummy class when hxvlc is not available
class MP4Sprite extends flixel.FlxSprite
{
	public var readyCallback:Void->Void;
	public var finishCallback:Void->Void;

	public function new(x:Float = 0, y:Float = 0, width:Float = 320, height:Float = 240, autoScale:Bool = true)
	{
		super(x, y);
		trace("MP4Sprite: hxvlc not available");
	}

	public function playVideo(path:String, ?repeat:Bool = false, ?pauseMusic:Bool = false):Void
	{
		trace("MP4Sprite.playVideo: hxvlc not available");
	}

	public function pause():Void {}
	public function resume():Void {}
}
#end
