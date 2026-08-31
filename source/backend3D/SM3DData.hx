package backend3D;

class SM3DData
{
	public var sourcePath:String;
	public var meshes:Array<SM3DMesh> = [];
	public var materials:Array<SM3DMaterial> = [];
	public var bounds:SM3DBounds = new SM3DBounds();

	public function new(?sourcePath:String)
	{
		this.sourcePath = sourcePath;
	}

	public function rebuildBounds():SM3DBounds
	{
		bounds.reset();
		for (mesh in meshes)
		{
			mesh.rebuildBounds();
			bounds.includeBounds(mesh.bounds);
		}
		return bounds;
	}

	public function getTriangleCount():Int
	{
		var total = 0;
		for (mesh in meshes)
			total += mesh.triangles.length;
		return total;
	}
}

class SM3DMesh
{
	public var name:String;
	public var flags:Int;
	public var materialIndex:Int;
	public var vertices:Array<SM3DVertex> = [];
	public var normals:Array<SM3DVec3> = [];
	public var triangles:Array<SM3DTriangle> = [];
	public var bounds:SM3DBounds = new SM3DBounds();

	public function new(name:String, flags:Int = 0, materialIndex:Int = -1)
	{
		this.name = name;
		this.flags = flags;
		this.materialIndex = materialIndex;
	}

	public function rebuildBounds():SM3DBounds
	{
		bounds.reset();
		for (vertex in vertices)
			bounds.include(vertex.position);
		return bounds;
	}
}

class SM3DVertex
{
	public var flags:Int;
	public var position:SM3DVec3;
	public var uv:SM3DUV;
	public var boneIndex:Int;

	public function new(flags:Int, x:Float, y:Float, z:Float, u:Float, v:Float, boneIndex:Int)
	{
		this.flags = flags;
		position = new SM3DVec3(x, y, z);
		uv = new SM3DUV(u, v);
		this.boneIndex = boneIndex;
	}
}

class SM3DTriangle
{
	public var flags:Int;
	public var vertexIndices:Array<Int>;
	public var normalIndices:Array<Int>;
	public var smoothingGroup:Int;
	public var materialIndex:Int;

	public function new(flags:Int, vertexIndices:Array<Int>, normalIndices:Array<Int>, smoothingGroup:Int, materialIndex:Int = -1)
	{
		this.flags = flags;
		this.vertexIndices = vertexIndices;
		this.normalIndices = normalIndices;
		this.smoothingGroup = smoothingGroup;
		this.materialIndex = materialIndex;
	}
}

class SM3DMaterial
{
	public var name:String;
	public var ambient:SM3DColor;
	public var diffuse:SM3DColor;
	public var specular:SM3DColor;
	public var emissive:SM3DColor;
	public var shininess:Float;
	public var transparency:Float;
	public var colorMap:String;
	public var alphaMap:String;

	public function new(name:String)
	{
		this.name = name;
		ambient = new SM3DColor();
		diffuse = new SM3DColor();
		specular = new SM3DColor();
		emissive = new SM3DColor();
		shininess = 0;
		transparency = 1;
		colorMap = "";
		alphaMap = "";
	}
}

class SM3DVec3
{
	public var x:Float;
	public var y:Float;
	public var z:Float;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0)
	{
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public inline function set(x:Float, y:Float, z:Float):SM3DVec3
	{
		this.x = x;
		this.y = y;
		this.z = z;
		return this;
	}

	public inline function clone():SM3DVec3
	{
		return new SM3DVec3(x, y, z);
	}
}

class SM3DUV
{
	public var u:Float;
	public var v:Float;

	public function new(u:Float = 0, v:Float = 0)
	{
		this.u = u;
		this.v = v;
	}
}

class SM3DColor
{
	public var r:Float;
	public var g:Float;
	public var b:Float;
	public var a:Float;

	public function new(r:Float = 1, g:Float = 1, b:Float = 1, a:Float = 1)
	{
		this.r = r;
		this.g = g;
		this.b = b;
		this.a = a;
	}

	public inline function set(r:Float, g:Float, b:Float, a:Float):SM3DColor
	{
		this.r = r;
		this.g = g;
		this.b = b;
		this.a = a;
		return this;
	}
}

class SM3DBounds
{
	public var min:SM3DVec3 = new SM3DVec3();
	public var max:SM3DVec3 = new SM3DVec3();
	public var empty:Bool = true;

	public function new() {}

	public function reset():Void
	{
		empty = true;
		min.set(0, 0, 0);
		max.set(0, 0, 0);
	}

	public function include(point:SM3DVec3):Void
	{
		if (point == null)
			return;

		if (empty)
		{
			min.set(point.x, point.y, point.z);
			max.set(point.x, point.y, point.z);
			empty = false;
			return;
		}

		if (point.x < min.x) min.x = point.x;
		if (point.y < min.y) min.y = point.y;
		if (point.z < min.z) min.z = point.z;
		if (point.x > max.x) max.x = point.x;
		if (point.y > max.y) max.y = point.y;
		if (point.z > max.z) max.z = point.z;
	}

	public function includeBounds(bounds:SM3DBounds):Void
	{
		if (bounds == null || bounds.empty)
			return;
		include(bounds.min);
		include(bounds.max);
	}
}
