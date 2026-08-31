package psychlua;

import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.display.Shape;

class MatrixCubeSprite extends ModchartSprite
{
	static final FACE_INDICES:Array<Array<Int>> = [
		[0, 1, 2, 3],
		[4, 7, 6, 5],
		[0, 4, 5, 1],
		[3, 2, 6, 7],
		[1, 5, 6, 2],
		[0, 3, 7, 4]
	];

	static final FACE_COLORS:Array<Int> = [
		0x5E7BFF,
		0x26306A,
		0x36D1FF,
		0x1A8DDE,
		0x91E8FF,
		0x4456D8
	];

	public var cubeSize(default, set):Float = 120;
	public var heightScale(default, set):Float = 1;
	public var rotX:Float = -18;
	public var rotY:Float = 36;
	public var rotZ:Float = 0;
	public var focalLength:Float = 360;
	public var cameraDistance:Float = 420;
	public var fillAlpha:Float = 0.88;
	public var lineAlpha:Float = 0.7;
	public var edgeColor:Int = 0xDDEBFF;
	public var edgeThickness:Float = 2;
	public var wireframeOnly:Bool = false;
	public var floorAnchored:Bool = false;
	public var autoRotate:Bool = true;
	public var spinSpeedX:Float = 12;
	public var spinSpeedY:Float = 34;
	public var spinSpeedZ:Float = 0;

	var canvasWidth:Int;
	var canvasHeight:Int;
	var bitmap:BitmapData;
	var shape:Shape = new Shape();
	var vertices:Array<CubeVertex> = [];
	var projected:Array<ProjectedVertex> = [];
	var faces:Array<ProjectedFace> = [];
	var meshDirty:Bool = true;

	public function new(x:Float, y:Float, width:Int = 360, height:Int = 360, size:Float = 120)
	{
		super(x, y);
		canvasWidth = Std.int(Math.max(8, width));
		canvasHeight = Std.int(Math.max(8, height));
		cubeSize = size;
		makeGraphic(canvasWidth, canvasHeight, FlxColor.TRANSPARENT, true);
		bitmap = pixels;
		scrollFactor.set(1, 1);
		active = true;

		for (i in 0...8)
		{
			vertices.push(new CubeVertex());
			projected.push(new ProjectedVertex());
		}
		for (i in 0...FACE_INDICES.length)
			faces.push(new ProjectedFace(i));

		renderCube();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (autoRotate)
		{
			rotX += spinSpeedX * elapsed;
			rotY += spinSpeedY * elapsed;
			rotZ += spinSpeedZ * elapsed;
			meshDirty = true;
		}

		if (meshDirty)
			renderCube();
	}

	public function pulse(stretch:Float = 1.65):Void
	{
		heightScale = stretch;
		meshDirty = true;
	}

	public function setRotation3D(x:Float, y:Float, z:Float):Void
	{
		rotX = x;
		rotY = y;
		rotZ = z;
		meshDirty = true;
	}

	public function setSpin(x:Float, y:Float, z:Float):Void
	{
		spinSpeedX = x;
		spinSpeedY = y;
		spinSpeedZ = z;
	}

	public function setStyle(wireframe:Bool, edgeColor:Int, fillAlpha:Float, lineAlpha:Float, edgeThickness:Float):Void
	{
		wireframeOnly = wireframe;
		this.edgeColor = edgeColor & 0xFFFFFF;
		this.fillAlpha = Math.max(0, Math.min(1, fillAlpha));
		this.lineAlpha = Math.max(0, Math.min(1, lineAlpha));
		this.edgeThickness = Math.max(0, edgeThickness);
		meshDirty = true;
	}

	function set_cubeSize(value:Float):Float
	{
		cubeSize = Math.max(1, value);
		meshDirty = true;
		return cubeSize;
	}

	function set_heightScale(value:Float):Float
	{
		heightScale = Math.max(0.05, value);
		meshDirty = true;
		return heightScale;
	}

