package objects;

/**
 * Compatibility surface used by Psych-derived HScript mods.
 *
 * It deliberately matches the simple load/play/callback API rather than
 * exposing hxvlc internals directly.
 */
#if hxvlc
class PsychVideoSprite extends hxvlc.flixel.FlxVideoSprite
{
	/** LibVLC option used by legacy scripts: `[PsychVideoSprite.muted]`. */
	public static inline var muted:String = "no-audio";

	public function new()
	{
		super();
	}

	public function addCallback(name:String, callback:Dynamic):Void
	{
		if (bitmap == null || callback == null || !Reflect.isFunction(callback))
			return;

		var invoke = function():Void Reflect.callMethod(null, callback, []);
		switch (name == null ? "" : name.toLowerCase())
		{
			case "onformat" | "onformatsetup" | "ontexturesetup":
				bitmap.onFormatSetup.add(invoke);
			case "onend" | "onendreached":
				bitmap.onEndReached.add(invoke);
			case "onopening":
				bitmap.onOpening.add(invoke);
			default:
				trace('PsychVideoSprite: unsupported callback "$name"');
		}
	}
}
#else
class PsychVideoSprite extends flixel.FlxSprite
{
	public static inline var muted:String = "";

	public function new()
	{
		super();
	}

	public function addCallback(name:String, callback:Dynamic):Void {}
	public function load(location:Dynamic, ?options:Array<String>):Bool return false;
	public function play():Bool return false;
}
#end
