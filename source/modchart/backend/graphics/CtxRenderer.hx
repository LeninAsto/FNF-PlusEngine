package modchart.backend.graphics;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.graphics.FlxGraphic;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxSignal;
import flixel.util.FlxSort;
import haxe.ds.IntMap;
import haxe.ds.Vector;
import modchart.backend.graphics.renderers.*;
import modchart.engine.PlayField;
import openfl.display.BlendMode;

using modchart.backend.util.SortUtil;

class CtxRenderer {
	/**
	 * Global quality multiplier consumed by PathRenderer.
	 * 1.0 = full quality, lower values reduce path divisions to protect FPS.
	 */
	public static var pathQualityScale:Float = 1.0;

	var ctx:Context;

	public function new() {}

	var queue:Vector<DrawCommand>;
	var count:Int = 0;

	/** Debug stats — populated each frame by emit(). */
	public var dbgDrawCmds:Int = 0;
	public var dbgHoldCmds:Int = 0;
	public var dbgVertices:Int = 0;
	public var dbgEmitMs:Float = 0.0;
	public var dbgActiveHolds:Int = 0;

	public function alloc(n:Int) {
		queue = new Vector<DrawCommand>(n);
		count = 0;
	}

	public function emitArrowCmd(item:FlxSprite) {
		final dc = ctx.arrowRenderer.prepare(item);
		if (dc != null)
			dc.zIndex = Std.int(item._z * 1000);
		return dc;
	}

	public function emitHoldCmd(item:FlxSprite) {
		final dc = ctx.holdRenderer.prepare(item);
		if (dc != null) {
			dc.zIndex = Std.int(item._z * 1000);
			dbgHoldCmds++;
		}
		return dc;
	}

	public function emitPathCmd(item:FlxSprite) {
		final dc = ctx.pathRenderer.prepare(item);
		if (dc != null)
			dc.zIndex = Std.int(item._z * 1000) + 1;
		return dc;
	}

	var emptyVec:openfl.Vector<Int> = new openfl.Vector<Int>(8, true, [for (i in 0...8) 0]);

	/** Target subdivisions set by the user (restored when FPS recovers). */
	var __targetSubdivisions:Int = 4;
	/** Adaptive FPS tracking: running average of the last N frame times. */
	var __fpsSum:Float = 0;
	var __fpsFrames:Int = 0;
	static final FPS_WINDOW:Int = 30;

	/**
	 * Adaptively lower or restore hold subdivisions based on FPS.
	 * Below 45 FPS → reduce to 2; above 55 FPS → restore to the last
	 * user-set value (respects Lua overrides when performance is fine).
	 */
	private inline function updateAdaptiveSubdivisions():Void {
		final elapsed = flixel.FlxG.elapsed;
		if (elapsed <= 0)
			return;
		__fpsSum += elapsed;
		__fpsFrames++;
		if (__fpsFrames < FPS_WINDOW)
			return;
		final avgFps = __fpsFrames / __fpsSum;
		__fpsSum = 0;
		__fpsFrames = 0;
		final cur = Adapter.instance.getHoldSubdivisions(null);
		if (avgFps < 45 && cur > 2) {
			__targetSubdivisions = cur; // save before lowering
			Adapter.instance.setHoldSubdivisions(2);
			pathQualityScale = 0.65;
		} else if (avgFps < 50) {
			pathQualityScale = 0.8;
		} else if (avgFps >= 55) {
			if (cur == 2 && __targetSubdivisions > 2)
				Adapter.instance.setHoldSubdivisions(__targetSubdivisions);
			else
				__targetSubdivisions = cur; // keep in sync with Lua overrides
			pathQualityScale = 1.0;
		}
	}

