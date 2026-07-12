package modchart.backend.graphics.renderers;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;
import openfl.geom.ColorTransform;
import modchart.engine.modifiers.list.Reverse;

using flixel.util.FlxColorTransformUtil;

// Legacy module-level vector kept only to avoid breaking external references.
var pathVector = new Vector3();

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
final class PathRenderer extends BaseRenderer<FlxSprite> {
	static inline final DEFAULT_PATH_BOUND:Float = 300;
	static inline final BASE_PATH_LIMIT:Float = 1800 + DEFAULT_PATH_BOUND;
	static inline final MAX_ADAPTIVE_DIVISIONS:Int = 512;

	var __lineGraphic:FlxGraphic;
	var __lastDivisions:Int = -1;

	// Shared UVT and index buffers (rebuilt only when divisions change).
	var uvt:openfl.Vector<Float>;
	var indices:openfl.Vector<Int>;

	// Per-lane vertex and color-transform buffers.
	// These persist across frames so DrawCommands can reference them safely
	// (each lane's prepare() overwrites its own slot, never another lane's).
	static final MAX_LANES:Int = 16;
	var _perLaneVertices:Array<openfl.Vector<Float>>;
	var _perLaneTransforms:Array<NativeVector<ColorTransform>>;

	// Shared per-frame sample buffers (only valid during one prepare() call).
	var _px:Array<Float> = [];
	var _py:Array<Float> = [];
	var _pz:Array<Float> = [];
	var _palpha:Array<Float> = [];
	var _pglow:Array<Float> = [];
	var _pglowR:Array<Float> = [];
	var _pglowG:Array<Float> = [];
	var _pglowB:Array<Float> = [];
	var _pscale:Array<Float> = [];
	// Smooth-normal buffers (central-differences, filled during Phase 2).
	var _nx:Array<Float> = [];
	var _ny:Array<Float> = [];

	// Scratch objects reused every iteration to avoid per-sample allocations.
	final _scratch:Vector3 = new Vector3();
	final _paramBuf:ArrowData = {hitTime: 0, distance: 0, sourceTime: 0, lane: 0, player: 0, isTapArrow: true, straightHolds: false};

	public function updateTris(divisions:Int) {
		if (divisions == __lastDivisions)
			return;

		final segs = divisions - 1;

		uvt = new openfl.Vector<Float>(segs * 12, true);
		indices = new openfl.Vector<Int>(segs * 6, true);

		// Rebuild per-lane vertex / CT pools.
		_perLaneVertices = [for (_ in 0...MAX_LANES) new openfl.Vector<Float>(segs * 8, true)];
		_perLaneTransforms = [
			for (_ in 0...MAX_LANES) {
				final nv = new NativeVector<ColorTransform>(segs);
				for (i in 0...segs)
					nv[i] = new ColorTransform();
				nv;
			}
		];

		// Resize shared sample arrays.
		_px.resize(divisions);
		_py.resize(divisions);
		_pz.resize(divisions);
		_palpha.resize(divisions);
		_pglow.resize(divisions);
		_pglowR.resize(divisions);
		_pglowG.resize(divisions);
		_pglowB.resize(divisions);
		_pscale.resize(divisions);
		_nx.resize(divisions);
		_ny.resize(divisions);

		// Fill static UVT and index data.
		var ui = 0, ii = 0, vertCount = 0;
		for (_ in 0...segs) {
			for (__ in 0...4) {
				uvt.set(ui++, 0);
				uvt.set(ui++, 0);
				uvt.set(ui++, 1);
			}
			indices.set(ii++, vertCount);
			indices.set(ii++, vertCount + 1);
			indices.set(ii++, vertCount + 2);
			indices.set(ii++, vertCount + 1);
			indices.set(ii++, vertCount + 3);
			indices.set(ii++, vertCount + 2);
			vertCount += 4;
		}

		__lastDivisions = divisions;
	}

