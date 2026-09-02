package psychlua;

import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.display.Graphics;
import openfl.display.Shape;

class MatrixCitySprite extends ModchartSprite
{
	static final FACE_INDICES:Array<Array<Int>> = [
		[0, 1, 2, 3],
		[4, 7, 6, 5],
		[0, 4, 5, 1],
		[3, 2, 6, 7],
		[1, 5, 6, 2],
		[0, 3, 7, 4]
	];

	public var originX(default, set):Float;
	public var originY(default, set):Float;
	public var worldX(default, set):Float = 0;
	public var worldY(default, set):Float = 0;
	public var worldZ(default, set):Float = 0;
	public var cameraX(default, set):Float = 0;
	public var cameraY(default, set):Float = -140;
	public var cameraZ(default, set):Float = 620;
	public var pitch(default, set):Float = 18;
	public var yaw(default, set):Float = 0;
	public var roll(default, set):Float = 0;
	public var zoom(default, set):Float = 1;
	public var focalLength(default, set):Float = 520;
	public var nearClip(default, set):Float = 80;
	public var pulse(default, set):Float = 0;

	public var lineColor:Int = 0x00FF3C;
	public var fillColor:Int = 0x0A271A;
	public var roadColor:Int = 0x182339;
	public var horizonColor:Int = 0x00FF3C;
	public var lineAlpha:Float = 0.9;
	public var fillAlpha:Float = 0.035;
	public var roadAlpha:Float = 0.5;
	public var horizonAlpha:Float = 0.95;
	public var edgeThickness:Float = 2;
	public var floorScrollSpeed:Float = 1.1;
	public var floorY:Float = 0;
	public var floorNearZ:Float = -80;
	public var floorFarZ:Float = -2300;
	public var floorWidthNear:Float = 1450;
	public var floorWidthFar:Float = 4200;
	public var floorHorizontalLines:Int = 30;
	public var floorVerticalLines:Int = 34;

	var canvasWidth:Int;
	var canvasHeight:Int;
	var bitmap:BitmapData;
	var shape:Shape = new Shape();
	var buildings:Array<MatrixCityBuilding> = [];
	var faceCommands:Array<MatrixCityFaceCommand> = [];
	var projected:Array<MatrixCityPoint> = [];
	var floorNearLeft:MatrixCityPoint = new MatrixCityPoint();
	var floorNearRight:MatrixCityPoint = new MatrixCityPoint();
	var floorFarLeft:MatrixCityPoint = new MatrixCityPoint();
	var floorFarRight:MatrixCityPoint = new MatrixCityPoint();
	var floorLineA:MatrixCityPoint = new MatrixCityPoint();
	var floorLineB:MatrixCityPoint = new MatrixCityPoint();
	var horizonPoint:MatrixCityPoint = new MatrixCityPoint();
	var dirtyMesh:Bool = true;
	var floorScroll:Float = 0;

	public function new(x:Float, y:Float, width:Int = 1280, height:Int = 720)
	{
		super(x, y);
		canvasWidth = Std.int(Math.max(8, width));
		canvasHeight = Std.int(Math.max(8, height));
		originX = canvasWidth * 0.5;
		originY = canvasHeight * 0.72;
		makeGraphic(canvasWidth, canvasHeight, FlxColor.TRANSPARENT, true);
		bitmap = pixels;
		scrollFactor.set(0, 0);
		active = true;

		for (i in 0...8)
			projected.push(new MatrixCityPoint());

		renderCity();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		floorScroll = (floorScroll + elapsed * floorScrollSpeed) % 1;
		dirtyMesh = true;

		if (dirtyMesh)
			renderCity();
	}

	public function clearBuildings():Void
	{
		buildings.resize(0);
		faceCommands.resize(0);
		dirtyMesh = true;
	}

	public function addBuilding(id:String, x:Float, y:Float, z:Float, width:Float = 128, height:Float = 400, depth:Float = 128, yaw:Float = 0):Void
	{
		var building = getBuilding(id);
		if (building == null)
		{
			building = new MatrixCityBuilding(id);
			buildings.push(building);
		}

		building.x = x;
		building.y = y;
		building.z = z;
		building.width = Math.max(1, width);
		building.height = Math.max(1, height);
		building.depth = Math.max(1, depth);
		building.yaw = yaw;
		dirtyMesh = true;
	}

