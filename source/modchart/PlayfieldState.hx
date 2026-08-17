package modchart;

import haxe.ds.StringMap;
import modchart.backend.core.ModifierOutput;
import modchart.backend.core.VisualParameters;
import modchart.backend.math.Vector3;

/**
 * Per-playfield cache for frame-local modchart outputs.
 *
 * The goal is to keep path resolution and field-level values stable during a
 * frame so renderers can reuse the same transformed output instead of
 * recomputing the same modifier pipeline repeatedly.
 */
final class PlayfieldState
{
	public var frameId(default, null):Int = -1;
	public var songPosition(default, null):Float = 0;
	public var beat(default, null):Float = 0;

	private var __pathCache:StringMap<ModifierOutput> = new StringMap();

	public function new()
	{
	}

	public inline function beginFrame(frameId:Int, songPosition:Float, beat:Float):Void
	{
		if (this.frameId != frameId)
			__pathCache = new StringMap();

		this.frameId = frameId;
		this.songPosition = songPosition;
		this.beat = beat;
	}

	public inline function getCachedPath(key:String):Null<ModifierOutput>
	{
		return __pathCache.get(key);
	}

	public inline function setCachedPath(key:String, output:ModifierOutput):ModifierOutput
	{
		__pathCache.set(key, output);
		return output;
	}

	public inline function cloneOutput(output:ModifierOutput):ModifierOutput
	{
		return {
			pos: new Vector3(output.pos.x, output.pos.y, output.pos.z, output.pos.w),
			visuals: cloneVisuals(output.visuals),
			rawX: output.rawX,
			rawY: output.rawY,
			rawZ: output.rawZ
		};
	}

	private inline function cloneVisuals(visuals:VisualParameters):VisualParameters
	{
		return {
			scaleX: visuals.scaleX,
			scaleY: visuals.scaleY,
			alpha: visuals.alpha,
			glow: visuals.glow,
			glowR: visuals.glowR,
			glowG: visuals.glowG,
			glowB: visuals.glowB,
			angleX: visuals.angleX,
			angleY: visuals.angleY,
			angleZ: visuals.angleZ,
			skewX: visuals.skewX,
			skewY: visuals.skewY
		};
	}
}

