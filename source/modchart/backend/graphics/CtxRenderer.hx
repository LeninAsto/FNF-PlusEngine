package modchart.backend.graphics;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.graphics.FlxGraphic;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxSignal;
import flixel.util.FlxSort;
import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.ds.Vector;
import modchart.backend.graphics.renderers.*;
import modchart.engine.PlayField;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;

using modchart.backend.util.SortUtil;

class CtxRenderer {
	/**
	 * Global quality multiplier consumed by PathRenderer.
	 * 1.0 = full quality, lower values reduce path divisions to protect FPS.
	 */
	public static var pathQualityScale:Float = 1.0;
	public var collectDebugStats:Bool = false;

	var ctx:Context;

	public function new() {}

	var queue:Vector<DrawCommand>;
	var sortBuffer:Vector<DrawCommand>;
	var count:Int = 0;
	var capacity:Int = 0;
	var suppressedVisibility:ObjectMap<FlxObject, Bool> = new ObjectMap();
	var suppressedObjects:Array<FlxObject> = [];
	var pathEnabled:Array<Bool> = [];
	var cameraColorTransform:ColorTransform = new ColorTransform();
	var cameraGradientTransforms:NativeVector<ColorTransform> = new NativeVector<ColorTransform>(0);

	/** Debug stats — populated each frame by emit(). */
	public var dbgDrawCmds:Int = 0;
	public var dbgHoldCmds:Int = 0;
	public var dbgVertices:Int = 0;
	public var dbgEmitMs:Float = 0.0;
	public var dbgCollectMs:Float = 0.0;
	public var dbgArrowMs:Float = 0.0;
	public var dbgHoldMs:Float = 0.0;
	public var dbgPathMs:Float = 0.0;
	public var dbgSortMs:Float = 0.0;
	public var dbgSubmitMs:Float = 0.0;
	public var dbgModifierCalls:Int = 0;
	public var dbgPathSamples:Int = 0;
	public var dbgSpawnCulled:Int = 0;
	public var dbgSlotsReused:Int = 0;
	public var dbgActiveHolds:Int = 0;
	public var dbgPlayfields:Int = 0;
	public var dbgReceptors:Int = 0;
	public var dbgArrows:Int = 0;
	public var dbgHolds:Int = 0;
	public var dbgAttachments:Int = 0;
	public var dbgPathCmds:Int = 0;
	public var dbgHoldSubdivisions:Int = 0;
	public var dbgPathQuality:Float = 1.0;