	public function setCamera(x:Float, y:Float, z:Float, pitch:Float, yaw:Float, roll:Float, zoom:Float):Void
	{
		cameraX = x;
		cameraY = y;
		cameraZ = z;
		this.pitch = pitch;
		this.yaw = yaw;
		this.roll = roll;
		this.zoom = zoom;
		dirtyMesh = true;
	}

	public function setWorld(x:Float, y:Float, z:Float):Void
	{
		worldX = x;
		worldY = y;
		worldZ = z;
		dirtyMesh = true;
	}

	public function setStyle(lineColor:Int, fillColor:Int, roadColor:Int, lineAlpha:Float, fillAlpha:Float, roadAlpha:Float, edgeThickness:Float):Void
	{
		this.lineColor = lineColor & 0xFFFFFF;
		this.fillColor = fillColor & 0xFFFFFF;
		this.roadColor = roadColor & 0xFFFFFF;
		this.lineAlpha = clamp01(lineAlpha);
		this.fillAlpha = clamp01(fillAlpha);
		this.roadAlpha = clamp01(roadAlpha);
		this.edgeThickness = Math.max(0, edgeThickness);
		dirtyMesh = true;
	}

	public function setFloor(widthNear:Float, widthFar:Float, nearZ:Float, farZ:Float, horizontalLines:Int, verticalLines:Int):Void
	{
		floorWidthNear = Math.max(1, widthNear);
		floorWidthFar = Math.max(1, widthFar);
		floorNearZ = nearZ;
		floorFarZ = farZ;
		floorHorizontalLines = Std.int(Math.max(2, horizontalLines));
		floorVerticalLines = Std.int(Math.max(2, verticalLines));
		dirtyMesh = true;
	}

	public function getBuilding(id:String):MatrixCityBuilding
	{
		for (building in buildings)
			if (building.id == id)
				return building;
		return null;
	}

	function renderCity():Void
	{
		if (bitmap == null)
			return;

		dirtyMesh = false;
		bitmap.fillRect(bitmap.rect, FlxColor.TRANSPARENT);

		var graphics = shape.graphics;
		graphics.clear();

		drawFloor(graphics);
		buildFaceCommands();
		drawBuildings(graphics);
		drawHorizon(graphics);

		bitmap.draw(shape, null, null, null, null, true);
		dirty = true;
	}

	function drawFloor(graphics:Graphics):Void
	{
		projectFloorInto(-floorWidthNear * 0.5, floorNearZ, floorNearLeft);
		projectFloorInto(floorWidthNear * 0.5, floorNearZ, floorNearRight);
		projectFloorInto(floorWidthFar * 0.5, floorFarZ, floorFarRight);
		projectFloorInto(-floorWidthFar * 0.5, floorFarZ, floorFarLeft);

		graphics.beginFill(roadColor, roadAlpha);
		graphics.moveTo(floorFarLeft.x, floorFarLeft.y);
		graphics.lineTo(floorFarRight.x, floorFarRight.y);
		graphics.lineTo(floorNearRight.x, floorNearRight.y);
		graphics.lineTo(floorNearLeft.x, floorNearLeft.y);
		graphics.lineTo(floorFarLeft.x, floorFarLeft.y);
		graphics.endFill();

		for (i in -floorVerticalLines...floorVerticalLines + 1)
		{
			var t = i / floorVerticalLines;
			var nearX = t * floorWidthNear * 0.5;
			var farX = t * floorWidthFar * 0.5;
			projectFloorInto(nearX, floorNearZ, floorLineA);
			projectFloorInto(farX, floorFarZ, floorLineB);
			graphics.lineStyle(1, lineColor, lineAlpha * depthAlpha(floorLineB.depth));
			graphics.moveTo(floorLineA.x, floorLineA.y);
			graphics.lineTo(floorLineB.x, floorLineB.y);
		}

		for (i in 0...floorHorizontalLines)
		{
			var t = (i + floorScroll) / floorHorizontalLines;
			var curved = t * t;
			var z = lerp(floorNearZ, floorFarZ, curved);
			var width = lerp(floorWidthNear, floorWidthFar, curved);
			projectFloorInto(-width * 0.5, z, floorLineA);
			projectFloorInto(width * 0.5, z, floorLineB);
			var alpha = lineAlpha * Math.max(0.16, 1 - t);
			graphics.lineStyle(1 + t * 2, lineColor, alpha);
			graphics.moveTo(floorLineA.x, floorLineA.y);
			graphics.lineTo(floorLineB.x, floorLineB.y);
		}
	}

