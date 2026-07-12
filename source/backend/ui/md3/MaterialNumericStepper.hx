package backend.ui.md3;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import backend.ui.md3.MD3Theme;
#if mobile
import funkin.mobile.backend.TouchUtil;
#end

/**
 * Material Design 3 Numeric Stepper Component
 * Inspired by: https://m3.material.io/components/text-fields and segmented buttons
 *
 * A compact [−] value [+] control inside an outlined pill container.
 * Supports hold-to-repeat, configurable step / range / decimals.
 */
class MaterialNumericStepper extends FlxSpriteGroup
{
	static inline var TRACE_LAYOUT:Bool = false;

	// -----------------------------------------------------------------------
	// Public API
	// -----------------------------------------------------------------------

	/** Current numeric value. Setting this programmatically does NOT fire onChange. */
	public var value(default, set):Float = 0;

	public var min:Float       = 0;
	public var max:Float       = 100;
	public var step:Float      = 1;
	public var decimals:Int    = 0;
	public var enabled:Bool    = true;
	public var allowMouseInput:Bool = true;

	/** Called with the new value only when the user presses − or +. */
	public var onChange:Float->Void = null;

	// -----------------------------------------------------------------------
	// Dimensions
	// -----------------------------------------------------------------------

	public var stepperWidth:Float = 120;

	inline function controlHeight():Int return MD3Metrics.size(44);
	inline function buttonArea():Int return MD3Metrics.size(42);
	inline function cornerRadius():Int return MD3Metrics.corner(22, stepperWidth, controlHeight());
	inline function valueSize():Int return MD3Metrics.text(15);
	inline function iconSize():Int return MD3Metrics.text(20);
	inline function dividerInset():Int return MD3Metrics.size(9);
	inline function hitHeight():Int return MD3Metrics.touch(controlHeight());

	// -----------------------------------------------------------------------
	// Visual components
	// -----------------------------------------------------------------------

	var background:FlxSprite;
	var decrState:FlxSprite;
	var incrState:FlxSprite;
	var divL:FlxSprite;
	var divR:FlxSprite;
	var decrText:FlxText;
	var incrText:FlxText;
	var valueText:FlxText;

	// -----------------------------------------------------------------------
	// Interaction state
	// -----------------------------------------------------------------------

	var hoverDecr:Bool  = false;
	var hoverIncr:Bool  = false;
	var holdDecr:Bool   = false;
	var holdIncr:Bool   = false;
	var holdTimer:Float = 0;
	var holdElapsd:Float = 0;

	static inline var HOLD_DELAY:Float  = 0.45;
	static inline var HOLD_REPEAT:Float = 1 / 12;

	// -----------------------------------------------------------------------
	// Constructor
	// -----------------------------------------------------------------------

