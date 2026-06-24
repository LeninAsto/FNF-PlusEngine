package modchart.engine.modifiers.list;

import flixel.FlxG;
import modchart.backend.core.ModifierParameters;
import modchart.backend.core.TransformMode;
import modchart.backend.util.ModchartUtil;

class Field extends Modifier {
	override public function render(curPos:Vector3, params:ModifierParameters) {
		final player = params.player;

		final fieldX = getPercent('fieldX', player);
		final fieldY = getPercent('fieldY', player);
		final fieldDepth = getPercent('fieldDepth', player);
		final fieldYaw = getPercent('fieldYaw', player);

		if (fieldX == 0 && fieldY == 0 && fieldDepth == 0 && fieldYaw == 0)
			return curPos;

		// Yaw is the only real 3D field action here; the other submods are plain offsets.
		if (fieldYaw != 0) {
			final origin:Vector3 = new Vector3(FlxG.width * 0.5, FlxG.height * 0.5);
			final zScale = FlxG.height;
			final diff = curPos.subtract(origin);
			diff.z *= zScale;

			final out = ModchartUtil.rotate3DVector(diff, 0, fieldYaw, 0);
			out.z /= zScale;

			origin.addToOutput(out, curPos);
		}

		curPos.x += fieldX;
		curPos.y += fieldY;
		curPos.z += fieldDepth;

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function transformMode():TransformMode
		return TransformMode.FIELD;
}
