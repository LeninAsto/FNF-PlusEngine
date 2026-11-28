package scripting;

#if HSCRIPT_ALLOWED
import flixel.FlxG;

class ScriptShims {
	public static function register():Void {
		var shims = hxscript.Config.callShims;

		shims.set('flixel.FlxCamera.addShader', function(o:Dynamic, args:Array<Dynamic>):Dynamic {
			// Compatibility shim for old Psych/Codename scripts.
			// Some mod shaders compile only in their original camera pipeline and can
			// crash OpenFL during render if applied blindly here, so keep this safe.
			return null;
		});

		shims.set('flixel.system.frontEnds.SoundFrontEnd.playMusic', function(o:Dynamic, args:Array<Dynamic>):Dynamic {
			var volume:Float = (args.length > 1 && args[1] != null) ? args[1] : 1.0;
			var looped:Bool = (args.length > 2 && args[2] != null) ? args[2] : true;

			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();

			FlxG.sound.music = FlxG.sound.create(args[0]).setup(volume, looped);
			FlxG.sound.music.play();
			return FlxG.sound.music;
		});

		shims.set('flixel.math.FlxRandom.getObject', function(o:Dynamic, args:Array<Dynamic>):Dynamic {
			if (args.length < 1 || args[0] == null)
				return null;

			var values:Array<Dynamic> = cast args[0];
			if (values == null || values.length < 1)
				return null;

			var startIndex:Int = (args.length > 2 && args[2] != null) ? Std.int(args[2]) : 0;
			var endIndex:Int = (args.length > 3 && args[3] != null) ? Std.int(args[3]) : values.length - 1;
			startIndex = Std.int(Math.max(0, Math.min(startIndex, values.length - 1)));
			endIndex = Std.int(Math.max(startIndex, Math.min(endIndex, values.length - 1)));

			return values[FlxG.random.int(startIndex, endIndex)];
		});

		shims.set('flixel.graphics.FlxGraphic.fromRectangle', function(o:Dynamic, args:Array<Dynamic>):Dynamic {
			var width:Int = args.length > 0 && args[0] != null ? Std.int(args[0]) : 1;
			var height:Int = args.length > 1 && args[1] != null ? Std.int(args[1]) : 1;
			var color:flixel.util.FlxColor = args.length > 2 && args[2] != null ? args[2] : flixel.util.FlxColor.WHITE;
			var unique:Bool = args.length > 3 && args[3] != null ? args[3] : false;
			var key:String = args.length > 4 ? args[4] : null;
			return flixel.graphics.FlxGraphic.fromRectangle(width, height, color, unique, key);
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
