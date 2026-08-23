package objects;

import lime.app.Future;
import openfl.Assets;
import openfl.display.BitmapData;

/**
 * Global cursor system shared by Plus/Psych and the VSlice runtime.
 * Based on the official Funkin' cursor set, using assets/images/cursor.
 */
class Cursor
{
	public static var cursorMode(default, set):Null<CursorMode> = null;

	public static inline function show():Void
	{
		FlxG.mouse.visible = true;
		Cursor.cursorMode = Default;
	}

	public static inline function hide():Void
	{
		FlxG.mouse.visible = false;
		Cursor.cursorMode = null;
	}

	public static inline function toggle():Void
	{
		if (FlxG.mouse.visible)
			hide();
		else
			show();
	}

	public static final CURSOR_DEFAULT_PARAMS:CursorParams = {
		graphic: cursorGraphic("cursor-default"),
		scale: 1.0,
		offsetX: 0,
		offsetY: 0,
	};
	static var assetCursorDefault:Null<BitmapData> = null;

	public static final CURSOR_CROSS_PARAMS:CursorParams = {
		graphic: cursorGraphic("cursor-cross"),
		scale: 1.0,
		offsetX: 0,
		offsetY: 0,
	};
	static var assetCursorCross:Null<BitmapData> = null;

	public static final CURSOR_ERASER_PARAMS:CursorParams = {
		graphic: cursorGraphic("cursor-eraser"),
		scale: 1.0,
		offsetX: 0,
		offsetY: 0,
	};
	static var assetCursorEraser:Null<BitmapData> = null;

	public static final CURSOR_POINTER_PARAMS:CursorParams = {
		graphic: cursorGraphic("cursor-pointer"),
		scale: 1.0,
		offsetX: -8,
		offsetY: 0,
	};
	static var assetCursorPointer:Null<BitmapData> = null;

	public static final CURSOR_GRABBING_PARAMS:CursorParams = {
		graphic: cursorGraphic("cursor-grabbing"),
		scale: 1.0,
		offsetX: -8,
		offsetY: 0,
	};
	static var assetCursorGrabbing:Null<BitmapData> = null;

	public static final CURSOR_HOURGLASS_PARAMS:CursorParams = {
		graphic: cursorGraphic("cursor-hourglass"),
		scale: 1.0,
		offsetX: 0,
		offsetY: 0,
	};
	static var assetCursorHourglass:Null<BitmapData> = null;

	public static final CURSOR_TEXT_PARAMS:CursorParams = {
		graphic: cursorGraphic("cursor-text"),
		scale: 0.2,
		offsetX: 0,
		offsetY: 0,
	};
	static var assetCursorText:Null<BitmapData> = null;

	public static final CURSOR_TEXT_VERTICAL_PARAMS:CursorParams = {
		graphic: cursorGraphic("cursor-text-vertical"),
		scale: 0.2,
		offsetX: 0,
		offsetY: 0,
	};
	static var assetCursorTextVertical:Null<BitmapData> = null;

	public static final CURSOR_ZOOM_IN_PARAMS:CursorParams = {
		graphic: cursorGraphic("cursor-zoom-in"),
		scale: 1.0,
		offsetX: 0,
		offsetY: 0,
	};
	static var assetCursorZoomIn:Null<BitmapData> = null;

	public static final CURSOR_ZOOM_OUT_PARAMS:CursorParams = {
		graphic: cursorGraphic("cursor-zoom-out"),
		scale: 1.0,
		offsetX: 0,
		offsetY: 0,
	};
	static var assetCursorZoomOut:Null<BitmapData> = null;

	public static final CURSOR_CROSSHAIR_PARAMS:CursorParams = {
		graphic: cursorGraphic("cursor-crosshair"),
		scale: 1.0,
		offsetX: -16,
		offsetY: -16,
	};
	static var assetCursorCrosshair:Null<BitmapData> = null;

	public static final CURSOR_CELL_PARAMS:CursorParams = {
		graphic: cursorGraphic("cursor-cell"),
		scale: 1.0,
		offsetX: -16,
		offsetY: -16,
	};
	static var assetCursorCell:Null<BitmapData> = null;

	public static final CURSOR_SCROLL_PARAMS:CursorParams = {
		graphic: cursorGraphic("cursor-scroll"),
		scale: 0.2,
		offsetX: -15,
		offsetY: -15,
	};
	static var assetCursorScroll:Null<BitmapData> = null;

	static function cursorGraphic(name:String):String
	{
		return 'assets/images/cursor/$name.png';
	}

	static function set_cursorMode(value:Null<CursorMode>):Null<CursorMode>
	{
		if (cursorMode == value)
			return cursorMode;

		cursorMode = value;
		loadCursorGraphicSync(cursorMode);
		return cursorMode;
	}

