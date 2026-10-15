package modchart.engine.modifiers.list;

import flixel.FlxG;
import modchart.backend.core.ModifierParameters;

class CenterRotate extends Rotate {
	private final centerOrigin:Vector3 = new Vector3();

	override public function getOrigin(curPos:Vector3, params:ModifierParameters):Vector3 {
		centerOrigin.setTo(FlxG.width * 0.5, HEIGHT * 0.5, 0);
		return centerOrigin;
	}

	override public function getRotateName():String
		return 'centerRotate';

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
