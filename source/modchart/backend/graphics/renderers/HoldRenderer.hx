package modchart.backend.graphics.renderers;

import haxe.ds.ObjectMap;

using flixel.util.FlxColorTransformUtil;

typedef HoldSegmentOutput = {
	origin:Vector3,
	left:Vector3,
	right:Vector3,
	visuals:VisualParameters,
	depth:Float,
	clipped:Bool
}

@:publicFields
@:structInit
private final class HoldSegment {
	var origin:Vector3;
	var left:Vector3;
	var right:Vector3;
}

final __matrix:Matrix = new Matrix();

/** Reusable unit-up vector for OPTIMIZE_HOLDS path — avoids allocating `new Vector3(0,1,0)` per segment. */
final __holdUnitUp:Vector3 = new Vector3(0, 1, 0);

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
final class HoldRenderer extends BaseRenderer<FlxSprite> {
	private var __lastHoldSubs:Int = -1;

	/** Debug: total getPath() calls in the last frame across all holds. */
	public var dbgGetPathCalls:Int = 0;

	var _indices:openfl.Vector<Int>;

	// UVT cache: avoids re-computing identical UV data every frame for the same hold tile
	var _uvtCacheKeys:Array<Dynamic> = [];
	var _uvtCacheVals:Array<openfl.Vector<Float>> = [];
	var _uvtCacheSubs:Int = -1;

	// Per-hold pools to avoid per-frame allocations of geometry/color buffers.
	var _holdVerticesPool:ObjectMap<FlxSprite, openfl.Vector<Float>> = new ObjectMap<FlxSprite, openfl.Vector<Float>>();
	var _holdColorsPool:ObjectMap<FlxSprite, NativeVector<ColorTransform>> = new ObjectMap<FlxSprite, NativeVector<ColorTransform>>();
	var _holdPoolSubs:ObjectMap<FlxSprite, Int> = new ObjectMap<FlxSprite, Int>();

	inline private function _getPooledVertices(item:FlxSprite, subs:Int):openfl.Vector<Float> {
		final oldSubs = _holdPoolSubs.get(item);
		var verts = _holdVerticesPool.get(item);
		if (verts == null || oldSubs == null || oldSubs != subs || verts.length != subs * 8) {
			verts = new openfl.Vector<Float>(subs * 8, true);
			_holdVerticesPool.set(item, verts);
			_holdPoolSubs.set(item, subs);
		}
		return verts;
	}

	inline private function _getPooledColors(item:FlxSprite, subs:Int):NativeVector<ColorTransform> {
		final oldSubs = _holdPoolSubs.get(item);
		var cols = _holdColorsPool.get(item);
		if (cols == null || oldSubs == null || oldSubs != subs || cols.length != subs) {
			cols = new NativeVector<ColorTransform>(subs);
			for (i in 0...subs)
				cols[i] = new ColorTransform();
			_holdColorsPool.set(item, cols);
			_holdPoolSubs.set(item, subs);
		}
		return cols;
	}

	inline private function _getCachedUVT(item:FlxSprite, subs:Int):openfl.Vector<Float> {
		if (subs != _uvtCacheSubs) {
			// Subdivision count changed (settings) — invalidate entire cache
			_uvtCacheKeys = [];
			_uvtCacheVals = [];
			_uvtCacheSubs = subs;
		}
		final frame = item.frame;
		final idx = _uvtCacheKeys.indexOf(frame);
		if (idx >= 0) return _uvtCacheVals[idx];
		final uvt:openfl.Vector<Float> = ModchartUtil.getHoldUVT(item, subs);
		_uvtCacheKeys.push(frame);
		_uvtCacheVals.push(uvt);
		return uvt;
	}

	public function new(parent:PlayField) {
		super(parent);

		parent.setPercent('dizzyHolds', 1, -1);
	}

