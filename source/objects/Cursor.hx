package objects;

import lime.app.Future;
import openfl.display.BitmapData;
import openfl.Assets;

/**
 * Advanced cursor system for custom mouse cursors.
 * Based on the official Funkin' repository implementation.
 */
class Cursor
{
	/**
	 * The current cursor mode.
	 * Set this value to change the cursor graphic.
	 */
	public static var cursorMode(default, set):Null<CursorMode> = null;

	/**
	 * Show the cursor.
	 */
	public static inline function show():Void
	{
		FlxG.mouse.visible = true;
		// Reset the cursor mode
		Cursor.cursorMode = Default;
	}

	/**
	 * Hide the cursor.
	 */
	public static inline function hide():Void
	{
		FlxG.mouse.visible = false;
		// Reset the cursor mode
		Cursor.cursorMode = null;
	}

	/**
	 * Toggle cursor visibility.
	 */
	public static inline function toggle():Void
	{
		if (FlxG.mouse.visible)
		{
			hide();
		}
		else
		{
			show();
		}
	}

	// Cursor parameters for each mode
	public static final CURSOR_DEFAULT_PARAMS:CursorParams = {
		graphic: "assets/shared/images/ui/cursor.png",
		scale: 0.8,
		offsetX: -5,
		offsetY: -10,
	};
	static var assetCursorDefault:Null<BitmapData> = null;

	public static final CURSOR_POINTER_PARAMS:CursorParams = {
		graphic: "assets/shared/images/ui/cursor.png",
		scale: 0.8,
		offsetX: -13,
		offsetY: -10,
	};
	static var assetCursorPointer:Null<BitmapData> = null;

	public static final CURSOR_GRABBING_PARAMS:CursorParams = {
		graphic: "assets/shared/images/ui/cursor.png",
		scale: 0.8,
		offsetX: -13,
		offsetY: -10,
	};
	static var assetCursorGrabbing:Null<BitmapData> = null;

	public static final CURSOR_TEXT_PARAMS:CursorParams = {
		graphic: "assets/shared/images/ui/beam.png",
		scale: 0.8,
		offsetX: -1,
		offsetY: -6,
	};
	static var assetCursorText:Null<BitmapData> = null;

	static function set_cursorMode(value:Null<CursorMode>):Null<CursorMode>
	{
		if (value != null && cursorMode != value)
		{
			cursorMode = value;
			setCursorGraphic(cursorMode);
		}
		return cursorMode;
	}

	/**
	 * Synchronous cursor loading.
	 */
	static function setCursorGraphic(?value:CursorMode = null):Void
	{
		if (value == null)
		{
			FlxG.mouse.unload();
			return;
		}

		switch (value)
		{
			case Default:
				if (assetCursorDefault == null)
				{
					var bitmapData:BitmapData = Assets.getBitmapData(CURSOR_DEFAULT_PARAMS.graphic);
					assetCursorDefault = bitmapData;
					applyCursorParams(assetCursorDefault, CURSOR_DEFAULT_PARAMS);
				}
				else
				{
					applyCursorParams(assetCursorDefault, CURSOR_DEFAULT_PARAMS);
				}

			case Pointer:
				if (assetCursorPointer == null)
				{
					var bitmapData:BitmapData = Assets.getBitmapData(CURSOR_POINTER_PARAMS.graphic);
					assetCursorPointer = bitmapData;
					applyCursorParams(assetCursorPointer, CURSOR_POINTER_PARAMS);
				}
				else
				{
					applyCursorParams(assetCursorPointer, CURSOR_POINTER_PARAMS);
				}

			case Grabbing:
				if (assetCursorGrabbing == null)
				{
					var bitmapData:BitmapData = Assets.getBitmapData(CURSOR_GRABBING_PARAMS.graphic);
					assetCursorGrabbing = bitmapData;
					applyCursorParams(assetCursorGrabbing, CURSOR_GRABBING_PARAMS);
				}
				else
				{
					applyCursorParams(assetCursorGrabbing, CURSOR_GRABBING_PARAMS);
				}

			case Text:
				if (assetCursorText == null)
				{
					var bitmapData:BitmapData = Assets.getBitmapData(CURSOR_TEXT_PARAMS.graphic);
					assetCursorText = bitmapData;
					applyCursorParams(assetCursorText, CURSOR_TEXT_PARAMS);
				}
				else
				{
					applyCursorParams(assetCursorText, CURSOR_TEXT_PARAMS);
				}

			default:
				FlxG.mouse.unload();
		}
	}

