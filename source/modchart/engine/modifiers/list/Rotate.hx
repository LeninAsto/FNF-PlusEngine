package modchart.engine.modifiers.list;

import flixel.FlxG;
import modchart.backend.core.ModifierParameters;
import modchart.backend.util.ModchartUtil;

class Rotate extends Modifier {
	private final origin:Vector3 = new Vector3();
	private var _angleXID:Int = -1;
	private var _angleYID:Int = -1;
	private var _angleZID:Int = -1;

	inline private function ensureIDs():Void {
		if (_angleXID >= 0)
			return;
		final name = getRotateName();
		_angleXID = findID(name + 'X');
		_angleYID = findID(name + 'Y');
		_angleZID = findID(name + 'Z');
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		ensureIDs();
		var player = params.player;

		var angleX = getUnsafe(_angleXID, player);
		var angleY = getUnsafe(_angleYID, player);
		var angleZ = getUnsafe(_angleZID, player);

		// does angleY work here if angleX and angleZ are disabled? - ye
		if (angleX == 0 && angleY == 0 && angleZ == 0)
			return curPos;

		final origin:Vector3 = getOrigin(curPos, params);
		curPos -= origin;
		ModchartUtil.rotate3DVectorInto(curPos, angleX, angleY, angleZ, curPos);
		curPos += origin;
		return curPos;
	}

	public function getOrigin(curPos:Vector3, params:ModifierParameters):Vector3 {
		var fixedLane = Math.round(getKeyCount(params.player) * .5);
		origin.setTo(getReceptorX(fixedLane, params.player), FlxG.height / 2, 0);
		return origin;
	}

	public function getRotateName():String
		return 'rotate';

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function isActive(player:Int):Bool {
		ensureIDs();
		return getUnsafe(_angleXID, player) != 0 || getUnsafe(_angleYID, player) != 0 || getUnsafe(_angleZID, player) != 0;
	}
}
