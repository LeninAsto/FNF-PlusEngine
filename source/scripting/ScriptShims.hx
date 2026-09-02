package scripting;

#if HSCRIPT_ALLOWED
import flixel.FlxG;

class ScriptShims {
	public static function register():Void {
		var shims = hxscript.Config.callShims;

		shims.set('flixel.system.frontEnds.SoundFrontEnd.playMusic', function(o:Dynamic, args:Array<Dynamic>):Dynamic {
			var volume:Float = (args.length > 1 && args[1] != null) ? args[1] : 1.0;
			var looped:Bool = (args.length > 2 && args[2] != null) ? args[2] : true;

			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();

			FlxG.sound.music = FlxG.sound.load(args[0], volume, looped);
			FlxG.sound.music.play();
			return FlxG.sound.music;
		});

		shims.set('haxe.io.Bytes.get', function(o:Dynamic, args:Array<Dynamic>):Dynamic {
			return (cast o : haxe.io.Bytes).get(args[0]);
		});
		shims.set('haxe.io.Bytes.set', function(o:Dynamic, args:Array<Dynamic>):Dynamic {
			(cast o : haxe.io.Bytes).set(args[0], args[1]);
			return null;
		});
		shims.set('haxe.io.Bytes.getUInt16', function(o:Dynamic, args:Array<Dynamic>):Dynamic {
			return (cast o : haxe.io.Bytes).getUInt16(args[0]);
		});
		shims.set('haxe.io.Bytes.getInt32', function(o:Dynamic, args:Array<Dynamic>):Dynamic {
			return (cast o : haxe.io.Bytes).getInt32(args[0]);
		});
		shims.set('haxe.io.Bytes.getDouble', function(o:Dynamic, args:Array<Dynamic>):Dynamic {
			return (cast o : haxe.io.Bytes).getDouble(args[0]);
		});
		shims.set('haxe.io.Bytes.getFloat', function(o:Dynamic, args:Array<Dynamic>):Dynamic {
			return (cast o : haxe.io.Bytes).getFloat(args[0]);
		});
		shims.set('haxe.Timer.stamp', function(o:Dynamic, args:Array<Dynamic>):Dynamic {
			return haxe.Timer.stamp();
		});
	}
}
#end
