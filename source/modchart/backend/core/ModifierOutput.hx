package modchart.backend.core;

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:structInit
@:publicFields
class ModifierOutput {
	var pos:Vector3;
	var visuals:VisualParameters;
	var rawX:Float = 0;
	var rawY:Float = 0;
	var rawZ:Float = 0;
}
