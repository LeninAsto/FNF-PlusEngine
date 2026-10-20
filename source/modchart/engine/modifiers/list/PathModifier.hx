package modchart.engine.modifiers.list;

import flixel.math.FlxMath;
import haxe.ds.Vector;
import modchart.backend.core.ModifierParameters;
import modchart.engine.PlayField;

/**
 * Manages path-based transformations for arrows.
 * 
 * This modifier interpolates arrow positions along a predefined path,
 * allowing smooth transitions and animations.
 * 
 * @author TheoDev
 */
class PathModifier extends Modifier {
	private static inline final MAX_PATH_NODES:Int = 4096;

	private var __path:Vector<PathNode>;
	private var __pathBound(default, set):Float;

	private var __boundDiv:Float;

	// Per-lane paths: Map<Lane, Vector<PathNode>>
	private var __lanePaths:Map<Int, Vector<PathNode>> = new Map<Int, Vector<PathNode>>();
	private final __sample:Vector3 = new Vector3();
	private final __originSample:Vector3 = new Vector3();

	function set___pathBound(value:Float):Float {
		if (!Math.isFinite(value) || value <= 0) {
			__boundDiv = 0;
			return __pathBound = 0;
		}
		__boundDiv = 1 / value;
		return __pathBound = value;
	}

	public var pathOffset:Vector3 = new Vector3();

	public function new(pf:PlayField, ?path:Array<PathNode>) {
		super(pf);

		__pathBound = 1500;
		loadPath(path);
	}

	public inline function setPathBound(value:Float):Void {
		__pathBound = value;
	}

	public inline function getPathBound():Float {
		return __pathBound;
	}

	private function copyValidPath(newPath:Array<PathNode>):Vector<PathNode> {
		if (newPath == null || newPath.length <= 0)
			return new Vector<PathNode>(0);

		final clean:Array<PathNode> = [];
		final limit = FlxMath.minInt(newPath.length, MAX_PATH_NODES);
		for (i in 0...limit) {
			final node = newPath[i];
			if (node == null || !Math.isFinite(node.x) || !Math.isFinite(node.y) || !Math.isFinite(node.z))
				continue;
			clean.push({x: node.x, y: node.y, z: node.z});
		}
		return Vector.fromArrayCopy(clean);
	}

	public function loadPath(newPath:Array<PathNode>) {
		__path = copyValidPath(newPath);
	}

	public function loadPathForLane(newPath:Array<PathNode>, lane:Int) {
		if (newPath == null || newPath.length <= 0) {
			__lanePaths.remove(lane);
			return;
		}
		final clean = copyValidPath(newPath);
		if (clean.length <= 0)
			__lanePaths.remove(lane);
		else
			__lanePaths.set(lane, clean);
	}

	public inline function clearLanePaths():Void {
		__lanePaths.clear();
	}

	public function getPathForLane(lane:Int):Vector<PathNode> {
		final lanePath = __lanePaths.get(lane);
		return lanePath != null ? lanePath : __path;
	}

	private function samplePathInto(activePath:Vector<PathNode>, distance:Float, output:Vector3):Bool {
		final pathLength = activePath.length;
		if (pathLength <= 0)
			return false;

		if (pathLength == 1) {
			output.setTo(activePath[0].x, activePath[0].y, activePath[0].z);
		} else {
			final progress = (pathLength - 1) * FlxMath.bound(distance, 0, __pathBound) * __boundDiv;
			final nodeIndex = Std.int(Math.floor(progress));
			final nextNodeIndex = FlxMath.minInt(nodeIndex + 1, pathLength - 1);
			final ratio = progress - nodeIndex;
			final node = activePath[nodeIndex];
			final nextNode = activePath[nextNodeIndex];
			output.setTo(FlxMath.lerp(node.x, nextNode.x, ratio), FlxMath.lerp(node.y, nextNode.y, ratio),
				FlxMath.lerp(node.z, nextNode.z, ratio));
		}
		return true;
	}

	/**
	 * Samples and applies a path without per-call allocations. When originWeight
	 * is non-zero, the sampled origin is subtracted from every point. This makes
	 * a moving path window possible while its receptor remains anchored.
	 */
	public function computePathAt(pos:Vector3, lane:Int, distance:Float, percent:Float, relative:Bool = false, extraZ:Float = 0,
			originDistance:Float = 0, originWeight:Float = 0, useAnchor:Bool = false, anchorX:Float = 0, anchorY:Float = 0,
			anchorZ:Float = 0):Vector3 {
		if (percent == 0 || !Math.isFinite(percent) || !Math.isFinite(distance) || __pathBound <= 0 || __boundDiv == 0)
			return pos;

		final activePath = getPathForLane(lane);
		if (!samplePathInto(activePath, distance, __sample))
			return pos;

		var pathX = __sample.x;
		var pathY = __sample.y;
		var pathZ = __sample.z;
		if (originWeight != 0 && Math.isFinite(originDistance) && samplePathInto(activePath, originDistance, __originSample)) {
			final weight = FlxMath.bound(originWeight, 0, 1);
			pathX -= __originSample.x * weight;
			pathY -= __originSample.y * weight;
			pathZ -= __originSample.z * weight;
		}

		if (relative) {
			pos.x += pathX * percent;
			pos.y += pathY * percent;
			pos.z += pathZ * percent;
		} else {
			final offsetX = useAnchor ? anchorX : pathOffset.x;
			final offsetY = useAnchor ? anchorY : pathOffset.y;
			final offsetZ = useAnchor ? anchorZ : pathOffset.z + extraZ;
			pos.x += (pathX + offsetX - pos.x) * percent;
			pos.y += (pathY + offsetY - pos.y) * percent;
			pos.z += (pathZ + offsetZ - pos.z) * percent;
		}
		return pos;
	}

	public inline function computePath(pos:Vector3, params:ModifierParameters, percent:Float):Vector3
		return computePathAt(pos, params.lane, params.distance, percent);

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}

@:structInit
class PathNode {
	public var x:Float;
	public var y:Float;
	public var z:Float;
}
