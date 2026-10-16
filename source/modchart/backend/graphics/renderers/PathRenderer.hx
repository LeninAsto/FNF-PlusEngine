package modchart.backend.graphics.renderers;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxMath;
import openfl.display.BitmapData;
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
	static inline final MIN_PATH_SEGMENTS:Int = 2;
	static inline final MAX_PATH_SEGMENTS:Int = 96;
	static inline final CURVE_ERROR_TOLERANCE:Float = 0.75;

	var __lineGraphic:FlxGraphic;

	// Per-lane geometry buffers. They must not be shared: commands for several
	// lanes coexist in the same frame and may use different adaptive resolutions.
	// These persist across frames so DrawCommands can reference them safely
	// (each lane's prepare() overwrites its own slot, never another lane's).
	static final MAX_LANES:Int = 16;
	var _perLaneVertices:Array<openfl.Vector<Float>>;
	var _perLaneUVT:Array<openfl.Vector<Float>>;
	var _perLaneIndices:Array<openfl.Vector<Int>>;
	var _perLaneTransforms:Array<NativeVector<ColorTransform>>;
	var _perLaneDivisions:Array<Int>;
	var _nextLaneDivisions:Array<Int>;
	var _commands:Array<DrawCommand>;
	var _pathCameras:Array<Array<FlxCamera>>;

	// Percent IDs are resolved once. Path visibility is checked every frame, so
	// rebuilding names such as `path3thickness` in that hot path is needless GC.
	var _pathID:Int;
	var _pathThicknessID:Int;
	var _pathTicknessID:Int;
	var _pathBoundID:Int;
	var _arrowPathAlphaID:Int;
	var _arrowPathThicknessID:Int;
	var _lanePathIDs:Array<Int>;
	var _laneThicknessIDs:Array<Int>;
	var _laneTicknessIDs:Array<Int>;
	var _laneBoundIDs:Array<Int>;

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
	final _outputPos:Vector3 = new Vector3();
	final _outputVisuals:VisualParameters = {};
	final _output:ModifierOutput;
	final _paramBuf:ArrowData = {
		hitTime: 0,
		distance: 0,
		sourceTime: 0,
		lane: 0,
		player: 0,
		isTapArrow: true,
		straightHolds: false,
		isHoldBody: false
	};

	private function updateTris(laneSlot:Int, divisions:Int):Void {
		if (_perLaneDivisions[laneSlot] == divisions)
			return;

		final segs = divisions - 1;
		final uvt = new openfl.Vector<Float>(segs * 12, true);
		final indices = new openfl.Vector<Int>(segs * 6, true);
		final transforms = new NativeVector<ColorTransform>(segs);

		_perLaneVertices[laneSlot] = new openfl.Vector<Float>(segs * 8, true);
		_perLaneUVT[laneSlot] = uvt;
		_perLaneIndices[laneSlot] = indices;
		_perLaneTransforms[laneSlot] = transforms;
		_perLaneDivisions[laneSlot] = divisions;

		// The 4px texture is transparent at its sides and opaque in its centre.
		// Mapping U across the width gives cheap edge smoothing without extra path
		// geometry or an expensive shader.
		var ui = 0, ii = 0, vertCount = 0;
		for (i in 0...segs) {
			transforms[i] = new ColorTransform();
			for (u in [0.0, 1.0, 0.0, 1.0]) {
				uvt.set(ui++, u);
				uvt.set(ui++, 0.5);
				uvt.set(ui++, 1.0);
			}
			indices.set(ii++, vertCount);
			indices.set(ii++, vertCount + 1);
			indices.set(ii++, vertCount + 2);
			indices.set(ii++, vertCount + 1);
			indices.set(ii++, vertCount + 3);
			indices.set(ii++, vertCount + 2);
			vertCount += 4;
		}
	}

	private inline function ensureSampleCapacity(divisions:Int):Void {
		if (_px.length >= divisions)
			return;
		_px.resize(divisions); _py.resize(divisions); _pz.resize(divisions);
		_palpha.resize(divisions); _pglow.resize(divisions);
		_pglowR.resize(divisions); _pglowG.resize(divisions); _pglowB.resize(divisions);
		_pscale.resize(divisions); _nx.resize(divisions); _ny.resize(divisions);
	}

	public function new(parent:PlayField) {
		super(parent);
		_output = {pos: _outputPos, visuals: _outputVisuals};

		final lineBitmap = new BitmapData(4, 1, true, 0xFFFFFFFF);
		lineBitmap.setPixel32(0, 0, 0x00FFFFFF);
		lineBitmap.setPixel32(3, 0, 0x00FFFFFF);
		__lineGraphic = FlxG.bitmap.add(lineBitmap, true);
		__lineGraphic.destroyOnNoUse = false;
		__lineGraphic.persist = true;

		// Start at 16 segments: enough to detect curves on the first frame, then
		// each lane independently settles toward 8..96 segments.
		_perLaneVertices = [for (_ in 0...MAX_LANES) new openfl.Vector<Float>(0, true)];
		_perLaneUVT = [for (_ in 0...MAX_LANES) new openfl.Vector<Float>(0, true)];
		_perLaneIndices = [for (_ in 0...MAX_LANES) new openfl.Vector<Int>(0, true)];
		_perLaneTransforms = [for (_ in 0...MAX_LANES) new NativeVector<ColorTransform>(0)];
		_perLaneDivisions = [for (_ in 0...MAX_LANES) 0];
		_nextLaneDivisions = [for (_ in 0...MAX_LANES) 17];
		_pathCameras = [for (_ in 0...MAX_LANES) []];
		_commands = [for (lane in 0...MAX_LANES) {
			parent: null, graphic: null, antialiasing: true, blend: NORMAL, shader: null, cameras: _pathCameras[lane],
			vertices: null, uvs: null, indices: null, isColored: false, hasColorOffsets: false,
			color: null, colors: null, zIndex: 0
		}];

		final percents = parent.modifiers.percents;
		_pathID = percents.getID('path');
		_pathThicknessID = percents.getID('paththickness');
		_pathTicknessID = percents.getID('pathtickness');
		_pathBoundID = percents.getID('pathbound');
		_arrowPathAlphaID = percents.getID('arrowPathAlpha');
		_arrowPathThicknessID = percents.getID('arrowPathThickness');
		_lanePathIDs = [for (lane in 0...MAX_LANES) percents.getID('path$lane')];
		_laneThicknessIDs = [for (lane in 0...MAX_LANES) percents.getID('path${lane}thickness')];
		_laneTicknessIDs = [for (lane in 0...MAX_LANES) percents.getID('path${lane}tickness')];
		_laneBoundIDs = [for (lane in 0...MAX_LANES) percents.getID('path${lane}bound')];
	}

	var __lastPlayer:Int = -1;
	var __lastLane:Int = -1;
	var __lastAlpha:Float = 0;
	var __lastThickness:Float = 0;
	var __lastBound:Float = 0;

	private inline function getDefinedPercent(id:Int, player:Int):Null<Float> {
		final percs = parent.modifiers.percents.getUnsafe(id);
		return percs != null ? percs[player] : null;
	}

	private inline function getMirroredPercent(id:Int, player:Int):Null<Float> {
		final current = getDefinedPercent(id, player);
		if (current != null)
			return current;

		final otherPlayer = player == 0 ? 1 : 0;
		return getDefinedPercent(id, otherPlayer);
	}

	private inline function getPathAlpha(player:Int, lane:Int):Float {
		final laneAlpha = lane >= 0 && lane < MAX_LANES ? getMirroredPercent(_lanePathIDs[lane], player) : null;
		if (laneAlpha != null)
			return laneAlpha;

		final globalAlpha = getMirroredPercent(_pathID, player);
		if (globalAlpha != null)
			return globalAlpha;

		final mirroredArrowPathAlpha = getMirroredPercent(_arrowPathAlphaID, player);
		return mirroredArrowPathAlpha != null ? mirroredArrowPathAlpha : parent.getPercent('arrowPathAlpha', player);
	}

	private inline function getPathThickness(player:Int, lane:Int):Float {
		final laneThickness = lane >= 0 && lane < MAX_LANES ? getMirroredPercent(_laneThicknessIDs[lane], player) : null;
		if (laneThickness != null)
			return laneThickness;

		final laneTickness = lane >= 0 && lane < MAX_LANES ? getMirroredPercent(_laneTicknessIDs[lane], player) : null;
		if (laneTickness != null)
			return laneTickness;

		final globalThickness = getMirroredPercent(_pathThicknessID, player);
		if (globalThickness != null)
			return globalThickness;

		final globalTickness = getMirroredPercent(_pathTicknessID, player);
		if (globalTickness != null)
			return globalTickness;

		final mirroredArrowPathThickness = getMirroredPercent(_arrowPathThicknessID, player);
		return mirroredArrowPathThickness != null ? mirroredArrowPathThickness : parent.getPercent('arrowPathThickness', player);
	}

	private inline function getPathBound(player:Int, lane:Int):Float {
		var requested:Null<Float> = null;
		final laneBound = lane >= 0 && lane < MAX_LANES ? getMirroredPercent(_laneBoundIDs[lane], player) : null;
		if (laneBound != null)
			requested = laneBound;

		if (requested == null) {
			final globalBound = getMirroredPercent(_pathBoundID, player);
			if (globalBound != null)
				requested = globalBound;
		}

		// A path describes the same future window as spawned notes. Never draw or
		// transform samples beyond spawnTime: besides looking too long, those points
		// are clamped by Reverse and only waste CPU in an overlapping tail.
		final reverseModifier = parent.modifiers.modifiers.get('reverse');
		if (reverseModifier != null && Std.isOfType(reverseModifier, Reverse)) {
			final spawnTimeMs = cast(reverseModifier, Reverse).getSpawnTime(player);
			if (requested != null && requested > 0)
				return Math.min(requested, spawnTimeMs);
			return spawnTimeMs;
		}

		return requested != null ? requested : DEFAULT_PATH_BOUND;
	}

	public function hasVisiblePath():Bool {
		final players = Adapter.instance.getPlayerCount();
		for (player in 0...players) {
			final keys = Adapter.instance.getKeyCount(player);
			for (lane in 0...keys)
				if (getPathAlpha(player, lane) > 0 && getPathThickness(player, lane) > 0 && getPathBound(player, lane) > 0)
					return true;
		}
		return false;
	}

	private inline function getAdaptiveDivisions(laneSlot:Int):Int {
		final qualityScale = FlxMath.bound(modchart.backend.graphics.CtxRenderer.pathQualityScale, 0.5, 1.0);
		final maxSegments = Std.int(Math.max(MIN_PATH_SEGMENTS, Math.floor(MAX_PATH_SEGMENTS * qualityScale)));
		final segments = Std.int(FlxMath.bound(_nextLaneDivisions[laneSlot] - 1, MIN_PATH_SEGMENTS, maxSegments));
		return segments + 1;
	}

	private function updateAdaptiveDivisions(laneSlot:Int, divisions:Int, pathThickness:Float, applyDepth:Bool):Bool {
		final segs = divisions - 1;
		var maxError = 0.0;

		// Screen-space second difference: zero means the transformed path is a
		// straight line, while larger values reveal bends that need more samples.
		for (i in 1...(divisions - 1)) {
			if (_pz[i - 1] > 1e6 || _pz[i] > 1e6 || _pz[i + 1] > 1e6)
				continue;
			final dx = _px[i] - ((_px[i - 1] + _px[i + 1]) * 0.5);
			final dy = _py[i] - ((_py[i - 1] + _py[i + 1]) * 0.5);
			final error = Math.sqrt(dx * dx + dy * dy);
			if (error > maxError)
				maxError = error;
		}

		var stylesStable = true;
		for (i in 1...divisions) {
			if (Math.abs(_palpha[i] - _palpha[0]) > (1.0 / 255.0)
				|| Math.abs(_pglow[i] - _pglow[0]) > (1.0 / 255.0)
				|| Math.abs(_pglowR[i] - _pglowR[0]) > (1.0 / 255.0)
				|| Math.abs(_pglowG[i] - _pglowG[0]) > (1.0 / 255.0)
				|| Math.abs(_pglowB[i] - _pglowB[0]) > (1.0 / 255.0)
				|| Math.abs(_pscale[i] - _pscale[0]) > 0.001) {
				stylesStable = false;
				break;
			}
		}
		var widthError = 0.0;
		if (_pz[0] <= 1e6 && _pz[divisions - 1] <= 1e6) {
			final firstWidth = pathThickness * _pscale[0] * (applyDepth ? 1.0 / _pz[0] : 1.0) * 0.5;
			final lastWidth = pathThickness * _pscale[divisions - 1] * (applyDepth ? 1.0 / _pz[divisions - 1] : 1.0) * 0.5;
			for (i in 1...(divisions - 1)) {
				if (_pz[i] > 1e6)
					continue;
				final ratio = i / (divisions - 1);
				final actualWidth = pathThickness * _pscale[i] * (applyDepth ? 1.0 / _pz[i] : 1.0) * 0.5;
				final expectedWidth = firstWidth + (lastWidth - firstWidth) * ratio;
				widthError = Math.max(widthError, Math.abs(actualWidth - expectedWidth));
			}
		}

		final qualityScale = FlxMath.bound(modchart.backend.graphics.CtxRenderer.pathQualityScale, 0.5, 1.0);
		final tolerance = CURVE_ERROR_TOLERANCE / qualityScale;
		final isStraight = maxError <= tolerance && widthError <= tolerance && stylesStable;
		var targetSegments = isStraight
			? MIN_PATH_SEGMENTS
			: Std.int(Math.ceil(segs * Math.sqrt(maxError / tolerance)));
		final maxSegments = Std.int(Math.max(MIN_PATH_SEGMENTS, Math.floor(MAX_PATH_SEGMENTS * qualityScale)));
		targetSegments = Std.int(FlxMath.bound(targetSegments, MIN_PATH_SEGMENTS, maxSegments));

		// Quantizing avoids buffer churn when an animated curve changes by tiny
		// fractions each frame. Increase immediately; reduce one step at a time.
		if (!isStraight)
			targetSegments = Std.int(Math.ceil(targetSegments / 8.0)) * 8;
		if (targetSegments < segs)
			targetSegments = Std.int(Math.max(targetSegments, segs - 8));
		_nextLaneDivisions[laneSlot] = targetSegments + 1;
		return isStraight;
	}

	// The entry sprite should be A RECEPTOR / STRUM.
	override public function prepare(item:FlxSprite):Null<DrawCommand> {
		final lane = Adapter.instance.getLaneFromArrow(item);
		final fn = Adapter.instance.getPlayerFromArrow(item);
		final laneSlot = lane >= 0 ? ((fn * 8) + lane) % MAX_LANES : 0;

		final pathAlpha = getPathAlpha(fn, lane);
		final pathThickness = getPathThickness(fn, lane);
		final pathBound = getPathBound(fn, lane);

		if (pathAlpha <= 0 || pathThickness <= 0 || pathBound <= 0)
			return null;

		final limit = pathBound;
		final divisions = getAdaptiveDivisions(laneSlot);
		final interval = limit / (divisions - 1); // max point distance = limit (receptor → furthest sample)
		final songPos = parent.state.songPosition;
		final segs = divisions - 1;

		ensureSampleCapacity(divisions);

		// Compute receptor base position once (avoid re-alloc in the loop).
		final baseX = Adapter.instance.getDefaultReceptorX(lane, fn) + Manager.ARROW_SIZEDIV2;
		final baseY = Adapter.instance.getDefaultReceptorY(lane, fn) + Manager.ARROW_SIZEDIV2;
		final baseZ = 0.0;

		final colored = Config.ARROW_PATHS_CONFIG.APPLY_COLOR;
		final applyAlpha = Config.ARROW_PATHS_CONFIG.APPLY_ALPHA;
		final applyDepth = Config.ARROW_PATHS_CONFIG.APPLY_DEPTH;
		final applyScale = Config.ARROW_PATHS_CONFIG.APPLY_SCALE;
		final applyVisuals = colored || applyAlpha || applyScale;

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

			final output = parent.getReceptorPathInto(_scratch, _paramBuf, _output, _outputPos, _outputVisuals, 0, applyVisuals, true);

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

		// Select next frame's resolution from the curve we just transformed.
		// Straight paths quickly fall to 8 segments; curved paths gain only the
		// detail required to keep their screen-space error below one pixel.
		final straightPath = updateAdaptiveDivisions(laneSlot, divisions, pathThickness, applyDepth);
		final renderDivisions = straightPath ? 2 : divisions;
		final renderSegs = renderDivisions - 1;
		updateTris(laneSlot, renderDivisions);

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
		final laneVerts = _perLaneVertices[laneSlot];
		final laneUVT = _perLaneUVT[laneSlot];
		final laneIndices = _perLaneIndices[laneSlot];
		final laneTrans = _perLaneTransforms[laneSlot];

		var vi = 0;
		var hasC = false;
		var hasCOff = false;

		for (seg in 0...renderSegs) {
			final i0 = straightPath ? 0 : seg;
			final i1 = straightPath ? divisions - 1 : seg + 1;

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

		final command = _commands[laneSlot];
		command.parent = item;
		command.graphic = __lineGraphic;
		command.antialiasing = true;
		command.blend = NORMAL;
		command.cameras = ModchartUtil.resolveCameras(parent, item, _pathCameras[laneSlot]);
		command.shader = null;
		command.vertices = laneVerts;
		command.uvs = laneUVT;
		command.indices = laneIndices;
		command.color = null;
		command.colors = laneTrans;
		command.isColored = hasC;
		command.hasColorOffsets = hasCOff;
		command.zIndex = 0;
		return command;
	}

	override function dispose() {
		__lineGraphic.destroy();
		__lineGraphic = null;
	}
}