	function buildFaceCommands():Void
	{
		var needed = buildings.length * FACE_INDICES.length;
		while (faceCommands.length < needed)
			faceCommands.push(new MatrixCityFaceCommand());
		faceCommands.resize(needed);

		var commandIndex = 0;
		for (buildingIndex in 0...buildings.length)
		{
			var building = buildings[buildingIndex];
			projectBuilding(building);

			for (faceIndex in 0...FACE_INDICES.length)
			{
				var indices = FACE_INDICES[faceIndex];
				var command = faceCommands[commandIndex++];
				command.building = building;
				command.faceIndex = faceIndex;
				command.depth = 0;
				command.visible = true;

				for (i in 0...4)
				{
					var point = projected[indices[i]];
					command.points[i].copyFrom(point);
					command.depth += point.depth;
					if (point.clipped)
						command.visible = false;
				}
				command.depth /= 4;
			}
		}

		faceCommands.sort(function(a, b)
		{
			if (a.depth > b.depth) return -1;
			if (a.depth < b.depth) return 1;
			return 0;
		});
	}

	function drawBuildings(graphics:Graphics):Void
	{
		for (command in faceCommands)
		{
			if (!command.visible)
				continue;

			var alpha = lineAlpha * depthAlpha(command.depth);
			if (fillAlpha > 0)
				graphics.beginFill(fillColor, fillAlpha * depthAlpha(command.depth));
			graphics.lineStyle(edgeThickness, lineColor, alpha);
			graphics.moveTo(command.points[0].x, command.points[0].y);
			for (i in 1...4)
				graphics.lineTo(command.points[i].x, command.points[i].y);
			graphics.lineTo(command.points[0].x, command.points[0].y);
			if (fillAlpha > 0)
				graphics.endFill();
		}
	}

	function drawHorizon(graphics:Graphics):Void
	{
		projectFloorInto(0, floorFarZ, horizonPoint);
		graphics.lineStyle(5, horizonColor, horizonAlpha);
		graphics.moveTo(0, horizonPoint.y);
		graphics.lineTo(canvasWidth, horizonPoint.y);
		graphics.lineStyle(18, horizonColor, horizonAlpha * 0.2);
		graphics.moveTo(0, horizonPoint.y + 2);
		graphics.lineTo(canvasWidth, horizonPoint.y + 2);
	}

	function projectBuilding(building:MatrixCityBuilding):Void
	{
		var halfW = building.width * 0.5;
		var halfD = building.depth * 0.5;
		var height = building.height * (1 + pulse * building.pulseAmount);
		var top = building.y - height;
		var bottom = building.y;

		setProjectedVertex(0, building, -halfW, top, -halfD);
		setProjectedVertex(1, building, halfW, top, -halfD);
		setProjectedVertex(2, building, halfW, bottom, -halfD);
		setProjectedVertex(3, building, -halfW, bottom, -halfD);
		setProjectedVertex(4, building, -halfW, top, halfD);
		setProjectedVertex(5, building, halfW, top, halfD);
		setProjectedVertex(6, building, halfW, bottom, halfD);
		setProjectedVertex(7, building, -halfW, bottom, halfD);
	}

	function setProjectedVertex(index:Int, building:MatrixCityBuilding, localX:Float, localY:Float, localZ:Float):Void
	{
		var yawRad = building.yaw * Math.PI / 180;
		var cosY = Math.cos(yawRad);
		var sinY = Math.sin(yawRad);
		var x = localX * cosY + localZ * sinY + building.x;
		var z = -localX * sinY + localZ * cosY + building.z;
		projectPointInto(x, localY, z, projected[index]);
	}

	function projectFloorInto(x:Float, z:Float, point:MatrixCityPoint):Void
	{
		projectPointInto(x, floorY, z, point);
	}

