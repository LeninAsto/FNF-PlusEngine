package backend.ui.md3;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import openfl.display.Shape;

/**
 * Material Design 3 Loading Indicator
 * Based on: https://m3.material.io/components/loading-indicator/guidelines
 *
 * A solid shape that morphs through the 7 M3 shape keyframes while gently
 * rotating.  Designed for short indeterminate waits (200 ms – 5 s).
 *
 * For longer or detectable-progress waits, use MaterialProgressIndicator instead.
 *
 * Usage:
 *   var indicator = new MaterialLoadingIndicator(x, y);          // default 48 px
 *   var big       = new MaterialLoadingIndicator(x, y, 64);      // custom size
 *   var onSurface = new MaterialLoadingIndicator(x, y, 48, true); // with container bg
 */
class MaterialLoadingIndicator extends FlxSpriteGroup
{
	/** Side length of the indicator in pixels (24–240). Default 48. */
	public var indicatorSize(default, null):Int;

	/** When true, a circular container is rendered behind the indicator. */
	public var showContainer(default, null):Bool;

	var _container:FlxSprite;
	var _indicator:FlxSprite;

	// Animation state
	var _spinTravel:Float = 0;
	var _spinAngle:Float = 0;
	var _shapeIndex:Int = 0;
	var _lastTurn:Int = -1;
	var _lastLobes:Float = -1;
	var _lastAmplitude:Float = -1;
	var _lastSecondary:Float = -1;
	var _lastSoftness:Float = -1;
	var _lastPhase:Float = -1;

	// Circular shape family. Each turn advances to the next preset.
	// The sequence now mixes rounded blobs, ovals, and triangular silhouettes.
	static var LOBES:Array<Int> =       [0, 4, 6, 7, 3, 5, 8, 3];
	static var AMPLITUDES:Array<Float> = [0.00, 0.16, 0.12, 0.10, 0.08, 0.12, 0.14, 0.09];
	static var SECONDARY:Array<Float> =  [0.00, 0.02, 0.03, 0.02, 0.01, 0.03, 0.04, 0.01];
	static var SOFTNESS:Array<Float> =   [1.00, 0.94, 0.96, 0.97, 0.98, 0.92, 0.90, 0.99];
	static var PHASE_OFF:Array<Float> =  [0.00, 0.78, 0.35, 0.18, 0.00, 0.64, 0.30, 0.00];
	static var SCALE_X:Array<Float> =    [1.00, 1.00, 1.18, 0.96, 1.00, 1.22, 0.92, 1.00];
	static var SCALE_Y:Array<Float> =    [1.00, 1.00, 0.78, 1.08, 1.00, 0.74, 1.14, 1.00];
	static var TRIANGLE_MIX:Array<Float> = [0.00, 0.10, 0.00, 0.14, 0.78, 0.00, 0.22, 0.60];

	static inline var SPIN_SPEED:Float = 248.0;
	static inline var SHAPE_MORPH_PORTION:Float = 0.36;
	static inline var TAU:Float = 6.283185307179586;

	public function new(x:Float = 0, y:Float = 0, size:Int = 48, showContainer:Bool = false)
	{
		super(x, y);

		this.indicatorSize  = size;
		this.showContainer  = showContainer;

		if (showContainer)
		{
			// Container: circle ~1.67× the indicator, centred behind it
			var cs:Int     = Std.int(size * 1.667);
			var offset:Int = Std.int((cs - size) / 2);
			_container = new FlxSprite(-offset, -offset);
			_container.makeGraphic(cs, cs, FlxColor.TRANSPARENT, true);
			_drawFilledCircle(_container, cs, MD3Theme.primaryContainer);
			add(_container);
		}

		_indicator = new FlxSprite(0, 0);
		_indicator.makeGraphic(size, size, FlxColor.TRANSPARENT, true);
		_redrawShape(LOBES[0], AMPLITUDES[0], SECONDARY[0], SOFTNESS[0], PHASE_OFF[0], SCALE_X[0], SCALE_Y[0], TRIANGLE_MIX[0]);
		add(_indicator);
		MD3Theme.addListener(_onThemeChange);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		_spinTravel += elapsed * SPIN_SPEED;
		_spinAngle = _spinTravel % 360;

		var turn:Int = Std.int(_spinTravel / 360);
		if (turn != _lastTurn)
		{
			_lastTurn = turn;
			_shapeIndex = turn % LOBES.length;
		}

		var previousIndex = ((_shapeIndex - 1) + LOBES.length) % LOBES.length;
		var turnT:Float = (_spinTravel % 360) / 360;
		var morphT:Float = turnT <= SHAPE_MORPH_PORTION ? _smoothstep(turnT / SHAPE_MORPH_PORTION) : 1.0;

		var lobes = _lerp(LOBES[previousIndex], LOBES[_shapeIndex], morphT);
		var amplitude = _lerp(AMPLITUDES[previousIndex], AMPLITUDES[_shapeIndex], morphT);
		var secondary = _lerp(SECONDARY[previousIndex], SECONDARY[_shapeIndex], morphT);
		var softness = _lerp(SOFTNESS[previousIndex], SOFTNESS[_shapeIndex], morphT);
		var phaseOffset = _lerp(PHASE_OFF[previousIndex], PHASE_OFF[_shapeIndex], morphT);
		var scaleX = _lerp(SCALE_X[previousIndex], SCALE_X[_shapeIndex], morphT);
		var scaleY = _lerp(SCALE_Y[previousIndex], SCALE_Y[_shapeIndex], morphT);
		var triangleMix = _lerp(TRIANGLE_MIX[previousIndex], TRIANGLE_MIX[_shapeIndex], morphT);

		if (Math.abs(lobes - _lastLobes) > 0.02
			|| Math.abs(amplitude - _lastAmplitude) > 0.01
			|| Math.abs(secondary - _lastSecondary) > 0.01
			|| Math.abs(softness - _lastSoftness) > 0.01
			|| Math.abs(phaseOffset - _lastPhase) > 0.01)
		{
			_lastLobes = lobes;
			_lastAmplitude = amplitude;
			_lastSecondary = secondary;
			_lastSoftness = softness;
			_lastPhase = phaseOffset;
			_redrawShape(lobes, amplitude, secondary, softness, phaseOffset, scaleX, scaleY, triangleMix);
		}

		_indicator.angle = _spinAngle;
	}