	public function emit(items:Array<Array<Array<FlxSprite>>>, playfields:Array<PlayField>) {
		final __emitStart = haxe.Timer.stamp();

		// Adaptively throttle hold subdivisions when FPS is consistently low.
		updateAdaptiveSubdivisions();

		// used for preallocate
		var playfieldCount = 0;
		for (playfield in playfields) {
			if (playfield != null)
				playfieldCount++;
		}

		var receptorCount = 0;
		var arrowCount = 0;
		var holdCount = 0;
		var attachmentCount = 0;

		var pathCount = 0;

		for (i in 0...items.length) {
			final curItems = items[i];

			if (curItems == null || curItems.length == 0)
				continue;

			if (curItems[0] != null)
				receptorCount = receptorCount + curItems[0].length;
			if (curItems[1] != null)
				arrowCount = arrowCount + curItems[1].length;
			if (curItems[2] != null)
				holdCount = holdCount + curItems[2].length;
			if (curItems[3] != null)
				attachmentCount = attachmentCount + curItems[3].length;
		}

		pathCount = receptorCount;

		// Reset per-frame debug stats
		dbgDrawCmds = 0;
		dbgHoldCmds = 0;
		dbgVertices = 0;
		dbgActiveHolds = holdCount * playfieldCount;

		alloc((arrowCount + receptorCount + attachmentCount + holdCount + pathCount) * playfieldCount);

		// i is player index
		for (f in 0...playfields.length) {
			var playfield = playfields[f];
			if (playfield == null)
				continue;

			ctx = playfield.context;

			for (player in 0...items.length) {
				var curItems:Array<Array<FlxSprite>> = items[player];

				if (curItems == null || curItems.length == 0)
					continue;

				// path stuff
				if (pathCount > 0) {
					// iterate through receptors, yes
					for (receptor in curItems[0]) {
						if (!getVisibility(receptor))
							continue;
						var _ = emitPathCmd(receptor);
						if (_ != null)
							this.append(_);
					}
				}

				final drawHolds = () -> {
					if (holdCount > 0) {
						for (hold in curItems[2]) {
							if (!getVisibility(hold))
								continue;
							var _ = emitHoldCmd(hold);
							if (_ != null)
								this.append(_);
						}
					}
				};

				// holds (behind strums)
				if (Config.HOLDS_BEHIND_STRUM)
					drawHolds();

				// receptors
				if (receptorCount > 0) {
					for (receptor in curItems[0]) {
						if (!getVisibility(receptor))
							continue;

						var _ = emitArrowCmd(receptor);
						if (_ != null)
							this.append(_);
					}
				}

				// holds (infront of strums)
				if (!Config.HOLDS_BEHIND_STRUM)
					drawHolds();

				// tap arrow
				if (arrowCount > 0) {
					for (arrow in curItems[1]) {
						if (!getVisibility(arrow))
							continue;

						var _ = emitArrowCmd(arrow);
						if (_ != null)
							this.append(_);
					}
				}

				// attachments (splashes)
				if (attachmentCount > 0) {
					for (attachment in curItems[3]) {
						if (!getVisibility(attachment))
							continue;

						var _ = emitArrowCmd(attachment);

						if (_ != null)
							this.append(_);
					}
				}
			}
		}

		queue.nullSort((a, b) -> return b.zIndex - a.zIndex);

		var i = 0;
		while (i < count) {
			var item = queue[i];
			if (item == null || item.graphic == null || item.cameras == null || item.cameras.length == 0 || item.vertices == null || item.indices == null || item.uvs == null) {
				i++;
				continue;
			}
			for (camera in item.cameras) {
				if (camera == null)
					continue;
				var dc = camera.startTrianglesBatch(item.graphic, item.antialiasing, item.isColored, item.blend, item.hasColorOffsets, item.shader);
				if (dc == null)
					continue;
				@:privateAccess var cameraBounds:FlxRect = camera._bounds;
				if (cameraBounds == null) {
					cameraBounds = new FlxRect();
					@:privateAccess camera._bounds = cameraBounds;
				}
				cameraBounds.set(camera.viewMarginLeft, camera.viewMarginTop, camera.viewWidth, camera.viewHeight);

				final scrollFactorX = item.parent != null ? item.parent.scrollFactor.x : 0;
				final scrollFactorY = item.parent != null ? item.parent.scrollFactor.y : 0;
				final cameraScrollX = camera.scroll != null ? camera.scroll.x : 0;
				final cameraScrollY = camera.scroll != null ? camera.scroll.y : 0;
				final point = FlxPoint.weak(cameraScrollX * -scrollFactorX, cameraScrollY * -scrollFactorY);

				if (item.color != null)
					dc.addTriangles(item.vertices, item.indices, item.uvs, emptyVec, point, cameraBounds,
						item.color);
				else if (item.colors != null)
					dc.addGradientTriangles(item.vertices, item.indices, item.uvs, point, cameraBounds, item.colors);
			}
			i++;
		}
		dbgEmitMs = (haxe.Timer.stamp() - __emitStart) * 1000.0;
	}

	public function append(dc:DrawCommand) {
		@:privateAccess
		queue[count++] = ctx.parent.transformCmd(dc);
		dbgDrawCmds++;
		dbgVertices += dc.vertices != null ? Std.int(dc.vertices.length / 2) : 0;
	}

	private function getVisibility(obj:flixel.FlxObject) {
		@:bypassAccessor obj.visible = false;
		return obj._fmVisible;
	}

	public function dispose() {}
}