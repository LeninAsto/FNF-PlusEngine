package backend;

import openfl.display.BitmapData;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import flash.media.Sound;
import haxe.ds.WeakMap;
import lime.utils.Assets;
import lime.media.AudioBuffer;
import lime.media.AudioSource;
import lime.media.vorbis.VorbisFile;
import shaders.ShaderCompatibility;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end

/**
 * Raw asset I/O for filesystem and bundled assets.
 * Inspired by the loader separation used in P-Slice.
 */
class AssetLoader
{
	#if (lime_vorbis && sys)
	// Weak keys ensure clearing the normal sound cache can still release streamed buffers.
	static final streamedAudioPaths:WeakMap<AudioBuffer, String> = new WeakMap<AudioBuffer, String>();
	static final analyzerAllowed:WeakMap<AudioBuffer, Bool> = new WeakMap<AudioBuffer, Bool>();
	static final analyzerBuffers:WeakMap<AudioBuffer, AnalyzerPreparation> = new WeakMap<AudioBuffer, AnalyzerPreparation>();
	#if target.threaded
	static final analyzerLock:sys.thread.Mutex = new sys.thread.Mutex();
	#end
	static inline final MAX_ANALYZER_BYTES:Int = 64 * 1024 * 1024;
	#end

	static inline function lockAnalyzer():Void
	{
		#if (lime_vorbis && sys && target.threaded)
		analyzerLock.acquire();
		#end
	}

	static inline function unlockAnalyzer():Void
	{
		#if (lime_vorbis && sys && target.threaded)
		analyzerLock.release();
		#end
	}

	public static function exists(path:String, type:AssetType):Bool
	{
		if (path == null || path.length == 0)
			return false;

		#if MODS_ALLOWED
		try
		{
			if (FileSystem.exists(path))
				return true;
		}
		catch (_:Dynamic)
		{
		}
		#end
		try
		{
			return OpenFlAssets.exists(path, type);
		}
		catch (_:Dynamic)
		{
		}
		return false;
	}

	public static function loadText(path:String):String
	{
		if (path == null || path.length == 0)
			return null;

		var text:String = null;
		#if MODS_ALLOWED
		try
		{
			if (FileSystem.exists(path))
				text = File.getContent(path);
		}
		catch (_:Dynamic)
		{
		}
		#end
		if (text != null)
			return maybeAdaptShaderText(path, text);

		try
		{
			if (OpenFlAssets.exists(path, TEXT))
				text = Assets.getText(path);
		}
		catch (_:Dynamic)
		{
		}
		return maybeAdaptShaderText(path, text);
	}

	static function maybeAdaptShaderText(path:String, text:String):String
	{
		if (text == null)
			return null;

		var normalized:String = path.replace("\\", "/");
		if (normalized.indexOf("/shaders/") == -1)
			return text;

		var stage:String = StringTools.endsWith(normalized.toLowerCase(), ".vert") ? "vertex" : "fragment";
		var shaderName:String = normalized;
		var slash:Int = shaderName.lastIndexOf("/");
		if (slash != -1)
			shaderName = shaderName.substr(slash + 1);
		var dot:Int = shaderName.lastIndexOf(".");
		if (dot != -1)
			shaderName = shaderName.substr(0, dot);

		return ShaderCompatibility.adaptRuntimeShaderCode(text, shaderName, stage);
	}

	public static function loadBitmap(path:String):BitmapData
	{
		if (path == null || path.length == 0)
			return null;

		#if MODS_ALLOWED
		try
		{
			if (FileSystem.exists(path))
				return BitmapData.fromFile(path);
		}
		catch (_:Dynamic)
		{
		}
		#end
		try
		{
			if (OpenFlAssets.exists(path, IMAGE))
				return OpenFlAssets.getBitmapData(path);
		}
		catch (_:Dynamic)
		{
		}
		return null;
	}

	public static function loadSound(path:String):Sound
	{
		if (path == null || path.length == 0)
			return null;

		#if MODS_ALLOWED
		try
		{
			if (FileSystem.exists(path))
				return Sound.fromFile(path);
		}
		catch (_:Dynamic)
		{
		}
		#end
		try
		{
			if (OpenFlAssets.exists(path, SOUND))
				return OpenFlAssets.getSound(path);
		}
		catch (_:Dynamic)
		{
		}
		return null;
	}

	/** Upload decoded playback PCM during the loading screen, on the audio-context thread. */
	public static function warmAudio(sound:Sound):Void
	{
		#if (lime_openal && !html5 && !flash)
		if (sound == null) return;
		@:privateAccess var buffer = sound.__buffer;
		if (buffer == null || buffer.data == null) return;
		@:privateAccess if (buffer.__srcBuffer != null) return;
		var warmup = new AudioSource(buffer);
		warmup.dispose();
		#end
	}