	/**
	 * @param x        Group X position.
	 * @param y        Group Y position.
	 * @param step     Amount to add / subtract on each press.
	 * @param value    Initial value.
	 * @param min      Minimum allowed value (inclusive).
	 * @param max      Maximum allowed value (inclusive).
	 * @param decimals Decimal places shown and used for rounding.
	 * @param width    Total pixel width of the stepper.
	 * @param onChange Callback fired after every user-triggered step.
	 */
	public function new(x:Float = 0, y:Float = 0,
	                    step:Float = 1, value:Float = 0,
	                    min:Float = 0, max:Float = 100, decimals:Int = 0,
	                    width:Float = 120, ?onChange:Float->Void)
	{
		super(x, y);

		this.step      = step;
		this.min       = min;
		this.max       = max;
		this.decimals  = decimals;
		this.onChange  = onChange;
		this.stepperWidth = width;

		var w = Std.int(width);
		var h = controlHeight();
		var area = buttonArea();

		// Outlined background
		background = new FlxSprite(0, 0);
		background.antialiasing = ClientPrefs.data.antialiasing;
		MD3ShapeTools.fillAndStrokeRoundRect(background, w, h, cornerRadius(), 1, MD3Theme.surface, MD3Theme.outline);
		add(background);

		// Decrement state layer (hover / press)
		decrState = new FlxSprite(0, 0);
		decrState.antialiasing = ClientPrefs.data.antialiasing;
		MD3ShapeTools.fillRoundRect(decrState, area, h, cornerRadius());
		decrState.color = MD3Theme.stateLayerColor(MD3Theme.primary);
		decrState.alpha = 0;
		add(decrState);

		// Increment state layer (hover / press)
		incrState = new FlxSprite(w - area, 0);
		incrState.antialiasing = ClientPrefs.data.antialiasing;
		MD3ShapeTools.fillRoundRect(incrState, area, h, cornerRadius());
		incrState.color = MD3Theme.stateLayerColor(MD3Theme.primary);
		incrState.alpha = 0;
		add(incrState);

		// Vertical dividers
		divL = new FlxSprite(area, dividerInset());
		divL.makeGraphic(1, h - dividerInset() * 2, MD3Theme.outlineVariant);
		add(divL);

		divR = new FlxSprite(w - area - 1, dividerInset());
		divR.makeGraphic(1, h - dividerInset() * 2, MD3Theme.outlineVariant);
		add(divR);

		// Decrement glyph
		decrText = new FlxText(0, 0, area, "\u2212", iconSize());
		decrText.setFormat(Paths.font('NotoSans-Medium.ttf'), iconSize(), MD3Theme.primary, CENTER);
		decrText.antialiasing = ClientPrefs.data.antialiasing;
		decrText.y = (h - decrText.height) * 0.5 - 1;
		add(decrText);

		// Increment glyph
		incrText = new FlxText(w - area, 0, area, "+", iconSize());
		incrText.setFormat(Paths.font('NotoSans-Medium.ttf'), iconSize(), MD3Theme.primary, CENTER);
		incrText.antialiasing = ClientPrefs.data.antialiasing;
		incrText.y = (h - incrText.height) * 0.5 - 1;
		add(incrText);

		// Value display
		valueText = new FlxText(area + 2, 0, w - area * 2 - 4, "", valueSize());
		valueText.setFormat(Paths.font('NotoSans-Medium.ttf'), valueSize(), MD3Theme.onSurface, CENTER);
		valueText.antialiasing = ClientPrefs.data.antialiasing;
		valueText.y = (h - valueText.height) * 0.5;
		add(valueText);

		// Assign value after all sprites are ready
		this.value = value;

		MD3Theme.addListener(_onThemeChange);
		_onThemeChange();
		traceLayout('create');
	}

	function traceLayout(reason:String):Void
	{
		if (!TRACE_LAYOUT) return;
	}

	public function getDebugLayout():String
	{
		return 'group=(' + x + ', ' + y + ')'
			+ ' width=' + stepperWidth
			+ ' decrLocal=(' + (decrState.x - x) + ', ' + (decrState.y - y) + ', ' + decrState.width + 'x' + decrState.height + ')'
			+ ' incrLocal=(' + (incrState.x - x) + ', ' + (incrState.y - y) + ', ' + incrState.width + 'x' + incrState.height + ')'
			+ ' valueTextLocal=(' + (valueText.x - x) + ', ' + (valueText.y - y) + ', ' + valueText.width + 'x' + valueText.height + ')'
			+ ' value=' + value;
	}

	// -----------------------------------------------------------------------
	// Value setter — does NOT fire onChange (programmatic use)
	// -----------------------------------------------------------------------

	function set_value(v:Float):Float
	{
		v = FlxMath.bound(v, min, max);
		var factor = Math.pow(10, decimals);
		v = Math.round(v * factor) / factor;
		value = v;
		if (valueText != null)
		{
			valueText.text = decimals > 0
				? Std.string(FlxMath.roundDecimal(v, decimals))
				: Std.string(Std.int(v));
			valueText.y = y + (controlHeight() - valueText.height) * 0.5;
		}
		traceLayout('set_value');
		return value;
	}

	// -----------------------------------------------------------------------
	// Internal step — fires onChange
	// -----------------------------------------------------------------------

