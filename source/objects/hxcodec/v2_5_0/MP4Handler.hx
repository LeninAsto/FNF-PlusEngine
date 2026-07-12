package objects.hxcodec.v2_5_0;

#if hxvlc
import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import hxvlc.openfl.Video as HxvlcVideo;
import openfl.events.Event;
import sys.FileSystem;

/**
 * Compatibility wrapper for hxCodec 3.x (old VLC wrapper) MP4Handler using hxvlc 2.2.5
 * Emulates the VlcBitmap-based API from hxCodec version 3.x
 */
class MP4Handler extends HxvlcVideo
{
	public var readyCallback:Void->Void;
	public var finishCallback:Void->Void;

	private var pauseMusic:Bool;
	private var _repeat:Int = 0;
	private var _isReady:Bool = false;
	private var _location:String = null;

	public var repeat(get, set):Int;
	private function get_repeat():Int
	{
		return _repeat;
	}
	private function set_repeat(value:Int):Int
	{
		_repeat = value;
		return _repeat;
	}

	public var location(get, never):String;
	private function get_location():String
	{
		return _location;
	}

	public function new(width:Float = 320, height:Float = 240, autoScale:Bool = true)
	{
		super();

		this.width = width;
		this.height = height;

		onFormatSetup.add(onVLCVideoReady);
		onEndReached.add(onVLCComplete);
		onEncounteredError.add(onVLCError);

		FlxG.addChildBelowMouse(this);

		FlxG.stage.addEventListener(Event.ENTER_FRAME, update);

		if (FlxG.autoPause)
		{
			FlxG.signals.focusGained.add(function()
			{
				resume();
			});
			FlxG.signals.focusLost.add(function()
			{
				pause();
			});
		}
	}

	private function update(?E:Event):Void
	{
		#if FLX_KEYBOARD
		if ((FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE) && isPlaying)
			finishVideo();
		#end

		#if FLX_SOUND_SYSTEM
		if (FlxG.sound.muted || FlxG.sound.volume <= 0)
			volume = 0;
		else
			volume = Std.int(FlxG.sound.volume * 100);
		#end
	}

	private function checkFile(fileName:String):String
	{
		#if sys
		#if !android
		var pDir = "";
		var appDir = Sys.getCwd();

		if (fileName.indexOf(":") == -1) // Not a path
			pDir = appDir;

		var fullPath = pDir + fileName;
		if (FileSystem.exists(fullPath))
			return fullPath;

		return fileName;
		#else
		return fileName;
		#end
		#else
		return fileName;
		#end
	}

	private function onVLCVideoReady():Void
	{
		trace("MP4Handler: Video loaded!");
		_isReady = true;

		if (readyCallback != null)
			readyCallback();
	}

	private function onVLCError(error:String):Void
	{
		trace("MP4Handler: VLC caught an error: " + error);
		finishVideo();
	}

	private function onVLCComplete():Void
	{
		if (_repeat < 0) // Infinite loop
		{
			stop();
			haxe.Timer.delay(function()
			{
				if (_location != null && load(_location))
					resume();
			}, 50);
		}
		else if (_repeat > 0)
		{
			_repeat--;
			stop();
			haxe.Timer.delay(function()
			{
				if (_location != null && load(_location))
					resume();
			}, 50);
		}
		else
		{
			finishVideo();
		}
	}

	public function finishVideo():Void
	{
		if (FlxG.sound.music != null && pauseMusic)
			FlxG.sound.music.resume();

		if (FlxG.stage.hasEventListener(Event.ENTER_FRAME))
			FlxG.stage.removeEventListener(Event.ENTER_FRAME, update);

		dispose();

		if (FlxG.game.contains(this))
			FlxG.game.removeChild(this);

		if (finishCallback != null)
			finishCallback();
	}

	/**
	 * Native video support for Flixel & OpenFL
	 * @param path Example: `your/video/here.mp4`
	 * @param repeat Repeat the video (-1 = infinite, 0 = once, >0 = repeat n times).
	 * @param pauseMusic Pause music until done video.
	 */
	public function playVideo(path:String, ?repeat:Bool = false, ?pauseMusic:Bool = false):Void
	{
		this.pauseMusic = pauseMusic;
		this._repeat = repeat ? -1 : 0;

		if (FlxG.sound.music != null && pauseMusic)
			FlxG.sound.music.pause();

		var videoPath = checkFile(path);
		_location = videoPath;

		if (load(videoPath))
			resume();
	}

	override public function dispose():Void
	{
		_isReady = false;
		_location = null;

		if (FlxG.autoPause)
		{
			FlxG.signals.focusGained.remove(resume);
			FlxG.signals.focusLost.remove(pause);
		}

		super.dispose();
	}
}
#else
// Dummy class when hxvlc is not available
class MP4Handler
{
	public var readyCallback:Void->Void;
	public var finishCallback:Void->Void;
	public var repeat:Int = 0;

	public function new(width:Float = 320, height:Float = 240, autoScale:Bool = true)
	{
		trace("MP4Handler: hxvlc not available");
	}

	public function playVideo(path:String, ?repeat:Bool = false, ?pauseMusic:Bool = false):Void
	{
		trace("MP4Handler.playVideo: hxvlc not available");
	}

	public function finishVideo():Void {}
	public function pause():Void {}
	public function resume():Void {}
	public function dispose():Void {}
}
#end