	function projectPointInto(x:Float, y:Float, z:Float, point:MatrixCityPoint):Void
	{
		x = x + worldX - cameraX;
		y = y + worldY - cameraY;
		z = z + worldZ - cameraZ;

		var rx = pitch * Math.PI / 180;
		var ry = yaw * Math.PI / 180;
		var rz = roll * Math.PI / 180;

		var cosX = Math.cos(rx);
		var sinX = Math.sin(rx);
		var y1 = y * cosX - z * sinX;
		var z1 = y * sinX + z * cosX;

		var cosY = Math.cos(ry);
		var sinY = Math.sin(ry);
		var x2 = x * cosY + z1 * sinY;
		var z2 = -x * sinY + z1 * cosY;

		var cosZ = Math.cos(rz);
		var sinZ = Math.sin(rz);
		var x3 = x2 * cosZ - y1 * sinZ;
		var y3 = x2 * sinZ + y1 * cosZ;

		var depth = Math.max(nearClip, focalLength - z2);
		var scale = focalLength / depth * zoom;
		point.x = originX + x3 * scale;
		point.y = originY + y3 * scale;
		point.depth = depth;
		point.scale = scale;
		point.clipped = depth <= nearClip + 0.001 || point.x < -canvasWidth || point.x > canvasWidth * 2 || point.y < -canvasHeight || point.y > canvasHeight * 2;
	}

	function set_originX(value:Float):Float return setDirty(originX = value);
	function set_originY(value:Float):Float return setDirty(originY = value);
	function set_worldX(value:Float):Float return setDirty(worldX = value);
	function set_worldY(value:Float):Float return setDirty(worldY = value);
	function set_worldZ(value:Float):Float return setDirty(worldZ = value);
	function set_cameraX(value:Float):Float return setDirty(cameraX = value);
	function set_cameraY(value:Float):Float return setDirty(cameraY = value);
	function set_cameraZ(value:Float):Float return setDirty(cameraZ = value);
	function set_pitch(value:Float):Float return setDirty(pitch = value);
	function set_yaw(value:Float):Float return setDirty(yaw = value);
	function set_roll(value:Float):Float return setDirty(roll = value);
	function set_zoom(value:Float):Float return setDirty(zoom = Math.max(0.01, value));
	function set_focalLength(value:Float):Float return setDirty(focalLength = Math.max(1, value));
	function set_nearClip(value:Float):Float return setDirty(nearClip = Math.max(0.1, value));
	function set_pulse(value:Float):Float return setDirty(pulse = Math.max(0, value));

	inline function setDirty(value:Float):Float
	{
		dirtyMesh = true;
		return value;
	}

	static inline function clamp01(value:Float):Float
		return value < 0 ? 0 : (value > 1 ? 1 : value);

	static inline function lerp(a:Float, b:Float, t:Float):Float
		return a + (b - a) * t;

	static inline function depthAlpha(depth:Float):Float
		return Math.max(0.16, Math.min(1, (1450 - depth) / 900));
}

class MatrixCityBuilding
{
	public var id:String;
	public var x:Float = 0;
	public var y:Float = 0;
	public var z:Float = 0;
	public var width:Float = 128;
	public var height:Float = 400;
	public var depth:Float = 128;
	public var yaw:Float = 0;
	public var pulseAmount:Float = 0.95;

	public function new(id:String)
	{
		this.id = id;
	}
}

private class MatrixCityPoint
{
	public var x:Float = 0;
	public var y:Float = 0;
	public var depth:Float = 0;
	public var scale:Float = 1;
	public var clipped:Bool = false;

	public function new() {}

	public inline function copyFrom(other:MatrixCityPoint):Void
	{
		x = other.x;
		y = other.y;
		depth = other.depth;
		scale = other.scale;
		clipped = other.clipped;
	}
}

private class MatrixCityFaceCommand
{
	public var building:MatrixCityBuilding;
	public var faceIndex:Int = 0;
	public var depth:Float = 0;
	public var visible:Bool = true;
	public var points:Array<MatrixCityPoint> = [];

	public function new()
	{
		for (i in 0...4)
			points.push(new MatrixCityPoint());
	}
}
