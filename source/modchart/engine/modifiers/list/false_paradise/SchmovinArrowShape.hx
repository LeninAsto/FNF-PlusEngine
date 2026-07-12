package modchart.engine.modifiers.list.false_paradise;

import flixel.math.FlxMath;

private class TimeVector extends Vector3D {
	public var startDist = 0.0;
	public var endDist = 0.0;
	public var next:TimeVector;
}

class SchmovinArrowShape extends Modifier {
	var _path:List<TimeVector>;
	var _pathDistance:Float = 0;

	static inline var SCALE:Float = 200;

	function CalculatePathDistances(path:List<TimeVector>) {
		var iterator = path.iterator();
		var last = iterator.next();
		last.startDist = 0;
		var dist = 0.0;
		var iteratorHasNext = iterator.hasNext;
		var iteratorNext = iterator.next;
		while (iteratorHasNext()) {
			var current = iteratorNext();
			var differential = current.subtract(last);
			dist += differential.length;
			current.startDist = dist;
			last.next = current;
			last.endDist = current.startDist;
			last = current;
		}
		return dist;
	}

	function GetPointAlongPath(distance:Float):Null<Vector3> {
		for (vec in _path) {
			if (FlxMath.inBounds(distance, vec.startDist, vec.endDist) && vec.next != null) {
				var ratio = (distance - vec.startDist) / vec.next.subtract(vec).length;
				return ModchartUtil.lerpVector3D(vec, vec.next, ratio);
			}
		}
		return _path.first();
	}

	function LoadPath():List<TimeVector> {
		var file = ModchartUtil.coolTextFile('modchart/arrowShape.csv');
		var path = new List<TimeVector>();
		for (line in file) {
			var coords = line.split(';');
			var vec = new TimeVector(Std.parseFloat(coords[0]), Std.parseFloat(coords[1]), Std.parseFloat(coords[2]), Std.parseFloat(coords[3]));
			vec.scaleBy(SCALE);
			path.add(vec);
		}
		_pathDistance = CalculatePathDistances(path);
		return path;
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		if (_path == null)
			_path = LoadPath();

		final perc = getPercent('schmovinArrowShape', params.player);

		if (perc == 0)
			return curPos;

		var path = GetPointAlongPath(params.distance / 1500.0 * _pathDistance);

		return ModchartUtil.lerpVector3D(curPos,
			path.add(new Vector3(WIDTH * .5, HEIGHT * .5 + 280, params.lane * getPercent('schmovinArrowShapeOffset', params.player) + curPos.z)), perc);
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