	/** Keeps long OGG tracks compressed and streamable for native tempo processing. */
	public static function loadStreamedSound(path:String):Sound
	{
		#if (lime_vorbis && sys && !mobile)
		if (path != null && path.length > 0)
		{
			try
			{
				if (sys.FileSystem.exists(path))
				{
					// Some older mods store a Theora video and Vorbis audio in the same
					// .ogg container. Lime's streaming reader can open it, but may stall
					// once playback starts. The regular decoder handles these legacy files.
					if (hasTheoraStream(path))
						return loadSound(path);

					var vorbis = VorbisFile.fromFile(path);
					if (vorbis != null)
					{
						var buffer:AudioBuffer = AudioBuffer.fromVorbisFile(vorbis);
						if (buffer != null)
						{
							var maxFrames = Std.int(MAX_ANALYZER_BYTES / Math.max(1, buffer.channels * (buffer.bitsPerSample / 8)));
							var allowed = haxe.Int64.compare(vorbis.pcmTotal(), haxe.Int64.ofInt(maxFrames)) <= 0;
							lockAnalyzer();
							streamedAudioPaths.set(buffer, path);
							analyzerAllowed.set(buffer, allowed);
							unlockAnalyzer();
							return Sound.fromAudioBuffer(buffer);
						}
					}
				}
			}
			catch (_:Dynamic) {}
		}
		#end
		return loadSound(path);
	}

	/**
	 * Returns an audio source that funkin.vis can inspect safely.
	 *
	 * Lime keeps streamed Vorbis tracks in a decoder, so their `AudioBuffer.data` is null.
	 * funkin.vis expects decoded PCM there. Keep playback streamed, but decode a separate,
	 * non-playing CPU buffer prepared during loading. Never decode a song here.
	 */
	public static function analyzerSource(source:AudioSource):AudioSource
	{
		if (source == null || source.buffer == null)
			return null;

		#if web
		return source;
		#else
		if (source.buffer.data != null)
			return source;

		#if (lime_vorbis && sys)
		lockAnalyzer();
		var preparation = analyzerBuffers.get(source.buffer);
		var decoded = preparation != null ? preparation.decoded : null;
		unlockAnalyzer();
		if (decoded != null)
		{
			// Passing decoded PCM to the constructor would upload the entire track
			// to OpenAL, although this source is only used to read samples.
			var analysis = new AudioSource();
			analysis.buffer = decoded;
			return analysis;
		}
		#if target.threaded
		if (preparation == null)
			beginAnalyzerPreparation(source.buffer, true);
		#end
		#end

		return null;
		#end
	}

	/** Called from a loading worker, before playback starts. */
	public static function prepareAnalyzer(sound:Sound):Void
	{
		#if (lime_vorbis && sys)
		if (sound != null)
		{
			@:privateAccess var buffer = sound.__buffer;
			beginAnalyzerPreparation(buffer, false);
		}
		#end
	}

	public static function isAnalyzerPreparationFinished(buffer:AudioBuffer):Bool
	{
		if (buffer == null || buffer.data != null) return true;
		#if (lime_vorbis && sys)
		lockAnalyzer();
		var preparation = analyzerBuffers.get(buffer);
		var finished = preparation != null && preparation.finished;
		unlockAnalyzer();
		return finished;
		#else
		return true;
		#end
	}

	#if (lime_vorbis && sys)
	static function beginAnalyzerPreparation(buffer:AudioBuffer, asynchronous:Bool):Void
	{
		if (buffer == null || buffer.data != null) return;
		lockAnalyzer();
		if (analyzerBuffers.exists(buffer))
		{
			unlockAnalyzer();
			return;
		}
		var path = streamedAudioPaths.get(buffer);
		if (analyzerAllowed.get(buffer) != true) path = null;
		var preparation:AnalyzerPreparation = {decoded: null, finished: path == null};
		analyzerBuffers.set(buffer, preparation);
		unlockAnalyzer();
		if (path == null) return;
		var decode = () ->
		{
			var decoded:AudioBuffer = null;
			try
			{
				// Bound the additional PCM cache instead of doubling an arbitrary long track.
				decoded = AudioBuffer.fromFile(path);
			}
			catch (_:Dynamic) {}
			if (decoded != null && (decoded.data == null || decoded.data.length > MAX_ANALYZER_BYTES))
			{
				decoded.dispose();
				decoded = null;
			}
			lockAnalyzer();
			preparation.decoded = decoded;
			preparation.finished = true;
			unlockAnalyzer();
		};
		#if target.threaded
		if (asynchronous)
			ThreadUtil.execAsync(decode);
		else
		#end
			decode();
	}
	#end

	#if sys
	static function hasTheoraStream(path:String):Bool
	{
		var input:sys.io.FileInput = null;
		try
		{
			var size:Int = Std.int(Math.min(sys.FileSystem.stat(path).size, 65536));
			input = sys.io.File.read(path, true);
			var header:haxe.io.Bytes = input.read(size);
			input.close();
			var signature:haxe.io.Bytes = haxe.io.Bytes.ofString('theora');
			for (offset in 0...(header.length - signature.length + 1))
			{
				var matches:Bool = true;
				for (index in 0...signature.length)
					if (header.get(offset + index) != signature.get(index))
					{
						matches = false;
						break;
					}
				if (matches)
					return true;
			}
			return false;
		}
		catch (_:Dynamic)
		{
			if (input != null)
				try input.close() catch (_:Dynamic) {}
			return false;
		}
	}
	#end
}

#if (lime_vorbis && sys)
private typedef AnalyzerPreparation = {decoded:Null<AudioBuffer>, finished:Bool};
#end

