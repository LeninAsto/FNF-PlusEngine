package modchart.engine.modifiers.list;

import flixel.math.FlxMath;
import modchart.backend.core.ModifierParameters;

class Snap extends Modifier {
	var amountIDs:Array<Int>;
	var intervalIDs:Array<Int>;

	public function new(pf) {
		super(pf);
		setPercent('snapXInterval', 64, -1);
		setPercent('snapYInterval', 64, -1);
		setPercent('snapZInterval', 64, -1);
		amountIDs = [findID('snapX'), findID('snapY'), findID('snapZ')];
		intervalIDs = [findID('snapXInterval'), findID('snapYInterval'), findID('snapZInterval')];
	}

	inline function snapped(value:Float, interval:Float):Float
		return interval > 0 ? Math.round(value / interval) * interval : value;

	override public function render(pos:Vector3, params:ModifierParameters) {
		final player = params.player;
		final x = getUnsafe(amountIDs[0], player);
		final y = getUnsafe(amountIDs[1], player);
		final z = getUnsafe(amountIDs[2], player);
		if (x != 0) pos.x = FlxMath.lerp(pos.x, snapped(pos.x, getUnsafe(intervalIDs[0], player)), x);
		if (y != 0) pos.y = FlxMath.lerp(pos.y, snapped(pos.y, getUnsafe(intervalIDs[1], player)), y);
		if (z != 0) pos.z = FlxMath.lerp(pos.z, snapped(pos.z, getUnsafe(intervalIDs[2], player)), z);
		return pos;
	}

	override public function shouldRun(params:ModifierParameters):Bool return true;
	override public function isActive(player:Int):Bool
		return getUnsafe(amountIDs[0], player) != 0 || getUnsafe(amountIDs[1], player) != 0 || getUnsafe(amountIDs[2], player) != 0;
	override public function allowOnStraightHolds():Bool return false;
}
