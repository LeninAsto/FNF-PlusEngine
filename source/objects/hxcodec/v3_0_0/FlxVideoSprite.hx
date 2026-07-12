package objects.hxcodec.v3_0_0;

#if hxvlc
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import objects.hxcodec.v3_0_0.Video;
import sys.FileSystem;

/**
 * Compatibility wrapper for hxCodec's FlxVideoSprite using hxvlc
 * Emulates the old hxCodec API for legacy Psych 0.7.3 mods
 */
class FlxVideoSprite extends FlxSprite
{
	// Variables
	public var bitmap(default, null):Video;
	private var _shouldLoop:Bool = false;

	public function new(x:Float = 0, y:Float = 0):Void
	{
		super(x, y);

		makeGraphic(1, 1, FlxColor.TRANSPARENT);

		bitmap = new Video();
		bitmap.alpha = 0;
		bitmap.onOpening.add(function()
		{
			#if FLX_SOUND_SYSTEM
			bitmap.volume = Std.int((FlxG.sound.muted ? 0 : 1) * FlxG.sound.volume * 100);
			#end
		});
		bitmap.onFormatSetup.add(() -> {
			if (bitmap.bitmapData != null)
				loadGraphic(bitmap.bitmapData);
		});
		FlxG.game.addChild(bitmap);
	}

	// Methods
	public function play(location:String, shouldLoop:Bool = false):Bool
	{
		_shouldLoop = shouldLoop;

		if (FlxG.autoPause)
		{
			if (!FlxG.signals.focusGained.has(resume))
				FlxG.signals.focusGained.add(resume);

			if (!FlxG.signals.focusLost.has(pause))
				FlxG.signals.focusLost.add(pause);
		}

		if (bitmap != null)
		{
			// Setup loop behavior
			if (_shouldLoop)
			{
				bitmap.onEndReached.add(function()
				{
					bitmap.stop();
					haxe.Timer.delay(function()
					{
						if (bitmap != null)
						{
							var path = bitmap.location;
							if (path != null && bitmap.load(path))
								bitmap.resume();
						}
					}, 50);
				});
			}

			var videoPath = location;
			if (FileSystem.exists(Sys.getCwd() + location))
				videoPath = Sys.getCwd() + location;

			var success = bitmap.load(videoPath);
			if (success)
			{
				bitmap.resume();
				return true;
			}
			return false;
		}
		else
			return false;
	}

	public function stop():Void
	{
		if (bitmap != null)
			bitmap.stop();
	}

	public function pause():Void
	{
		if (bitmap != null)
			bitmap.pause();
	}

	public function resume():Void
	{
		if (bitmap != null)
			bitmap.resume();
	}

	public function togglePaused():Void
	{
		if (bitmap != null)
		{
			if (bitmap.isPlaying)
				bitmap.pause();
			else
				bitmap.resume();
		}
	}

	// Overrides
	override public function update(elapsed:Float):Void
	{
		#if FLX_SOUND_SYSTEM
		if (bitmap != null)
			bitmap.volume = Std.int((FlxG.sound.muted ? 0 : 1) * FlxG.sound.volume * 100);
		#end

		super.update(elapsed);
	}

	override public function destroy():Void
	{
		if (FlxG.autoPause)
		{
			if (FlxG.signals.focusGained.has(resume))
				FlxG.signals.focusGained.remove(resume);

			if (FlxG.signals.focusLost.has(pause))
				FlxG.signals.focusLost.remove(pause);
		}

		if (bitmap != null)
		{
			bitmap.dispose();

			if (FlxG.game.contains(bitmap))
				FlxG.game.removeChild(bitmap);
		}

		super.destroy();
	}
}
#else
// Dummy class when hxvlc is not available
class FlxVideoSprite extends flixel.FlxSprite
{
	public var bitmap(default, null):Dynamic;

	public function new(x:Float = 0, y:Float = 0):Void
	{
		super(x, y);
		trace("FlxVideoSprite: hxvlc not available");
	}

	public function play(location:String, shouldLoop:Bool = false):Bool
	{
		trace("FlxVideoSprite.play: hxvlc not available");
		return false;
	}

	public function stop():Void {}
	public function pause():Void {}
	public function resume():Void {}
	public function togglePaused():Void {}
}
#end