	public function new(parent:PlayField) {
		super(parent);

		__lineGraphic = FlxG.bitmap.create(1, 1, 0xFFFFFFFF, true);
		__lineGraphic.destroyOnNoUse = false;
		__lineGraphic.persist = true;

		// Pre-allocate lane pools with sensible defaults so the first frame works.
		_perLaneVertices = [for (_ in 0...MAX_LANES) new openfl.Vector<Float>(0, true)];
		_perLaneTransforms = [for (_ in 0...MAX_LANES) new NativeVector<ColorTransform>(0)];
	}

	var __lastPlayer:Int = -1;
	var __lastLane:Int = -1;
	var __lastAlpha:Float = 0;
	var __lastThickness:Float = 0;
	var __lastBound:Float = 0;

	private inline function getDefinedPercent(name:String, player:Int):Null<Float> {
		final percs = parent.modifiers.percents.get(name);
		return percs != null ? percs[player] : null;
	}

	private inline function getPathAlpha(player:Int, lane:Int):Float {
		final laneAlpha = getDefinedPercent('path' + lane, player);
		if (laneAlpha != null)
			return laneAlpha;

		final globalAlpha = getDefinedPercent('path', player);
		if (globalAlpha != null)
			return globalAlpha;

		return parent.getPercent('arrowPathAlpha', player);
	}

	private inline function getPathThickness(player:Int, lane:Int):Float {
		final laneThickness = getDefinedPercent('path' + lane + 'thickness', player);
		if (laneThickness != null)
			return laneThickness;

		final laneTickness = getDefinedPercent('path' + lane + 'tickness', player);
		if (laneTickness != null)
			return laneTickness;

		final globalThickness = getDefinedPercent('paththickness', player);
		if (globalThickness != null)
			return globalThickness;

		final globalTickness = getDefinedPercent('pathtickness', player);
		if (globalTickness != null)
			return globalTickness;

		return parent.getPercent('arrowPathThickness', player);
	}

	private inline function getPathBound(player:Int, lane:Int):Float {
		final laneBound = getDefinedPercent('path' + lane + 'bound', player);
		if (laneBound != null)
			return laneBound;

		final globalBound = getDefinedPercent('pathbound', player);
		if (globalBound != null)
			return globalBound;

		// Connect pathBound dynamically with spawnTime for synchronized visual anticipation
		final reverseModifier = parent.modifiers.modifiers.get('reverse');
		if (reverseModifier != null && Std.isOfType(reverseModifier, Reverse)) {
			final spawnTimeMs = cast(reverseModifier, Reverse).getSpawnTime(player);
			final scrollSpeed = Adapter.instance.getCurrentScrollSpeed();
			// Convert spawn time (ms) to visual distance (pixels)
			// scrollSpeed represents pixels per millisecond of note progression
			final dynamicBound = Math.max(spawnTimeMs * scrollSpeed * 0.5, DEFAULT_PATH_BOUND);
			return dynamicBound;
		}

		return DEFAULT_PATH_BOUND;
	}

	private inline function getAdaptiveDivisions(limit:Float):Int {
		final baseDivisions = Std.int(Config.ARROW_PATHS_CONFIG.BASE_DIVISIONS * Config.ARROW_PATHS_CONFIG.RESOLUTION);
		final safeBase = Std.int(Math.max(2, baseDivisions));
		final ratio = BASE_PATH_LIMIT > 0 ? (limit / BASE_PATH_LIMIT) : 1.0;
		final qualityScale = FlxMath.bound(modchart.backend.graphics.CtxRenderer.pathQualityScale, 0.5, 1.0);
		final scaledDivisions = Std.int(Math.ceil(safeBase * Math.max(1.0, ratio) * qualityScale));
		return Std.int(FlxMath.bound(scaledDivisions, 2, MAX_ADAPTIVE_DIVISIONS));
	}

