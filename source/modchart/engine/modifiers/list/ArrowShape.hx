package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;
import modchart.engine.PlayField;
import modchart.engine.modifiers.list.PathModifier.PathNode;
class ArrowShape extends PathModifier {
	public function new(pf:PlayField) {
		var path:Array<PathNode> = [];

		for (line in ModchartUtil.coolTextFile('modchart/arrowShape.csv')) {
			var coords = line.split(';');
			path.push({
				x: Std.parseFloat(coords[0]) * 200,
				y: Std.parseFloat(coords[1]) * 200,
				z: Std.parseFloat(coords[2]) * 200
			});
		}

		super(pf, path);

		pathOffset.setTo(WIDTH * 0.5, HEIGHT * 0.5 + 280, 0);
	}

	override function render(pos:Vector3, params:ModifierParameters) {
		if (!params.isTapArrow)
			return pos;

		var perc = getPercent('arrowshape', params.player);

		if (perc == 0)
			return pos;

		pathOffset.z = pos.z;
		return computePath(pos, params, perc);
	}
}
