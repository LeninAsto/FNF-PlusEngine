package psychlua;

import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.display.Shape;

class MatrixGridFloorSprite extends ModchartSprite
{
	public var lineColor:Int = 0x00FF3C;
	public var horizonColor:Int = 0x00FF3C;
	public var roadColor:Int = 0x192435;
	public var lineAlpha:Float = 0.58;
	public var horizonAlpha:Float = 0.95;
	public var roadAlpha:Float = 0.5;
	public var horizonY:Float = 58;
	public var vanishingX:Float;
	public var scrollSpeed:Float = 0.85;
	public var verticalLines:Int = 22;
	public var horizontalLines:Int = 22;
	public var roadNearWidth:Float = 270;
	public var roadFarWidth:Float = 76;

	var canvasWidth:Int;
	var canvasHeight:Int;
	var bitmap:BitmapData;
	var shape:Shape = new Shape();
	var scroll:Float = 0;
	var gridDirty:Bool = true;

	public function new(x:Float, y:Float, width:Int = 1280, height:Int = 720)
	{
		super(x, y);
		canvasWidth = Std.int(Math.max(8, width));
		canvasHeight = Std.int(Math.max(8, height));
		vanishingX = canvasWidth * 0.5;
		makeGraphic(canvasWidth, canvasHeight, FlxColor.TRANSPARENT, true);
		bitmap = pixels;
		scrollFactor.set(0, 0);
		active = true;
		renderGrid();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		scroll = (scroll + elapsed * scrollSpeed) % 1;
		gridDirty = true;

		if (gridDirty)
			renderGrid();
	}

	public function setStyle(lineColor:Int, horizonColor:Int, roadColor:Int, lineAlpha:Float, horizonAlpha:Float, roadAlpha:Float):Void
	{
		this.lineColor = lineColor & 0xFFFFFF;
		this.horizonColor = horizonColor & 0xFFFFFF;
		this.roadColor = roadColor & 0xFFFFFF;
		this.lineAlpha = clamp01(lineAlpha);
		this.horizonAlpha = clamp01(horizonAlpha);
		this.roadAlpha = clamp01(roadAlpha);
		gridDirty = true;
	}

	function renderGrid():Void
	{
		if (bitmap == null)
			return;

		gridDirty = false;
		bitmap.fillRect(bitmap.rect, FlxColor.TRANSPARENT);

		var graphics = shape.graphics;
		graphics.clear();

		var bottom = canvasHeight + 4;
		var center = vanishingX;
		graphics.beginFill(roadColor, roadAlpha);
		graphics.moveTo(center - roadFarWidth * 0.5, horizonY);
		graphics.lineTo(center + roadFarWidth * 0.5, horizonY);
		graphics.lineTo(center + roadNearWidth * 0.5, bottom);
		graphics.lineTo(center - roadNearWidth * 0.5, bottom);
		graphics.lineTo(center - roadFarWidth * 0.5, horizonY);
		graphics.endFill();

		graphics.lineStyle(1, lineColor, lineAlpha);
		var spacing = canvasWidth / Math.max(2, verticalLines);
		for (i in -verticalLines...verticalLines + 1)
		{
			var bottomX = center + i * spacing;
			graphics.moveTo(bottomX, bottom);
			graphics.lineTo(center + i * 3, horizonY);
		}

		for (i in 0...horizontalLines)
		{
			var t = (i + scroll) / horizontalLines;
			var eased = t * t;
			var y = horizonY + eased * (bottom - horizonY);
			var fade = Math.min(1, Math.max(0.18, eased * 1.25));
			graphics.lineStyle(1 + eased * 2, lineColor, lineAlpha * fade);
			graphics.moveTo(0, y);
			graphics.lineTo(canvasWidth, y);
		}

		graphics.lineStyle(6, horizonColor, horizonAlpha);
		graphics.moveTo(0, horizonY);
		graphics.lineTo(canvasWidth, horizonY);
		graphics.lineStyle(18, horizonColor, horizonAlpha * 0.22);
		graphics.moveTo(0, horizonY + 2);
		graphics.lineTo(canvasWidth, horizonY + 2);

		bitmap.draw(shape, null, null, null, null, true);
		dirty = true;
	}

	static inline function clamp01(value:Float):Float
		return value < 0 ? 0 : (value > 1 ? 1 : value);
}