	inline private function __rotateTail(pos:Vector3) {
		if (__parentOutput == null || (__rotateX == 0 && __rotateY == 0 && __rotateZ == 0))
			return pos;

		var tailFactor = pos.subtract(new Vector3(__parentOutput.rawX, __parentOutput.rawY, __parentOutput.rawZ));
		tailFactor = ModchartUtil.rotate3DVector(tailFactor, __rotateX, __rotateY, __rotateZ);
		return new Vector3(__parentOutput.rawX + tailFactor.x, __parentOutput.rawY + tailFactor.y, __parentOutput.rawZ + tailFactor.z);
	}

	/**
	 * Measures the visible distance between two hold segments on screen.
	 * Using the projected center avoids over-stretching the cap with strong scroll modifiers.
	 */
	@:noCompletion
	inline private function getSegmentScreenLength(first:HoldSegmentOutput, second:HoldSegmentOutput):Float {
		final startX = (first.left.x + first.right.x) * 0.5;
		final startY = (first.left.y + first.right.y) * 0.5;
		final endX = (second.left.x + second.right.x) * 0.5;
		final endY = (second.left.y + second.right.y) * 0.5;
		final deltaX = endX - startX;
		final deltaY = endY - startY;
		return Math.sqrt((deltaX * deltaX) + (deltaY * deltaY));
	}

	/**
	 * Returns the normal points along the hold path at specific hitTime using.
	 *
	 * Based on schmovin' hold system
	 * @param basePos The hold position per default
	 * @see https://en.wikipedia.org/wiki/Unit_circle
	 */
	@:noCompletion
	inline private function getHoldSegment(hold:FlxSprite, basePos:Vector3, params:ArrowData, doClip:Bool = true):HoldSegmentOutput {
		@:privateAccess
		var holdTime = params.hitTime;
		var parentTime = Adapter.instance.getHoldParentTime(hold);
		var clipped = false;

		var holdDistance = params.distance;
		var parentDistance = Math.max(0, parentTime - Adapter.instance.getSongPosition());

		params.hitTime = FlxMath.lerp(parentTime, holdTime, __long);
		params.distance = FlxMath.lerp(parentDistance, holdDistance, __long);

		// not this
		if (doClip && params.hitten && params.distance < 0) {
			params.distance = 0;
			clipped = true;
		}

		final size = hold.frame.frame.width * hold.scale.x * .5;

		var origin:ModifierOutput = parent.modifiers.getPath(copyVec3(basePos, _pathInputA), params);
		var curPoint = new Vector3(origin.pos.x, origin.pos.y, 0);
		final depth = (origin.pos.z - 1) * 1000;
		final worldX = origin.rawX;
		final worldY = origin.rawY;
		final worldZ = origin.rawZ;

		// before this, bc it fails with optimiz eholds too
		var unit:Vector3;

		if (Config.OPTIMIZE_HOLDS) {
			unit = __holdUnitUp; // reuse static up-vector, no allocation
		} else {
			var next = parent.modifiers.getPath(copyVec3(basePos, _pathInputB), params, 1, false, true);
			next.pos.z = 0;

			// normalized points difference (from 0-1)
			unit = next.pos.subtract(curPoint);
			unit.normalize();
		}

		var quad0 = new Vector3(-unit.y * size, unit.x * size);
		var quad1 = new Vector3(unit.y * size, -unit.x * size);

		final visuals = origin.visuals;
		@:privateAccess
		for (i in 0...2) {
			var quad = i == 0 ? quad0 : quad1;
			var rotation = quad;
			var rotate = __dizzy != 0;

			if (rotate)
				rotation = ModchartUtil.rotate3DVector(quad, 0, visuals.angleY * __dizzy, 0);

			if (visuals.skewX != 0 || visuals.skewY != 0) {
				__matrix.identity();

				__matrix.b = ModchartUtil.tan(visuals.skewY * FlxAngle.TO_RAD);
				__matrix.c = ModchartUtil.tan(visuals.skewX * FlxAngle.TO_RAD);

				rotation.x = __matrix.__transformX(rotation.x, rotation.y);
				rotation.y = __matrix.__transformY(rotation.x, rotation.y);
			}
			rotation.x = rotation.x * visuals.scaleX;
			rotation.y = rotation.y * visuals.scaleY;

			var view = new Vector3(rotation.x + worldX, rotation.y + worldY, worldZ + (rotation.z * 0.001 * Config.Z_SCALE));
			view = __rotateTail(view);

			// The result of the perspective projection of rotation
			var projection = this.view.transformVector(view);

			quad.x = projection.x;
			quad.y = projection.y;
			quad.z = projection.z;
		}

		return {
			origin: curPoint,
			left: quad0,
			right: quad1,
			visuals: origin.visuals,
			depth: depth,
			clipped: clipped
		};
	}

