package modchart.backend.graphics.renderers;

using flixel.util.FlxColorTransformUtil;

private final class HoldSegmentOutput {
	public final origin:Vector3 = new Vector3();
	public final left:Vector3 = new Vector3();
	public final right:Vector3 = new Vector3();
	public final modifierPos:Vector3 = new Vector3();
	public var visuals:VisualParameters = {};
	public final modifierOutput:ModifierOutput;
	public var depth:Float = 0;
	public var clipped:Bool = false;

	public function new() {
		modifierOutput = {pos: modifierPos, visuals: visuals};
	}
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
	public var collectDebugStats:Bool = false;

	var _indices:openfl.Vector<Int>;
	var _indicesBySubs:Array<openfl.Vector<Int>> = [];
	final _segmentA:HoldSegmentOutput = new HoldSegmentOutput();
	final _segmentB:HoldSegmentOutput = new HoldSegmentOutput();
	final _rawSegmentA:HoldSegmentOutput = new HoldSegmentOutput();
	final _rawSegmentB:HoldSegmentOutput = new HoldSegmentOutput();
	final _probeStart:HoldSegmentOutput = new HoldSegmentOutput();
	final _probeMid:HoldSegmentOutput = new HoldSegmentOutput();
	final _probeEnd:HoldSegmentOutput = new HoldSegmentOutput();
	final _directionPos:Vector3 = new Vector3();
	final _directionVisuals:VisualParameters = {};
	final _directionOutput:ModifierOutput;
	final _rotationScratch:Vector3 = new Vector3();
	final _viewScratch:Vector3 = new Vector3();
	final _tailScratch:Vector3 = new Vector3();
	final _basePos:Vector3 = new Vector3();
	final _parentPos:Vector3 = new Vector3();
	final _parentVisuals:VisualParameters = {};
	final _parentOutputBuffer:ModifierOutput;

	// UVT cache: avoids re-computing identical UV data every frame for the same hold tile
	var _uvtCacheKeys:Array<Dynamic> = [];
	var _uvtCacheSubsKeys:Array<Int> = [];
	var _uvtCacheVals:Array<openfl.Vector<Float>> = [];

	// Frame slots mirror ArrowRenderer: memory follows peak simultaneous holds,
	// never every Note object that existed during the song.
	var _slots:Array<HoldRenderSlot> = [];
	var _slotIndex:Int = 0;
	public var dbgSlotsReused(default, null):Int = 0;

	public inline function beginFrame():Void {
		_slotIndex = 0;
		dbgGetPathCalls = 0;
		dbgSlotsReused = 0;
	}

	inline private function nextSlot(subs:Int):HoldRenderSlot {
		if (_slotIndex >= _slots.length)
			_slots.push(new HoldRenderSlot());
		else if (collectDebugStats)
			dbgSlotsReused++;
		final slot = _slots[_slotIndex++];
		slot.ensureCapacity(subs);
		return slot;
	}

	private function _getCachedUVT(item:FlxSprite, subs:Int):openfl.Vector<Float> {
		final frame = item.frame;
		for (i in 0..._uvtCacheKeys.length)
			if (_uvtCacheKeys[i] == frame && _uvtCacheSubsKeys[i] == subs)
				return _uvtCacheVals[i];
		final uvt:openfl.Vector<Float> = ModchartUtil.getHoldUVT(item, subs);
		_uvtCacheKeys.push(frame);
		_uvtCacheSubsKeys.push(subs);
		_uvtCacheVals.push(uvt);
		return uvt;
	}

	public function new(parent:PlayField) {
		super(parent);
		_directionOutput = {pos: _directionPos, visuals: _directionVisuals};
		_parentOutputBuffer = {pos: _parentPos, visuals: _parentVisuals};

		parent.setPercent('dizzyHolds', 1, -1);
	}

