package objects.hxcodec.v2_6_0;

#if hxvlc
import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import hxvlc.openfl.Video as HxvlcVideo;
import openfl.events.Event;
import sys.FileSystem;

/**
 * Compatibility wrapper for hxCodec 2.x VideoHandler using hxvlc 2.2.5
 * Emulates the VLCBitmap-based API from hxCodec version 2.x
 */
class VideoHandler extends HxvlcVideo
{
	public var canSkip:Bool = true;
	public var skipKeys:Array<FlxKey> = [FlxKey.SPACE];
	public var canUseSound:Bool = true;
	public var canUseAutoResize:Bool = true;

	public var openingCallback:Void->Void = null;
	public var finishCallback:Void->Void = null;

	private var pauseMusic:Bool = false;
	private var _isPlaying:Bool = false;

	// Emulate VLCBitmap properties
	public var isDisplaying(get, never):Bool;
	private function get_isDisplaying():Bool
	{
		return _isPlaying && bitmapData != null;
	}

	public var videoWidth(get, never):Int;
	private function get_videoWidth():Int
	{
		return bitmapData != null ? bitmapData.width : 0;
	}

	public var videoHeight(get, never):Int;
	private function get_videoHeight():Int
	{
		return bitmapData != null ? bitmapData.height : 0;
	}

	// mrl property is inherited from hxvlc.openfl.Video

	private var _location:String = null;
	public var location(get, never):String;
	private function get_location():String
	{
		return _location;
	}

	public function new(IndexModifier:Int = 0):Void
	{
		super();

		onOpening.add(onVLCOpening);
		onEndReached.add(onVLCEndReached);
		onEncounteredError.add(onVLCEncounteredError);

		FlxG.addChildBelowMouse(this, IndexModifier);
	}

	private function onVLCOpening():Void
	{
		#if FLX_SOUND_SYSTEM
		volume = Std.int(((FlxG.sound.muted || !canUseSound) ? 0 : 1) * FlxG.sound.volume * 100);
		#end

		if (openingCallback != null)
			openingCallback();
	}

	private function onVLCEncounteredError(error:String):Void
	{
		trace('VideoHandler Error: $error');
		onVLCEndReached();
	}

	private function onVLCEndReached():Void
	{
		_isPlaying = false;

		if (FlxG.sound.music != null && pauseMusic)
			FlxG.sound.music.resume();

		if (FlxG.stage.hasEventListener(Event.ENTER_FRAME))
			FlxG.stage.removeEventListener(Event.ENTER_FRAME, update);

		if (FlxG.autoPause)
		{
			if (FlxG.signals.focusGained.has(resume))
				FlxG.signals.focusGained.remove(resume);

			if (FlxG.signals.focusLost.has(pause))
				FlxG.signals.focusLost.remove(pause);
		}

		dispose();
		FlxG.removeChild(this);

		if (finishCallback != null)
			finishCallback();
	}

	/**
	 * Plays a video.
	 *
	 * @param Path Example: `your/video/here.mp4`
	 * @param Loop Loop the video.
	 * @param PauseMusic Pause music until the video ends.
	 */
	public function playVideo(Path:String, Loop:Bool = false, PauseMusic:Bool = false):Void
	{
		pauseMusic = PauseMusic;

		if (FlxG.sound.music != null && PauseMusic)
			FlxG.sound.music.pause();

		FlxG.stage.addEventListener(Event.ENTER_FRAME, update);

		if (FlxG.autoPause)
		{
			FlxG.signals.focusGained.add(resume);
			FlxG.signals.focusLost.add(pause);
		}

		var videoPath = Path;
		if (FileSystem.exists(Sys.getCwd() + Path))
			videoPath = Sys.getCwd() + Path;

		_location = videoPath;

		// Setup loop behavior
		if (Loop)
		{
			onEndReached.add(function()
			{
				stop();
				haxe.Timer.delay(function()
				{
					if (load(videoPath))
						resume();
				}, 50);
			});
		}

		if (load(videoPath))
		{
			resume();
			_isPlaying = true;
		}
	}

	private function update(?E:Event):Void
	{
		#if FLX_KEYBOARD
		if (canSkip && (FlxG.keys.anyJustPressed(skipKeys) #if android || FlxG.android.justReleased.BACK #end) && _isPlaying && isDisplaying)
			onVLCEndReached();
		#elseif android
		if (canSkip && FlxG.android.justReleased.BACK && _isPlaying && isDisplaying)
			onVLCEndReached();
		#end

		if (canUseAutoResize && (videoWidth > 0 && videoHeight > 0))
		{
			width = calcSize(0);
			height = calcSize(1);
		}

		#if FLX_SOUND_SYSTEM
		volume = Std.int(((FlxG.sound.muted || !canUseSound) ? 0 : 1) * FlxG.sound.volume * 100);
		#end
	}

	public function calcSize(Ind:Int):Int
	{
		var stageWidth = FlxG.stage.stageWidth;
		var stageHeight = FlxG.stage.stageHeight;
		
		var appliedWidth:Float = stageHeight * (FlxG.width / FlxG.height);
		var appliedHeight:Float = stageWidth * (FlxG.height / FlxG.width);

		if (appliedHeight > stageHeight)
			appliedHeight = stageHeight;

		if (appliedWidth > stageWidth)
			appliedWidth = stageWidth;

		switch (Ind)
		{
			case 0:
				return Std.int(appliedWidth);
			case 1:
				return Std.int(appliedHeight);
			default:
				return 0;
		}
	}

	override public function dispose():Void
	{
		_isPlaying = false;
		_location = null;
		super.dispose();
	}
}
#else
// Dummy class when hxvlc is not available
class VideoHandler
{
	public var canSkip:Bool = true;
	public var canUseSound:Bool = true;
	public var canUseAutoResize:Bool = true;
	public var openingCallback:Void->Void = null;
	public var finishCallback:Void->Void = null;

	public function new(IndexModifier:Int = 0):Void
	{
		trace("VideoHandler: hxvlc not available");
	}

	public function playVideo(Path:String, Loop:Bool = false, PauseMusic:Bool = false):Void
	{
		trace("VideoHandler.playVideo: hxvlc not available");
	}

	public function pause():Void {}
	public function resume():Void {}
	public function stop():Void {}
	public function dispose():Void {}
}
#end