	private var __long:Float = 0.0;
	private var __rotateX:Float = 0;
	private var __rotateY:Float = 0;
	private var __rotateZ:Float = 0;
	private var __dizzy:Float = 0;
	private var __straightHolds:Float = 0;
	private var __parentOutput:ModifierOutput;
	private var __centered2:Float = 0;
	private var basePos:Vector3;

	@:noCompletion
	inline private function updateIndices(subdivisionCount:Int) {
		_indices = new openfl.Vector<Int>(subdivisionCount * 6, true);

		for (subdivision in 0...subdivisionCount) {
			var vertexPosition = subdivision * 4;
			var indexCount = subdivision * 6;

			_indices[indexCount] = vertexPosition;
			_indices[indexCount + 1] = vertexPosition + 1;
			_indices[indexCount + 2] = vertexPosition + 3;
			_indices[indexCount + 3] = vertexPosition;
			_indices[indexCount + 4] = vertexPosition + 2;
			_indices[indexCount + 5] = vertexPosition + 3;
		}
	}
	var __lastLong:Float = 0;
	var __lastC2:Float = 0;
	var __lastDizzy:Float = 0;
	var __lastStraightHolds:Float = 0;

	var __lastRX:Float = 0;
	var __lastRY:Float = 0;
	var __lastRZ:Float = 0;

	// YOU MOTHERFUCKER
	var __lastPlayer:Int = -1;

	/** Pre-allocated ArrowData buffer reused by getArrowParams() to avoid per-segment heap allocation. */
	final _holdArrowBuf:ArrowData = {hitTime: 0, distance: 0, sourceTime: 0, lane: 0, player: 0, hitten: false, isTapArrow: false, straightHolds: false};
	/** Pre-allocated ArrowData buffer for parentData (rotate path) to avoid per-hold heap allocation. */
	final _parentDataBuf:ArrowData = {hitTime: 0, distance: 0, sourceTime: 0, lane: 0, player: 0, hitten: false, isTapArrow: false, straightHolds: false};
	/** Reused path input vectors to avoid allocating basePos.clone() for every getPath call. */
	final _pathInputA:Vector3 = new Vector3();
	final _pathInputB:Vector3 = new Vector3();

	// Cached hold metadata used by getArrowParams() in the subdivision loop.
	var __cachedHoldPlayer:Int = 0;
	var __cachedHoldLane:Int = 0;
	var __cachedHoldHitTime:Float = 0;
	var __cachedHoldParentTime:Float = 0;
	var __cachedHoldHitten:Bool = false;
	var __cachedSongPos:Float = 0;

	inline private function copyVec3(from:Vector3, into:Vector3):Vector3 {
		into.x = from.x;
		into.y = from.y;
		into.z = from.z;
		return into;
	}