	/**
	 * Asynchronous cursor loading.
	 */
	static function loadCursorGraphic(?value:CursorMode = null):Void
	{
		if (value == null)
		{
			FlxG.mouse.unload();
			return;
		}

		switch (value)
		{
			case Default:
				if (assetCursorDefault == null)
				{
					var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_DEFAULT_PARAMS.graphic);
					future.onComplete(function(bitmapData:BitmapData)
					{
						assetCursorDefault = bitmapData;
						applyCursorParams(assetCursorDefault, CURSOR_DEFAULT_PARAMS);
					});
					future.onError(onCursorError.bind(Default));
				}
				else
				{
					applyCursorParams(assetCursorDefault, CURSOR_DEFAULT_PARAMS);
				}

			case Pointer:
				if (assetCursorPointer == null)
				{
					var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_POINTER_PARAMS.graphic);
					future.onComplete(function(bitmapData:BitmapData)
					{
						assetCursorPointer = bitmapData;
						applyCursorParams(assetCursorPointer, CURSOR_POINTER_PARAMS);
					});
					future.onError(onCursorError.bind(Pointer));
				}
				else
				{
					applyCursorParams(assetCursorPointer, CURSOR_POINTER_PARAMS);
				}

			case Grabbing:
				if (assetCursorGrabbing == null)
				{
					var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_GRABBING_PARAMS.graphic);
					future.onComplete(function(bitmapData:BitmapData)
					{
						assetCursorGrabbing = bitmapData;
						applyCursorParams(assetCursorGrabbing, CURSOR_GRABBING_PARAMS);
					});
					future.onError(onCursorError.bind(Grabbing));
				}
				else
				{
					applyCursorParams(assetCursorGrabbing, CURSOR_GRABBING_PARAMS);
				}

			case Text:
				if (assetCursorText == null)
				{
					var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_TEXT_PARAMS.graphic);
					future.onComplete(function(bitmapData:BitmapData)
					{
						assetCursorText = bitmapData;
						applyCursorParams(assetCursorText, CURSOR_TEXT_PARAMS);
					});
					future.onError(onCursorError.bind(Text));
				}
				else
				{
					applyCursorParams(assetCursorText, CURSOR_TEXT_PARAMS);
				}

			default:
				FlxG.mouse.unload();
		}
	}

	static inline function applyCursorParams(graphic:BitmapData, params:CursorParams):Void
	{
		FlxG.mouse.load(graphic, params.scale, params.offsetX, params.offsetY);
	}

	static function onCursorError(cursorMode:CursorMode, error:String):Void
	{
		trace("Failed to load cursor graphic for cursor mode " + cursorMode + ": " + error);
	}

	/**
	 * Clear all cached cursor graphics from memory.
	 */
	public static function clearCache():Void
	{
		assetCursorDefault = null;
		assetCursorPointer = null;
		assetCursorGrabbing = null;
		assetCursorText = null;
	}
}

/**
 * Available cursor modes.
 * Add more modes as needed for your game.
 */
enum CursorMode
{
	Default;
	Pointer;
	Grabbing;
	Text;
}

/**
 * Static data describing how a cursor should be rendered.
 */
typedef CursorParams =
{
	graphic:String,
	scale:Float,
	offsetX:Int,
	offsetY:Int,
}
