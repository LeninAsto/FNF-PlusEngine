package backend.native;

import openfl.Vector;

#if cpp
import cpp.Float64;
import cpp.Pointer as CppPointer;
import cpp.RawPointer;
#end

/** Allocation-free kernels for numeric render buffers owned by Haxe/OpenFL. */
#if cpp
@:cppFileCode('
#include <cstddef>
extern "C" void plus_affine2d_batch(double* xy, std::size_t vertex_count,
	double a, double b, double c, double d, double tx, double ty);
')
#end
class NativeGeometry
{
	/** Small sprites stay in Haxe; bridge overhead only pays off on larger geometry. */
	public static inline final MIN_NATIVE_VERTICES:Int = 16;

	public static function affine2D(vertices:Vector<Float>, a:Float, b:Float, c:Float, d:Float, tx:Float, ty:Float):Void
	{
		if (vertices == null || vertices.length < 2)
			return;

		var vertexCount:Int = Std.int(vertices.length / 2);
		#if cpp
		if (vertexCount >= MIN_NATIVE_VERTICES)
		{
			affine2DNative(vertices, vertexCount, a, b, c, d, tx, ty);
			return;
		}
		#end
		affine2DHaxe(vertices, vertexCount, a, b, c, d, tx, ty);
	}

	public static function affine2DHaxe(vertices:Vector<Float>, vertexCount:Int,
		a:Float, b:Float, c:Float, d:Float, tx:Float, ty:Float):Void
	{
		var count = Std.int(Math.min(vertexCount, vertices.length / 2));
		for (index in 0...count)
		{
			var offset = index * 2;
			var x = vertices[offset];
			var y = vertices[offset + 1];
			vertices[offset] = x * a + y * c + tx;
			vertices[offset + 1] = x * b + y * d + ty;
		}
	}

	public static function affine2DNative(vertices:Vector<Float>, vertexCount:Int,
		a:Float, b:Float, c:Float, d:Float, tx:Float, ty:Float):Void
	{
		#if cpp
		var values:Array<Float> = vectorArray(vertices);
		if (values == null)
		{
			affine2DHaxe(vertices, vertexCount, a, b, c, d, tx, ty);
			return;
		}
		var count = Std.int(Math.min(vertexCount, values.length / 2));
		if (count > 0)
			NativeGeometryCpp.affine2D(doublePointer(values), count, a, b, c, d, tx, ty);
		#else
		affine2DHaxe(vertices, vertexCount, a, b, c, d, tx, ty);
		#end
	}

	#if cpp
	@:privateAccess
	static inline function vectorArray(vertices:Vector<Float>):Array<Float>
	{
		var storage:Dynamic = cast vertices;
		return cast storage.__array;
	}

	static inline function doublePointer(values:Array<Float>):RawPointer<Float64>
		return cast CppPointer.ofArray(values).ptr;
	#end
}