	function renderCube():Void
	{
		if (bitmap == null)
			return;

		meshDirty = false;
		bitmap.fillRect(bitmap.rect, FlxColor.TRANSPARENT);
		buildVertices();
		projectVertices();
		sortFaces();

		var graphics = shape.graphics;
		graphics.clear();

		for (face in faces)
		{
			var indices = FACE_INDICES[face.index];
			var color = shadedColor(FACE_COLORS[face.index], face.light);
			if (!wireframeOnly)
				graphics.beginFill(color, fillAlpha);
			graphics.lineStyle(edgeThickness, edgeColor, lineAlpha);
			graphics.moveTo(projected[indices[0]].x, projected[indices[0]].y);
			for (i in 1...indices.length)
				graphics.lineTo(projected[indices[i]].x, projected[indices[i]].y);
			graphics.lineTo(projected[indices[0]].x, projected[indices[0]].y);
			if (!wireframeOnly)
				graphics.endFill();
		}

		bitmap.draw(shape, null, null, null, null, true);
		dirty = true;
	}

	function buildVertices():Void
	{
		var half = cubeSize * 0.5;
		var top = floorAnchored ? -cubeSize * heightScale : -half * heightScale;
		var bottom = floorAnchored ? 0 : half * heightScale;
		setVertex(0, -half, top, -half);
		setVertex(1, half, top, -half);
		setVertex(2, half, bottom, -half);
		setVertex(3, -half, bottom, -half);
		setVertex(4, -half, top, half);
		setVertex(5, half, top, half);
		setVertex(6, half, bottom, half);
		setVertex(7, -half, bottom, half);
	}

	function setVertex(index:Int, x:Float, y:Float, z:Float):Void
	{
		var vertex = vertices[index];
		vertex.x = x;
		vertex.y = y;
		vertex.z = z;
	}

	function projectVertices():Void
	{
		var rx = rotX * Math.PI / 180;
		var ry = rotY * Math.PI / 180;
		var rz = rotZ * Math.PI / 180;
		var cosX = Math.cos(rx);
		var sinX = Math.sin(rx);
		var cosY = Math.cos(ry);
		var sinY = Math.sin(ry);
		var cosZ = Math.cos(rz);
		var sinZ = Math.sin(rz);
		var cx = canvasWidth * 0.5;
		var cy = canvasHeight * 0.54;

		for (i in 0...vertices.length)
		{
			var vertex = vertices[i];
			var y1 = vertex.y * cosX - vertex.z * sinX;
			var z1 = vertex.y * sinX + vertex.z * cosX;
			var x2 = vertex.x * cosY + z1 * sinY;
			var z2 = -vertex.x * sinY + z1 * cosY;
			var x3 = x2 * cosZ - y1 * sinZ;
			var y3 = x2 * sinZ + y1 * cosZ;
			var denom = Math.max(1, cameraDistance - z2);
			var scale = focalLength / denom;

			var point = projected[i];
			point.x = cx + x3 * scale;
			point.y = cy + y3 * scale;
			point.z = z2;
		}
	}

	function sortFaces():Void
	{
		for (face in faces)
		{
			var indices = FACE_INDICES[face.index];
			var z = 0.0;
			for (index in indices)
				z += projected[index].z;
			face.depth = z / indices.length;
			face.light = Math.max(0.38, Math.min(1, 0.62 + face.depth / cubeSize * 0.32));
		}
		faces.sort((a, b) -> a.depth < b.depth ? -1 : (a.depth > b.depth ? 1 : 0));
	}

	function shadedColor(color:Int, light:Float):Int
	{
		var r = Std.int(((color >> 16) & 0xFF) * light);
		var g = Std.int(((color >> 8) & 0xFF) * light);
		var b = Std.int((color & 0xFF) * light);
		return (r << 16) | (g << 8) | b;
	}
}

private class CubeVertex
{
	public var x:Float = 0;
	public var y:Float = 0;
	public var z:Float = 0;

	public function new() {}
}

private class ProjectedVertex
{
	public var x:Float = 0;
	public var y:Float = 0;
	public var z:Float = 0;

	public function new() {}
}

private class ProjectedFace
{
	public var index:Int;
	public var depth:Float = 0;
	public var light:Float = 1;

	public function new(index:Int)
		this.index = index;
}
