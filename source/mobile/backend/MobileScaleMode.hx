package mobile.backend;

import flixel.system.scaleModes.BaseScaleMode;

/**
 * @author Karim Akra, adapted for Plus Engine
 */
class MobileScaleMode extends BaseScaleMode
{
	public static var allowInfinityDisplay(default, set):Bool = true;

	// Base game resolution — the canonical 16:9 safe area used by mods.
	public static final BASE_GAME_WIDTH:Int = 1280;
	public static final BASE_GAME_HEIGHT:Int = 720;

	// Maximum aspect ratio before black bars reappear (20:9).
	static inline final MAX_RATIO_W:Float = 20;
	static inline final MAX_RATIO_H:Float = 9;

	// Logical game dimensions after the last onMeasure, used by the helpers.
	static var currentGameWidth:Int = BASE_GAME_WIDTH;
	static var currentGameHeight:Int = BASE_GAME_HEIGHT;

	/** Returns the original 16:9 safe area width (always 1280). */
	public static inline function getSafeWidth():Float
		return BASE_GAME_WIDTH;

	/** Returns the original 16:9 safe area height (always 720). */
	public static inline function getSafeHeight():Float
		return BASE_GAME_HEIGHT;

	/** Returns the full logical game width after expansion. */
	public static inline function getScreenWidth():Float
		return currentGameWidth;

	/** Returns the full logical game height after expansion. */
	public static inline function getScreenHeight():Float
		return currentGameHeight;

	/**
	 * Returns the X offset (in game pixels) from the left screen edge to the
	 * start of the original 16:9 safe area.
	 * Add this to positions that should sit inside the centered 1280-wide zone.
	 */
	public static inline function getHorizontalOffset():Float
		return (currentGameWidth - BASE_GAME_WIDTH) / 2;

	/**
	 * Returns the Y offset (in game pixels) from the top screen edge to the
	 * start of the original 16:9 safe area.
	 * Add this to positions that should sit inside the centered 720-tall zone.
	 */
	public static inline function getVerticalOffset():Float
		return (currentGameHeight - BASE_GAME_HEIGHT) / 2;

	override public function onMeasure(Width:Int, Height:Int):Void
	{
		// BaseScaleMode.onMeasure already resets FlxG.width/height to
		// initialWidth/initialHeight before calling updateGameSize, so our
		// override just needs to snapshot the result afterwards.
		super.onMeasure(Width, Height);

		currentGameWidth = FlxG.width;
		currentGameHeight = FlxG.height;
	}

	override function updateGameSize(Width:Int, Height:Int):Void
	{
		if (ClientPrefs.data.infinityDisplay && allowInfinityDisplay)
		{
			var physRatio:Float = Width / Height;
			var baseRatio:Float = BASE_GAME_WIDTH / BASE_GAME_HEIGHT; // 16:9 ≈ 1.777
			var maxRatio:Float = MAX_RATIO_W / MAX_RATIO_H;           // 20:9 ≈ 2.222

			if (physRatio >= baseRatio)
			{
				// Screen wider than 16:9 (most modern landscape phones).
				// Scale by height, expand game width up to the max ratio cap.
				var clampedRatio:Float = Math.min(physRatio, maxRatio);
				gameSize.y = Height;
				gameSize.x = Math.floor(gameSize.y * clampedRatio);
				// Expand the logical width so the world is wider, not stretched.
				untyped FlxG.width = Math.floor(BASE_GAME_HEIGHT * clampedRatio);
			}
			else
			{
				// Screen taller than 16:9 (tablets, unusual orientations).
				// Scale by width, expand game height.
				gameSize.x = Width;
				gameSize.y = Height;
				untyped FlxG.height = Math.floor(BASE_GAME_WIDTH / physRatio);
			}
		}
		else
		{
			// Standard 16:9 locked mode — black bars on wider / taller screens.
			var ratio:Float = BASE_GAME_WIDTH / BASE_GAME_HEIGHT;
			var realRatio:Float = Width / Height;

			if (realRatio < ratio)
			{
				gameSize.x = Width;
				gameSize.y = Math.floor(gameSize.x / ratio);
			}
			else
			{
				gameSize.y = Height;
				gameSize.x = Math.floor(gameSize.y * ratio);
			}
		}
	}

	override function updateGamePosition():Void
	{
		super.updateGamePosition();
	}

	@:noCompletion
	private static function set_allowInfinityDisplay(value:Bool):Bool
	{
		if (allowInfinityDisplay == value)
			return value;

		allowInfinityDisplay = value;

		if (Std.isOfType(FlxG.scaleMode, MobileScaleMode) && FlxG.stage != null)
			cast(FlxG.scaleMode, MobileScaleMode).onMeasure(FlxG.stage.stageWidth, FlxG.stage.stageHeight);

		return value;
	}
}
