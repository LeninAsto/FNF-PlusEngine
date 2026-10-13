package objects;

import flixel.sound.FlxSound;

#if funkin.vis
import funkin.vis.dsp.SpectralAnalyzer;
import lime.media.AudioSource;
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
	var _analysisSource:AudioSource;
	var _sourceAttempted:Bool = false;
	var _lastAnalysisStamp:Float = -9999;
	var _lastAnalysisPosition:Float = -1;
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
		_analysisSource = null;
		_sourceAttempted = false;
		_lastAnalysisStamp = -9999;
		_lastAnalysisPosition = -1;
		refreshAnalyzer();
		#end
	}

	public function dispose():Void
	{
		_snd = null;
		#if funkin.vis
		_analyzer = null;
		_analysisSource = null;
		_sourceAttempted = false;
		_bars = null;
		#end

		for (i in 0..._out.length)
			_out[i] = 0;
	}

	public function levels():Array<Float>
	{
		#if funkin.vis
		if (_analyzer == null && _snd != null && !_sourceAttempted)
			refreshAnalyzer();

		if (_analyzer == null)
			return _out;
		// The display can draw at 240+ FPS; seven audio bars do not need 240 FFTs.
		var now = haxe.Timer.stamp();
		var position = _snd != null ? _snd.time : 0;
		if (position == _lastAnalysisPosition || now - _lastAnalysisStamp < 1 / 60)
			return _out;
		_lastAnalysisStamp = now;
		_lastAnalysisPosition = position;

		try
		{
			_bars = _analyzer.getLevels(_bars);
		}
		catch (_:Dynamic)
		{
			// Unsupported/corrupt audio must not take down the whole stage.
			_analyzer = null;
			_analysisSource = null;
			for (i in 0..._out.length)
				_out[i] = 0;
			return _out;
		}
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
		var source:AudioSource = (_snd._channel != null) ? _snd._channel.__audioSource : null;
		if (source == null)
			return;

		_analysisSource = backend.AssetLoader.analyzerSource(source);
		_sourceAttempted = _analysisSource != null || backend.AssetLoader.isAnalyzerPreparationFinished(source.buffer);
		if (_analysisSource == null)
			return;

		_analyzer = new SpectralAnalyzer(_analysisSource, bands, _smoothing, _peakHold);
		_analyzer.fftN = 256;
	}
	#end
}