	inline private function __rotateTailInto(pos:Vector3):Vector3 {
		if (__parentOutput == null || (__rotateX == 0 && __rotateY == 0 && __rotateZ == 0))
			return pos;

		_tailScratch.setTo(pos.x - __parentOutput.rawX, pos.y - __parentOutput.rawY, pos.z - __parentOutput.rawZ);
		ModchartUtil.rotate3DVectorInto(_tailScratch, __rotateX, __rotateY, __rotateZ, _tailScratch);
		pos.setTo(__parentOutput.rawX + _tailScratch.x, __parentOutput.rawY + _tailScratch.y, __parentOutput.rawZ + _tailScratch.z);
		return pos;
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

	inline private function midpointError(start:Vector3, middle:Vector3, end:Vector3):Float {
		final dx = middle.x - (start.x + end.x) * 0.5;
		final dy = middle.y - (start.y + end.y) * 0.5;
		return Math.sqrt(dx * dx + dy * dy);
	}

	inline private function visualDifference(a:VisualParameters, b:VisualParameters):Float {
		return Math.max(Math.abs(a.alpha - b.alpha), Math.max(Math.abs(a.glow - b.glow),
			Math.max(Math.abs(a.glowR - b.glowR), Math.max(Math.abs(a.glowG - b.glowG), Math.abs(a.glowB - b.glowB)))));
	}

	/**
	 * Returns the normal points along the hold path at specific hitTime using.
	 *
	 * Based on schmovin' hold system
	 * @param basePos The hold position per default
	 * @see https://en.wikipedia.org/wiki/Unit_circle
	 */
	@:noCompletion
	inline private function getHoldSegmentInto(hold:FlxSprite, basePos:Vector3, params:ArrowData, dest:HoldSegmentOutput, doClip:Bool = true):HoldSegmentOutput {
		@:privateAccess
		final holdIsEnd = Adapter.instance.isHoldEnd(hold);
		var holdTime = params.hitTime;
		var parentTime = Adapter.instance.getHoldParentTime(hold);
		var clipped = false;

		var holdDistance = params.distance;
		var parentDistance = Math.max(0, parentTime - __cachedSongPos);

		params.hitTime = FlxMath.lerp(parentTime, holdTime, __long);
		params.distance = FlxMath.lerp(parentDistance, holdDistance, __long);

		// not this
		if (doClip && params.hitten && params.distance < 0) {
			params.distance = 0;
			clipped = true;
		}

		final size = hold.frame.frame.width * hold.scale.x * .5;

		if (collectDebugStats) dbgGetPathCalls++;
		var origin:ModifierOutput = parent.getNotePathInto(copyVec3(basePos, _pathInputA), params, dest.modifierOutput, dest.modifierPos, dest.visuals);
		dest.visuals = origin.visuals;
		final curPoint = dest.origin;
		curPoint.setTo(origin.pos.x, origin.pos.y, 0);
		final depth = (origin.pos.z - 1) * 1000;
		final worldX = origin.rawX;
		final worldY = origin.rawY;
		final worldZ = origin.rawZ;

		// before this, bc it fails with optimiz eholds too
		var unitX = 0.0;
		var unitY = 1.0;

		if (Config.OPTIMIZE_HOLDS) {
			unitX = __holdUnitUp.x;
			unitY = __holdUnitUp.y;
		} else {
			if (collectDebugStats) dbgGetPathCalls++;
			final next = parent.getNotePathInto(copyVec3(basePos, _pathInputB), params, _directionOutput, _directionPos, _directionVisuals, 1, false, true);
			unitX = next.pos.x - curPoint.x;
			unitY = next.pos.y - curPoint.y;
			final unitLength = Math.sqrt(unitX * unitX + unitY * unitY);
			if (unitLength > 0.000001) { unitX /= unitLength; unitY /= unitLength; }
			else { unitX = 0; unitY = 1; }
		}

		final quad0 = dest.left;
		final quad1 = dest.right;
		quad0.setTo(-unitY * size, unitX * size, 0);
		quad1.setTo(unitY * size, -unitX * size, 0);

		final visuals = origin.visuals;
		final visualScaleY = holdIsEnd ? Math.min(visuals.scaleY, 1.15) : visuals.scaleY;
		@:privateAccess
		for (i in 0...2) {
			var quad = i == 0 ? quad0 : quad1;
			var rotation = quad;
			if (__dizzy != 0)
				rotation = ModchartUtil.rotate3DVectorInto(quad, 0, visuals.angleY * __dizzy, 0, _rotationScratch);

			if (visuals.skewX != 0 || visuals.skewY != 0) {
				__matrix.identity();

				__matrix.b = ModchartUtil.tan(visuals.skewY * FlxAngle.TO_RAD);
				__matrix.c = ModchartUtil.tan(visuals.skewX * FlxAngle.TO_RAD);

				rotation.x = __matrix.__transformX(rotation.x, rotation.y);
				rotation.y = __matrix.__transformY(rotation.x, rotation.y);
			}
			rotation.x = rotation.x * visuals.scaleX;
			rotation.y = rotation.y * visualScaleY;

			_viewScratch.setTo(rotation.x + worldX, rotation.y + worldY, worldZ + (rotation.z * 0.001 * Config.Z_SCALE));
			__rotateTailInto(_viewScratch);

			// The result of the perspective projection of rotation
			var projection = this.view.transformVector(_viewScratch);
			quad.x = projection.x;
			quad.y = projection.y;
			quad.z = projection.z;
		}

		dest.depth = depth;
		dest.clipped = clipped;
		return dest;
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
		if (subdivisionCount < _indicesBySubs.length && _indicesBySubs[subdivisionCount] != null) {
			_indices = _indicesBySubs[subdivisionCount];
			return;
		}
		_indices = new openfl.Vector<Int>(subdivisionCount * 6, true);
		while (_indicesBySubs.length <= subdivisionCount)
			_indicesBySubs.push(null);
		_indicesBySubs[subdivisionCount] = _indices;

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

	// Player-local modifier values reused across consecutive holds.
	var __lastPlayer:Int = -1;

	/** Pre-allocated ArrowData buffer reused by getArrowParams() to avoid per-segment heap allocation. */
	final _holdArrowBuf:ArrowData = {
		hitTime: 0,
		distance: 0,
		sourceTime: 0,
		lane: 0,
		player: 0,
		hitten: false,
		isTapArrow: false,
		straightHolds: false,
		isHoldBody: true
	};
	/** Pre-allocated ArrowData buffer for parentData (rotate path) to avoid per-hold heap allocation. */
	final _parentDataBuf:ArrowData = {
		hitTime: 0,
		distance: 0,
		sourceTime: 0,
		lane: 0,
		player: 0,
		hitten: false,
		isTapArrow: false,
		straightHolds: false,
		isHoldBody: false
	};
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

		final REQUESTED_SUBDIVISIONS = Std.int(Math.max(1, Adapter.instance.getHoldSubdivisions(item)));

		final player = Adapter.instance.getPlayerFromArrow(item);
		final lane = Adapter.instance.getLaneFromArrow(item);
		final hitten = Adapter.instance.arrowHit(item);
		final holdHitTime = Adapter.instance.getTimeFromArrow(item);
		final holdParentTime = Adapter.instance.getHoldParentTime(item);
		final songPosNow = parent.state.songPosition;

		__cachedHoldPlayer = player;
		__cachedHoldLane = lane;
		__cachedHoldHitTime = holdHitTime;
		__cachedHoldParentTime = holdParentTime;
		__cachedHoldHitten = hitten;
		__cachedSongPos = songPosNow;

		basePos = _basePos;
		basePos.setTo(Adapter.instance.getDefaultReceptorX(lane, player) + Manager.ARROW_SIZEDIV2,
			Adapter.instance.getDefaultReceptorY(lane, player) + Manager.ARROW_SIZEDIV2, 0);

		final holdIsEnd:Bool = Adapter.instance.isHoldEnd(item);
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
		_parentDataBuf.isHoldBody = false;
		final parentData = _parentDataBuf;
		if (__rotateX != 0 || __rotateY != 0 || __rotateZ != 0) {
			if (collectDebugStats) dbgGetPathCalls++;
			__parentOutput = parent.getNotePathInto(copyVec3(basePos, _pathInputA), parentData, _parentOutputBuffer, _parentPos, _parentVisuals);
		} else __parentOutput = null;

		final holdHeight:Float = item.width * Config.HOLD_END_SCALE;
		final fullHoldTime:Float = Adapter.instance.getHoldLength(item) * (holdIsEnd ? Config.HOLD_END_SCALE : 1.0);
		var HOLD_SUBDIVISIONS = REQUESTED_SUBDIVISIONS;
		var useAdaptiveEndpoints = false;
		if (!holdIsEnd && REQUESTED_SUBDIVISIONS > 1) {
			getHoldSegmentInto(item, basePos, getArrowParams(item, 0), _probeStart);
			getHoldSegmentInto(item, basePos, getArrowParams(item, fullHoldTime * 0.5), _probeMid);
			getHoldSegmentInto(item, basePos, getArrowParams(item, fullHoldTime), _probeEnd);
			final geometryError = Math.max(midpointError(_probeStart.left, _probeMid.left, _probeEnd.left),
				midpointError(_probeStart.right, _probeMid.right, _probeEnd.right));
			final visualsStable = visualDifference(_probeStart.visuals, _probeMid.visuals) <= (1.0 / 255.0)
				&& visualDifference(_probeStart.visuals, _probeEnd.visuals) <= (1.0 / 255.0);
			if (_probeStart.clipped == _probeMid.clipped && _probeMid.clipped == _probeEnd.clipped
				&& geometryError <= 0.75 && visualsStable) {
				HOLD_SUBDIVISIONS = 1;
				useAdaptiveEndpoints = true;
			}
		}

		if (HOLD_SUBDIVISIONS != __lastHoldSubs)
			updateIndices(HOLD_SUBDIVISIONS);
		final slot = nextSlot(HOLD_SUBDIVISIONS);
		var vertices = slot.vertices;
		var transfTotal = slot.colors;
		var tID = 0;
		var vertPointer = 0;
		final holdTimeInterval:Float = fullHoldTime / HOLD_SUBDIVISIONS;
		var timeScale:Float = 1;
		var firstIteration:Bool = true;

		var hasC = false;
		var hasCOff = false;
		var nextSegment = _segmentA;
		var spareSegment = _segmentB;

		for (subIndex in 0...HOLD_SUBDIVISIONS) {
			var holdTimeProgress = holdTimeInterval * subIndex * timeScale;

			var out1:HoldSegmentOutput;
			var out2:HoldSegmentOutput;

			if (firstIteration && useAdaptiveEndpoints) {
				out1 = _probeStart;
				out2 = _probeEnd;
			} else {
				out1 = firstIteration ? getHoldSegmentInto(item, basePos, lastData != null ? lastData : getArrowParams(item, holdTimeProgress), nextSegment) : lastSegment;
				out2 = getHoldSegmentInto(item, basePos, (lastData = getArrowParams(item, holdTimeProgress + (holdTimeInterval * timeScale))), spareSegment);
			}

			if (firstIteration) {
				item._z = out1.depth;

				if (holdIsEnd) {
					var segmentLength = getSegmentScreenLength(out1, out2);

					if (out1.clipped || out2.clipped) {
						final rawStartSegment = getHoldSegmentInto(item, basePos, getArrowParams(item, holdTimeProgress), _rawSegmentA, false);
						final rawEndSegment = getHoldSegmentInto(item, basePos, getArrowParams(item, holdTimeProgress + holdTimeInterval), _rawSegmentB, false);
						segmentLength = getSegmentScreenLength(rawStartSegment, rawEndSegment);
					}

					if (segmentLength > 0) {
						final rawTimeScale = (holdHeight / HOLD_SUBDIVISIONS) / segmentLength;
						// A cap may compress to fit a short projected segment, but never
						// stretches past its authored length (the old 1.15 cap looked gummy).
						timeScale = Math.min(rawTimeScale, 1.0);
						out2 = getHoldSegmentInto(item, basePos, (lastData = getArrowParams(item, holdTimeInterval * timeScale)), spareSegment);
					}
				}
			}

			__lastPlayer = player;
			lastSegment = out2;
			final swapSegment = nextSegment;
			nextSegment = spareSegment;
			spareSegment = swapSegment;

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

		final dc = slot.command;
		dc.parent = item;
		dc.graphic = item.graphic;
		dc.antialiasing = item.antialiasing;
		dc.blend = item.blend;
		dc.cameras = ModchartUtil.resolveCameras(parent, item, slot.cameras);
		dc.shader = item.shader;
		dc.vertices = vertices;
		dc.uvs = _getCachedUVT(item, HOLD_SUBDIVISIONS);
		dc.indices = _indices;
		dc.color = null;
		dc.colors = transfTotal;
		dc.isColored = hasC;
		dc.hasColorOffsets = hasCOff;
		dc.zIndex = 0;

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
		_holdArrowBuf.isHoldBody = true;
		return _holdArrowBuf;
	}

	override function dispose() {
		_uvtCacheKeys = [];
		_uvtCacheSubsKeys = [];
		_uvtCacheVals = [];
		_indicesBySubs = [];
		_slots.resize(0);
	}
}

private class HoldRenderSlot {
	public var vertices:openfl.Vector<Float> = new openfl.Vector<Float>(0, true);
	public var colors:NativeVector<ColorTransform> = new NativeVector<ColorTransform>(0);
	public final cameras:Array<FlxCamera> = [];
	public final command:DrawCommand;
	var capacity:Int = 0;

	public function new() {
		command = {parent: null, graphic: null, antialiasing: false, blend: null, shader: null, cameras: cameras,
			vertices: vertices, uvs: null, indices: null, isColored: false, hasColorOffsets: false, color: null, colors: colors, zIndex: 0};
	}

	public function ensureCapacity(subs:Int):Void {
		if (subs == capacity)
			return;
		capacity = subs;
		vertices = new openfl.Vector<Float>(capacity * 8, true);
		colors = new NativeVector<ColorTransform>(capacity);
		for (i in 0...capacity) colors[i] = new ColorTransform();
	}
}
