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
	private var __path:Vector<PathNode>;
	private var __pathBound(default, set):Float;

	private var __boundDiv:Float;

	// Per-lane paths: Map<Lane, Vector<PathNode>>
	private var __lanePaths:Map<Int, Vector<PathNode>> = new Map<Int, Vector<PathNode>>();

	function set___pathBound(value:Float):Float {
		if (value <= 0) {
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

	public function loadPath(newPath:Array<PathNode>) {
		if (newPath == null || newPath.length <= 0) {
			__path = new Vector<PathNode>(0);
			return;
		}
		__path = Vector.fromArrayCopy(newPath);
	}

	public function loadPathForLane(newPath:Array<PathNode>, lane:Int) {
		if (newPath == null || newPath.length <= 0) {
			__lanePaths.remove(lane);
			return;
		}
		__lanePaths.set(lane, Vector.fromArrayCopy(newPath));
	}

	public function getPathForLane(lane:Int):Vector<PathNode> {
		if (__lanePaths.exists(lane))
			return __lanePaths.get(lane);
		return __path; // fallback to global path
	}

	public function computePath(pos:Vector3, params:ModifierParameters, percent:Float) {
		// Get the appropriate path for this lane
		final activePath = getPathForLane(params.lane);
		final __path_length = activePath.length;
		if (__path_length <= 0)
			return pos;
		if (__path_length == 1) {
			final pathNode = activePath[0];
			return new Vector3(pathNode.x, pathNode.y, pathNode.z);
		}

		if (__pathBound <= 0 || __boundDiv == 0 || Math.isNaN(params.distance))
			return pos;

		final cappedDistance = Math.min(__pathBound, params.distance);
		final rawProgress = (__path_length - 1) * cappedDistance * __boundDiv;
		final nodeProgress = FlxMath.bound(rawProgress, 0, __path_length - 1);
		final thisNodeIndex = Math.floor(nodeProgress);
		final nextNodeIndex = FlxMath.minInt(thisNodeIndex + 1, __path_length - 1);
		final nextNodeRatio = nodeProgress - thisNodeIndex;

		final thisNode = activePath[thisNodeIndex];
		final nextNode = activePath[nextNodeIndex];

		return pos.interpolate(new Vector3(FlxMath.lerp(thisNode.x, nextNode.x, nextNodeRatio), FlxMath.lerp(thisNode.y, nextNode.y, nextNodeRatio),
			FlxMath.lerp(thisNode.z, nextNode.z, nextNodeRatio)).add(pathOffset),
			percent, pos);
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}

@:structInit
class PathNode {
	public var x:Float;
	public var y:Float;
	public var z:Float;
}
