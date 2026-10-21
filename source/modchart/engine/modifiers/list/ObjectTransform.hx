package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;
import modchart.backend.core.TransformMode;
import modchart.backend.core.VisualParameters;

class ObjectTransform extends Modifier {
	static final TYPES = ['note', 'hold', 'receptor'];
	static final AXES = ['X', 'Y', 'Z'];

	var positionIDs:Array<Array<Int>>;
	var angleIDs:Array<Array<Int>>;
	var scaleIDs:Array<Array<Int>>;

	public function new(pf) {
		super(pf);
		positionIDs = [for (type in TYPES) [for (axis in AXES) findID(type + axis)]];
		angleIDs = [for (type in TYPES) [for (axis in AXES) findID(type + 'Angle' + axis)]];
		scaleIDs = [for (type in TYPES) [findID(type + 'Scale'), findID(type + 'ScaleX'), findID(type + 'ScaleY')]];
		for (type in TYPES) {
			setPercent(type + 'Scale', 1, -1);
			setPercent(type + 'ScaleX', 1, -1);
			setPercent(type + 'ScaleY', 1, -1);
		}
	}

	inline function objectType(params:ModifierParameters):Int
		return params.isHoldBody ? 1 : (params.isTapArrow ? 0 : 2);

	override public function render(pos:Vector3, params:ModifierParameters) {
		final ids = positionIDs[objectType(params)];
		pos.x += getUnsafe(ids[0], params.player);
		pos.y += getUnsafe(ids[1], params.player);
		pos.z += getUnsafe(ids[2], params.player);
		return pos;
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters):VisualParameters {
		final type = objectType(params);
		final angles = angleIDs[type];
		data.angleX += getUnsafe(angles[0], params.player);
		data.angleY += getUnsafe(angles[1], params.player);
		data.angleZ += getUnsafe(angles[2], params.player);
		final scales = scaleIDs[type];
		final common = getUnsafe(scales[0], params.player);
		data.scaleX *= common * getUnsafe(scales[1], params.player);
		data.scaleY *= common * getUnsafe(scales[2], params.player);
		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool return true;
	override public function isActive(player:Int):Bool {
		for (type in 0...TYPES.length) {
			for (axis in 0...3)
				if (getUnsafe(positionIDs[type][axis], player) != 0 || getUnsafe(angleIDs[type][axis], player) != 0)
					return true;
			for (id in scaleIDs[type]) if (getUnsafe(id, player) != 1) return true;
		}
		return false;
	}
	override public function transformMode():TransformMode return TransformMode.NOTE | TransformMode.RECEPTOR;
}
