package objects.hxcodec.v3_0_0;

#if hxvlc
import hxvlc.openfl.Video as HxvlcVideo;

/**
 * Simple wrapper to expose hxvlc's Video class with hxCodec-compatible API
 * This is used internally by FlxVideo and FlxVideoSprite wrappers
 */
class Video extends HxvlcVideo
{
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

	public var location(get, never):String;
	private function get_location():String
	{
		return _location;
	}

	public function new():Void
	{
		super();
		Reflect.setField(this, "play", function(location:String, ?options:Array<String>):Bool
		{
			return load(location, options);
		});
	}

	override public function load(location:hxvlc.util.Location, ?options:Array<String>):Bool
	{
		if ((location is String))
			_location = cast(location, String);
		else
			_location = null;

		return super.load(location, options);
	}

	// hxvlc already has most methods compatible:
	// - load(location):Bool
	// - play():Bool (but is called automatically by load in hxvlc 2.2.5)
	// - stop():Void
	// - pause():Void
	// - resume():Void
	// - dispose():Void
	// 
	// Properties:
	// - volume:Int (0-100)
	// - isPlaying:Bool
	// - bitmapData:BitmapData
	// - onOpening:Event
	// - onEndReached:Event
	// - onFormatSetup:Event (equivalent to onTextureSetup in older hxvlc)
}
#else
// Dummy class when hxvlc is not available
class Video
{
	public var volume:Float = 1.0;
	public var isPlaying:Bool = false;
	public var bitmapData:Dynamic = null;
	public var onOpening:Dynamic = null;
	public var onEndReached:Dynamic = null;
	public var onFormatSetup:Dynamic = null;
	public var location:String = null;
	public var alpha:Float = 1.0;

	public function new():Void
	{
		trace("Video: hxvlc not available");
	}

	public function load(path:String):Bool
	{
		trace("Video.load: hxvlc not available");
		return false;
	}

	public function play():Bool
	{
		trace("Video.play: hxvlc not available");
		return false;
	}

	public function stop():Void {}
	public function pause():Void {}
	public function resume():Void {}
	public function dispose():Void {}
}
#end
