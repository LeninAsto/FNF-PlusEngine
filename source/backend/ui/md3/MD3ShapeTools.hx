package backend.ui.md3;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import haxe.ds.ObjectMap;
import openfl.display.Shape;

class MD3ShapeTools
{
	static var _spriteCacheKeys:ObjectMap<FlxSprite, String> = new ObjectMap<FlxSprite, String>();
	static var _sharedShape:Shape;

	inline static function rgb(color:FlxColor):Int
	{
		return color & 0xFFFFFF;
	}

	inline static function alpha(color:FlxColor):Float
	{
		return ((color >> 24) & 0xFF) / 255;
	}

	inline static function f(value:Float):String
	{
		return Std.string(Math.round(value * 1000) / 1000);
	}

	inline static function getCachedKey(sprite:FlxSprite):String
	{
		return _spriteCacheKeys.get(sprite);
	}

	inline static function setCachedKey(sprite:FlxSprite, key:String):Void
	{
		_spriteCacheKeys.set(sprite, key);
	}

	static function getSharedShape():Shape
	{
		if (_sharedShape == null)
			_sharedShape = new Shape();
		_sharedShape.graphics.clear();
		return _sharedShape;
	}

	static function render(sprite:FlxSprite, width:Int, height:Int, cacheKey:String, drawShape:Shape->Void):Void
	{
		var sizeChanged = sprite.pixels == null || sprite.frameWidth != width || sprite.frameHeight != height;
		if (!sizeChanged && getCachedKey(sprite) == cacheKey)
			return;

		if (sizeChanged)
			sprite.makeGraphic(width, height, FlxColor.TRANSPARENT, true);
		else
			sprite.pixels.fillRect(sprite.pixels.rect, FlxColor.TRANSPARENT);

		var shape = getSharedShape();
		drawShape(shape);
		sprite.pixels.draw(shape, null, null, null, null, true);
		setCachedKey(sprite, cacheKey);
		sprite.dirty = true;
		if (sizeChanged)
			sprite.updateHitbox();
	}

	public static function fillRoundRect(sprite:FlxSprite, width:Int, height:Int, radius:Float, ?fillColor:FlxColor = 0xFFFFFFFF):Void
	{
		var key = 'fillRoundRect|' + width + '|' + height + '|' + f(radius) + '|' + fillColor;
		render(sprite, width, height, key, function(shape:Shape)
		{
			shape.graphics.beginFill(rgb(fillColor), alpha(fillColor));
			shape.graphics.drawRoundRect(0, 0, width, height, radius * 2, radius * 2);
			shape.graphics.endFill();
		});
	}

	public static function fillRoundRectComplex(sprite:FlxSprite, width:Int, height:Int,
		topLeft:Float, topRight:Float, bottomLeft:Float, bottomRight:Float,
		?fillColor:FlxColor = 0xFFFFFFFF):Void
	{
		var key = 'fillRoundRectComplex|' + width + '|' + height + '|' + f(topLeft) + '|' + f(topRight) + '|'
			+ f(bottomLeft) + '|' + f(bottomRight) + '|' + fillColor;
		render(sprite, width, height, key, function(shape:Shape)
		{
			shape.graphics.beginFill(rgb(fillColor), alpha(fillColor));
			shape.graphics.drawRoundRectComplex(0, 0, width, height, topLeft, topRight, bottomLeft, bottomRight);
			shape.graphics.endFill();
		});
	}

	public static function strokeRoundRect(sprite:FlxSprite, width:Int, height:Int, radius:Float,
		thickness:Float = 1, ?strokeColor:FlxColor = 0xFFFFFFFF):Void
	{
		var key = 'strokeRoundRect|' + width + '|' + height + '|' + f(radius) + '|' + f(thickness) + '|' + strokeColor;
		render(sprite, width, height, key, function(shape:Shape)
		{
			var inset = thickness * 0.5;
			shape.graphics.lineStyle(thickness, rgb(strokeColor), alpha(strokeColor));
			shape.graphics.drawRoundRect(inset, inset, Math.max(0, width - thickness), Math.max(0, height - thickness),
				Math.max(0, radius * 2 - thickness), Math.max(0, radius * 2 - thickness));
		});
	}

	public static function fillAndStrokeRoundRect(sprite:FlxSprite, width:Int, height:Int, radius:Float,
		thickness:Float, fillColor:FlxColor, strokeColor:FlxColor):Void
	{
		var key = 'fillAndStrokeRoundRect|' + width + '|' + height + '|' + f(radius) + '|' + f(thickness) + '|'
			+ fillColor + '|' + strokeColor;
		render(sprite, width, height, key, function(shape:Shape)
		{
			var inset = thickness * 0.5;
			shape.graphics.lineStyle(thickness, rgb(strokeColor), alpha(strokeColor));
			shape.graphics.beginFill(rgb(fillColor), alpha(fillColor));
			shape.graphics.drawRoundRect(inset, inset, Math.max(0, width - thickness), Math.max(0, height - thickness),
				Math.max(0, radius * 2 - thickness), Math.max(0, radius * 2 - thickness));
			shape.graphics.endFill();
		});
	}

	public static function fillCircle(sprite:FlxSprite, size:Int, ?fillColor:FlxColor = 0xFFFFFFFF):Void
	{
		var key = 'fillCircle|' + size + '|' + fillColor;
		render(sprite, size, size, key, function(shape:Shape)
		{
			var radius = size / 2;
			shape.graphics.beginFill(rgb(fillColor), alpha(fillColor));
			shape.graphics.drawCircle(radius, radius, radius);
			shape.graphics.endFill();
		});
	}

	public static function strokeCircle(sprite:FlxSprite, size:Int, thickness:Float = 1,
		?strokeColor:FlxColor = 0xFFFFFFFF):Void
	{
		var key = 'strokeCircle|' + size + '|' + f(thickness) + '|' + strokeColor;
		render(sprite, size, size, key, function(shape:Shape)
		{
			var radius = size / 2;
			shape.graphics.lineStyle(thickness, rgb(strokeColor), alpha(strokeColor));
			shape.graphics.drawCircle(radius, radius, Math.max(0, radius - thickness * 0.5));
		});
	}
}