	// -----------------------------------------------------------------------
	// Private helpers
	// -----------------------------------------------------------------------

	function _redrawShape(lobes:Float, amplitude:Float, secondary:Float, softness:Float, phaseOffset:Float, scaleX:Float, scaleY:Float, triangleMix:Float):Void
	{
		var frame:Int = indicatorSize;
		var center = frame * 0.5;
		var baseRadius = frame * 0.29;
		var col:FlxColor = showContainer ? MD3Theme.onPrimaryContainer : MD3Theme.primary;

		_indicator.makeGraphic(frame, frame, FlxColor.TRANSPARENT, true);
		var shape = new Shape();
		shape.graphics.beginFill(col & 0xFFFFFF, ((col >> 24) & 0xFF) / 255);

		var steps = 96;
		for (i in 0...steps + 1)
		{
			var t = i / steps;
			var angle = t * TAU;
			var primaryWave = lobes <= 0.01 ? 0.0 : Math.sin(angle * lobes + phaseOffset);
			var secondaryWave = lobes <= 0.01 ? 0.0 : Math.sin(angle * lobes * 0.5 + phaseOffset * 1.7);
			var normalizedPrimary = primaryWave >= 0 ? Math.pow(primaryWave, softness) : -Math.pow(-primaryWave, softness);
			var organicRadius = baseRadius * (1.0 + normalizedPrimary * amplitude + secondaryWave * secondary);
			var triangleRadius = _triangleRadius(angle, baseRadius * 1.08);
			var radius = organicRadius * (1.0 - triangleMix) + triangleRadius * triangleMix;
			var px = FlxMath.bound(center + Math.cos(angle) * radius * scaleX, 1, frame - 1);
			var py = FlxMath.bound(center + Math.sin(angle) * radius * scaleY, 1, frame - 1);

			if (i == 0)
				shape.graphics.moveTo(px, py);
			else
				shape.graphics.lineTo(px, py);
		}

		shape.graphics.endFill();
		_indicator.pixels.fillRect(_indicator.pixels.rect, FlxColor.TRANSPARENT);
		_indicator.pixels.draw(shape, null, null, null, null, true);
		_indicator.dirty = true;
	}

	function _triangleRadius(angle:Float, baseRadius:Float):Float
	{
		var sector:Float = TAU / 3;
		var local:Float = angle % sector;
		if (local < 0) local += sector;
		local -= sector * 0.5;

		var denom:Float = Math.cos(local);
		if (Math.abs(denom) < 0.001)
			denom = denom < 0 ? -0.001 : 0.001;

		var triangleRadius:Float = (baseRadius * Math.cos(Math.PI / 3)) / denom;
		return FlxMath.bound(triangleRadius, baseRadius * 0.52, baseRadius * 1.18);
	}

	public function getDebugLayout():String
	{
		return 'group=(' + x + ', ' + y + ')'
			+ ' indicator=(' + _indicator.x + ', ' + _indicator.y + ', ' + _indicator.width + 'x' + _indicator.height + ')'
			+ ' angle=' + _indicator.angle
			+ ' shape=(' + _lastLobes + ', ' + _lastAmplitude + ', ' + _lastSoftness + ')';
	}

	function _drawFilledCircle(sprite:FlxSprite, size:Int, color:FlxColor):Void
	{
		var bmp = sprite.pixels;
		var cx:Float = size * 0.5;
		var cy:Float = size * 0.5;
		var r:Float  = cx;
		for (py in 0...size)
			for (px in 0...size)
			{
				var dx:Float = px - cx + 0.5;
				var dy:Float = py - cy + 0.5;
				if (dx * dx + dy * dy <= r * r)
					bmp.setPixel32(px, py, color);
			}
		sprite.dirty = true;
	}

	static inline function _lerp(a:Float, b:Float, t:Float):Float
		return a + (b - a) * t;

	static inline function _smoothstep(t:Float):Float
	{
		var c:Float = t < 0 ? 0.0 : (t > 1 ? 1.0 : t);
		return c * c * (3.0 - 2.0 * c);
	}

	function _onThemeChange():Void
	{
		if (_container != null)
			_drawFilledCircle(_container, _container.frameWidth, MD3Theme.primaryContainer);
		_redrawShape(_lastLobes >= 0 ? _lastLobes : LOBES[0],
			_lastAmplitude >= 0 ? _lastAmplitude : AMPLITUDES[0],
			_lastSecondary >= 0 ? _lastSecondary : SECONDARY[0],
			_lastSoftness >= 0 ? _lastSoftness : SOFTNESS[0],
			_lastPhase >= 0 ? _lastPhase : PHASE_OFF[0],
			SCALE_X[_shapeIndex], SCALE_Y[_shapeIndex], TRIANGLE_MIX[_shapeIndex]);
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(_onThemeChange);
		super.destroy();
	}
}