	override public function prepare(item:FlxSprite):Null<DrawCommand> {
		if (item == null || item.graphic == null || item.frame == null) {
			return null;
		}

		if (item.alpha <= 0) {
			return null;
		}

		Manager.HOLD_SIZE = item.width;
		Manager.HOLD_SIZEDIV2 = item.width * .5;

		final HOLD_SUBDIVISIONS = Adapter.instance.getHoldSubdivisions(item);

		// Only reallocate indices when subdivision count changes (global setting)
		if (HOLD_SUBDIVISIONS != __lastHoldSubs)
			updateIndices(HOLD_SUBDIVISIONS);

		final player = Adapter.instance.getPlayerFromArrow(item);
		final lane = Adapter.instance.getLaneFromArrow(item);
		final hitten = Adapter.instance.arrowHit(item);
		final holdHitTime = Adapter.instance.getTimeFromArrow(item);
		final holdParentTime = Adapter.instance.getHoldParentTime(item);
		final songPosNow = Adapter.instance.getSongPosition();

		__cachedHoldPlayer = player;
		__cachedHoldLane = lane;
		__cachedHoldHitTime = holdHitTime;
		__cachedHoldParentTime = holdParentTime;
		__cachedHoldHitten = hitten;
		__cachedSongPos = songPosNow;

		basePos = ModchartUtil.getHalfPos();
		basePos.x += Adapter.instance.getDefaultReceptorX(lane, player);
		basePos.y += Adapter.instance.getDefaultReceptorY(lane, player);

		// Reuse per-hold buffers to avoid per-frame heap churn.
		var vertices = _getPooledVertices(item, HOLD_SUBDIVISIONS);
		var transfTotal = _getPooledColors(item, HOLD_SUBDIVISIONS);
		var tID = 0;

		var lastData:ArrowData = null;
		var lastSegment:Null<HoldSegmentOutput> = null;

		var canDraw = false;

		final canUseLast = __lastPlayer == player;

		// refresh global mods percents
		__long = canUseLast ? __lastLong : (__lastLong = parent.getPercent('longHolds', player) - parent.getPercent('shortHolds', player) + 1);
		__centered2 = canUseLast ? __lastC2 : (__lastC2 = parent.getPercent('centered2', player));
		__dizzy = canUseLast ? __lastDizzy : (__lastDizzy = parent.getPercent('dizzyHolds', player));
		__straightHolds = canUseLast ? __lastStraightHolds : (__lastStraightHolds = parent.getPercent('straightHolds', player));

		__rotateX = canUseLast ? __lastRX : (__lastRX = parent.getPercent('holdRotateX', player));
		__rotateY = canUseLast ? __lastRY : (__lastRY = parent.getPercent('holdRotateY', player));
		__rotateZ = canUseLast ? __lastRZ : (__lastRZ = parent.getPercent('holdRotateZ', player));

		var parentTime = holdParentTime;
		_parentDataBuf.hitTime = parentTime;
		// this fixed the clipping gaps
		_parentDataBuf.distance = Math.max(0, parentTime - songPosNow);
		_parentDataBuf.sourceTime = parentTime;
		_parentDataBuf.lane = lane;
		_parentDataBuf.player = player;
		_parentDataBuf.hitten = hitten;
		_parentDataBuf.isTapArrow = true;
		_parentDataBuf.straightHolds = __straightHolds > 0;
		final parentData = _parentDataBuf;
		if (__rotateX != 0 || __rotateY != 0 || __rotateZ != 0) {
			__parentOutput = parent.modifiers.getPath(copyVec3(basePos, _pathInputA), parentData);
		}

		var vertPointer = 0;

		final holdIsEnd:Bool = Adapter.instance.isHoldEnd(item);
		final holdHeight:Float = item.width * Config.HOLD_END_SCALE;
		final holdTimeInterval:Float = (Adapter.instance.getHoldLength(item) * (holdIsEnd ? Config.HOLD_END_SCALE : 1.0)) / HOLD_SUBDIVISIONS;
		var timeScale:Float = 1;
		var firstIteration:Bool = true;

		var hasC = false;
		var hasCOff = false;

		for (subIndex in 0...HOLD_SUBDIVISIONS) {
			var holdTimeProgress = holdTimeInterval * subIndex * timeScale;

			var out1:HoldSegmentOutput;
			var out2:HoldSegmentOutput;

			out1 = firstIteration ? getHoldSegment(item, basePos, lastData != null ? lastData : getArrowParams(item, holdTimeProgress)) : lastSegment;
			out2 = getHoldSegment(item, basePos, (lastData = getArrowParams(item, holdTimeProgress + (holdTimeInterval * timeScale))));

			if (firstIteration) {
				item._z = out1.depth;

				if (holdIsEnd) {
					var segmentLength = getSegmentScreenLength(out1, out2);

					if (out1.clipped || out2.clipped) {
						final rawStartSegment = getHoldSegment(item, basePos, getArrowParams(item, holdTimeProgress), false);
						final rawEndSegment = getHoldSegment(item, basePos, getArrowParams(item, holdTimeProgress + holdTimeInterval), false);
						segmentLength = getSegmentScreenLength(rawStartSegment, rawEndSegment);
					}

					if (segmentLength > 0) {
						timeScale = (holdHeight / HOLD_SUBDIVISIONS) / segmentLength;
						out2 = getHoldSegment(item, basePos, (lastData = getArrowParams(item, holdTimeInterval * timeScale)));
					}
				}
			}

			__lastPlayer = player;
			lastSegment = out2;

			if (out1.visuals.alpha > 0)
				canDraw = true;

			var vertPos = (vertPointer++) * 8;
			vertices[vertPos] = out1.left.x;
			vertices[vertPos + 1] = out1.left.y;
			vertices[vertPos + 2] = out1.right.x;
			vertices[vertPos + 3] = out1.right.y;
			vertices[vertPos + 4] = out2.left.x;
			vertices[vertPos + 5] = out2.left.y;
			vertices[vertPos + 6] = out2.right.x;
			vertices[vertPos + 7] = out2.right.y;

			final negGlow = 1 - out1.visuals.glow;
			final absGlow = out1.visuals.glow * 255;

			var ctr = transfTotal[tID++];
			if (ctr == null) {
				ctr = new ColorTransform();
				transfTotal[tID - 1] = ctr;
			}
			ctr.redMultiplier = negGlow;
			ctr.greenMultiplier = negGlow;
			ctr.blueMultiplier = negGlow;
			ctr.alphaMultiplier = out1.visuals.alpha * item.alpha;
			ctr.redOffset = Math.round(out1.visuals.glowR * absGlow);
			ctr.greenOffset = Math.round(out1.visuals.glowG * absGlow);
			ctr.blueOffset = Math.round(out1.visuals.glowB * absGlow);
			ctr.alphaOffset = 0;

			if (ctr.hasRGBMultipliers() || ctr.alphaMultiplier != 1)
				hasC = true;
			if (ctr.hasRGBAOffsets())
				hasCOff = true;

			firstIteration = false;
		}

		if (!canDraw)
			return null;

		var dc:DrawCommand = {
			parent: item,
			graphic: item.graphic,
			antialiasing: item.antialiasing,
			blend: item.blend,
			cameras: ModchartUtil.resolveCameras(parent, item),
			shader: item.shader,

			vertices: vertices,
			uvs: _getCachedUVT(item, HOLD_SUBDIVISIONS),
			indices: _indices,
			colors: transfTotal,
			isColored: hasC,
			hasColorOffsets: hasCOff
		};

		__lastHoldSubs = HOLD_SUBDIVISIONS;

		return dc;
	}

