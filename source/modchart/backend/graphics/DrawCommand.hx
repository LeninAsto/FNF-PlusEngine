package modchart.backend.graphics;

import flixel.FlxCamera;
import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets.FlxShader;
import openfl.display.BlendMode;

@:publicFields
@:structInit
class DrawCommand {
	// stuff
	var parent:FlxSprite;

	var graphic:FlxGraphic;
	var antialiasing:Bool;
	var blend:BlendMode;
	var shader:FlxShader;
	var cameras:Array<FlxCamera>;

	// rendering — use openfl.Vector directly to avoid conversion at render time
	var vertices:openfl.Vector<Float>;
	var uvs:openfl.Vector<Float>;
	var indices:openfl.Vector<Int>;

	var isColored:Bool;
	var hasColorOffsets:Bool;

	// each has a different use
	var color:Null<ColorTransform> = null;
	var colors:Null<NativeVector<ColorTransform>> = null;

	var zIndex:Int = 0;
}