	// The entry sprite should be A RECEPTOR / STRUM.
	override public function prepare(item:FlxSprite):Null<DrawCommand> {
		final lane = Adapter.instance.getLaneFromArrow(item);
		final fn = Adapter.instance.getPlayerFromArrow(item);

		final canUseLast = fn == __lastPlayer && lane == __lastLane;

		final pathAlpha = canUseLast ? __lastAlpha : getPathAlpha(fn, lane);
		final pathThickness = canUseLast ? __lastThickness : getPathThickness(fn, lane);
		final pathBound = canUseLast ? __lastBound : getPathBound(fn, lane);

		if (pathAlpha <= 0 || pathThickness <= 0 || pathBound <= 0)
			return null;

		__lastAlpha = pathAlpha;
		__lastThickness = pathThickness;
		__lastBound = pathBound;
		__lastPlayer = fn;
		__lastLane = lane;

		final limit = 1800 + pathBound;
		final divisions = getAdaptiveDivisions(limit);
		final interval = limit / (divisions - 1); // max point distance = limit (receptor → furthest sample)
		final songPos = Adapter.instance.getSongPosition();
		final segs = divisions - 1;

		updateTris(divisions);

		// Compute receptor base position once (avoid re-alloc in the loop).
		final half = ModchartUtil.getHalfPos();
		final baseX = Adapter.instance.getDefaultReceptorX(lane, fn) + half.x;
		final baseY = Adapter.instance.getDefaultReceptorY(lane, fn) + half.y;
		final baseZ = half.z;

		final colored = Config.ARROW_PATHS_CONFIG.APPLY_COLOR;
		final applyAlpha = Config.ARROW_PATHS_CONFIG.APPLY_ALPHA;
		final applyDepth = Config.ARROW_PATHS_CONFIG.APPLY_DEPTH;
		final applyScale = Config.ARROW_PATHS_CONFIG.APPLY_SCALE;

		// Fill scratch param fields that stay constant across the loop.
		_paramBuf.lane = lane;
		_paramBuf.player = fn;
		_paramBuf.isTapArrow = true;

		// Phase 1: Sample all N positions, storing results in flat arrays.
		// index=0 → distance=0 (exactly at the receptor);
		// index=divisions-1 → distance=limit (furthest point ahead).
		for (index in 0...divisions) {
			final hitTime = interval * index; // [0 .. limit]
			_scratch.x = baseX;
			_scratch.y = baseY;
			_scratch.z = baseZ;
			_paramBuf.hitTime = songPos + hitTime;
			_paramBuf.distance = hitTime;
			_paramBuf.sourceTime = songPos + hitTime;

			final output = parent.modifiers.getPath(_scratch, _paramBuf);

			_px[index] = output.pos.x;
			_py[index] = output.pos.y;
			_pz[index] = output.pos.z; // 1e9 = degenerate / behind camera
			_palpha[index] = applyAlpha ? output.visuals.alpha : 1.0;
			_pglow[index] = colored ? output.visuals.glow : 0.0;
			_pglowR[index] = output.visuals.glowR;
			_pglowG[index] = output.visuals.glowG;
			_pglowB[index] = output.visuals.glowB;
			_pscale[index] = applyScale ? output.visuals.scaleX : 1.0;
		}

		// --- Phase 2: Compute smooth normals via central differences ---
		// Using tangent = p[i+1] - p[i-1] (central difference) at interior points
		// avoids the per-segment zigzag caused by using a single segment direction.
		for (i in 0...divisions) {
			var tx:Float, ty:Float;
			if (i == 0) {
				tx = _px[1] - _px[0];
				ty = _py[1] - _py[0];
			} else if (i == divisions - 1) {
				tx = _px[i] - _px[i - 1];
				ty = _py[i] - _py[i - 1];
			} else {
				tx = _px[i + 1] - _px[i - 1];
				ty = _py[i + 1] - _py[i - 1];
			}
			final len = Math.sqrt(tx * tx + ty * ty);
			if (len > 0.0001) {
				_nx[i] = -ty / len;
				_ny[i] = tx / len;
			} else {
				_nx[i] = 1.0;
				_ny[i] = 0.0;
			}
		}

		// --- Phase 3: Build quads using smooth per-endpoint normals ---
		final laneVerts = _perLaneVertices[lane];
		final laneTrans = _perLaneTransforms[lane];

		var vi = 0;
		var hasC = false;
		var hasCOff = false;

		for (seg in 0...segs) {
			final i0 = seg;
			final i1 = seg + 1;

			// Skip segments touching a degenerate (behind-camera) point.
			final clipped = _pz[i0] > 1e6 || _pz[i1] > 1e6;

			if (clipped) {
				// Emit a zero-area quad at the receptor to keep vertex count stable.
				final rx = _px[0];
				final ry = _py[0];
				laneVerts.set(vi++, rx);
				laneVerts.set(vi++, ry);
				laneVerts.set(vi++, rx);
				laneVerts.set(vi++, ry);
				laneVerts.set(vi++, rx);
				laneVerts.set(vi++, ry);
				laneVerts.set(vi++, rx);
				laneVerts.set(vi++, ry);
				final ctr = laneTrans[seg];
				ctr.redMultiplier = 1;
				ctr.greenMultiplier = 1;
				ctr.blueMultiplier = 1;
				ctr.alphaMultiplier = 0; // fully transparent
				ctr.redOffset = 0;
				ctr.greenOffset = 0;
				ctr.blueOffset = 0;
				ctr.alphaOffset = 0;
				hasC = true; // need isColored to apply alpha=0
				continue;
			}

			final t0 = pathThickness * _pscale[i0] * (applyDepth ? 1.0 / _pz[i0] : 1.0) * 0.5;
			final t1 = pathThickness * _pscale[i1] * (applyDepth ? 1.0 / _pz[i1] : 1.0) * 0.5;

			// Use the smooth normal at each endpoint for a clean miter join.
			final a1x = _px[i0] + _nx[i0] * t0;
			final a1y = _py[i0] + _ny[i0] * t0;
			final a2x = _px[i0] - _nx[i0] * t0;
			final a2y = _py[i0] - _ny[i0] * t0;
			final b1x = _px[i1] + _nx[i1] * t1;
			final b1y = _py[i1] + _ny[i1] * t1;
			final b2x = _px[i1] - _nx[i1] * t1;
			final b2y = _py[i1] - _ny[i1] * t1;

			laneVerts.set(vi++, a1x);
			laneVerts.set(vi++, a1y);
			laneVerts.set(vi++, a2x);
			laneVerts.set(vi++, a2y);
			laneVerts.set(vi++, b1x);
			laneVerts.set(vi++, b1y);
			laneVerts.set(vi++, b2x);
			laneVerts.set(vi++, b2y);

			final glow = _pglow[i0];
			final fAlpha = _palpha[i0] * pathAlpha;
			final negGlow = 1.0 - glow;
			final absGlow = glow * 255.0;

			final ctr = laneTrans[seg];
			ctr.redMultiplier = negGlow;
			ctr.greenMultiplier = negGlow;
			ctr.blueMultiplier = negGlow;
			ctr.alphaMultiplier = fAlpha;
			ctr.redOffset = Math.round(_pglowR[i0] * absGlow);
			ctr.greenOffset = Math.round(_pglowG[i0] * absGlow);
			ctr.blueOffset = Math.round(_pglowB[i0] * absGlow);

			if (ctr.hasRGBMultipliers() || ctr.alphaMultiplier != 1)
				hasC = true;
			if (ctr.hasRGBAOffsets())
				hasCOff = true;
		}

		return {
			parent: item,
			graphic: __lineGraphic,
			antialiasing: false,
			blend: NORMAL,
			cameras: ModchartUtil.resolveCameras(parent, item),
			shader: null,

			vertices: laneVerts,
			uvs: uvt,
			indices: indices,
			colors: laneTrans,
			isColored: hasC,
			hasColorOffsets: hasCOff
		};
	}

	override function dispose() {
		__lineGraphic.destroy();
		__lineGraphic = null;
	}
}