	inline function _step(dir:Int):Void
	{
		var prev = value;
		value += dir * step;
		traceLayout('step(' + dir + ')');
		if (value != prev && onChange != null) onChange(value);
	}

	inline function isPointerOver(button:FlxSprite):Bool
	{
		if (button == null || !button.exists || !button.visible)
			return false;

		if (FlxG.mouse.overlaps(button, camera))
			return true;

		#if mobile
		if (TouchUtil.overlaps(button, camera))
			return true;
		#end

		return false;
	}

	inline function isJustPressedOn(button:FlxSprite):Bool
	{
		if (button == null || !button.exists || !button.visible)
			return false;

		if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(button, camera))
			return true;

		#if mobile
		if (TouchUtil.pressAction(button, camera, true))
			return true;
		#end

		return false;
	}

	// -----------------------------------------------------------------------
	// Update — hit-testing, hover, and hold-to-repeat
	// -----------------------------------------------------------------------

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (!enabled) return;
		if (!allowMouseInput)
		{
			hoverDecr = false;
			hoverIncr = false;
			holdDecr = false;
			holdIncr = false;
			decrState.alpha = 0;
			incrState.alpha = 0;
			return;
		}

		var overDecr = isPointerOver(decrState);
		var overIncr = isPointerOver(incrState);

		// Hover effect
		if (overDecr != hoverDecr)
		{
			hoverDecr = overDecr;
			FlxTween.cancelTweensOf(decrState);
			FlxTween.tween(decrState, {alpha: hoverDecr ? 0.10 : 0}, 0.1, {ease: FlxEase.sineOut});
		}
		if (overIncr != hoverIncr)
		{
			hoverIncr = overIncr;
			FlxTween.cancelTweensOf(incrState);
			FlxTween.tween(incrState, {alpha: hoverIncr ? 0.10 : 0}, 0.1, {ease: FlxEase.sineOut});
		}

		// Initial click
		if (isJustPressedOn(decrState))
		{
			_step(-1);
			holdDecr = true;
			holdIncr = false;
			holdTimer = 0;
			holdElapsd = 0;
		}
		else if (isJustPressedOn(incrState))
		{
			_step(1);
			holdIncr = true;
			holdDecr = false;
			holdTimer = 0;
			holdElapsd = 0;
		}

		var pointerReleased = FlxG.mouse.justReleased
			#if mobile
			|| TouchUtil.justReleased
			#end
		;
		var pointerPressed = FlxG.mouse.pressed
			#if mobile
			|| TouchUtil.pressed
			#end
		;
		if (pointerReleased || ((holdDecr || holdIncr) && !pointerPressed))
			holdDecr = holdIncr = false;

		// Hold-to-repeat
		if (holdDecr || holdIncr)
		{
			holdTimer += elapsed;
			if (holdTimer >= HOLD_DELAY)
			{
				holdElapsd += elapsed;
				while (holdElapsd >= HOLD_REPEAT)
				{
					_step(holdDecr ? -1 : 1);
					holdElapsd -= HOLD_REPEAT;
				}
			}
		}
	}

	// -----------------------------------------------------------------------
	// Theme listener
	// -----------------------------------------------------------------------

	function _onThemeChange():Void
	{
		if (background != null)
		{
			MD3ShapeTools.fillAndStrokeRoundRect(background, Std.int(stepperWidth), controlHeight(), cornerRadius(), 1, MD3Theme.surface, MD3Theme.outline);
		}
		if (decrText  != null) decrText.color  = MD3Theme.primary;
		if (incrText  != null) incrText.color  = MD3Theme.primary;
		if (valueText != null) valueText.color = MD3Theme.onSurface;
		if (decrState != null) decrState.color = MD3Theme.stateLayerColor(MD3Theme.primary);
		if (incrState != null) incrState.color = MD3Theme.stateLayerColor(MD3Theme.primary);
		if (divL != null) divL.color = MD3Theme.outlineVariant;
		if (divR != null) divR.color = MD3Theme.outlineVariant;
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(_onThemeChange);
		super.destroy();
	}

}
