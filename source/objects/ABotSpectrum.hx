package objects;

import flixel.sound.FlxSound;

#if funkin.vis
import funkin.vis.dsp.SpectralAnalyzer;
#end

/**
	Per-band audio levels for A-Bot style visualizers.

	The scripted speaker owns the sprites and frame mapping; this compiled helper owns the audio
	source access that scripts cannot safely reach. If funkin.vis is missing or disabled, the helper
	stays valid and returns silence instead of crashing the stage.
**/
class ABotSpectrum
{
	public var bands(default, null):Int;
	public var ready(get, never):Bool;

	var _out:Array<Float>;
	var _snd:FlxSound;

	#if funkin.vis
	var _analyzer:SpectralAnalyzer;
	var _bars:Array<Bar>;
	#end

	final _smoothing:Float;
	final _peakHold:Int;

	public function new(bands:Int = 7, smoothing:Float = 0.1, peakHold:Int = 40)
	{
		this.bands = bands;
		_smoothing = smoothing;
		_peakHold = peakHold;
		_out = [for (_ in 0...bands) 0.0];
	}

	public function bind(snd:FlxSound):Void
	{
		_snd = snd;
		#if funkin.vis
		_analyzer = null;
		refreshAnalyzer();
		#end
	}

	public function dispose():Void
	{
		_snd = null;
		#if funkin.vis
		_analyzer = null;
		_bars = null;
		#end

		for (i in 0..._out.length)
			_out[i] = 0;
	}

	public function levels():Array<Float>
	{
		#if funkin.vis
		if (_analyzer == null && _snd != null)
			refreshAnalyzer();

		if (_analyzer == null)
			return _out;

		_bars = _analyzer.getLevels(_bars);
		var count:Int = (_bars.length < _out.length) ? _bars.length : _out.length;
		for (i in 0...count)
		{
			var v:Float = _bars[i].value;
			_out[i] = (v < 0) ? 0 : ((v > 1) ? 1 : v);
		}
		for (i in count..._out.length)
			_out[i] = 0;
		#end
		return _out;
	}

	public function peak():Float
	{
		var vals:Array<Float> = levels();
		var max:Float = 0;
		for (i in 0...vals.length)
		{
			if (vals[i] > max)
				max = vals[i];
		}
		return max;
	}

	inline function get_ready():Bool
	{
		#if funkin.vis
		return _analyzer != null;
		#else
		return false;
		#end
	}

	#if funkin.vis
	function refreshAnalyzer():Void
	{
		if (_snd == null)
			return;

		@:privateAccess
		var source:Dynamic = (_snd._channel != null) ? _snd._channel.__audioSource : null;
		if (source == null)
			return;

		_analyzer = new SpectralAnalyzer(source, bands, _smoothing, _peakHold);
		#if desktop
		_analyzer.fftN = 256;
		#end
	}
	#end
}
