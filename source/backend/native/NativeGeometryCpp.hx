package backend.native;

#if cpp
import cpp.Float64;
import cpp.RawPointer;

extern class NativeGeometryCpp
{
	@:native('plus_affine2d_batch')
	public static function affine2D(xy:RawPointer<Float64>, vertexCount:Int,
		a:Float, b:Float, c:Float, d:Float, tx:Float, ty:Float):Void;
}
#end
