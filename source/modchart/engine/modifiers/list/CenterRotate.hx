package modchart.engine.modifiers.list;

import flixel.FlxG;
import modchart.backend.core.ModifierParameters;

class CenterRotate extends Rotate {
	override public function getOrigin(curPos:Vector3, params:ModifierParameters):Vector3 {
		return new Vector3(FlxG.width * 0.5, HEIGHT * 0.5);
	}

	override public function getRotateName():String
		return 'centerRotate';

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
