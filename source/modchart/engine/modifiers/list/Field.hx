package modchart.engine.modifiers.list;

import flixel.FlxG;
import modchart.backend.core.ModifierParameters;
import modchart.backend.core.TransformMode;
import modchart.backend.util.ModchartUtil;

class Field extends Modifier {
	var fieldXID:Int;
	var fieldYID:Int;
	var fieldZID:Int;
	var fieldDepthID:Int;
	var fieldPitchID:Int;
	var fieldYawID:Int;
	var fieldRollID:Int;
	var fieldRotateXID:Int;
	var fieldRotateYID:Int;
	var fieldRotateZID:Int;
	var fieldOriginXID:Int;
	var fieldOriginYID:Int;
	var fieldOriginZID:Int;
	final _origin:Vector3 = new Vector3();
	final _rotation:Vector3 = new Vector3();

	public function new(pf) {
		super(pf);

		fieldXID = findID('fieldX');
		fieldYID = findID('fieldY');
		fieldZID = findID('fieldZ');
		fieldDepthID = findID('fieldDepth');
		fieldPitchID = findID('fieldPitch');
		fieldYawID = findID('fieldYaw');
		fieldRollID = findID('fieldRoll');
		fieldRotateXID = findID('fieldRotateX');
		fieldRotateYID = findID('fieldRotateY');
		fieldRotateZID = findID('fieldRotateZ');
		fieldOriginXID = findID('fieldOriginX');
		fieldOriginYID = findID('fieldOriginY');
		fieldOriginZID = findID('fieldOriginZ');
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		final player = params.player;

		final fieldX = getUnsafe(fieldXID, player);
		final fieldY = getUnsafe(fieldYID, player);
		final fieldZ = getUnsafe(fieldZID, player) + getUnsafe(fieldDepthID, player);
		final fieldPitch = getUnsafe(fieldPitchID, player) + getUnsafe(fieldRotateXID, player);
		final fieldYaw = getUnsafe(fieldYawID, player) + getUnsafe(fieldRotateYID, player);
		final fieldRoll = getUnsafe(fieldRollID, player) + getUnsafe(fieldRotateZID, player);

		if (fieldX == 0 && fieldY == 0 && fieldZ == 0 && fieldPitch == 0 && fieldYaw == 0 && fieldRoll == 0)
			return curPos;

		if (fieldPitch != 0 || fieldYaw != 0 || fieldRoll != 0) {
			final origin = getFieldOrigin(params);
			final zScale = FlxG.height;
			_rotation.setTo(curPos.x - origin.x, curPos.y - origin.y, (curPos.z - origin.z) * zScale);
			final out = ModchartUtil.rotate3DVectorInto(_rotation, fieldPitch, fieldYaw, fieldRoll, _rotation);
			out.z /= zScale;

			origin.addToOutput(out, curPos);
		}

		curPos.x += fieldX;
		curPos.y += fieldY;
		curPos.z += fieldZ;

		return curPos;
	}

	inline function getFieldOrigin(params:ModifierParameters):Vector3 {
		final player = params.player;
		var x:Float = (WIDTH * 0.5) - ARROW_SIZE - 54 + ARROW_SIZE * 1.5;
		switch (player) {
			case 0:
				x -= WIDTH * 0.5 - ARROW_SIZE * 2 - 100;
			case 1:
				x += WIDTH * 0.5 - ARROW_SIZE * 2 - 100;
		}
		x -= 56;

		_origin.setTo(hasUnsafe(fieldOriginXID) ? getUnsafe(fieldOriginXID, player) : x,
			hasUnsafe(fieldOriginYID) ? getUnsafe(fieldOriginYID, player) : HEIGHT * 0.5,
			hasUnsafe(fieldOriginZID) ? getUnsafe(fieldOriginZID, player) : 0);
		return _origin;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;

	override public function isActive(player:Int):Bool
		return getUnsafe(fieldXID, player) != 0 || getUnsafe(fieldYID, player) != 0
			|| getUnsafe(fieldZID, player) != 0 || getUnsafe(fieldDepthID, player) != 0
			|| getUnsafe(fieldPitchID, player) != 0 || getUnsafe(fieldYawID, player) != 0 || getUnsafe(fieldRollID, player) != 0
			|| getUnsafe(fieldRotateXID, player) != 0 || getUnsafe(fieldRotateYID, player) != 0 || getUnsafe(fieldRotateZID, player) != 0;

	override public function transformMode():TransformMode
		return TransformMode.FIELD;
}