	static function loadCursorGraphicSync(?value:CursorMode = null):Void
	{
		applyCursorParams(value);
	}

	static function loadCursorGraphic(?value:CursorMode = null):Void
	{
		applyCursorParams(value, true);
	}

	static function applyCursorParams(mode:Null<CursorMode>, async:Bool = false):Void
	{
		if (mode == null)
		{
			FlxG.mouse.unload();
			return;
		}

		var data = switch (mode)
		{
			case Default: {cache: assetCursorDefault, params: CURSOR_DEFAULT_PARAMS, set: (bmp) -> assetCursorDefault = bmp};
			case Cross: {cache: assetCursorCross, params: CURSOR_CROSS_PARAMS, set: (bmp) -> assetCursorCross = bmp};
			case Eraser: {cache: assetCursorEraser, params: CURSOR_ERASER_PARAMS, set: (bmp) -> assetCursorEraser = bmp};
			case Pointer: {cache: assetCursorPointer, params: CURSOR_POINTER_PARAMS, set: (bmp) -> assetCursorPointer = bmp};
			case Grabbing: {cache: assetCursorGrabbing, params: CURSOR_GRABBING_PARAMS, set: (bmp) -> assetCursorGrabbing = bmp};
			case Hourglass: {cache: assetCursorHourglass, params: CURSOR_HOURGLASS_PARAMS, set: (bmp) -> assetCursorHourglass = bmp};
			case Text: {cache: assetCursorText, params: CURSOR_TEXT_PARAMS, set: (bmp) -> assetCursorText = bmp};
			case TextVertical: {cache: assetCursorTextVertical, params: CURSOR_TEXT_VERTICAL_PARAMS, set: (bmp) -> assetCursorTextVertical = bmp};
			case ZoomIn: {cache: assetCursorZoomIn, params: CURSOR_ZOOM_IN_PARAMS, set: (bmp) -> assetCursorZoomIn = bmp};
			case ZoomOut: {cache: assetCursorZoomOut, params: CURSOR_ZOOM_OUT_PARAMS, set: (bmp) -> assetCursorZoomOut = bmp};
			case Crosshair: {cache: assetCursorCrosshair, params: CURSOR_CROSSHAIR_PARAMS, set: (bmp) -> assetCursorCrosshair = bmp};
			case Cell: {cache: assetCursorCell, params: CURSOR_CELL_PARAMS, set: (bmp) -> assetCursorCell = bmp};
			case Scroll: {cache: assetCursorScroll, params: CURSOR_SCROLL_PARAMS, set: (bmp) -> assetCursorScroll = bmp};
			default: null;
		}

		if (data == null)
		{
			FlxG.mouse.unload();
			return;
		}

		if (data.cache != null)
		{
			applyGraphic(data.cache, data.params);
			return;
		}

		if (!Assets.exists(data.params.graphic))
		{
			onCursorError(mode, 'Missing asset: ${data.params.graphic}');
			FlxG.mouse.unload();
			return;
		}

		if (async)
		{
			var future:Future<BitmapData> = Assets.loadBitmapData(data.params.graphic);
			future.onComplete((bitmapData:BitmapData) ->
			{
				data.set(bitmapData);
				applyGraphic(bitmapData, data.params);
			});
			future.onError(onCursorError.bind(mode));
		}
		else
		{
			var bitmapData:BitmapData = Assets.getBitmapData(data.params.graphic);
			data.set(bitmapData);
			applyGraphic(bitmapData, data.params);
		}
	}

	static inline function applyGraphic(graphic:BitmapData, params:CursorParams):Void
	{
		FlxG.mouse.load(graphic, params.scale, params.offsetX, params.offsetY);
	}

	static function onCursorError(cursorMode:CursorMode, error:String):Void
	{
		trace("Failed to load cursor graphic for cursor mode " + cursorMode + ": " + error);
	}

	public static function clearCache():Void
	{
		assetCursorDefault = null;
		assetCursorCross = null;
		assetCursorEraser = null;
		assetCursorPointer = null;
		assetCursorGrabbing = null;
		assetCursorHourglass = null;
		assetCursorText = null;
		assetCursorTextVertical = null;
		assetCursorZoomIn = null;
		assetCursorZoomOut = null;
		assetCursorCrosshair = null;
		assetCursorCell = null;
		assetCursorScroll = null;
	}
}

enum CursorMode
{
	Default;
	Cross;
	Eraser;
	Pointer;
	Grabbing;
	Hourglass;
	Text;
	TextVertical;
	ZoomIn;
	ZoomOut;
	Crosshair;
	Cell;
	Scroll;
}

typedef CursorParams =
{
	graphic:String,
	scale:Float,
	offsetX:Int,
	offsetY:Int,
}