	inline private function getArrowParams(arrow:FlxSprite, posOff:Float = 0):ArrowData {
		final timeC2 = flixel.FlxG.height * 0.25 * __centered2;
		final hitTime = __cachedHoldHitTime;

		var pos = (hitTime - __cachedSongPos) + posOff;
		pos += timeC2;

		// Reuse _holdArrowBuf to avoid a heap allocation per segment.
		_holdArrowBuf.hitTime = hitTime + posOff + timeC2;
		_holdArrowBuf.distance = pos;
		_holdArrowBuf.sourceTime = __cachedHoldParentTime;
		_holdArrowBuf.lane = __cachedHoldLane;
		_holdArrowBuf.player = __cachedHoldPlayer;
		_holdArrowBuf.hitten = __cachedHoldHitten;
		_holdArrowBuf.isTapArrow = true;
		_holdArrowBuf.straightHolds = __straightHolds > 0;
		return _holdArrowBuf;
	}

	override function dispose() {
		_uvtCacheKeys = [];
		_uvtCacheVals = [];
		_holdVerticesPool = new ObjectMap<FlxSprite, openfl.Vector<Float>>();
		_holdColorsPool = new ObjectMap<FlxSprite, NativeVector<ColorTransform>>();
		_holdPoolSubs = new ObjectMap<FlxSprite, Int>();
	}
}