	public function alloc(n:Int) {
		if (queue != null)
		{
			for (i in 0...count)
				queue[i] = null;
		}

		if (queue == null || n > capacity)
		{
			capacity = Std.int(Math.ceil(Math.max(n, 64) / 64.0)) * 64;
			queue = new Vector<DrawCommand>(capacity);
			sortBuffer = new Vector<DrawCommand>(capacity);
		}
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
			if (collectDebugStats)
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

	public function emit(items:Array<Array<Array<FlxSprite>>>, playfields:Array<PlayField>) {
		final __emitStart = collectDebugStats ? haxe.Timer.stamp() : 0.0;
		// Keep references for at most one frame. Objects that left their group are
		// restored and released here instead of living in a song-long ObjectMap.
		restoreSuppressedVisibility();

		// Geometry now adapts by measured sub-pixel error, never by dropping
		// quality merely because the current FPS is low.
		pathQualityScale = 1.0;

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

		// A scripted `path` value is an explicit render request and must work even
		// when the optional global path preference is off. PathRenderer performs a
		// cheap value check here, so inactive paths add no per-sample work.
		var pathPlayfieldCount = 0;
		pathEnabled.resize(playfields.length);
		for (i in 0...playfields.length) {
			final playfield = playfields[i];
			final enabled = playfield != null && playfield.context != null && playfield.context.pathRenderer.hasVisiblePath();
			pathEnabled[i] = enabled;
			if (enabled)
				pathPlayfieldCount++;
		}

		if (collectDebugStats)
		{
			dbgDrawCmds = 0;
			dbgHoldCmds = 0;
			dbgVertices = 0;
			dbgActiveHolds = holdCount * playfieldCount;
			dbgPlayfields = playfieldCount;
			dbgReceptors = receptorCount;
			dbgArrows = arrowCount;
			dbgHolds = holdCount;
			dbgAttachments = attachmentCount;
			dbgPathCmds = 0;
			dbgHoldSubdivisions = Adapter.instance.getHoldSubdivisions(null);
			dbgPathQuality = pathQualityScale;
			dbgArrowMs = 0;
			dbgHoldMs = 0;
			dbgPathMs = 0;
			dbgSortMs = 0;
			dbgSubmitMs = 0;
			dbgModifierCalls = 0;
			dbgPathSamples = 0;
			dbgSpawnCulled = 0;
			dbgSlotsReused = 0;
		}

		alloc((arrowCount + receptorCount + attachmentCount + holdCount) * playfieldCount
			+ receptorCount * pathPlayfieldCount);

		// i is player index
		for (f in 0...playfields.length) {
			var playfield = playfields[f];
			if (playfield == null)
				continue;

			ctx = playfield.context;
			playfield.modifiers.trackDebugStats = collectDebugStats;
			ctx.holdRenderer.collectDebugStats = collectDebugStats;
			ctx.arrowRenderer.beginFrame();
			ctx.holdRenderer.beginFrame();
			final renderPaths = pathEnabled[f];
			for (player in 0...items.length) {
				var curItems:Array<Array<FlxSprite>> = items[player];

				if (curItems == null || curItems.length == 0)
					continue;
				final requestedSpawn = playfield.getPercent('spawnTime', player);
				final spawnWindow = requestedSpawn > 0 ? requestedSpawn : 2000.0;

				// path stuff
				if (renderPaths) {
					// iterate through receptors, yes
					for (receptor in curItems[0]) {
						final pathStart = collectDebugStats ? haxe.Timer.stamp() : 0.0;
						var _ = emitPathCmd(receptor);
						if (collectDebugStats) dbgPathMs += (haxe.Timer.stamp() - pathStart) * 1000.0;
						if (_ != null) {
							if (collectDebugStats)
								dbgPathCmds++;
							this.append(_);
						}
					}
				}

				// holds (behind strums)
				if (Config.HOLDS_BEHIND_STRUM)
					emitHolds(curItems[2], playfield, spawnWindow);

				// receptors
				if (receptorCount > 0) {
					for (receptor in curItems[0]) {
						if (!isRenderable(receptor) || !getVisibility(receptor))
							continue;
						final arrowStart = collectDebugStats ? haxe.Timer.stamp() : 0.0;
						var _ = emitArrowCmd(receptor);
						if (collectDebugStats) dbgArrowMs += (haxe.Timer.stamp() - arrowStart) * 1000.0;
						if (_ != null)
							this.append(_);
					}
				}

				// holds (infront of strums)
				if (!Config.HOLDS_BEHIND_STRUM)
					emitHolds(curItems[2], playfield, spawnWindow);

				// tap arrow
				if (arrowCount > 0) {
					for (arrow in curItems[1]) {
						if (!isRenderable(arrow) || isOutsideSpawnWindow(arrow, playfield, spawnWindow) || !getVisibility(arrow))
							continue;
						final arrowStart = collectDebugStats ? haxe.Timer.stamp() : 0.0;
						var _ = emitArrowCmd(arrow);
						if (collectDebugStats) dbgArrowMs += (haxe.Timer.stamp() - arrowStart) * 1000.0;
						if (_ != null)
							this.append(_);
					}
				}

				// attachments (splashes)
				if (attachmentCount > 0) {
					for (attachment in curItems[3]) {
						if (!isRenderable(attachment) || !getVisibility(attachment))
							continue;
						final arrowStart = collectDebugStats ? haxe.Timer.stamp() : 0.0;
						var _ = emitArrowCmd(attachment);
						if (collectDebugStats) dbgArrowMs += (haxe.Timer.stamp() - arrowStart) * 1000.0;

						if (_ != null)
							this.append(_);
					}
				}
			}
		}

		final sortStart = collectDebugStats ? haxe.Timer.stamp() : 0.0;
		sortActiveQueue();
		if (collectDebugStats) dbgSortMs = (haxe.Timer.stamp() - sortStart) * 1000.0;

		final submitStart = collectDebugStats ? haxe.Timer.stamp() : 0.0;
		var i = 0;
		while (i < count) {
			var item = queue[i];
			if (item == null || item.graphic == null || item.cameras == null || item.cameras.length == 0 || item.vertices == null || item.indices == null || item.uvs == null) {
				i++;
				continue;
			}
			for (camera in item.cameras) {
				if (camera == null || !camera.exists || !camera.visible || camera.alpha <= 0.0001)
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

				final scrollFactor = item.parent != null ? item.parent.scrollFactor : null;
				final scrollFactorX = scrollFactor != null ? scrollFactor.x : 0;
				final scrollFactorY = scrollFactor != null ? scrollFactor.y : 0;
				final cameraScrollX = camera.scroll != null ? camera.scroll.x : 0;
				final cameraScrollY = camera.scroll != null ? camera.scroll.y : 0;
				final point = FlxPoint.weak(cameraScrollX * -scrollFactorX, cameraScrollY * -scrollFactorY);

				if (item.color != null)
					dc.addTriangles(item.vertices, item.indices, item.uvs, emptyVec, point, cameraBounds,
						getCameraColorTransform(item.color, camera.alpha));
				else if (item.colors != null)
					dc.addGradientTriangles(item.vertices, item.indices, item.uvs, point, cameraBounds,
						getCameraGradientTransforms(item.colors, camera.alpha));
			}
			i++;
		}
		if (collectDebugStats) {
			dbgSubmitMs = (haxe.Timer.stamp() - submitStart) * 1000.0;
			for (playfield in playfields) if (playfield != null) {
				dbgModifierCalls += playfield.modifiers.dbgModifierCalls;
				dbgPathSamples += playfield.modifiers.dbgPathCalls;
				dbgSlotsReused += playfield.context.holdRenderer.dbgSlotsReused;
			}
			dbgEmitMs = (haxe.Timer.stamp() - __emitStart) * 1000.0;
		}
	}

	private function emitHolds(holds:Array<FlxSprite>, playfield:PlayField, spawnWindow:Float):Void {
		if (holds == null)
			return;
		for (hold in holds) {
			if (!isRenderable(hold) || isOutsideSpawnWindow(hold, playfield, spawnWindow) || !getVisibility(hold))
				continue;
			final holdStart = collectDebugStats ? haxe.Timer.stamp() : 0.0;
			final command = emitHoldCmd(hold);
			if (collectDebugStats) dbgHoldMs += (haxe.Timer.stamp() - holdStart) * 1000.0;
			if (command != null)
				append(command);
		}
	}

	private inline function isRenderable(item:FlxSprite):Bool
		return item != null && item.exists && item.alive && item.graphic != null && item.frame != null && item.alpha > 0;

	private inline function isOutsideSpawnWindow(item:FlxSprite, playfield:PlayField, spawnWindow:Float):Bool {
		final outside = Adapter.instance.getTimeFromArrow(item) - playfield.state.songPosition > spawnWindow;
		if (outside && collectDebugStats)
			dbgSpawnCulled++;
		return outside;
	}

	public function append(dc:DrawCommand) {
		if (dc == null || ctx == null || ctx.parent == null || dc.vertices == null || dc.indices == null || dc.uvs == null)
			return;

		@:privateAccess
		var transformed = ctx.parent.transformCmd(dc);
		if (transformed == null)
			return;
		if (count >= capacity)
		{
			final nextCapacity = capacity + 64;
			var grown = new Vector<DrawCommand>(nextCapacity);
			var grownSort = new Vector<DrawCommand>(nextCapacity);
			Vector.blit(queue, 0, grown, 0, capacity);
			queue = grown;
			sortBuffer = grownSort;
			capacity = nextCapacity;
		}
		queue[count++] = transformed;
		if (collectDebugStats)
		{
			dbgDrawCmds++;
			dbgVertices += dc.vertices != null ? Std.int(dc.vertices.length / 2) : 0;
		}
	}

	private function getCameraColorTransform(source:ColorTransform, cameraAlpha:Float):ColorTransform {
		if (cameraAlpha >= 0.999)
			return source;

		cameraColorTransform.redMultiplier = source.redMultiplier;
		cameraColorTransform.greenMultiplier = source.greenMultiplier;
		cameraColorTransform.blueMultiplier = source.blueMultiplier;
		cameraColorTransform.alphaMultiplier = source.alphaMultiplier * cameraAlpha;
		cameraColorTransform.redOffset = source.redOffset;
		cameraColorTransform.greenOffset = source.greenOffset;
		cameraColorTransform.blueOffset = source.blueOffset;
		cameraColorTransform.alphaOffset = source.alphaOffset;
		return cameraColorTransform;
	}

	private function getCameraGradientTransforms(source:NativeVector<ColorTransform>, cameraAlpha:Float):NativeVector<ColorTransform> {
		if (cameraAlpha >= 0.999)
			return source;

		if (cameraGradientTransforms == null || cameraGradientTransforms.length != source.length)
		{
			cameraGradientTransforms = new NativeVector<ColorTransform>(source.length);
			for (i in 0...source.length)
				cameraGradientTransforms[i] = new ColorTransform();
		}

		for (i in 0...source.length)
		{
			final from = source[i];
			var to = cameraGradientTransforms[i];
			if (to == null)
			{
				to = new ColorTransform();
				cameraGradientTransforms[i] = to;
			}

			if (from == null)
			{
				to.redMultiplier = 1;
				to.greenMultiplier = 1;
				to.blueMultiplier = 1;
				to.alphaMultiplier = cameraAlpha;
				to.redOffset = 0;
				to.greenOffset = 0;
				to.blueOffset = 0;
				to.alphaOffset = 0;
				continue;
			}

			to.redMultiplier = from.redMultiplier;
			to.greenMultiplier = from.greenMultiplier;
			to.blueMultiplier = from.blueMultiplier;
			to.alphaMultiplier = from.alphaMultiplier * cameraAlpha;
			to.redOffset = from.redOffset;
			to.greenOffset = from.greenOffset;
			to.blueOffset = from.blueOffset;
			to.alphaOffset = from.alphaOffset;
		}

		return cameraGradientTransforms;
	}

	private function sortActiveQueue():Void {
		if (count < 2)
			return;
		var width = 1;
		var source = queue;
		var target = sortBuffer;
		while (width < count) {
			var left = 0;
			while (left < count) {
				final mid = Std.int(Math.min(left + width, count));
				final end = Std.int(Math.min(left + width + width, count));
				var a = left, b = mid, out = left;
				while (a < mid && b < end) {
					// Left wins ties, preserving insertion order for equal zIndex.
					if (source[a].zIndex >= source[b].zIndex) target[out++] = source[a++];
					else target[out++] = source[b++];
				}
				while (a < mid) target[out++] = source[a++];
				while (b < end) target[out++] = source[b++];
				left = end;
			}
			final swap = source; source = target; target = swap;
			width *= 2;
		}
		if (source != queue)
			Vector.blit(source, 0, queue, 0, count);
	}

	private function getVisibility(obj:flixel.FlxObject) {
		if (obj == null)
			return false;

		if (!suppressedVisibility.exists(obj))
		{
			suppressedVisibility.set(obj, obj.visible);
			suppressedObjects.push(obj);
		}

		@:bypassAccessor obj.visible = false;
		return obj._fmVisible;
	}

	public function restoreSuppressedVisibility():Void {
		for (obj in suppressedObjects)
		{
			if (obj != null && suppressedVisibility.exists(obj))
				@:bypassAccessor obj.visible = suppressedVisibility.get(obj);
		}
		suppressedObjects.resize(0);
		suppressedVisibility = new ObjectMap();
	}

	public function dispose() {
		restoreSuppressedVisibility();
	}
}
