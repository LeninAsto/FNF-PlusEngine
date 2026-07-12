package objects.hxcodec.v3_0_0;

#if hxvlc
import flixel.FlxG;
import hxvlc.openfl.Video as HxvlcVideo;
import openfl.events.Event;
import sys.FileSystem;

/**
 * Compatibility wrapper for hxCodec's FlxVideo using hxvlc
 * Emulates the old hxCodec API for legacy Psych 0.7.3 mods
 */
class FlxVideo extends HxvlcVideo
{
	// Variables
	public var autoResize:Bool = true;
	private var _shouldLoop:Bool = false;
	private var _location:String = null;

	public var onTextureSetup(get, never):Dynamic;
	private function get_onTextureSetup():Dynamic
	{
		#if hxvlc
		return onFormatSetup;
		#else
		return null;
		#end
	}

	public function new():Void
	{
		super();
		Reflect.setField(this, "play", function(location:String, shouldLoop:Bool = false):Bool
		{
			return playMP4(location, shouldLoop);
		});

		onOpening.add(function()
		{
			#if FLX_SOUND_SYSTEM
			volume = Std.int((FlxG.sound.muted ? 0 : 1) * FlxG.sound.volume * 100);
			#end
		});

		FlxG.addChildBelowMouse(this);
	}

	public function playMP4(location:String, shouldLoop:Bool = false):Bool
	{
		_shouldLoop = shouldLoop;

		if (FlxG.autoPause)
		{
			if (!FlxG.signals.focusGained.has(resume))
				FlxG.signals.focusGained.add(resume);

			if (!FlxG.signals.focusLost.has(pause))
				FlxG.signals.focusLost.add(pause);
		}

		FlxG.stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);

		// Setup loop behavior
		if (_shouldLoop)
		{
			onEndReached.add(function()
			{
				stop();
				haxe.Timer.delay(function()
				{
					if (this != null && _location != null)
					{
						if (load(_location))
							resume();
					}
				}, 50);
			});
		}

		var videoPath = location;
		if (FileSystem.exists(Sys.getCwd() + location))
			videoPath = Sys.getCwd() + location;

		_location = videoPath;
		var success = load(videoPath);
		if (success)
		{
			resume();
			return true;
		}
		return false;
	}

	override public function dispose():Void
	{
		if (FlxG.autoPause)
		{
			if (FlxG.signals.focusGained.has(resume))
				FlxG.signals.focusGained.remove(resume);

			if (FlxG.signals.focusLost.has(pause))
				FlxG.signals.focusLost.remove(pause);
		}

		if (FlxG.stage.hasEventListener(Event.ENTER_FRAME))
			FlxG.stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);

		stop();

		FlxG.removeChild(this);
	}

	@:noCompletion private function onEnterFrame(e:Event):Void
	{
		if (autoResize)
		{
			var aspectRatio:Float = FlxG.width / FlxG.height;

			if (FlxG.stage.stageWidth / FlxG.stage.stageHeight > aspectRatio)
			{
				// stage is wider than video
				width = FlxG.stage.stageHeight * aspectRatio;
				height = FlxG.stage.stageHeight;
			}
			else
			{
				// stage is taller than video
				width = FlxG.stage.stageWidth;
				height = FlxG.stage.stageWidth * (1 / aspectRatio);
			}
		}

		#if FLX_SOUND_SYSTEM
		volume = Std.int((FlxG.sound.muted ? 0 : 1) * FlxG.sound.volume * 100);
		#end
	}
}
#else
// Dummy class when hxvlc is not available
class FlxVideo
{
	public var autoResize:Bool = true;

	public function new():Void
	{
		trace("FlxVideo: hxvlc not available");
	}

	public function play(location:String, shouldLoop:Bool = false):Bool
	{
		trace("FlxVideo.play: hxvlc not available");
		return false;
	}

	public function dispose():Void {}
	public function pause():Void {}
	public function resume():Void {}
	public function stop():Void {}
}
#end
